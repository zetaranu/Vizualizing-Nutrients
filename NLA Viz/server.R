library(shiny)
library(RCurl)
library(ggplot2)
library(lme4)
library(data.table)
NLA_MB.URL<-getURL("https://raw.githubusercontent.com/Monsauce/Vizualizing-Nutrients/master/NLAdataset.csv")
NLA_MB<-read.csv(text=NLA_MB.URL)

# Renaming variables
NLA_MB$MC <- NLA_MB$MCYST_TL_UGL
NLA_MB$CY <- NLA_MB$ALL.CYANOS

# Transform skewed variables
NLA_MB$log10MC <- log10(NLA_MB$MC)
NLA_MB$ssCY <- (NLA_MB$CY)^0.25
NLA_MB$log10NTL <- log10(NLA_MB$NTL)
NLA_MB$log10PTL <- log10(NLA_MB$PTL)
mod<-lmer(ssCY ~ log10NTL + (log10NTL|ECO_NUTA), data=NLA_MB)

# Define a server for the Shiny app
shinyServer(function(input, output) {
  # ui buttons
  output$slider <- renderUI({
    sliderInput(inputId="nut",
                label="Choose your nitrogen input",
                value=2, min=0.7, max=5.0)
  })
  # reactive functions
  getData <- reactive({
    df <- data.table(NLA_MB)
    df <- df[, list(LON_DD, 
                    LAT_DD, 
                    ECO_NUTA,
                    ni = input$nut)]
    
    return(df)
  })
  
  predictData <- reactive({
    dt <- getData()
    setnames(dt, old = "ni", new =  c("log10NTL"))
    predictions <- predict(mod, newdata = dt)
    dt[, `:=`(predictions = predictions)]
    return(dt)
  })
  output$test <- renderDataTable({
    dt <- predictData()
    return(dt)
  })
  output$CyanoMap <- renderPlot({
    Cyano <- predictData()
    all_states <- map_data("state")
    p <- ggplot()+geom_polygon(data=all_states, aes(x=long, y=lat, group = group),colour="grey70", fill="grey70" )+
      geom_point(data=Cyano, aes(colour=ECO_NUTA, x=LON_DD, y=LAT_DD, size = predictions))+
      theme(legend.position="none")+ 
      theme(axis.text.y = element_blank())+
      theme(axis.ticks = element_blank())+
      theme(axis.text.x = element_blank())+
      theme(axis.title.x = element_blank())+
      theme(axis.title.y = element_blank())+
      theme(panel.grid.major = element_blank())+
      theme(panel.grid.minor = element_blank())+
      theme(panel.background = element_rect(fill = "white"))
    
    return(p)
  })

})