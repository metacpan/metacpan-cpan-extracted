# Generator for the frozen expected values in t/lmer.R.t.
#
# Re-run with
#
#     Rscript t/lmer.R.R > /tmp/lmer.pl
#
# and paste the printed %EXPECT block over the one in the .t file.  It also
# writes t/sleepstudy.csv, t/Penicillin.csv and t/Pastes.csv from lme4's
# data, and copies statsmodels' regression/tests/results/lme*.csv to
# t/lme*.csv.  The test itself never runs this script, or R.
#
# Produced with R 4.6.1, lme4 2.0-6 and lmerTest 3.2-1.  Every model is fitted
# twice.  Once by lmer() with its default control, which is what a user of
# lme4 sees (pkg_*): its optimiser stops about 1e-6 from the optimum in
# theta.  And once more tightly, as the third opinion the .t file holds LikeR
# to: lme4's own profiled criterion -- lme4's code, not LikeR's -- handed
# through lmerControl(optimizer = ) to nlminb() at its tightest tolerances and
# then to Nelder-Mead from there, with lmerTest's Satterthwaite degrees of
# freedom computed on the result.

suppressMessages({library(lme4); library(lmerTest)})
options(digits = 17)

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")
str_ <- function(x) paste0("[", paste0("'", x, "'", collapse = ", "), "]")

data("sleepstudy", package = "lme4"); data("Penicillin", package = "lme4"); data("Pastes", package = "lme4")
S <- sleepstudy; S$Subject <- paste0("s", S$Subject)
write.csv(S, "t/sleepstudy.csv", row.names = FALSE)
P <- Penicillin; P$plate <- as.character(P$plate); P$sample <- as.character(P$sample)
write.csv(P, "t/Penicillin.csv", row.names = FALSE)
Pa <- Pastes; Pa$batch <- as.character(Pa$batch); Pa$cask <- as.character(Pa$cask)
Pa <- Pa[, c("strength", "batch", "cask")]
write.csv(Pa, "t/Pastes.csv", row.names = FALSE)
smdir <- "/home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages/statsmodels/regression/tests/results"
for (i in 0:11) file.copy(file.path(smdir, sprintf("lme%02d.csv", i)), sprintf("t/lme%02d.csv", i), overwrite = TRUE)
S <- read.csv("t/sleepstudy.csv"); P <- read.csv("t/Penicillin.csv"); Pa <- read.csv("t/Pastes.csv")

## An optimiser in lme4's own interface (lmerControl(optimizer = )), so that
## lmerTest can refit the deviance function from the model's call.
## Some of statsmodels' corpora have a local minimum on the boundary as well
## as the interior one (lme07's ML fit: lme4's default stops at a singular
## theta whose criterion is 0.92 above the interior minimum), so nlminb() is
## started from lme4's own start and from 30 random ones, and the best kept.
tightopt <- function(par, fn, lower, upper, control) {
  set.seed(20260922)
  starts <- c(list(par), lapply(1:30, function(i) ifelse(is.finite(lower), runif(length(par), 0.05, 2),
                                                           runif(length(par), -1, 1))))
  best <- NULL
  for (st in starts) {
    o <- tryCatch(nlminb(st, fn, lower = lower, upper = upper,
                         control = list(eval.max = 1e5, iter.max = 1e5, rel.tol = 1e-15, x.tol = 1e-15,
                                        step.min = 1e-12)), error = function(e) NULL)
    if (!is.null(o) && (is.null(best) || o$objective < best$objective)) best <- o
  }
  o2 <- optim(best$par, fn, method = "Nelder-Mead", control = list(reltol = 1e-16, maxit = 1e5))
  if (o2$value < best$objective && all(o2$par >= lower))
    list(par = o2$par, fval = o2$value, conv = 0, message = "")
  else list(par = best$par, fval = best$objective, conv = 0, message = "")
}
tight <- function(formula, data, REML)
  lmerTest::lmer(formula, data = data, REML = REML,
                 control = lmerControl(optimizer = tightopt, calc.derivs = FALSE))

