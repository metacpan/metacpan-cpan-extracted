# Generator for the frozen expected values in t/shapiro_test.R.scipy.t.
#
#   Rscript t/shapiro_test.R.scipy.R
#
# Prints the Perl data table that file carries; the test itself never runs
# this script and never calls R.  Re-run it only when the table has to be
# regenerated, and paste the output back into the .t file.
#
# Every sample here is built out of exact binary fractions -- multiples of
# 2**-16 and squares of them -- so that a long-double or __float128 perl
# reads back the very numbers R saw, ties and all, rather than a slightly
# different sample that happens to print the same.

options(digits = 17)

## The same 16-bit Lehmer generator the .t file re-implements.
sw_lcg <- function(n) {
	s <- 12345
	u <- numeric(n)
	for (i in seq_len(n)) {
		s <- (75 * s + 74) %% 65537
		u[i] <- (s %% 65536) / 65536
	}
	u
}
sw_normalish <- function(n) {	# Irwin-Hall(12): a passable normal sample
	u <- sw_lcg(12 * n)
	vapply(seq_len(n), function(i) sum(u[(12 * (i - 1) + 1):(12 * i)]) - 6, 0)
}
sw_skew <- function(n) sw_lcg(n)^2			# right-tailed, still exact
sw_ties <- function(n) floor(sw_lcg(n) * 20) / 16	# 20 distinct values

emit <- function(label, x) {
	r <- shapiro.test(x)
	cat(sprintf("\t[ '%s', %.17g, %.17g ],\n", label, r$statistic, r$p.value))
}

cat("# generated sets: label => [W, p]\n")
for (n in c(3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 20, 50, 100, 500, 1000, 5000))
	emit(sprintf("normalish_%d", n), sw_normalish(n))
for (n in c(4, 5, 6, 11, 12, 40, 200, 2000))
	emit(sprintf("skew_%d", n), sw_skew(n))
for (n in c(5, 12, 30, 300, 3000))
	emit(sprintf("ties_%d", n), sw_ties(n))

cat("# literal sets\n")
emit("scipy_x1", c(0.11, 7.87, 4.61, 10.14, 7.95, 3.14, 0.46, 4.43, 0.21,
                   4.75, 0.71, 1.52, 3.24, 0.93, 0.42, 4.97, 9.53, 4.55,
                   0.47, 6.66))
emit("scipy_x2", c(1.36, 1.14, 2.92, 2.55, 1.46, 1.06, 5.27, -1.11, 3.48,
                   1.10, 0.88, -0.51, 1.46, 0.52, 6.20, 1.69, 0.08, 3.67,
                   2.81, 3.49))
emit("scipy_x4", c(0.139, 0.157, 0.175, 0.256, 0.344, 0.413, 0.503, 0.577,
                   0.614, 0.655, 0.954, 1.392, 1.557, 1.648, 1.690, 1.994,
                   2.174, 2.206, 3.245, 3.510, 3.571, 4.354, 4.980, 6.084,
                   8.351))
emit("scipy_gh14462", c(0, 3.39996924e-08, -6.35166875e-09))
emit("scipy_gh18322", c(-0.7746653110021126, -0.4344432067942129,
                        1.8157053280290931))
emit("zero_zero_one", c(0, 0, 1))
emit("one_two_three", c(1, 2, 3))
emit("one_two_four",  c(1, 2, 4))
emit("seq_1_5",  1:5)
emit("seq_1_19", 1:19)
emit("tied_n4",  c(0, 0, 0, 1))	 # the smallest W four points can produce
emit("tied_n4b", c(0, 0, 1, 1))
emit("spike_n10", c(rep(0, 9), 1e6))
emit("offset_1e9", 1e9 + sw_normalish(30))   # R itself is inaccurate here

## R's own documented example, whose printed output is pinned in
## tests/Examples/stats-Ex.Rout.save as "W = 0.9956, p-value = 0.9876".
set.seed(1)
emit("Rd_example_rnorm100", rnorm(100, mean = 5, sd = 3))
set.seed(1)
cat("# Rd example data:\n")
cat(sprintf("#   %s\n", paste(sprintf("%.17g", rnorm(100, mean = 5, sd = 3)),
                              collapse = ", ")))
