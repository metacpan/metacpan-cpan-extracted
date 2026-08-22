# Generator for the frozen @CORPUS table in t/kruskal_test.R.scipy.t.
#
# Re-run with:   Rscript t/kruskal_test.R.scipy.R > /tmp/kruskal.corpus.pl
# then paste the output over the @CORPUS block in the .t file.  The .t file
# never invokes this script; the committed literals are what gets tested.
#
# R 4.6.1.  Values are printed at options(digits=17), which is round-trip
# exact for a double.  Every datum is an integer or a dyadic fraction
# (halves/quarters/eighths) so that which observations tie is identical on a
# double, long-double and __float128 build -- tie detection is an exact NV
# comparison, and a decimal like 0.1 that happens to collide with another
# literal at one width need not collide at the next.

options(digits = 17)

# NA becomes perl's undef, and NaN/+-Inf become the strings perl's
# looks_like_number() accepts, which is also how a caller reading a CSV would
# hand them over.  Everything else is %.17g, round-trip exact for a double.
fmt1 <- function(v) {
	if (is.na(v) && !is.nan(v)) return("undef")
	if (is.nan(v))             return("'NaN'")
	if (is.infinite(v))        return(sprintf("'%sInf'", if (v < 0) "-" else ""))
	sprintf("%.17g", v)
}

emit <- function(label, groups) {
	r <- suppressWarnings(kruskal.test(groups))
	body <- paste(sapply(groups, function(v)
		sprintf("[%s]", paste(sapply(v, fmt1), collapse = ", "))), collapse = ", ")
	cat(sprintf("\t[ '%s', [%s],\n\t  %s, %d, %s ],\n",
	            label, body,
	            if (is.nan(r$statistic)) "'NaN'" else sprintf("%.17g", r$statistic),
	            r$parameter,
	            if (is.nan(r$p.value)) "'NaN'" else sprintf("%.17g", r$p.value)))
}

# ---- reference examples -------------------------------------------------
# Hollander & Wolfe (1973) p.116, src/library/stats/man/kruskal.test.Rd,
# printed output pinned in tests/Examples/stats-Ex.Rout.save.
emit("HW1973 mucociliary", list(c(2.9,3.0,2.5,2.6,3.2), c(3.8,2.7,4.0,2.4),
                                c(2.8,3.4,3.7,2.2,2.0)))
# airquality Ozone by Month, same man page; heavily tied, k = 5, n = 116.
aq <- na.omit(data.frame(o = airquality$Ozone, m = airquality$Month))
emit("airquality Ozone by Month", split(aq$o, aq$m))
# mtcars mpg by a two-level character grouping: tests/reg-tests-1d.R, PR#16719
# ("kruskal.test(<non-numeric g>)", which gave 'all group levels must be
# finite' in R <= 3.5.1).
mt <- mtcars; mt$type <- rep(letters[1:2], c(16, 16))
emit("mtcars mpg by type PR#16719", split(mt$mpg, mt$type))

# ---- SciPy 1.18.0 TestKruskal ------------------------------------------
# scipy/stats/tests/test_stats.py::TestKruskal.  SciPy states these
# analytically (h_uncorr / corr worked out by hand in the test body), so they
# pin the tie correction independently of R.
emit("scipy test_array_like/test_simple", list(1, 2))
emit("scipy test_basic",       list(c(1,3,5,7,9), c(2,4,6,8,10)))
emit("scipy test_simple_tie",  list(1, c(1,2)))
emit("scipy test_another_tie", list(c(1,1,1,2), c(2,2,2,2)))
emit("scipy test_three_groups", list(c(1,1,1), c(2,2,2), c(2,2)))

# ---- systematic sweep --------------------------------------------------
# k = 2..5 crossed with unbalanced group sizes and four tie structures, over a
# dyadic value set.  Covers: no ties at all, ties inside one group only, ties
# spanning groups, a single tie block covering most of the sample, and the
# k > 2 unbalanced cases where a mis-set df would show up.
set.seed(1)                      # only used to pick which dyadic level to take
levels <- seq(0, 15.75, by = 0.25)         # 64 exactly-representable values
for (k in 2:5) {
	for (variant in 1:4) {
		sizes <- (1:k) + variant                # unbalanced, 2..k+4 per group
		pool <- switch(variant,
			`1` = levels,                       # distinct -> no ties
			`2` = rep(levels[1:4], 16),         # 4 levels -> heavy ties
			`3` = c(levels[1:2], rep(2.5, 60)), # one dominant tie block
			`4` = rep(c(0, 0.5), 32))           # two levels only
		idx <- 1
		groups <- lapply(sizes, function(n) { v <- pool[idx:(idx + n - 1)]
		                                      idx <<- idx + n; v })
		emit(sprintf("sweep k=%d variant=%d", k, variant), groups)
	}
}

# ---- edge cases --------------------------------------------------------
emit("k=2 n=2 minimum",        list(0, 1))
emit("k=2 n=2 tied",           list(1, 1))        # 0/0 -> H = NaN, p = NaN
emit("all identical k=3",      list(c(2,2), c(2,2), c(2,2)))
emit("one group of one",       list(0.5, c(1,1.5,2,2.5)))
emit("two levels perfectly separated", list(rep(0,6), rep(1,6)))
emit("+Inf kept, R drops only NA/NaN", list(c(1,2,Inf), c(4,5,6)))
emit("-Inf and +Inf",          list(c(-Inf,0,Inf), c(1,2,3)))
emit("large magnitudes",       list(c(2^52, 2^52+2, 2^-40), c(-2^52, 1, 2^-40)))
emit("negative values",        list(c(-4,-2,-1), c(-8,-16,-32)))
# NaN/NA are dropped by complete.cases() before ranking, so these must equal
# the same call with the NaN removed.
emit("NaN dropped (k=2)",      list(c(1,2,NaN), c(4,5,6)))
emit("NA dropped (k=2)",       list(c(1,2,NA), c(4,5,6)))
emit("NaN dropped (k=3, ties)", list(c(1,1,NaN), c(2,2,2), c(2,2,NA)))
emit("many ties k=4",          list(rep(1,5), rep(2,5), rep(1,5), rep(2,5)))
