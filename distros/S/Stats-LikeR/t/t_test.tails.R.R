# Regenerate the frozen table in t/t_test.tails.R.t:
#
#     Rscript t/t_test.tails.R.R
#
# and paste the output into that file's __DATA__ block.  Written against R
# 4.6.1 (2026-06-24).  The test reads only the frozen literals; installing or
# testing Stats::LikeR needs no R.
#
# The cases come from R's own material:
#
#   tests/d-p-q-r-tst-2.R:53  -- pt(-a, df = 1) == pcauchy(-a) to 1e-15 for
#       a = 1e15 ... 1e300, and tests/reg-tests-1a.R:4117, the same comparison
#       on the log scale, "failed at about 1e150 in 2.2.1".  t.test() reaches
#       pt() with that |t| when mu is far from the data, so each a is driven
#       through t.test(c(1, 2), mu = m), whose t is exactly 3 - 2m.  The a here
#       are powers of two near R's powers of ten, so that the input parses to
#       the same value on every perl (5.10.1's atof is several ulp out near the
#       exponent extremes).
#   The same at df = 2 (c(1, 2, 3)) and at a Welch df, so the tail is checked
#       off the Cauchy special case too.
#   src/library/stats/man/t.test.Rd -- the sleep data, one-sample, Welch and
#       the paired wide-format test, used by the .t file through tied arrays.
#
# Output columns, tab separated:
#   label  statistic  parameter  p.value  ci_lo  ci_hi
# with "-" for the interval on the tail rows.  R builds it as
# mu + (t -/+ q) * stderr, which at these |mu| cancels to [0, 0]; t_test() builds
# estimate -/+ q * stderr, so R's interval there is not a reference for it.

options(digits = 17, warn = -1)

# A finite value is written m p e, meaning m * 2^e with m an integer of at most
# 53 bits, which is exact; the .t file rebuilds it as $m * 2**$e.  A %.17g
# literal is not enough here: perl 5.10.1's atof reads 4.7530725789634658e-301
# 19% away from the double R printed it from.
num <- function(z) {
	if (is.na(z)) "NA"
	else if (is.infinite(z)) if (z > 0) "Inf" else "-Inf"
	else if (z == 0) "0p0"
	else {
		e <- max(floor(log2(abs(z))) - 52, -1074)	# -1074: a subnormal's exponent
		#log2() rounds up to the next integer just below a power of two
		while (z / 2^e != round(z / 2^e)) e <- e - 1
		sprintf("%.0fp%d", z / 2^e, e)
	}
}

emit <- function(label, r, ci = FALSE) {
	lim <- if (ci) c(num(r$conf.int[1]), num(r$conf.int[2])) else c("-", "-")
	cat(label, num(r$statistic), num(r$parameter), num(r$p.value), lim,
	    sep = "\t")
	cat("\n")
}

alts <- c("two.sided", "less", "greater")

for (k in c(50, 66, 83, 166, 332, 664, 996))
	for (a in alts)
		emit(sprintf("df1|%d|%s", k, a), t.test(c(1, 2), mu = 2^k, alternative = a))

for (k in c(83, 166, 332, 500))
	for (a in alts)
		emit(sprintf("df2|%d|%s", k, a), t.test(c(1, 2, 3), mu = 2^k, alternative = a))

for (k in c(83, 166, 332, 500))
	for (a in alts)
		emit(sprintf("welch|%d|%s", k, a),
		     t.test(c(1, 2), c(0, 10, 20), mu = 2^k, alternative = a))

# tiny-scale data against mu = 1: |t| ~ 2^533, past sqrt(DBL_MAX)
for (a in alts)
	emit(sprintf("tiny|%s", a), t.test(c(2^-532, 2^-531), mu = 1, alternative = a))

s1 <- sleep$extra[sleep$group == 1]
s2 <- sleep$extra[sleep$group == 2]
emit("sleep|1s", t.test(s1), ci = TRUE)
emit("sleep|welch", t.test(s1, s2), ci = TRUE)
emit("sleep|paired", t.test(s1, s2, paired = TRUE), ci = TRUE)
