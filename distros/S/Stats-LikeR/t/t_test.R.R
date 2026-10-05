# Regenerate the R half of t/t_test.R.scipy.t:
#
#     Rscript t/t_test.R.R
#
# and paste the output into that file's __DATA__ block, before the %%SCIPY%%
# marker.  Written against R 4.6.1 (2026-06-24).  The test reads only the
# frozen literals; installing or testing Stats::LikeR needs no R.
#
# Every case here comes from R's own material, not from cases invented for
# Stats::LikeR:
#
#   src/library/stats/man/t.test.Rd  -- t.test(1:10, 7:20), the same with the
#       outlier 200 appended, the mtcars mpg-by-am split, and all three sleep
#       forms (one-sample, and the paired wide-format test).
#   tests/reg-tests-1a.R:4529        -- "t.test with one group of size one",
#       both orientations, var.equal = TRUE.
#   tests/reg-tests-2.R:3199         -- print(t.test(1:28), digits = 3).
#   tests/reg-tests-1e.R:1985        -- t.test(<Inf>...), PR#18901.
#   doc/manual/R-intro.R:371/375     -- Michelson's A and B, Welch and pooled.
#   datasets/man/sleep.Rd:39         -- the paired test in long format.
#   stats/man/ks.test.Rd:165         -- t.test(x, x2, alternative = "g").
#   base/man/array2DF.Rd:103         -- t.test() on each ToothGrowth cell.
#   stats/man/pairwise.t.test.Rd:52  -- pool.sd = FALSE: t.test() on each pair
#       of months of airquality's Ozone, NA included; tcltk/demo/tkttest.R:86
#       is the 5 v 8 pair.
#
# Each documented case is then crossed over the whole argument space R exposes
# (alternative x var.equal x paired x mu x conf.level), because a reference
# case exercised only at its defaults pins one path out of dozens.
#
# Output columns, tab separated:
#   label  n_est  statistic  parameter  p.value  estimate...  ci_lo  ci_hi
# with "NA" for anything R reports as NA and "-" where there is no CI.

options(digits = 17, warn = -1)

num <- function(v) {
	sapply(v, function(z) {
		if (is.null(z) || length(z) == 0 || is.na(z)) "NA"
		else if (is.infinite(z)) if (z > 0) "Inf" else "-Inf"
		else sprintf("%.17g", z)
	})
}

emit <- function(label, r) {
	est <- num(as.numeric(r$estimate))
	ci  <- if (is.null(r$conf.int)) c("-", "-") else num(as.numeric(r$conf.int))
	cat(sprintf("%s\t%d\t%s\t%s\t%s\t%s\t%s\t%s\n",
	            label, length(est),
	            num(r$statistic), num(r$parameter), num(r$p.value),
	            paste(est, collapse = ","), ci[1], ci[2]))
}

# Try every combination the call form allows, labelling each uniquely.
sweep_one <- function(tag, x, mus = c(0, 0.5, -2), cls = c(0.95, 0.9, 0.99)) {
	for (alt in c("two.sided", "less", "greater"))
		for (mu in mus)
			for (cl in cls)
				emit(sprintf("%s|1s|%s|mu=%g|cl=%g", tag, alt, mu, cl),
				     t.test(x, mu = mu, alternative = alt, conf.level = cl))
}

sweep_two <- function(tag, x, y, mus = c(0, 1.5), cls = c(0.95, 0.9),
                      paired = FALSE) {
	for (alt in c("two.sided", "less", "greater"))
		for (ve in c(FALSE, TRUE))
			for (mu in mus)
				for (cl in cls)
					emit(sprintf("%s|2s|%s|ve=%d|mu=%g|cl=%g|p=%d",
					             tag, alt, as.integer(ve), mu, cl, as.integer(paired)),
					     t.test(x, y, mu = mu, alternative = alt,
					            var.equal = ve, conf.level = cl, paired = paired))
}

## ---- t.test.Rd: two-sample ----
cat("# t.test(1:10, y = c(7:20))  -- man page says P = .00001855\n")
sweep_two("man.1to10.7to20", 1:10, c(7:20))
cat("# t.test(1:10, y = c(7:20, 200)) -- man page says P = .1245, not significant\n")
sweep_two("man.1to10.outlier", 1:10, c(7:20, 200))

## ---- t.test.Rd: mtcars mpg by am ----
data(mtcars)
a0 <- mtcars$mpg[mtcars$am == 0]
a1 <- mtcars$mpg[mtcars$am == 1]
cat(sprintf("# mtcars mpg am==0: %s\n", paste(a0, collapse = ",")))
cat(sprintf("# mtcars mpg am==1: %s\n", paste(a1, collapse = ",")))
sweep_two("man.mtcars.am", a0, a1)

