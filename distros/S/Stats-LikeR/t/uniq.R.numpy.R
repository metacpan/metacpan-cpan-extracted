# R half of the generator for t/uniq.R.numpy.t.  Re-run with
#     Rscript t/uniq.R.numpy.R
# (R 4.6.2 printed the values committed in the test on 2026-11-26.)
options(digits = 17)
x <- c(3:5, 11:8, 8 + 0:5)           # unique.Rd, \examples
cat("unique.Rd ux:", unique(x), "\n")
nx <- 0.3 + 2e-16 * -2:2             # reg-tests-1b.R, as.character(<numeric>)
cat("1b nx unique as.character:", unique(as.character(nx)), "\n")
cat("1b nx unique numeric count:", length(unique(nx)), "\n")
cat("unique(c(5,7,1,2,1,5,7)):", unique(c(5, 7, 1, 2, 1, 5, 7)), "\n")
cat("unique(c(0,-0)):", length(unique(c(0, -0))), "\n")
cat("unique(c(NaN,NA,NaN,1)):", length(unique(c(NaN, NA, NaN, 1))), "\n")
cat("unique(c(-Inf,Inf,Inf)):", unique(c(-Inf, Inf, Inf)), "\n")
cat("unique(character(0)):", length(unique(character(0))), "\n")
cat("unique(c('a','A','a')):", unique(c("a", "A", "a")), "\n")
