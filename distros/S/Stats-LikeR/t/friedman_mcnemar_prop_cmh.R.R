# Regenerate the frozen table in t/friedman_mcnemar_prop_cmh.R.t:
#
#     Rscript t/friedman_mcnemar_prop_cmh.R.R
#
# and paste the output into that file's DATA section.  Written against
# R 4.6.1 (2026-06-24).  The test reads only the frozen literals; installing or
# testing Stats::LikeR needs no R.
#
# Four functions share one file because they share one shape of answer -- a
# statistic, a df, a p-value, and sometimes an estimate and an interval -- and
# one source: R's own man-page examples for the functions they port.
#
#   friedman_test  <- stats::friedman.test
#       src/library/stats/man/friedman.test.Rd: the Hollander & Wolfe (1973)
#       p.140ff RoundingTimes matrix (22 players x 3 methods), and the
#       warpbreaks aggregate example.
#   mcnemar_test   <- stats::mcnemar.test
#       src/library/stats/man/mcnemar.test.Rd: Agresti (1990) p.350,
#       Presidential Approval Ratings.
#   prop_test      <- stats::prop.test
#       src/library/stats/man/prop.test.Rd: Fleiss (1981) p.139, four groups of
#       patients, plus the one-sample form the page opens with.
#   cmh_test       <- stats::mantelhaen.test
#       src/library/stats/man/mantelhaen.test.Rd: Agresti (1990) pp.231-237
#       Penicillin and Rabbits (2x2x5), and UCBAdmissions (2x2x6).
#
# Each is then crossed over its own switches -- correct, exact, alternative, p,
# conf.level -- and over the edges the references themselves cover: all-ties,
# k = 2, b == c, 3x3 and 4x4 tables, 0 and n successes, and a single stratum.
#
# Output is one row per case:  label <TAB> comma-separated numbers
# in the order the test expects for that label's prefix, with NaN spelled NaN.

options(digits = 17, warn = -1)

f <- function(k, v) {
	s <- sapply(v, function(z)
		if (is.null(z) || length(z) == 0 || is.na(z)) "NaN" else sprintf("%.17g", z))
	cat(sprintf("%s\t%s\n", k, paste(s, collapse = ",")))
}
# statistic, parameter, p.value
htest3 <- function(k, r) f(k, c(r$statistic, r$parameter, r$p.value))

##
## friedman.test -- rows are blocks, columns are treatments
##
RT <- matrix(c(5.40,5.50,5.55, 5.85,5.70,5.75, 5.20,5.60,5.50, 5.55,5.50,5.40,
               5.90,5.85,5.70, 5.45,5.55,5.60, 5.40,5.40,5.35, 5.45,5.50,5.35,
               5.25,5.15,5.00, 5.85,5.80,5.70, 5.25,5.20,5.10, 5.65,5.55,5.45,
               5.60,5.35,5.45, 5.05,5.00,4.95, 5.50,5.50,5.40, 5.45,5.55,5.50,
               5.55,5.55,5.35, 5.45,5.50,5.55, 5.50,5.45,5.25, 5.65,5.60,5.40,
               5.70,5.65,5.55, 6.30,6.30,6.25), nrow = 22, byrow = TRUE)
htest3("friedman.roundingtimes", friedman.test(RT))

# the warpbreaks example: friedman.test(wb$x, wb$w, wb$t) -- 3 blocks (tension)
# by 2 treatments (wool), which is the k = 2 boundary of the statistic
wb <- aggregate(warpbreaks$breaks,
                by = list(w = warpbreaks$wool, t = warpbreaks$tension), FUN = mean)
cat(sprintf("# warpbreaks wb$x (w fastest): %s\n",
            paste(sprintf("%.17g", wb$x), collapse = ",")))
htest3("friedman.warpbreaks", friedman.test(wb$x, wb$w, wb$t))

