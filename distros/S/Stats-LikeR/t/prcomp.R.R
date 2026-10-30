# Generator for the frozen expected values in t/prcomp.R.t.
#
#   Rscript t/prcomp.R.R
#
# Prints the Perl data table that file carries; the test never runs this
# script and never calls R.  Re-run it only to regenerate the table, and paste
# the output over the table in the .t file.  Written against R 4.6.1.
#
# Provenance: stats::prcomp (prcomp.default, src/library/stats/R/prcomp.R) on
#   * README's own example, matrix(c(2,4,6,4,2,6), 3);
#   * center = FALSE, scale. = TRUE, where scale() divides by
#     sqrt(sum(x^2)/(n-1)) of the raw column;
#   * rank. = 1, where s$d is returned whole and only the rotation is cut;
#   * tests/reg-tests-1a.R's "prcomp(tol=1e-6)" case: set.seed(16);
#     x <- matrix(runif(30), ncol = 10); stopifnot(length(s$sdev) == 3,
#     ncol(s$rotation) == 2).  x is printed here exactly (m:e);
#   * a 20 x 4 matrix whose third column is the sum of the first two, exactly,
#     so that one singular value is 0 in exact arithmetic;
#   * prcomp.Rd's tol/rank. example, on a matrix of the same shape of idea:
#     a 200 x 32 Z = X %*% B with B[i, j] = 1 on and above the diagonal --
#     each row a random walk -- so that the columns are correlated and the
#     singular values decay, as the Rd's toeplitz ones do.  Every
#     entry is dyadic and the product is exact in double, so the perl test
#     rebuilds the very same Z.  The Rd asserts that rank. = 3 gives the same
#     sdev as the full fit; that, and the number of PCs tol = 0.1 keeps, are
#     what is frozen from it.
#
# Values print as %.17g, except x and the m:e lines (m * 2^e, exact).

options(digits = 17)
lcg_state <- 12345
lcg <- function(n) {	# the 16-bit Lehmer generator of t/quantile.R.R, centred
	u <- numeric(n)
	for (i in seq_len(n)) {
		lcg_state <<- (75 * lcg_state + 74) %% 65537
		u[i] <- (lcg_state %% 65536) / 65536 - 0.5
	}
	u
}
dy <- function(v) sapply(v, function(z) {
	if (z == 0) return("0:0")
	e <- floor(log2(abs(z))) - 52
	m <- z / 2^e
	stopifnot(m == round(m), abs(m) < 2^53, m * 2^e == z)
	sprintf("%.0f:%d", m, e)
})
g  <- function(v) paste(sprintf("%.17g", v), collapse = ", ")
mat <- function(m) paste(apply(m, 1, function(r) sprintf("[ %s ]", g(r))), collapse = ", ")
emit <- function(label, p) {
	cat(sprintf("\t%s => {\n\t\tsdev => [ %s ],\n\t\trotation => [ %s ],\n", label, g(p$sdev), mat(p$rotation)))
	if (!is.null(p$x)) cat(sprintf("\t\tx => [ %s ],\n", mat(p$x)))
	if (!isFALSE(p$scale)) cat(sprintf("\t\tscale => [ %s ],\n", g(p$scale)))
	if (!isFALSE(p$center)) cat(sprintf("\t\tcenter => [ %s ],\n", g(p$center)))
	cat("\t},\n")
}

readme <- matrix(c(2, 4, 6, 4, 2, 6), 3)
m4 <- rbind(c(1, 2), c(3, 5), c(4, 4), c(7, 9))
set.seed(16); rt <- matrix(runif(30), ncol = 10)
ab <- matrix(lcg(40), 20, 2); col4 <- lcg(20)
coll <- cbind(ab, ab[, 1] + ab[, 2], col4)
X <- matrix(lcg(200 * 32), 200, 32, byrow = TRUE)
B <- outer(1:32, 1:32, function(i, j) ifelse(j >= i, 1, 0))
Z <- X %*% B

cat("my %R = (\n")
emit("readme", prcomp(readme))
emit("readme_scaled", prcomp(readme, scale. = TRUE))
emit("nocenter_scale", prcomp(m4, center = FALSE, scale. = TRUE))
emit("nocenter", prcomp(m4, center = FALSE))
emit("rank1", prcomp(m4, rank. = 1))
emit("regtest_tol", prcomp(rt, tol = 1e-6))
emit("collinear", prcomp(coll))
emit("collinear_scaled", prcomp(coll, scale. = TRUE))
pZ <- prcomp(Z, tol = 0.1); pz3 <- prcomp(Z, rank. = 3)
stopifnot(isTRUE(all.equal(pz3$sdev, pZ$sdev, tolerance = 1e-15)))
cat(sprintf("\tZ => { sdev => [ %s ], tol_ncol => %d, rank3_ncol => %d },\n",
	g(pZ$sdev), ncol(pZ$rotation), ncol(pz3$rotation)))
cat(");\n")
cat(sprintf("# reg-tests-1a.R's x, set.seed(16); matrix(runif(30), ncol = 10), row by row\nmy @RT = (%s);\n",
	paste(apply(rt, 1, function(r) sprintf("[ %s ]", paste(sprintf("'%s'", dy(r)), collapse = ", "))), collapse = ",\n\t")))
