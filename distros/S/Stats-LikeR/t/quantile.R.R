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

# ---- added 0.331: exact values, and R's names ------------------------------
#
# Every value below is printed as "m:e", meaning m * 2**e with m an integer of
# at most 53 bits, so that any perl -- 5.10.1's own decimal parser included --
# reads back R's double exactly.  The test compares these bit for bit on a
# double perl: type 7 is one product, one sum and one interpolation, done in
# the same order on both sides, so there is nothing to round differently.
dy <- function(v) sapply(v, function(z) {
	if (is.na(z)) return("NA")
	if (z == 0) return("0:0")
	e <- floor(log2(abs(z))) - 52
	m <- z / 2^e
	stopifnot(m == round(m), abs(m) < 2^53, m * 2^e == z)
	sprintf("%.0f:%d", m, e)
})
emit_exact <- function(label, x, probs) {
	q <- quantile(x, probs, names = FALSE)
	cat(sprintf("\t[ '%s', '%s' ],\n", label, paste(dy(q), collapse = " ")))
}
cat("# exact: probs k/997, k = 0..997, as m:e\n")
K <- (0:997) / 997
for (lab in c("plain_10", "plain_101", "ties_1000", "sawtooth_64", "reversed_7"))
	emit_exact(lab, patterns[[sub("_.*", "", lab)]](as.integer(sub(".*_", "", lab))), K)
cat("# exact: tiny probs, where 1 + (n-1)p rounds back to 1\n")
emit_exact("tiny_plain_10", patterns$plain(10), c(1e-17, 1e-16, 2^-60, 2^-53, 2^-52, 1e-15))

# R's own names.  quantile.default() names its result format_perc(probs,
# digits = 7): formatC(100 * probs, "fg") under 100 probs, format(100 * probs)
# from 100 on, and "" for an NA or NaN.
emit_names <- function(label, probs) {
	q <- quantile(patterns$plain(25), probs)
	cat(sprintf("\t[ '%s', [ %s ], [ %s ] ],\n", label,
		paste(sprintf("'%s'", names(q)), collapse = ", "),
		paste(dy(q), collapse = ", ") |> (\(s) gsub("([^ ,]+)", "'\\1'", s))()))
}
cat("# names: label, R's names, the values (m:e)\n")
emit_names("fg", c(0, 1e-9, 5e-7, 1e-6, 1.2345678e-6, 0.000999999, 1/3, 2/3, 0.0015,
                   0.123456789, 1, 0.5, 0.05, 0.001, 0.0014, 0.0012, 0.0004, 1e-17))
emit_names("fg_tiny", c(2^-996, 0.5))
emit_names("format_seq", seq(0, 1, 0.005))
emit_names("format_fixed8", c(1e-10, (0:99) / 99))
emit_names("format_150", (0:150) / 150)
emit_names("format_sci", c(2^-60, (0:99) / 99))