htest3("friedman.noties", friedman.test(matrix(c(1,2,3, 2,3,1, 3,1,2, 1,3,2),
                                               nrow = 4, byrow = TRUE)))
htest3("friedman.ties",   friedman.test(matrix(c(1,1,2, 2,2,2, 3,1,1, 1,2,2),
                                               nrow = 4, byrow = TRUE)))
htest3("friedman.k2",     friedman.test(matrix(c(1,2, 2,1, 1,2, 2,2, 1,1),
                                               nrow = 5, byrow = TRUE)))
# every cell identical: the tie correction divides by zero and R returns NaN
# rather than erroring, which is a behaviour worth pinning
htest3("friedman.allsame", friedman.test(matrix(rep(1, 12), nrow = 4)))

##
## mcnemar.test
##
P <- matrix(c(794, 86, 150, 570), nrow = 2)      # Agresti (1990) p.350
htest3("mcnemar.perf.corr",     mcnemar.test(P))
htest3("mcnemar.perf.nocorr",   mcnemar.test(P, correct = FALSE))
S <- matrix(c(10, 2, 8, 12), nrow = 2)           # small: the exact test matters
htest3("mcnemar.small.corr",    mcnemar.test(S))
htest3("mcnemar.small.nocorr",  mcnemar.test(S, correct = FALSE))
# R has no exact= for mcnemar.test; the two-sided exact binomial on the
# discordant pairs is what mcnemar_test(exact => 1) does, and is what every
# textbook calls McNemar's exact test.  b = 8, c = 2, so 2 of 10.
f("mcnemar.small.exact", binom.test(2, 10, 0.5)$p.value)
E <- matrix(c(10, 5, 5, 10), nrow = 2)           # b == c: statistic exactly 0
htest3("mcnemar.equal.corr",    mcnemar.test(E))
htest3("mcnemar.equal.nocorr",  mcnemar.test(E, correct = FALSE))
htest3("mcnemar.3x3", mcnemar.test(matrix(c(10,5,2, 3,12,4, 1,6,15),
                                          nrow = 3, byrow = TRUE)))
htest3("mcnemar.4x4", mcnemar.test(matrix(c(20,3,1,2, 4,25,2,1, 0,3,18,5, 1,2,4,22),
                                          nrow = 4, byrow = TRUE)))

##
## prop.test -- statistic, parameter, p.value, estimate(s), conf.int
##
prop_row <- function(k, r) f(k, c(r$statistic, r$parameter, r$p.value,
                                  as.numeric(r$estimate), as.numeric(r$conf.int)))
prop_row("prop.1s.83.100.corr",   prop.test(83, 100))
prop_row("prop.1s.83.100.nocorr", prop.test(83, 100, correct = FALSE))
for (alt in c("two.sided", "less", "greater")) for (co in c(TRUE, FALSE))
	prop_row(sprintf("prop.1s.p7.%s.%s", alt, if (co) "corr" else "nocorr"),
	         prop.test(83, 100, p = 0.7, alternative = alt, correct = co))
for (cl in c(0.9, 0.99))
	prop_row(sprintf("prop.1s.cl%g", cl * 100), prop.test(83, 100, conf.level = cl))
# Fleiss (1981) p.139 -- four groups, so a k-sample chi-square and no interval
prop_row("prop.fleiss4", prop.test(c(83, 90, 129, 70), c(86, 93, 136, 82)))
for (alt in c("two.sided", "less", "greater")) for (co in c(TRUE, FALSE))
	prop_row(sprintf("prop.2s.%s.%s", alt, if (co) "corr" else "nocorr"),
	         prop.test(c(83, 90), c(100, 100), alternative = alt, correct = co))
# the edges: no successes, all successes, exactly half, and both extremes at once
prop_row("prop.1s.0.10",    prop.test(0, 10))
prop_row("prop.1s.10.10",   prop.test(10, 10))
prop_row("prop.1s.5.10",    prop.test(5, 10))
prop_row("prop.2s.extreme", prop.test(c(0, 10), c(10, 10)))

