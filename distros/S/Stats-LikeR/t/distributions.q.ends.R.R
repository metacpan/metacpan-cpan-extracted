# Generator for the frozen table in t/distributions.q.ends.R.t.
#
# Re-run with:   Rscript t/distributions.q.ends.R.R > /tmp/q.ends.tsv
# then paste the rows into the __DATA__ section of t/distributions.q.ends.R.t.
# The test never invokes this script; it reads only the frozen copy.
#
# This covers one thing: what a q* function returns when the probability is at
# an end of its range (p of 0 or 1, a log p of -Inf or 0) and a distribution
# parameter is invalid, degenerate or NaN. R answers the ends before it
# validates the parameter in qnorm.c, qt.c and qgamma.c (which qchisq.c calls)
# and after it in qf.c, so the first three return the end of the support where
# the fourth returns NaN. An interior p (0.5, or a log p of -1) is crossed in
# beside the ends to pin that the parameter check still fires there.
#
# Each row is  fn \t args \t value , the args being p, the parameters, then
# lower.tail and log.p as 1/0. Every finite number here is a short dyadic
# decimal (0, 0.5, 1, -1, -0.5, 2, 3, 5), which every perl reads exactly, so
# there is no "M/2^K" encoding as in t/distributions.limits.R.R. No value is
# rounded: each is -Inf, Inf, NaN, 0 or the mean handed in.
#
# lower.tail and log.p are passed by name, never by position: qt(), qchisq()
# and qf() take ncp before them, and a positional TRUE there is read as a
# noncentrality of 1 -- which is how a first draft of this script came to print
# qchisq(0.5, 0) as 1.9e-308.
#
# The rows with a valid parameter and an interior p are left out: their values
# are ordinary quantiles, which t/distributions.R.scipy.t already pins with a
# tolerance, and this table is compared exactly.
#
# Last run with R 4.6.2 (2026-10-29).

tok <- function(x) if (is.nan(x)) "NaN" else sprintf("%.17g", x)

emit <- function(fn, args, value) {
	cat(fn, paste(sapply(args, tok), collapse = ","), tok(value), sep = "\t")
	cat("\n")
}

TF <- c(TRUE, FALSE)

for (log in c(FALSE, TRUE)) for (lower in TF) {
	ps <- if (log) c(-Inf, -1, 0) else c(0, 0.5, 1)
	for (p in ps) {
		interior <- !(p %in% c(ps[1], ps[3]))

		# qnorm: sd negative, zero (a step at the mean) and NaN, and a NaN mean
		for (m in c(0, 3)) for (s in c(-Inf, -1, -0.5, 0, 1, NaN)) {
			if (interior && !is.nan(s) && s > 0) next
			emit("qnorm", c(p, m, s, lower, log), suppressWarnings(qnorm(p, m, s, lower.tail = lower, log.p = log)))
		}
		emit("qnorm", c(p, NaN, 1, lower, log), suppressWarnings(qnorm(p, NaN, 1, lower.tail = lower, log.p = log)))

		# qt: df negative, zero and NaN
		for (df in c(-Inf, -1, -0.5, 0, 5, NaN)) {
			if (interior && !is.nan(df) && df > 0) next
			emit("qt", c(p, df, lower, log), suppressWarnings(qt(p, df, lower.tail = lower, log.p = log)))
		}

		# qchisq: df negative and NaN; df = 0 is valid, all the mass at 0
		for (df in c(-Inf, -1, -0.5, 0, 5, NaN)) {
			if (interior && !is.nan(df) && df > 0) next
			emit("qchisq", c(p, df, lower, log), suppressWarnings(qchisq(p, df, lower.tail = lower, log.p = log)))
		}

		# qf: either df non-positive or NaN; qf.c checks df before the ends
		for (d in list(c(-1, 2), c(2, -1), c(0, 2), c(2, 0), c(-1, -1), c(-Inf, 2),
		               c(2, 5), c(NaN, 2), c(2, NaN))) {
			if (interior && !any(is.nan(d)) && all(d > 0)) next
			emit("qf", c(p, d, lower, log), suppressWarnings(qf(p, d[1], d[2], lower.tail = lower, log.p = log)))
		}
	}
}