## ---- t.test.Rd: sleep, one-sample and paired ----
data(sleep)
e1 <- sleep$extra[sleep$group == 1]
e2 <- sleep$extra[sleep$group == 2]
cat(sprintf("# sleep extra group 1: %s\n", paste(e1, collapse = ",")))
cat(sprintf("# sleep extra group 2: %s\n", paste(e2, collapse = ",")))
sweep_one("man.sleep.all", sleep$extra)
sweep_two("man.sleep.paired", e1, e2, paired = TRUE)
sweep_two("man.sleep.unpaired", e1, e2)

## ---- reg-tests-2.R:3199 -- print(t.test(1:28), digits = 3) ----
sweep_one("reg2.1to28", 1:28)

## ---- reg-tests-1a.R:4529 -- one group of size one, var.equal = TRUE ----
x <- c(23, 25, 29, 27, 30, 30)
for (alt in c("two.sided", "less", "greater")) for (cl in c(0.95, 0.99)) {
	emit(sprintf("reg1a.n1.xfirst|2s|%s|ve=1|mu=0|cl=%g|p=0", alt, cl),
	     t.test(x = x[1], y = x[-1], var.equal = TRUE, alternative = alt, conf.level = cl))
	emit(sprintf("reg1a.n1.yfirst|2s|%s|ve=1|mu=0|cl=%g|p=0", alt, cl),
	     t.test(y = x[1], x = x[-1], var.equal = TRUE, alternative = alt, conf.level = cl))
}

## ---- smallest samples the test accepts, and exact-integer edges ----
sweep_one("edge.two.pts", c(1, 2), mus = c(0, 1.5), cls = c(0.95))
sweep_two("edge.2v2", c(1, 2), c(3, 4), mus = c(0), cls = c(0.95))
sweep_two("edge.2v3", c(1, 2), c(3, 4, 5), mus = c(0), cls = c(0.95))
# same mean in both groups: statistic 0, p 1 two-sided
sweep_two("edge.samemean", c(1, 2, 3), c(0, 2, 4), mus = c(0), cls = c(0.95))
# a group with zero variance on one side only (Welch df collapses to n-1)
sweep_two("edge.onezerovar", c(5, 5, 5), c(1, 2, 3), mus = c(0), cls = c(0.95))

## ---- SciPy's R-checked cases, recomputed here so both agree ----
# scipy/stats/tests/test_stats.py::TestTTestIndMore::test_ttest_ind_with_uneq_var
sweep_two("scipy.uneqvar.a", c(1, 2, 3), c(1.1, 2.9, 4.2), mus = c(0), cls = c(0.95))
sweep_two("scipy.uneqvar.b", c(1, 2, 3, 4), c(1.1, 2.9, 4.2), mus = c(0), cls = c(0.95))
# ::test_ttest_uniform_pvalues -- t.test(c(2,3,5), c(1.5), var.equal=TRUE)
for (alt in c("two.sided", "less", "greater"))
	emit(sprintf("scipy.n1.235.15|2s|%s|ve=1|mu=0|cl=0.95|p=0", alt),
	     t.test(c(2, 3, 5), c(1.5), var.equal = TRUE, alternative = alt))
# ::test_ttest_ind_nan_2nd_arg -- the NaN-dropped pair, R-annotated upstream
sweep_two("scipy.nan2nd", c(1, 2, 1, 2), c(2, 3, 4), mus = c(0), cls = c(0.95))
# ::TestTTest_1samp -- t.test(c(-1,0,1), mu = 0 / 1 / 2) and t.test(c(0,1,2))
sweep_one("scipy.X1", c(-1, 0, 1), mus = c(0, 1, 2), cls = c(0.95))
sweep_one("scipy.X2", c(0, 1, 2), mus = c(0), cls = c(0.95))
# ::TestTTestRel -- linspace(1,100,100) vs linspace(1.01,99.989,100), paired.
# Written out as start + i*step with the last element pinned to the stop, which
# is what numpy's linspace does, so the two sides really are the same vector.
lin <- function(a, b, n) { s <- (b - a) / (n - 1); v <- a + s * (0:(n - 1)); v[n] <- b; v }
r1 <- lin(1, 100, 100); r2 <- lin(1.01, 99.989, 100)
cat(sprintf("# linspace(1.01, 99.989, 100) = %s\n", paste(sprintf("%.17g", r2), collapse = ",")))
sweep_two("scipy.rel.linspace", r1, r2, mus = c(0), cls = c(0.95), paired = TRUE)
# ::TestTTestIndMore regression pair, Welch, unequal n
r3 <- lin(1, 100, 25); r4 <- lin(5, 105, 100)
cat(sprintf("# linspace(1,100,25) = %s\n", paste(sprintf("%.17g", r3), collapse = ",")))
cat(sprintf("# linspace(5,105,100) = %s\n", paste(sprintf("%.17g", r4), collapse = ",")))
sweep_two("scipy.ind.linspace", r4, r1, mus = c(0), cls = c(0.95))
sweep_two("scipy.ind.linspace.uneqn", r4, r3, mus = c(0), cls = c(0.95))
# ::TestTTestCI -- the 11-vs-13 sample whose CI reference values R itself
# produced (via PairedData::yuen.t.test at tr = 0), at conf.level 0.9.
ci_a <- c(0.88236329, 0.97318744, 0.4549262, 0.97893335, 0.0606677,
          0.44013366, 0.55806018, 0.40151434, 0.14453315, 0.25860601, 0.20202162)
