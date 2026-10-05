# Regenerates the frozen tables in t/survival.R.t.
#   Rscript t/survival.R.R > /tmp/survival.tables
# then paste the two blocks over %LR and %KM in the test.  The test never runs
# this; it reads the literals that were pasted from it.
#
# R 4.6.1 with survival 3.8-12.  Every time is a small integer, so the data and
# every risk-set count are exact at each NV width.
options(digits = 17, scipen = 500)
suppressMessages(library(survival))

num <- function(v) paste0("[", paste(ifelse(is.na(v) | !is.finite(v), "undef",
                                            sprintf("%.17g", v)), collapse = ", "), "]")
str <- function(v) paste0("[", paste0("'", v, "'", collapse = ", "), "]")

# survival 3.8-12 tests/difftest.R: aml, and aml with a third group of seven
# early censorings "tacked on".  "These should give the same result (chisq,
# df), but the second has an extra group."
aml3 <- data.frame(time = c( 9, 13, 13, 18, 23, 28, 31, 34, 45, 48, 161,
                             5,  5,  8,  8, 12, 16, 23, 27, 30, 33, 43, 45,
                             1,  2,  2,  3,  3,  3,  4),
                   status = c(1,1,0,1,1,0,1,1,0,1,0, 1,1,1,1,1,0,1,1,1,1,1,1,
                              0,0,0,0,0,0,0),
                   x = c(rep("Maintained", 11), rep("Nonmaintained", 12), rep("Dummy", 7)))
lr <- list(
  aml  = data.frame(time = aml$time, status = aml$status, x = as.character(aml$x)),
  aml3 = aml3,
  # the 0.3212 fuzz case that found the bug: group a's one subject is censored
  # before the first event
  early_censor = data.frame(time = c(1,5,4,3,6,3,5,4), status = c(0,1,1,1,1,0,0,0),
                            x = c("a","c","c","c","b","b","b","b")),
  # dead group in the middle of the label order, not first or last
  dead_middle = data.frame(time = c(2,3,5,1,1,4,6,7,8), status = c(1,0,1,0,0,1,1,0,1),
                           x = c("a","a","a","b","b","c","c","c","c")),
  # only one group is ever at risk at an event time: chisq 0 on 0 df, p = 1
  one_live = data.frame(time = c(1,2,5,6), status = c(0,0,1,1), x = c("a","a","b","b"))
)
cat("my %LR = (\n")
for (nm in names(lr)) {
  d <- lr[[nm]]
  f <- survdiff(Surv(time, status) ~ x, d)
  # survdiff() orders groups by sorted factor level; the test re-keys by label
  lev <- sub("^x=", "", names(f$n))
  cat(sprintf("\t%s => {\n\t\ttime => %s,\n\t\tstatus => %s,\n\t\tgroup => %s,\n",
              nm, num(d$time), num(d$status), str(d$x)))
  cat(sprintf("\t\tstatistic => %.17g, parameter => %d, p => %.17g,\n",
              f$chisq, sum(f$exp > 0) - 1, f$pvalue))
  cat(sprintf("\t\tlevels => %s,\n\t\tobserved => %s,\n\t\texpected => %s,\n\t},\n",
              str(lev), num(f$obs), num(f$exp)))
}
cat(");\n\n")

km <- list(
  # survival 3.8-12 tests/quantile.R test1, less its status = NA row, which
  # survfit()'s na.omit drops and survfit() here refuses
  test1 = data.frame(time = c(9,1,1,6,6,8,10), status = c(1,1,0,1,1,0,0),
                     x = c("0","1","1","1","0","0","0")),
  aml = data.frame(time = aml$time, status = aml$status, x = as.character(aml$x)),
  # S steps onto exactly 0.5 and drops again later: median is the midpoint
  # (the 0.3212 fuzz cases, seeds 62, 108 and 148)
  flat62  = data.frame(time = c(3,6,6,4,1,5,4,1,4,4,4), status = c(0,1,1,0,0,1,0,0,1,0,1),
                       x = "all"),
  flat108 = data.frame(time = c(6,2,4,2,1,5,2,3,1,6,1,2), status = c(0,1,1,1,1,0,1,1,1,1,1,0),
                       x = "all"),
  flat148 = data.frame(time = c(1,5,3,3,2,2,4,5), status = c(1,0,0,0,0,1,1,1), x = "all"),
  # S steps onto exactly 0.5 and never drops again: median is that time
  flat_end = data.frame(time = c(1,2,3,4), status = c(1,1,0,0), x = "all"),
  # S = 3/4 * 2/3 = 1/2 at t = 3 with censorings before it and on the flat
  # stretch after it; the next drop is at t = 5, so the median is 4
  flat_censored = data.frame(time = c(1,1,2,2,2,3,4,5), status = c(1,1,0,0,0,1,0,1),
                             x = "all")
)
cat("my %KM = (\n")
for (nm in names(km)) {
  d <- km[[nm]]
  cat(sprintf("\t%s => {\n\t\ttime => %s,\n\t\tstatus => %s,\n\t\tgroup => %s,\n\t\tstrata => {\n",
              nm, num(d$time), num(d$status), str(d$x)))
  for (g in sort(unique(d$x))) {
    s <- survfit(Surv(time, status) ~ 1, d[d$x == g, ])
    med <- summary(s)$table["median"]
    cat(sprintf("\t\t\t'%s' => {\n\t\t\t\ttime => %s,\n\t\t\t\t'n_risk' => %s,\n\t\t\t\t'n_event' => %s,\n\t\t\t\t'n_censor' => %s,\n",
                g, num(s$time), num(s$n.risk), num(s$n.event), num(s$n.censor)))
    cat(sprintf("\t\t\t\tsurv => %s,\n\t\t\t\t'std_err' => %s,\n\t\t\t\tlower => %s,\n\t\t\t\tupper => %s,\n",
                num(s$surv), num(s$std.err * s$surv), num(s$lower), num(s$upper)))
    cat(sprintf("\t\t\t\tmedian => %s,\n\t\t\t},\n",
                ifelse(is.na(med), "undef", sprintf("%.17g", med))))
  }
  cat("\t\t},\n\t},\n")
}
cat(");\n")
