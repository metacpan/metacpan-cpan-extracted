postscript("file2.ps" , horizontal=FALSE , width=500 , height=500 , pointsize=1)

plot(c(1, 5, 10), type = "l")

dev.off()

unlink("file2.ps")

for (j in 1:3) { cat("loop iteration: "); print(j); }

write("Some innocuous message on stdout\n", stdout())

write("Some innocuous message on stderr\n", stderr())

x <- 123
print(x)

x <- 456 ; write.table(x, file="", row.names=FALSE, col.names=FALSE)

a <- 2
b <- 5
c <- a * b
print('ok')

