# Regenerates the frozen tables in t/survival.status_rho.R.t.
#   Rscript t/survival.status_rho.R.R > /tmp/survival.status_rho.tables
# then paste the blocks over %DATA, %LR, %KM and %COX in the test.  The test
# never runs this; it reads the literals that were pasted from it.
#
# R 4.6.1 with survival 3.8-12.  Every time is an integer, so the data and every
# risk-set count are exact at each NV width.
options(digits = 17, scipen = 500)
suppressMessages(library(survival))

num <- function(v) paste0("[", paste(ifelse(is.na(v) | !is.finite(v), "undef",
                                            sprintf("%.17g", v)), collapse = ", "), "]")
str <- function(v) paste0("[", paste0("'", v, "'", collapse = ", "), "]")

# lung is coded 1 = censored, 2 = dead.  Each case drops the rows its grouping
# variable is NA on, as survdiff() and survfit() do under na.omit; the test
# refuses an undef label instead.
lung_inst  <- lung[!is.na(lung$inst), ]
lung_ecog  <- lung[!is.na(lung$ph.ecog), ]
cat("my %DATA = (\n")
cat(sprintf("\tlung_inst => { time => %s, status => %s, group => %s },\n",
            num(lung_inst$time), num(lung_inst$status), str(lung_inst$inst)))
cat(sprintf("\tlung_ecog => { time => %s, status => %s, group => %s },\n",
            num(lung_ecog$time), num(lung_ecog$status), str(lung_ecog$ph.ecog)))
cat(sprintf("\tlung_age => { time => %s, status => %s, age => %s },\n",
            num(lung$time), num(lung$status), num(lung$age)))
cat(sprintf("\tovarian => { time => %s, status => %s, group => %s },\n",
            num(ovarian$futime), num(ovarian$fustat), str(ovarian$rx)))
cat(sprintf("\taml => { time => %s, status => %s, group => %s },\n",
            num(aml$time), num(aml$status), str(as.character(aml$x))))
cat(");\n\n")

lr <- list(
  # survival 3.8-12 tests/cancer.R: survdiff(Surv(time, status) ~ inst, lung, rho=.5)
  list(name = "lung_inst_rho0.5", data = "lung_inst", d = lung_inst, g = lung_inst$inst, rho = 0.5),
  # the same data on the log-rank test, which the 1/2 coding alone decides
  list(name = "lung_inst_rho0", data = "lung_inst", d = lung_inst, g = lung_inst$inst, rho = 0),
  # survival 3.8-12 man/survdiff.Rd: survdiff(Surv(futime, fustat) ~ rx, data=ovarian)
  list(name = "ovarian_rho0", data = "ovarian", d = data.frame(time = ovarian$futime, status = ovarian$fustat),
       g = ovarian$rx, rho = 0),
  # written here: the same data under Peto & Peto's weights
  list(name = "ovarian_rho1", data = "ovarian", d = data.frame(time = ovarian$futime, status = ovarian$fustat),
       g = ovarian$rx, rho = 1),
  # written here: aml (tests/difftest.R) across rho, a negative one included
  list(name = "aml_rho1", data = "aml", d = aml, g = as.character(aml$x), rho = 1),
  list(name = "aml_rho2", data = "aml", d = aml, g = as.character(aml$x), rho = 2),
  list(name = "aml_rho-0.5", data = "aml", d = aml, g = as.character(aml$x), rho = -0.5)
)
cat("my %LR = (\n")
for (c in lr) {
  g <- c$g
  f <- survdiff(Surv(c$d$time, c$d$status) ~ g, rho = c$rho)
  # survdiff() orders groups by sorted level; the test re-keys by label
  lev <- sub("^g=", "", names(f$n))
  cat(sprintf("\t'%s' => {\n\t\tdata => '%s', rho => %.17g,\n", c$name, c$data, c$rho))
  cat(sprintf("\t\tstatistic => %.17g, parameter => %d, p => %.17g,\n",
              f$chisq, sum(f$exp > 0) - 1, f$pvalue))
  cat(sprintf("\t\tlevels => %s,\n\t\tobserved => %s,\n\t\texpected => %s,\n\t},\n",
              str(lev), num(f$obs), num(f$exp)))
}
cat(");\n\n")

# survival 3.8-12 man/Surv.Rd and tests/cancer.R:
# survfit(Surv(time, status) ~ ph.ecog, data=lung)
cat("my %KM = (\n")
for (g in sort(unique(lung_ecog$ph.ecog))) {
  s <- survfit(Surv(time, status) ~ 1, lung_ecog[lung_ecog$ph.ecog == g, ])
  med <- summary(s)$table["median"]
  cat(sprintf("\t'%s' => {\n\t\ttime => %s,\n\t\t'n_risk' => %s,\n\t\t'n_event' => %s,\n\t\t'n_censor' => %s,\n",
              g, num(s$time), num(s$n.risk), num(s$n.event), num(s$n.censor)))
  cat(sprintf("\t\tsurv => %s,\n\t\t'std_err' => %s,\n\t\tlower => %s,\n\t\tupper => %s,\n",
              num(s$surv), num(s$std.err * s$surv), num(s$lower), num(s$upper)))
  cat(sprintf("\t\tmedian => %s,\n\t},\n",
              ifelse(is.na(med), "undef", sprintf("%.17g", med))))
}
cat(");\n\n")

# written here: an iteration limit past 65535, which coxph()'s unsigned short
# wrapped to 0 through 0.33
f <- coxph(Surv(time, status) ~ age, lung, iter.max = 65536)
cat(sprintf("my %%COX = (coef => %.17g, loglik => %.17g);\n", coef(f), f$loglik[2]))