EXP <- list()
rec <- function(key, formula, data, REML = TRUE) {
  pkg <- lmer(formula, data = data, REML = REML)
  fm <- tight(formula, data, REML)
  ct <- coef(summary(fm))
  vc <- as.data.frame(VarCorr(fm))
  EXP[[key]] <<- list(
    names = sub("^\\(Intercept\\)$", "Intercept", rownames(ct)),
    coef = unname(ct[, "Estimate"]), se = unname(ct[, "Std. Error"]),
    df = unname(ct[, "df"]), t = unname(ct[, "t value"]), p = unname(ct[, "Pr(>|t|)"]),
    theta = unname(getME(fm, "theta")), sigma = sigma(fm),
    crit = if (REML) REMLcrit(fm) else deviance(fm), loglik = as.numeric(logLik(fm)),
    vc_grp = vc$grp, vc_var1 = ifelse(is.na(vc$var1), "", vc$var1), vc_var2 = ifelse(is.na(vc$var2), "", vc$var2),
    vc_sdcor = vc$sdcor,
    pkg_coef = unname(fixef(pkg)), pkg_se = unname(sqrt(diag(as.matrix(vcov(pkg))))),
    pkg_theta = unname(getME(pkg, "theta")), pkg_crit = if (REML) REMLcrit(pkg) else deviance(pkg),
    pkg_df = unname(coef(summary(pkg))[, "df"]))
}

## lme4 man/sleepstudy.Rd and lmer.Rd, and lmerTest tests/test_summary.R
rec("sleep_slope",      Reaction ~ Days + (Days | Subject), S)
rec("sleep_slope_ml",   Reaction ~ Days + (Days | Subject), S, REML = FALSE)
rec("sleep_uncorr",     Reaction ~ Days + (1 | Subject) + (0 + Days | Subject), S)
rec("sleep_intercept",  Reaction ~ Days + (1 | Subject), S)
## lme4 man/Penicillin.Rd: crossed plate and sample
rec("penicillin",       diameter ~ 1 + (1 | plate) + (1 | sample), P)
## lme4 man/Pastes.Rd: cask nested in batch
rec("pastes",           strength ~ 1 + (1 | batch / cask), Pa)
## statsmodels regression/tests/test_lme.py: lme<k>.csv, fixed effects
## exog_fe_*, random effects exog_re_* by groups, dependent ("drf") and,
## with two random effects, independent ("irf"); ML and REML
for (k in 0:11) {
  D <- read.csv(sprintf("t/lme%02d.csv", k))
  fe <- grep("^exog_fe", names(D), value = TRUE); re <- grep("^exog_re", names(D), value = TRUE)
  D$groups <- paste0("g", D$groups)
  fx <- paste("endog ~ 0 +", paste(fe, collapse = " + "))
  f_drf <- as.formula(paste(fx, "+ (0 +", paste(re, collapse = " + "), "| groups)"))
  f_irf <- as.formula(paste(fx, "+", paste(sprintf("(0 + %s | groups)", re), collapse = " + ")))
  for (reml in c(FALSE, TRUE)) {
    m <- if (reml) "reml" else "ml"
    ok <- tryCatch({ rec(sprintf("lme%02d_%s_drf", k, m), f_drf, D, REML = reml); TRUE }, error = function(e) FALSE)
    if (length(re) > 1)
      tryCatch(rec(sprintf("lme%02d_%s_irf", k, m), f_irf, D, REML = reml), error = function(e) NULL)
  }
}

cat("my %EXPECT = (\n")
for (k in names(EXP)) {
  e <- EXP[[k]]
  cat(sprintf("  %s => {\n", k))
  for (f in names(e)) cat(sprintf("    %s => %s,\n", f,
      if (is.character(e[[f]])) str_(e[[f]]) else if (length(e[[f]]) == 1 && f %in% c("sigma", "crit", "loglik", "pkg_crit")) fmt1(e[[f]]) else num(e[[f]])))
  cat("  },\n")
}
cat(");\n")
