# Generator for the frozen expected values in t/coxph_extended.R.t.
#
# Re-run with
#
#     Rscript t/coxph_extended.R.R > /tmp/coxph_extended.pl
#
# and paste the printed %DATA and %EXPECT blocks over the ones in the .t
# file.  It also writes t/bladder.csv and t/bladder2.csv (survival's bladder
# data) and copies statsmodels' phreg corpora to t/phreg_*.csv.  The test
# itself never runs this script, or R.
#
# Produced with R 4.6.1 and survival 3.8-12.  Every model is one that
# survival's own tests/*.R or statsmodels' duration/tests/test_phreg.py fits;
# the file is named above each.

suppressMessages(library(survival))
options(digits = 17)

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  if (is.infinite(v)) return(if (v > 0) "9**9**9" else "-9**9**9")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")
str_ <- function(x) paste0("[", paste0("'", x, "'", collapse = ", "), "]")
col <- function(v) if (is.numeric(v) || is.logical(v)) num(as.numeric(v)) else str_(as.character(v))

cat("my %DATA = (\n")
data_out <- function(name, df) {
  cat(sprintf("  %s => {\n", name))
  for (nm in names(df)) cat(sprintf("    '%s' => %s,\n", nm, col(df[[nm]])))
  cat("  },\n")
}
EXP <- list()
rec <- function(key, fit, extra = list()) {
  e <- list(coef = unname(coef(fit)), se = unname(sqrt(diag(vcov(fit)))),
            loglik = fit$loglik[2], loglik0 = fit$loglik[1],
            score = unname(fit$score), wald = unname(fit$wald.test), n = fit$n,
            nevent = fit$nevent, names = names(coef(fit)))
  if (!is.null(fit$naive.var)) {
    e$naive_se <- unname(sqrt(diag(fit$naive.var)))
    e$rscore <- unname(fit$rscore)
  }
  EXP[[key]] <<- c(e, extra)
}

## ---------------------------------------------------------------- doweight.R
## Case weights, and the same data done by replication.
testw1 <- data.frame(time = c(1,1,2,2,2,2,3,4,5), status = c(1,0,1,1,1,0,0,1,0),
                     x = c(2,0,1,1,0,1,0,1,0), wt = c(1,2,3,4,3,2,1,2,1))
xx <- c(1,2,3,4,3,2,1,2,1)
testw2 <- data.frame(time = rep(testw1$time, xx), status = rep(testw1$status, xx),
                     x = rep(testw1$x, xx), id = rep(1:9, xx))
data_out("testw1", testw1)
data_out("testw2", testw2)
for (tie in c("breslow", "efron")) {
  rec(paste0("testw1_", tie), coxph(Surv(time, status) ~ x, testw1, weights = wt, ties = tie))
  rec(paste0("testw2_", tie), coxph(Surv(time, status) ~ x, testw2, ties = tie))
  rec(paste0("testw1_", tie, "_robust"), coxph(Surv(time, status) ~ x, testw1, weights = wt,
                                               ties = tie, robust = TRUE))
  rec(paste0("testw2_", tie, "_cluster"), coxph(Surv(time, status) ~ x, testw2, ties = tie,
                                                cluster = id))
}
## a fractional weight makes the variance robust by default in survival
testw1$fw <- testw1$wt / 3
rec("testw1_fractional", coxph(Surv(time, status) ~ x, testw1, weights = fw))

## ---------------------------------------------------------------- counting.R
## The simplest test data set, and the same subjects split into
## (start, stop] intervals; the fits must agree.
test1 <- data.frame(time = c(9, 3,1,1,6,6,8), status = c(1,NA,1,0,1,1,0), x = c(0, 2,1,1,1,0,0))
test1b <- data.frame(start = c(0, 3,  0,  0, 5,  0, 6,14,  0,  0, 10,20,30, 0),
                     stop  = c(3,10, 10,  5,20,  6,14,20, 30,  10,20,30,40, 10),
                     status= c(0, 1,  0,  0, 1,  0, 0, 1,  0,   0, 0, 0, 1,  0),
                     x     = c(1, 1,  1,  1, 1,  0, 0, 0,  0,   0, 0, 0, 0,  NA),
                     id    = c(3, 3,  4,  5, 5,  6, 6, 6,  7,   1, 1, 1, 1,   2))
