#Suppress warnings
options(warn=-1)

#Read command-line arguments
args <- commandArgs(trailingOnly=TRUE)
posDataset <- args[1]
negDataset <- args[2]

#Read datasets
pos.df <- read.table(posDataset, header=TRUE, as.is=TRUE, dec=".", sep="\t", row.names=1)
neg.df <- read.table(negDataset, header=TRUE, as.is=TRUE, dec=".", sep="\t", row.names=1)
mirna.df <- rbind(pos.df, neg.df)

#Define model respone and explanatory variables
mirna.df[,1] <- as.factor(mirna.df[,1])
covar <- colnames(mirna.df)[-1]
form <- paste("MIRNA ~ ", paste(covar, sep=" + ", collapse=" + "), sep="", collapse="")

#Fit model to data and write model coefficients to file
model <- glm(formula = form, family=binomial(logit), data=mirna.df)
write.table(as.matrix(model$coefficients), file="regression_model", sep="\t", quote=FALSE, col.names=FALSE)