ci_b <- c(0.93455277, 0.42680603, 0.49751939, 0.14152846, 0.711435,
          0.77669667, 0.20507578, 0.78702772, 0.94691855, 0.32464958,
          0.3873582, 0.35187468, 0.21731811)
for (alt in c("two.sided", "less", "greater")) for (ve in c(FALSE, TRUE))
	emit(sprintf("scipy.ci.11v13|2s|%s|ve=%d|mu=0|cl=0.9|p=0", alt, as.integer(ve)),
	     t.test(ci_a, ci_b, alternative = alt, var.equal = ve, conf.level = 0.9))

## ---- doc/manual/R-intro.R:371/375 -- Michelson's two sets of latent heats ----
## (pinned in tests/R-intro.Rout.save:581 and :609)
A <- c(79.98, 80.04, 80.02, 80.04, 80.03, 80.03, 80.04, 79.97,
       80.05, 80.03, 80.02, 80, 80.02)
B <- c(80.02, 79.94, 79.98, 79.97, 79.97, 80.03, 79.95, 79.97)
sweep_two("rintro.AB", A, B)

## ---- datasets/man/sleep.Rd:39 -- the paired test in long format ----
## (pinned in tests/Examples/datasets-Ex.Rout.save:3292).  The same numbers as
## t.test.Rd's wide-format test, but a separate example, so a separate tag.
with(sleep, sweep_two("sleepRd.paired", extra[group == 1], extra[group == 2],
                      mus = c(0), cls = c(0.95), paired = TRUE))

## ---- stats/man/ks.test.Rd:165 -- t.test(x, x2, alternative = "g") ----
## R CMD check runs each example after set.seed(1) (cleanEx() in
## share/R/examples-header.R), and nothing between that and x2 draws, so these
## are the vectors of tests/Examples/stats-Ex.Rout.save:9232, whose printed
## t = 5.6742, df = 96.85, p-value = 7.242e-08 this reproduces.  The .t file
## carries them at the 17 digits printed here.
set.seed(1)
ks_x <- rnorm(50)
ks_y <- runif(30)
ks_x2 <- rnorm(50, -1)
cat(sprintf("# ks.test.Rd x  = %s\n", paste(sprintf("%.17g", ks_x), collapse = ",")))
cat(sprintf("# ks.test.Rd x2 = %s\n", paste(sprintf("%.17g", ks_x2), collapse = ",")))
sweep_two("ksRd.x.x2", ks_x, ks_x2, mus = c(0), cls = c(0.95))

## ---- base/man/array2DF.Rd:103 -- t.test(x) on each ToothGrowth cell ----
for (d in c(0.5, 1, 2)) for (s in c("OJ", "VC")) {
	v <- with(ToothGrowth, len[dose == d & supp == s])
	cat(sprintf("# ToothGrowth len dose=%g supp=%s: %s\n", d, s, paste(v, collapse = ",")))
	sweep_one(sprintf("array2DF.tooth.%g.%s", d, s), v, mus = c(0, 10), cls = c(0.95, 0.99))
}

## ---- stats/man/pairwise.t.test.Rd:52 -- pairwise.t.test(Ozone, Month,
## pool.sd = FALSE), which is t.test(xi, xj) on every pair of months
## (stats/R/pairwise.R:54); Ozone has 37 NA, so this is the NA-dropping path on
## real data.  tcltk/demo/tkttest.R:86 runs Ozone[Month == 5] against
## Ozone[Month == 8] from a dialog -- the 5 v 8 pair below, which is why its
## sweep is the full one.
oz <- airquality$Ozone; mo <- airquality$Month
cat(sprintf("# airquality Ozone = %s\n", paste(ifelse(is.na(oz), "NA", oz), collapse = ",")))
cat(sprintf("# airquality Month = %s\n", paste(mo, collapse = ",")))
for (i in 5:8) for (j in (i + 1):9) {
	if (i == 5 && j == 8) sweep_two("pairwise.ozone.5v8", oz[mo == i], oz[mo == j])
	else sweep_two(sprintf("pairwise.ozone.%dv%d", i, j), oz[mo == i], oz[mo == j],
	               mus = c(0), cls = c(0.95))
}
