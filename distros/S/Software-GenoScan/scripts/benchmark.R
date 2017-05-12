#Suppress warnings
options(warn=-1)

#Read command-line arguments
args <- commandArgs(trailingOnly=TRUE)
posDataset <- args[1]
negDataset <- args[2]
genDataset <- args[3]

#Read datasets
pos.df <- read.table(posDataset, header=TRUE, as.is=TRUE, dec=".", sep="\t", row.names=1)
neg.df <- read.table(negDataset, header=TRUE, as.is=TRUE, dec=".", sep="\t", row.names=1)
gen.df <- read.table(genDataset, header=TRUE, as.is=TRUE, dec=".", sep="\t", row.names=1)
mirna.df <- rbind(pos.df, neg.df)

#Define model respone and explanatory variables
mirna.df[,1] <- as.factor(mirna.df[,1])
covar <- colnames(mirna.df)[-1]
form <- paste("MIRNA ~ ", paste(covar, sep=" + ", collapse=" + "), sep="", collapse="")

#Fit model to whole dataset
model <- glm(formula = form, family=binomial(logit), data=mirna.df)

#Benchmarking with leave-one-out cross validation
TP <- c()
FN <- c()
TN <- c()
FP <- c()
SN <- c()
SP <- c()
MCC <- c()
FDR <- c()
GPR <- c()
Probability <- c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)
for(thresh in Probability){
	
	#Estimate SN, SP, FDR and MCC with the pos/neg dataset
	tp <- 0
	fn <- 0
	tn <- 0
	fp <- 0
	numHp <- length(rownames(mirna.df))
	for(index in c(1:numHp)){
		cat("    Threshold", thresh, "LOOCV round", index, "/", numHp, "     \r")
		
		#Define test and training set
		test.hp <- mirna.df[index,]
		train.hp <- mirna.df[-index,]
		
		#Fit model to training set
		cv.model <- glm(formula = form, family=binomial(logit), data=train.hp)
		
		#Classify test set
		prob <- predict(cv.model, test.hp, type="response")[1]
		true.class <- as.numeric(test.hp[,1]) - 1
		if(true.class == 1){
			if(prob >= thresh){
				tp <- tp + 1
			}
			else{
				fn <- fn + 1
			}
		}
		else{
			if(prob >= thresh){
				fp <- fp + 1
			}
			else{
				tn <- tn + 1
			}
		}
	}
	TP <- c(TP, tp)
	FN <- c(FN, fn)
	TN <- c(TN, tn)
	FP <- c(FP, fp)
	SN <- c(SN, (tp / (tp + fn)) * 100)
	SP <- c(SP, (tn / (tn + fp)) * 100)
	MCC <- c(MCC, ((tp * tn) - (fp * fn)) / sqrt((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn)))
	FDR <- c(FDR, (fp / (fp + tp)) * 100)
	
	#Estimate GPR with the genomic dataset
	cat("    Threshold", thresh, "Estimating GPR            \r")
	numPred <- 0
	numHp <- length(rownames(gen.df))
	for(index in c(1:numHp)){
		gen.hp <- gen.df[index,]
		prob <- predict(model, gen.hp, type="response")[1]
		if(prob >= thresh){
			numPred <- numPred + 1
		}
	}
	GPR <- c(GPR, (numPred / numHp) * 100)
}
cat("\n")

#Write performance matrix to file
perMat <- matrix(data=c(Probability, TP, FN, TN, FP, SN, SP, MCC, FDR, GPR), nrow=9)
colnames(perMat) <- c("Probability", "TP", "FN", "TN", "FP", "SN", "SP", "MCC", "FDR", "GPR")
write.table(perMat, file="performance_matrix", row.names=FALSE, col.names=TRUE, sep="\t", quote=FALSE)
