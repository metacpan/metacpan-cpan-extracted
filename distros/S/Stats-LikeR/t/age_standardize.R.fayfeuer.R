# Generator for t/age_standardize.R.fayfeuer.t.  Run with
#     Rscript t/age_standardize.R.fayfeuer.R
# R has no age-standardization function in base or in the packages in
# ~/Scripts/r-pkg-sources (survey's svystandardize() post-stratifies a design,
# a different estimator), and epitools, whose ageadjust.direct() the README
# names, is not installed.  So this is the Fay-Feuer (1997, Stat Med 16:791-801)
# directly standardized rate and gamma interval written out in base R with
# qgamma, the algorithm epitools::ageadjust.direct implements (transcribed from
# the paper and from memory of that function, NOT checked against its source):
#   w = stdpop / sum(stdpop); rate = count / pop
#   dsr = sum(w * rate); v = sum(w^2 * count / pop^2); wm = max(w / pop)
#   lower = qgamma(a/2,   shape = dsr^2 / v,              scale = v / dsr)
#   upper = qgamma(1-a/2, shape = (dsr+wm)^2 / (v + wm^2), scale = (v+wm^2) / (dsr+wm))
# crude = sum(count) / sum(pop).  R 4.6.2.
options(digits = 17)
emit <- function(name, count, pop, stdpop, cl = 0.95, per = 1) {
	a <- 1 - cl
	w <- stdpop / sum(stdpop); rate <- count / pop
	dsr <- sum(w * rate); v <- sum(w^2 * count / pop^2); wm <- max(w / pop)
	lo <- qgamma(a / 2, shape = dsr^2 / v, scale = v / dsr)
	hi <- qgamma(1 - a / 2, shape = (dsr + wm)^2 / (v + wm^2), scale = (v + wm^2) / (dsr + wm))
	f <- function(x) format(x * per, digits = 17)
	cat(sprintf("\t[ '%s', [%s], [%s], [%s], %s, %s, %s, %s, %s, %s, %s ],\n", name,
		paste(count, collapse = ", "), paste(pop, collapse = ", "),
		paste(stdpop, collapse = ", "), format(cl), format(per),
		f(sum(count) / sum(pop)), f(dsr), f(lo), f(hi), f(sqrt(v))))
}
emit("readme",  c(5, 20, 55, 60), c(1000, 3000, 4000, 2000), c(2000, 3000, 3000, 2000))
emit("per1e5",  c(5, 20, 55, 60), c(1000, 3000, 4000, 2000), c(2000, 3000, 3000, 2000), per = 1e5)
emit("cl90",    c(5, 20, 55, 60), c(1000, 3000, 4000, 2000), c(2000, 3000, 3000, 2000), cl = 0.90)
emit("cl99",    c(5, 20, 55, 60), c(1000, 3000, 4000, 2000), c(2000, 3000, 3000, 2000), cl = 0.99)
emit("cl50",    c(5, 20, 55, 60), c(1000, 3000, 4000, 2000), c(2000, 3000, 3000, 2000), cl = 0.50)
emit("zerocell", c(0, 2, 15, 40, 90), c(5000, 8000, 9000, 6000, 3000), c(1, 2, 3, 2, 1))
emit("rare",    c(0, 0, 1, 2), c(100000, 90000, 80000, 50000), c(30, 30, 25, 15), per = 1e5)
emit("single",  c(12), c(400), c(1))
emit("big",     c(120, 540, 2310, 5800, 9000), c(1e5, 2e5, 3e5, 2.5e5, 1e5), c(0.2, 0.3, 0.25, 0.15, 0.1), cl = 0.999)
emit("equalwt", c(3, 7, 11), c(100, 100, 100), c(1, 1, 1))
