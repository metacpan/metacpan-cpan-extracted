#!/usr/bin/env Rscript
## created on 2013-08-30

scale_human <- function(m, info) {
  for(i in 1:nrow(info)) {
    cp <- prod(info[1:i,"factor"])
    if(m/cp < 100)
      return( list(factor=cp,abbr=as.character(info[i,"abbr"])))
  }
  return(list(factor=c(1), abbr=as.character(info[1, "abbr"])))
}

args <- commandArgs(T)

fin <- args[1]
fout <- args[2]

## some basic checks
if(is.na(fout))
  fout <- paste0(fin,".pdf", collapse="")
cat("INPUT:",  fin,  "\n", file=stderr())
cat("OUTPUT:", fout, "\n", file=stderr())
if(fin == fout)
  stop("input and output files are the same")

if(file.info(fin)$size == 0)
  stop("input file empty")

z <- read.table(fin, header=TRUE, sep="\t", fill=TRUE)
## get rid of incomplete columns (sometimes incomplete output while the profiling is running)
z.incomplete.idx <- apply(z,c(1), function(x) { any(is.na(x)) })

z <- z[!z.incomplete.idx,]

if(nrow(z) < 3)
  stop("at least 3 data points are needed")

cat("data rows:", nrow(z), "\n", file=stderr())
z[!is.finite(z[,"pcpu"]),"pcpu"] <- 0

info.byte <- data.frame(factor=c(1,1024,1024,1024), abbr=c("b", "kb", "mb", "gb"))
info.ts <- data.frame(factor=c(1, 60, 60, 24), abbr=c("sec", "min", "h", "d"))

t.scale <- scale_human(max(z[,"time"]), info.ts)
m.scale <- scale_human(median(z[,"rss"]), info.byte)

k2 <- with(z, by(z, tp, function(x) {
    c(
      t=mean(x[,"time"])/t.scale[["factor"]],
      m=mean(x[,"rss"])/m.scale[["factor"]],
      pc=mean(x[,"pcpu"])
    )
}))
k <- as.data.frame(do.call(rbind,k2))
k$pc <- k$pc * 100


## old method. Got rid of plyr dependency
#library(plyr)
#k <- ddply(z7, .(tp), summarise, t=mean(time)/t.scale[["factor"]], m=mean(rss)/m.scale[["factor"]], pc=mean(pcpu))

span <- 0.3
#if(nrow(k) > 300)
  #span <- 1/20

pdf(fout,width=13, height=6)
plot(
     pc ~ t,
     data=k,
     xlab=paste0("time in ", t.scale[["abbr"]], collapse=" "),
     ylab="% cpu usage",
     cex=0.3,
     pch=16,
     col="grey20"
     )
with(k, lines(loess.smooth(t, pc, span=span), col = "brown", lwd=1.6))
plot(
     m ~ t,
     data=k,
     xlab=paste0("time in ", t.scale[["abbr"]], collapse=" "),
     ylab=paste0("mem in ", m.scale[["abbr"]], collapse=" "),
     cex=0.3,
     pch=16,
     col="grey20"
    )
with(k, lines(loess.smooth(t, m, span=span), col = "brown", lwd=1.6))
dev.off()
