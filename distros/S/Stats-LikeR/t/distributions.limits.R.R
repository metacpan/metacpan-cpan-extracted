# Generator for the frozen table in t/distributions.limits.R.t.
#
# Re-run with:   Rscript t/distributions.limits.R.R > /tmp/limits.tsv
# then paste the rows into the __DATA__ section of t/distributions.limits.R.t.
# The test never invokes this script; it reads only the frozen copy.
#
# This covers what t/distributions.R.scipy.t's grid does not reach: an infinite
# df, a df in the billions, a log probability carried through either way, and
# a log p near 0 or past the double's underflow. Every argument is dyadic and is
# written as an exact ratio "M/2^K", for the reason t/distributions.R.scipy.R
# gives (perl 5.10.1's atof); the dyad() and emit() below are that file's.
# Each row is  fn \t args \t value , the args ending in lower.tail and log.p as
# 1/0. R 4.6.1, options(digits = 17).

options(digits = 17)

dyad <- function(x) {
	if (!is.finite(x)) return(sprintf("%.17g", x))
	# 2^53 and up: "M*2^K", which the .t file's dyad() rebuilds exactly
	if (abs(x) >= 2^53 && x == floor(x)) {
		k <- 0; y <- x
		while (abs(y) >= 2^53 && y / 2 == floor(y / 2)) { y <- y / 2; k <- k + 1 }
		if (abs(y) < 2^53) return(sprintf("%.0f*2^%d", y, k))
	}
	k <- 0; y <- x
	while (y != floor(y) && k < 1100) { y <- y * 2; k <- k + 1 }
	if (y != floor(y) || abs(y) >= 2^53) return(sprintf("%.17g", x))
	sprintf("%.0f/2^%d", y, k)
}

emit <- function(fn, args, value) {
	cat(fn, paste(sapply(args, dyad), collapse = ","), dyad(value), sep = "\t")
	cat("\n")
}

TF <- c(TRUE, FALSE)

# pchisq / qchisq at large df, near the median and a few sd out, both tails and
# both scales. df = 2^20, 2^34 (1.7e10) and 2^50 (1.1e15); the sd is
# sqrt(2 df), so q = df + k * 2^(e/2 + 1) for df = 2^e stays dyadic.
for (e in c(20, 34, 50)) {
	df <- 2^e; s <- 2^(e / 2 + 1)
	for (k in c(-8, -1, 0, 1, 8)) for (lt in TF) for (lg in TF)
		emit("pchisq", c(df + k * s, df, lt, lg), pchisq(df + k * s, df, lower.tail = lt, log.p = lg))
	for (p in c(2^-20, 2^-2, 0.5, 1 - 2^-10)) for (lt in TF)
		emit("qchisq", c(p, df, lt, 0), qchisq(p, df, lower.tail = lt))
}
# small and moderate df on the log scale, including logs a double's exp()
# underflows or rounds to 1
for (df in c(2^-4, 1, 3, 100)) {
	for (lp in c(-2^-66, -2^-30, -1, -64, -1024, -2^20)) for (lt in TF)
		emit("qchisq", c(lp, df, lt, 1), qchisq(lp, df, lower.tail = lt, log.p = TRUE))
	for (q in c(2^-40, 2^-4, 1, 64, 1024)) for (lt in TF)
		emit("pchisq", c(q, df, lt, 1), pchisq(q, df, lower.tail = lt, log.p = TRUE))
}

# t on infinite and very large df
for (q in c(-40, -1.5, 0.25, 1.9599639845400538, 8)) for (lt in TF) for (lg in TF) {
	emit("pt", c(q, Inf, lt, lg), pt(q, Inf, lower.tail = lt, log.p = lg))
	emit("pt", c(q, 2^50, lt, lg), pt(q, 2^50, lower.tail = lt, log.p = lg))
	emit("pt", c(q, 2^24, lt, lg), pt(q, 2^24, lower.tail = lt, log.p = lg))
}
for (p in c(2^-20, 2^-6, 0.5, 0.96875)) for (lt in TF) {
	emit("qt", c(p, Inf, lt, 0), qt(p, Inf, lower.tail = lt))
	emit("qt", c(p, 2^50, lt, 0), qt(p, 2^50, lower.tail = lt))
}
# qt on the log scale: near 0, ordinary, and past the underflow
for (df in c(1, 2, 5, 30, 2^20)) for (lp in c(-2^-66, -2^-10, -3, -700)) for (lt in TF)
	emit("qt", c(lp, df, lt, 1), qt(lp, df, lower.tail = lt, log.p = TRUE))
