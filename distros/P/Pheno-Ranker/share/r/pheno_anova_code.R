# matrix.txt and pheno_table in the same directory as the script. Args to introduce:
  #column disease in pheno_table ("Diagnosis_Disease.at.onset")
  #column ID (ID)
  #numeric_comorbidities (in a vector, c("Demography_Age", "Demography_Year.of.birth", "Diagnosis_Age.at.onset", "Medication_Average.Weekly.Dose", "Sampling_Disease.duration", "Symptom_Disease.activity"))

library(ggplot2)
library(ggrepel)
library(dplyr)
library(stringr)
args <- commandArgs(trailingOnly = TRUE)


#MDS plot
# Read in the input file as a matrix 
data <- as.matrix(read.table("matrix.txt", header = TRUE, row.names = 1, check.names = FALSE))

#calculate distance matrix
#d <- dist(data)

#perform multidimensional scaling 
#fit <- cmdscale(d, eig=TRUE, k=2)
fit <- cmdscale(data, eig=TRUE, k=2)

#extract (x, y) coordinates of multidimensional scaling
x <- fit$points[,1]
y <- fit$points[,2]

# Create example data frame
df <- data.frame(x, y, label=row.names(data))

# Add a new variable to the data frame based on the label prefixes
df <- df %>% mutate(label_prefix = str_extract(label, "^[^_]*_"))

# Save image
png(filename = "mds.png", width = 1000, height = 1000,
    units = "px", pointsize = 12, bg = "white", res = NA)

# Create scatter plot
ggplot(df, aes(x, y, label = label, color = label_prefix)) +
  geom_point() +
  geom_text_repel(size = 5, # Adjust the size of the text
                  box.padding = 0.2, # Adjust the padding around the text
                  max.overlaps = 10) + # Change the maximum number of overlaps
  labs(title = "Multidimensional Scaling Results",
       x = "Hamming Distance MDS Coordinate 1",
       y = "Hamming Distance MDS Coordinate 2") + # Add title and axis labels
  theme(
    plot.title = element_text(size = 30, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 25),
    axis.text = element_text(size = 15),
    legend.position = "right")
#legend.position = "none") # remove legend

dev.off()


df$disease <- unlist(lapply(strsplit(df$label,split = "_"),`[[`,1))
df$ID <- unlist(lapply(strsplit(df$label,split = "_"),`[[`,2))

#ANOVA table
pheno_table <- read.table(file="pheno_table.csv", sep = ';', header = TRUE)

anova_all<- function(mds,pheno_table, omicID_column, numeric_comorbidities){
  coordinates<- colnames(mds)[1:2]
  comorbidities <- colnames(pheno_table[,-which(colnames(pheno_table) == omicID_column)])
  #merge two tables
  big_table <- merge(mds, pheno_table, by=omicID_column) 
  
  table.results <- data.frame("dim"=NA,"comorbidity"=NA, "Df"=NA, "Sum_Sq"=NA,"Mean_Sq"=NA, "F_value"=NA,  "Pr"=NA,"issue"=NA )
  for (coor in coordinates) {
    for (com in comorbidities) {
      paste_rowname <- paste0(coor,"_",com)
      table.results[paste_rowname,"dim"] <- coor
      table.results[paste_rowname,"comorbidity"] <- com
      
      if(all(is.na( big_table[,com]))){
        #check if there is only NA values
        table.results[paste_rowname,"issue"] <- "only NA values"
      }
      
      else{
        if (com %in% numeric_comorbidities) {
          #check and analyse numeric variables
          table.results[paste_rowname,"issue"] <- "Numeric"
          big_table[,com] <- as.numeric(big_table[,com])
          aov_table <- summary(aov(as.formula(paste0(coor,"~",com)), big_table))
          
          table.results[paste_rowname,3:7] <-unlist(aov_table[[1]][1,])
        }
        
        else{
          #check if there is only 1 value
          big_table[,com] <- factor(big_table[,com], levels=unique(big_table[,com])[order(unique(big_table[,com]))]) 
          if(length(levels(big_table[,com]))==1){
            table.results[paste_rowname,"issue"] <- paste0("only 1 level: ",levels(big_table[,com]))
          }
          else{
            #the remaining values are categoric
            table.results[paste_rowname,"issue"] <- "Categoric"
            aov_table <- summary(aov(as.formula(paste0(coor,"~",com)), big_table))
            table.results[paste_rowname,3:7] <-unlist(aov_table[[1]][1,])
          }
        }
      }
    }
  }
  
  table.results <- table.results[-1,]
  #adjust pval
  table.results$p_BH <- p.adjust(table.results$Pr,method = "BH")
  
  #table only with x dimension results
  table.results.x <- table.results[table.results[,"dim"]=="x",]
  rownames(table.results.x) <- table.results.x[,"comorbidity"]
  table.results.x <- table.results.x[,-which(colnames(table.results.x)=="comorbidity")]
  colnames(table.results.x) <- paste0(colnames(table.results.x),"_","x")
  table.results.x <- table.results.x[,-which(colnames(table.results.x)=="dim_x")]
  
  #table only with y dimension results
  table.results.y <- table.results[table.results[,"dim"]=="y",]
  rownames(table.results.y) <- table.results.y[,"comorbidity"]
  table.results.y <- table.results.y[,-which(colnames(table.results.y)=="comorbidity")]
  colnames(table.results.y) <- paste0(colnames(table.results.y),"_","y")
  table.results.y <- table.results.y[,-which(colnames(table.results.y)=="dim_y")]
  
  #merge tables
  merged.table.results <- merge(table.results.x,table.results.y,by="row.names")
  rownames(merged.table.results) <- merged.table.results[,"Row.names"]
  merged.table.results <- merged.table.results[,-which(colnames(merged.table.results)=="Row.names")]
  
  #obtain metap value
  library(metap)
  #to emphasise small p values, they recomend sumlog (fisher) or minimump (tippett) https://rdrr.io/cran/metap/f/inst/doc/compare.pdf
  metap.values <- data.frame("chisq"=NA, "df"=NA, "metap"=NA)
  for (com in comorbidities) {
    pvals.tometap <- merged.table.results[com,c("Pr_x","Pr_y")]
    if(any(is.na(pvals.tometap))){
      metap.values[com,] <- NA
    }
    else{
      all.values.sumlog <- sumlog(pvals.tometap)
      metap.values[com,"chisq"] <- all.values.sumlog$chisq
      metap.values[com,"df"] <- all.values.sumlog$df
      metap.values[com,"metap"] <- all.values.sumlog$p
    }
  }
  metap.values <- metap.values[-1,]
  
  merged.table.results2 <- merge(merged.table.results, metap.values, by="row.names")
  rownames(merged.table.results2) <- merged.table.results2[,"Row.names"]
  merged.table.results2 <- merged.table.results2[,-which(colnames(merged.table.results2)=="Row.names")]
  
  #adjust pval
  merged.table.results2$metap_BH <- p.adjust(merged.table.results2$metap,method = "BH")
  return(merged.table.results2)
}

anova_all_table <- anova_all(df, pheno_table[,-which(colnames(pheno_table)==args[1])], args[2], args[3:length(args)])
anova_all_table <- cbind(rownames(anova_all_table), anova_all_table)
colnames(anova_all_table)[1] <- "characteristic"
write.table(anova_all_table, file = "anova_mds.csv", quote = FALSE, sep=";",row.names = FALSE,col.names = TRUE,dec = ".")


