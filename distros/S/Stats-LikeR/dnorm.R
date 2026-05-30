for (x in -5:5) {
	cat(sprintf('%.15f', dnorm(x)), "\n")
}
for (x in seq(-3,3,0.5)) {
	cat(x, sprintf('%.15f', dnorm(x)), "\n")
}
cat('mean = 0, sd = 2', sprintf('%.15f', dnorm(0, sd = 2)), "\n")
cat('mean = 0, sd = 2', sprintf('%.15f', dnorm(0, mean = 0, sd = 2)), "\n")
cat('mean = 0, sd = 2, log = true', sprintf('%.15f', dnorm(0, mean = 0, sd = 2, log = TRUE)), "\n")
