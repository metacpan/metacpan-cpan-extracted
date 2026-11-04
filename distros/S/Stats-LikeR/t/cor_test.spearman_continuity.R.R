# Regenerates the frozen table in t/cor_test.spearman_continuity.R.t.
#   Rscript t/cor_test.spearman_continuity.R.R
# and paste its output over @R_ROWS.  The test never runs this, or R.
#
# R 4.6.1.  x is 1:n in every row.  y is:
#   - R's tests/reg-tests-2.R line 2425, "and a little for Spearman's":
#     x = 1:5, y = c(8, 6, 7, 5, 3);
#   - the corpus of t/cor_test.spearman.R.R (the same set.seed(n*100 + s)
#     permutations, and its two tied vectors);
#   - n = 1300, y = (37 i) mod 1301, a permutation because 1301 is prime, the
#     smallest n past R's 1290 at which cor.test() leaves the exact branch
#     whatever `exact` says;
#   - "straddle": n = 6, y = c(1, 5, 6, 3, 4, 2), whose S of 36 lies in
#     (n(n^2-1)/6, n(n^2-1)/6 + 1] = (35, 36], where R's two-sided p takes
#     the tail S lies in although the corrected r is positive, and so returns
#     1.  With no ties S is even, so this needs n(n^2-1)/6 odd; n = 6 is the
#     smallest such n, and this y the first permutation of 1:6, in
#     lexicographic order, with S = 36.
# Small integers throughout, so the ranks and the tie structure are the same
# at every NV width.
options(digits = 17, scipen = 500)
mk <- function(n, seed) { set.seed(seed); sample.int(n) }
cases <- list(list(n = 5, y = c(8, 6, 7, 5, 3)))
for (n in c(4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 16, 20, 24, 32, 50, 100))
  for (s in 1:2) cases[[length(cases)+1]] <- list(n = n, y = mk(n, n*100+s))
cases[[length(cases)+1]] <- list(n = 10, y = c(1,1,2,2,3,3,4,4,5,5))
cases[[length(cases)+1]] <- list(n = 12, y = c(1,1,1,2,2,2,3,3,3,4,4,4))
cases[[length(cases)+1]] <- list(n = 1300, y = (37 * (1:1300)) %% 1301)
cases[[length(cases)+1]] <- list(n = 6, y = c(1, 5, 6, 3, 4, 2))   # the straddle
for (cs in cases) {
  n <- cs$n; x <- 1:n; y <- cs$y
  ys <- if (n == 1300) "MOD1301" else paste(y, collapse = ",")
  for (alt in c("two.sided", "greater", "less"))
    for (ex in c(NA, TRUE, FALSE))
      for (cc in c(FALSE, TRUE)) {
        r <- suppressWarnings(
               if (is.na(ex)) cor.test(x, y, method = "spearman", alternative = alt, continuity = cc)
               else cor.test(x, y, method = "spearman", alternative = alt, exact = ex, continuity = cc))
        cat(sprintf("\t[%d, '%s', '%s', '%s', %d, %.17g, %.17g],\n",
                    n, ys, alt, if (is.na(ex)) "d" else if (ex) "1" else "0", cc,
                    r$statistic, r$p.value))
      }
}
