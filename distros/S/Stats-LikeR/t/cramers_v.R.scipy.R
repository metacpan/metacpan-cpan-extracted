# Generator for t/cramers_v.R.scipy.t (the R half).  Prints Perl literals.
#   Rscript t/cramers_v.R.scipy.R
# Tables are those of R 4.6.1 src/library/stats/man/chisq.test.Rd and
# fisher.test.Rd examples, plus mtcars (R's datasets package).  chisq.test(
# correct = FALSE) gives the uncorrected Pearson statistic V is built from.
# R has no Cramer's V; V = sqrt(X2 / (n * min(r-1, c-1))), and the Bergsma
# (2013, J. Korean Stat. Soc. 42:323-328) correction is written out here from
# the paper's formulas, independently of lib/Stats/LikeR.pm:
#   phi2c = max(0, phi2 - (r-1)(c-1)/(n-1)), rc = r - (r-1)^2/(n-1),
#   cc = c - (c-1)^2/(n-1), Vc = sqrt(phi2c / min(rc-1, cc-1)).
options(digits = 17, warn = -1)
emit <- function(name, M) {
	M <- as.matrix(M)
	X <- chisq.test(M, correct = FALSE)
	n <- sum(M); r <- nrow(M); c <- ncol(M)
	V <- sqrt(unname(X$statistic) / (n * (min(r, c) - 1)))
	phi2 <- unname(X$statistic) / n
	phi2c <- max(0, phi2 - (r - 1) * (c - 1) / (n - 1))
	rc <- r - (r - 1)^2 / (n - 1); cc <- c - (c - 1)^2 / (n - 1)
	Vc <- sqrt(phi2c / (min(rc, cc) - 1))
	cat(sprintf("\t%-12s => { chisq => %s, df => %d, n => %d, v => %s, vc => %s },\n",
		name, format(unname(X$statistic), digits = 17), r*c - r - c + 1, as.integer(n),
		format(V, digits = 17), format(Vc, digits = 17)))
}
emit("agresti", rbind(c(762, 327, 468), c(484, 239, 477)))
emit("x2x2", matrix(c(12, 5, 7, 7), ncol = 2))
emit("convictions", matrix(c(2, 10, 15, 3), nrow = 2))
emit("job", matrix(c(1,2,1,0, 3,3,6,1, 10,10,14,9, 6,7,12,11), 4, 4))
emit("scipy_obs1", rbind(c(12,13,14,15,16), c(17,16,18,19,11), c(9,15,14,12,11)))
emit("mtcars", table(mtcars$cyl, mtcars$gear))
emit("trivial", rbind(c(1,2), c(1,2)))
emit("perfect", rbind(c(10,0), c(0,10)))
emit("perfect3", rbind(c(5,0,0), c(0,7,0), c(0,0,9)))
emit("small", rbind(c(3,1), c(1,3)))
emit("tall", rbind(c(10,20), c(30,40), c(25,5), c(8,12)))
cat("# mtcars cyl, gear vectors\n")
cat("cyl  =", deparse(mtcars$cyl), "\n"); cat("gear =", deparse(mtcars$gear), "\n")
