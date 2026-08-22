# Generator for the frozen expected values in t/quantile.R.t.
#
#   Rscript t/quantile.R.R
#
# Prints the Perl data table that file carries; the test itself never runs
# this script and never calls R.  Re-run it only when the table has to be
# regenerated, and paste the output back into the .t file.
#
# The samples are built from an exact 16-bit Lehmer generator, so every value
# is a multiple of 2**-16 and a long-double or __float128 perl reads back the
# very sample R saw -- ties included, which is what decides where an order
# statistic lands.  sw_lcg() here and in the .t file agree value for value.

options(digits = 17)

sw_lcg <- function(n) {
	s <- 12345
	u <- numeric(n)
	for (i in seq_len(n)) {
		s <- (75 * s + 74) %% 65537
		u[i] <- (s %% 65536) / 65536
	}
	u
}
patterns <- list(
	plain    = function(n) sw_lcg(n),
	sorted   = function(n) sort(sw_lcg(n)),
	reversed = function(n) rev(sort(sw_lcg(n))),
	organ    = function(n) {	# up then down: the classic quicksort pathology
		v <- sort(sw_lcg(n))
		odd <- v[seq_len(n) %% 2 == 1]
		even <- v[seq_len(n) %% 2 == 0]
		c(odd, rev(even))
	},
	ties     = function(n) floor(sw_lcg(n) * 12) / 8,
	twovals  = function(n) ifelse(sw_lcg(n) < 0.5, 0, 1),
	sawtooth = function(n) (seq_len(n) %% 32) / 32
)

emit <- function(label, x, probs = NULL) {
	q <- if (is.null(probs)) quantile(x) else quantile(x, probs)
	cat(sprintf("\t[ '%s', [ %s ] ],\n", label,
	            paste(sprintf("%.17g", q), collapse = ", ")))
}

cat("# label => the five default quantiles, from R's quantile()\n")
for (p in names(patterns))
	for (n in c(1, 2, 3, 19, 20, 21, 100, 999, 1000, 5000))
		emit(sprintf("%s_%d", p, n), patterns[[p]](n))

cat("# non-default probs, same samples\n")
PR <- c(0, 0.001, 0.05, 1/3, 0.5, 0.666, 0.95, 0.999, 1)
for (p in c("plain", "ties", "sawtooth"))
	for (n in c(7, 100, 1000))
		emit(sprintf("probs_%s_%d", p, n), patterns[[p]](n), PR)

cat("# R's reg-tests-1d PR#16672 sample: 602 identical values\n")
emit("pr16672_x2", rep(-0.00090419678460984, 602))