data_out("test1", test1)
data_out("test1b", test1b)
for (tie in c("efron", "breslow")) {
  rec(paste0("test1_", tie), coxph(Surv(time, status) ~ x, test1, ties = tie))
  rec(paste0("test1b_", tie), coxph(Surv(start, stop, status) ~ x, test1b, ties = tie))
  rec(paste0("test1b_", tie, "_cluster"), coxph(Surv(start, stop, status) ~ x, test1b,
                                                ties = tie, cluster = id))
}

## ---------------------------------------------------------------- bladder.R
## Wei, Lin and Weissfeld's marginal model (strata by recurrence, robust by
## patient), Andersen-Gill's counting-process model, and Prentice's
## conditional models on the recurrence subsets.
B <- bladder; B2 <- bladder2
write.csv(B, "t/bladder.csv", row.names = FALSE)
write.csv(B2, "t/bladder2.csv", row.names = FALSE)
wfit <- coxph(Surv(stop, event) ~ (rx + size + number) * strata(enum), cluster = id, B, ties = "breslow")
rec("bladder_wlw", wfit)
rec("bladder2_ag", coxph(Surv(start, stop, event) ~ rx + size + number, cluster = id, B2, ties = "breslow"))
rec("bladder2_ag_efron", coxph(Surv(start, stop, event) ~ rx + size + number, cluster = id, B2))
rec("bladder2_ag_strata", coxph(Surv(start, stop, event) ~ rx + size + number + strata(enum), cluster = id, B2))
for (k in 1:3) {
  rec(sprintf("bladder2_prentice%d", k),
      coxph(Surv(stop, event) ~ rx + size + number, B2, subset = (enum == k), ties = "breslow"))
}
rec("bladder2_prentice2b", coxph(Surv(stop - start, event) ~ rx + size + number, B2,
                                 subset = (enum == 2), ties = "breslow"))
rec("bladder2_offset", coxph(Surv(start, stop, event) ~ size + number + offset(0.5 * rx), cluster = id, B2))

## ---------------------------------------------------------------- statsmodels
## duration/tests/test_phreg.py: its survival_data_<n>_<p>.csv corpora
## (columns time, status, entry, exog...), strata = kron(0:4, rep(1, n/5)),
## fitted plain, with entry times, with strata, and with both.
smdir <- "/home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages/statsmodels/duration/tests/results"
for (f in c("survival_data_20_1", "survival_data_50_2", "survival_data_100_5", "survival_data_1000_10")) {
  D <- read.table(file.path(smdir, paste0(f, ".csv")))
  file.copy(file.path(smdir, paste0(f, ".csv")), file.path("t", paste0("phreg_", sub("survival_data_", "", f), ".csv")),
            overwrite = TRUE)
  names(D) <- c("time", "status", "entry", paste0("x", seq_len(ncol(D) - 3)))
  n <- nrow(D)
  D$strata <- rep(0:4, each = n / 5)
  xs <- paste(paste0("x", seq_len(ncol(D) - 4)), collapse = " + ")
  for (tie in c("breslow", "efron")) {
    key <- paste0(sub("survival_data_", "phreg_", f), "_", substr(tie, 1, 3))
    rec(key, coxph(as.formula(paste("Surv(time, status) ~", xs)), D, ties = tie))
    rec(paste0(key, "_et"), coxph(as.formula(paste("Surv(entry, time, status) ~", xs)), D, ties = tie))
    rec(paste0(key, "_st"), coxph(as.formula(paste("Surv(time, status) ~", xs, "+ strata(strata)")), D, ties = tie))
    rec(paste0(key, "_et_st"), coxph(as.formula(paste("Surv(entry, time, status) ~", xs, "+ strata(strata)")),
                                     D, ties = tie))
  }
}
cat(");\n\n")

cat("my %EXPECT = (\n")
for (k in names(EXP)) {
  e <- EXP[[k]]
  cat(sprintf("  %s => {\n", k))
  for (f in names(e)) cat(sprintf("    %s => %s,\n", f,
                                  if (is.character(e[[f]])) str_(e[[f]]) else if (length(e[[f]]) == 1 && f %in% c("loglik", "loglik0", "score", "wald", "n", "nevent", "rscore")) fmt1(e[[f]]) else num(e[[f]])))
  cat("  },\n")
}
cat(");\n")