##
## mantelhaen.test -- statistic, parameter, p.value, common OR, conf.int
##
mh_row <- function(k, r) f(k, c(r$statistic, r$parameter, r$p.value,
                                as.numeric(r$estimate), as.numeric(r$conf.int)))
# Agresti (1990) pp.231-237, Penicillin and Rabbits.  array() fills
# column-major, so each group of four is a = x[1,1], c = x[2,1], b = x[1,2],
# d = x[2,2]; the test file re-orders them to cmh_test's [a, b, c, d].
Rabbits <- array(c(0,0,6,5, 3,0,3,6, 6,2,0,4, 5,6,1,0, 2,5,0,0), dim = c(2,2,5))
mh_row("mh.rabbits.corr",   mantelhaen.test(Rabbits))
mh_row("mh.rabbits.nocorr", mantelhaen.test(Rabbits, correct = FALSE))
mh_row("mh.ucb.corr",   mantelhaen.test(UCBAdmissions))
mh_row("mh.ucb.nocorr", mantelhaen.test(UCBAdmissions, correct = FALSE))
mh_row("mh.ucb.cl90",   mantelhaen.test(UCBAdmissions, conf.level = 0.9))
cat("# UCBAdmissions strata, column-major (a, c, b, d):\n")
for (k in 1:6)
	cat(sprintf("#   %s\n", paste(as.vector(UCBAdmissions[, , k]), collapse = ",")))
D <- array(c(10,5,3,12, 20,8,6,15, 7,9,4,11), dim = c(2,2,3))
mh_row("mh.doc3.corr",   mantelhaen.test(D))
mh_row("mh.doc3.nocorr", mantelhaen.test(D, correct = FALSE))

##
## Cases added in 0.3217 for the bugs TODO.md listed on 2026-10-12.  Each was
## wrong in Stats::LikeR before then; the label says which.
##
# |DELTA| = 0.37 < 0.5, so R applies no Yates correction.  cmh_test always
# subtracted 0.5 and clamped at 0, giving a statistic of 0 and p 1.
mh_row("mh.yates.small", mantelhaen.test(array(c(2,3,3,4, 3,2,2,3), dim = c(2,2,2))))
# V = 0: the statistic is 0/0.  cmh_test gave 0 and p 1.
mh_row("mh.v0", mantelhaen.test(array(c(5,0,0,0, 3,0,0,0), dim = c(2,2,2))))
# no off-diagonal mass: the common odds ratio is Inf.  cmh_test gave NaN.
# Column-major, so a group (5,3,0,4) is a = 5, c = 3, b = 0, d = 4.
mh_row("mh.s0", mantelhaen.test(array(c(5,3,0,4, 3,2,0,3), dim = c(2,2,2))))
# an empty discordant pair is 0/0 in R, not a statistic of 0
htest3("mcnemar.zero.discordant", mcnemar.test(matrix(c(5,0,0,5), 2)))
# the paired form: level "c" appears only in a pair that complete.cases()
# drops.  LikeR used to count it as a third level (df 3, p 0.9536).
htest3("mcnemar.paired.dropped.level",
       mcnemar.test(c("a","b","a","b","a","b","a","a","c"),
                    c("b","a","a","b","b","b","a","a",NA)))
# one-sided 'greater' far in the tail, where 1 - pnorm(z) cancels to 0
prop_row("prop.1s.999.1000.greater", prop.test(999, 1000, alternative = "greater"))
prop_row("prop.2s.90.10.greater", prop.test(c(90, 10), c(100, 100), alternative = "greater"))
prop_row("prop.1s.90.100.p5.greater", prop.test(90, 100, p = 0.5, alternative = "greater"))
# a missing x is dropped with its n, as complete.cases() drops it
prop_row("prop.na.dropped", prop.test(c(83, NA, 90), c(100, 100, 100)))