# pt on the log scale, far out
for (df in c(1, 5, 30)) for (q in c(-2^30, -64, 64)) for (lt in TF)
	emit("pt", c(q, df, lt, 1), pt(q, df, lower.tail = lt, log.p = TRUE))

# F with an infinite df: R's own tests/d-p-q-r-tests.R grid is c(1/pi, 1, pi);
# the dyadic grid below brackets it
for (x in c(0.25, 0.5, 1, 2, 4)) for (lt in TF) for (lg in TF) {
	emit("pf", c(x, 3, Inf, lt, lg), pf(x, 3, Inf, lower.tail = lt, log.p = lg))
	emit("pf", c(x, Inf, 5, lt, lg), pf(x, Inf, 5, lower.tail = lt, log.p = lg))
	emit("pf", c(x, Inf, Inf, lt, lg), pf(x, Inf, Inf, lower.tail = lt, log.p = lg))
	emit("pf", c(x, 2^30, 2^30, lt, lg), pf(x, 2^30, 2^30, lower.tail = lt, log.p = lg))
}
for (p in c(2^-20, 2^-2, 0.5, 0.96875)) for (lt in TF) {
	emit("qf", c(p, 3, Inf, lt, 0), qf(p, 3, Inf, lower.tail = lt))
	emit("qf", c(p, Inf, 5, lt, 0), qf(p, Inf, 5, lower.tail = lt))
	emit("qf", c(p, Inf, Inf, lt, 0), qf(p, Inf, Inf, lower.tail = lt))
}
for (d in list(c(1, 1), c(3, 5), c(10, 100))) for (lp in c(-2^-66, -2^-10, -3, -64)) for (lt in TF)
	emit("qf", c(lp, d, lt, 1), qf(lp, d[1], d[2], lower.tail = lt, log.p = TRUE))
for (d in list(c(1, 1), c(3, 5), c(10, 100))) for (q in c(2^-20, 1, 2^20)) for (lt in TF)
	emit("pf", c(q, d, lt, 1), pf(q, d[1], d[2], lower.tail = lt, log.p = TRUE))

# qnorm on the log scale
for (lp in c(-2^-66, -2^-30, -2^-4, -1, -50, -700, -800, -2^20, -2^40)) for (lt in TF)
	emit("qnorm", c(lp, 0, 1, lt, 1), qnorm(lp, lower.tail = lt, log.p = TRUE))

# pbinom on the log scale, and a size within R_nonint()'s 1e-9 fuzz
for (k in c(0, 3, 500, 999)) for (lt in TF)
	emit("pbinom", c(k, 1000, 0.25, lt, 1), pbinom(k, 1000, 0.25, lower.tail = lt, log.p = TRUE))
for (sz in c(10 + 2^-40, 10 - 2^-40, 2^20 + 2^-20, 10 + 2^-20)) for (lt in TF)
	emit("pbinom", c(3, sz, 0.5, lt, 0), pbinom(3, sz, 0.5, lower.tail = lt))

# The regime of R's tests/reg-tests-2.R:1758-1762 (PR#8528, "errors in the
# post-2.1.0 pgamma"): pgamma at shape 1e100 from 0.75 to 1.25 of the shape,
# here as pchisq on df = 2^333 (1.7e100) with a dyadic grid, both tails, log.
df <- 2^333
for (r in c(0.75, 0.875, 1 - 2^-5, 1 - 2^-33, 1, 1 + 2^-33, 1 + 2^-5, 1.125, 1.25)) for (lt in TF)
	emit("pchisq", c(r * df, df, lt, 1), pchisq(r * df, df, lower.tail = lt, log.p = TRUE))
