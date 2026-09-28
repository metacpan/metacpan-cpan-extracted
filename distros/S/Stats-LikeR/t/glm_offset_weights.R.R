# Generator for the frozen expected values in t/glm_offset_weights.R.t.
#
# Re-run with
#
#     Rscript t/glm_offset_weights.R.R > /tmp/glm_ow.pl
#
# and paste the printed %DATA and %EXPECT blocks over the ones in the .t file.
# The test itself never runs this script, or R -- it must pass on a machine
# with neither installed.
#
# Produced with R 4.6.1 and MASS 7.3-66.  Every model below is one that R's
# own regression tests or MASS's own tests fit; the file and line are given in
# the comment above each.  Where those tests draw their data from rnorm() or
# rbinom() without a seed, a seed is set here and the draw frozen, since the
# point of the original test is an identity (two fits that must agree) that
# holds for any draw.

suppressMessages(library(MASS))
options(digits = 17)

## The shortest of 15, 16 or 17 significant digits that reads back as the same
## double, so the table is exact without every 0.1 printed as
## 0.10000000000000001.  Perl has no Inf literal; 9**9**9 is the idiom that
## overflows to it.
fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  if (is.infinite(v)) return(if (v > 0) "9**9**9" else "-9**9**9")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
fmt <- function(x) vapply(x, fmt1, "")
num <- function(x) {
  if (length(x) == 0) return("[]")
  paste0("[", paste(fmt(x), collapse = ", "), "]")
}
str_ <- function(x) paste0("[", paste0("'", x, "'", collapse = ", "), "]")
col <- function(v) if (is.numeric(v)) num(v) else str_(as.character(v))

cat("my %DATA = (\n")
data_out <- function(name, df) {
  cat(sprintf("  %s => {\n", name))
  for (nm in names(df)) cat(sprintf("    '%s' => %s,\n", nm, col(df[[nm]])))
  cat("  },\n")
}
EXP <- list()
fitrec <- function(key, fit, extra = list(), disp1 = FALSE) {
  cf <- coef(fit)
  ## glm() handed negative.binomial(theta) is summarised by summary.glm(),
  ## which estimates a dispersion for any family but poisson and binomial;
  ## LikeR holds it at 1 for a fully specified variance, as summary.negbin()
  ## does, so those fits are recorded at dispersion = 1.
  V <- if (disp1) summary(fit, dispersion = 1)$cov.scaled else vcov(fit)
  se <- sqrt(diag(V))
  nm <- sub("^\\(Intercept\\)$", "Intercept", names(cf))
  rec <- list(names = nm, coef = unname(cf), se = unname(se[names(cf)]),
              deviance = deviance(fit), null = fit$null.deviance,
              aic = fit$aic, loglik = as.numeric(logLik(fit)),
              df = fit$df.residual, dfnull = fit$df.null)
  EXP[[key]] <<- c(rec, extra)
}

## tests/reg-tests-1a.R:385 -- "these are the same -- example from Jim
## Lindsey": glm(y1 - y2 ~ 1) and glm(y1 ~ offset(y2)).
set.seed(20260922)
y <- round(rnorm(20), 4)
lind <- data.frame(y1 = y[-1], y2 = y[-20])
lind$d <- lind$y1 - lind$y2
data_out("lindsey", lind)
fitrec("lindsey_g1", glm(d ~ 1, data = lind))
fitrec("lindsey_g2", glm(y1 ~ offset(y2), data = lind))

## tests/reg-tests-1a.R:396 (data) and :419 (fit), also the \donttest example
## in src/library/stats/man/glm.Rd:349 -- Venables & Ripley p.189.
anorexia <- MASS::anorexia
data_out("anorexia", anorexia)
fitrec("anorexia", glm(Postwt ~ Prewt + Treat + offset(Prewt),
                       family = gaussian, data = anorexia))

## tests/reg-tests-1a.R:1270 -- Patrick Connelly 2001-01-22, prediction
## with offsets; the offset both as a formula term and as offset =.
DF <- data.frame(counts = c(18, 17, 15, 20, 10, 20, 25, 13, 12),
                 outcome = gl(3, 1, 9), treatment = gl(3, 3),
                 exposure = c(1.17, 1.78, 1.00, 2.36, 2.58, 0.80, 2.51,
                              1.16, 1.77))
DF$outcome <- paste0("o", DF$outcome); DF$treatment <- paste0("t", DF$treatment)
data_out("connelly", DF)
f1 <- glm(counts ~ outcome + treatment + offset(log(exposure)),
          family = poisson, data = DF)
f2 <- glm(counts ~ outcome + treatment, offset = log(exposure),
          family = poisson, data = DF)
fitrec("connelly_term", f1, list(link = unname(predict(f1, newdata = DF)),
                                 resp = unname(predict(f1, newdata = DF, type = "response"))))
fitrec("connelly_arg", f2, list(link = unname(predict(f2, newdata = DF))))

## tests/reg-tests-1a.R:1434 -- PR#1422, the MASS ships fit with an offset.
ships <- MASS::ships
ships <- ships[ships$service != 0, ]
data_out("ships", data.frame(incidents = ships$incidents, type = as.character(ships$type),
                             year = ships$year, period = ships$period,
                             service = ships$service))
fitrec("ships", glm(incidents ~ type + year + period + offset(log(service)),
                    family = poisson, data = ships))

## tests/reg-tests-1a.R:1228 -- PR#6656, successive offsets.
d6656 <- data.frame(x = 1:4, y = sqrt(1:4), z = c(2:4, 1))
data_out("pr6656", d6656)
fitrec("pr6656_one", glm(y ~ offset(x) + z, data = d6656))
fitrec("pr6656_two", glm(y ~ offset(x) + offset(log(x)) + z, data = d6656))

## MASS tests/glm.nb.R:1 -- glm.nb with frequency weights must agree with the
## same data expanded ("wrong results in 7.2-18").
yeast <- data.frame(numbers = 0:5, fr = c(213, 128, 37, 18, 3, 1))
data_out("yeast", yeast)
data_out("yeast_long", data.frame(n = rep(yeast$numbers, yeast$fr)))
y2 <- glm.nb(numbers ~ 1, link = log, weights = fr, data = yeast)
y3 <- glm.nb(rep(yeast$numbers, yeast$fr) ~ 1, link = log)
fitrec("yeast_w", y2, list(theta = y2$theta, se_theta = y2$SE.theta, twologlik = y2$twologlik))
fitrec("yeast_long", y3, list(theta = y3$theta, se_theta = y3$SE.theta, twologlik = y3$twologlik))

## MASS tests/glm.nb.R:21 -- "another one, corrected in 7.2-43": duplicated
## rows with fractional weights summing to 1 must reproduce the plain fit,
## by glm.nb and by glm(negative.binomial(theta)).
set.seed(13245)
x <- c(-5:5)
mu <- exp(1 + 0.1 * x)
y <- rnegbin(length(mu), mu = mu, theta = 1.5)
dat <- data.frame(x, y)
dat2 <- dat[rep(1:11, each = 2), ]
w <- round(runif(11), 2)
dat2$w <- as.vector(rbind(w, 1 - w))
data_out("nb_dat", dat)
data_out("nb_dat2", dat2)
fm2 <- glm.nb(y ~ x, dat)
gm2 <- glm.nb(y ~ x, dat2, weights = w)
fitrec("fm2", fm2, list(theta = fm2$theta, se_theta = fm2$SE.theta))
fitrec("gm2", gm2, list(theta = gm2$theta, se_theta = gm2$SE.theta))
fm3 <- glm(y ~ x, negative.binomial(theta = fm2$theta), dat)
gm3 <- glm(y ~ x, negative.binomial(theta = fm2$theta), dat2, weights = w)
fitrec("fm3", fm3, list(theta_used = fm2$theta), disp1 = TRUE)
fitrec("gm3", gm3, list(theta_used = fm2$theta), disp1 = TRUE)

## tests/reg-tests-1b.R:1670 -- nobs() for zero-weight glm fits (was 9 for
## glm and 6 for lm in R < 2.14.1).
DFz <- data.frame(x1 = log(1:10), x2 = c(1/(1:9), NA), y = 1:10,
                  wt = c(0, 2, 0, 4, 0, 6, 7, 8, 9, 10))
data_out("nobs0", DFz)
gz <- glm(y ~ x1 + x2, weights = wt, data = DFz)
fitrec("nobs0", gz, list(nobs = nobs(gz), dispersion = summary(gz)$dispersion))

## tests/reg-tests-2.R:1805 -- PR#8720, summary on a glm with zero weights and
## estimated dispersion, against the same fit on the subset.
set.seed(8720)
y8720 <- round(rnorm(10), 4)
d8720 <- data.frame(y = y8720, x = 1:10, w = c(rep(1, 9), 0))
data_out("pr8720", d8720)
g8720 <- glm(y ~ x, weights = w, data = d8720)
s8720 <- glm(y ~ x, subset = w > 0, data = d8720)
fitrec("pr8720_w", g8720, list(dispersion = summary(g8720)$dispersion))
fitrec("pr8720_sub", s8720, list(dispersion = summary(s8720)$dispersion))

## tests/reg-tests-1a.R:3225 -- a binomial proportion with its trials as
## prior weights, glm(y/10 ~ x, binomial, weights = rep(10, 10)).
set.seed(3225)
yb <- rbinom(10, 10, 0.5)
db <- data.frame(p = yb / 10, x = 1:10, n = rep(10, 10))
data_out("binprop", db)
fitrec("binprop", glm(p ~ x, binomial, weights = n, data = db))

## tests/reg-tests-3.R:75 -- weighted glm() fits: hills with 1/dist^2.
hills <- MASS::hills
data_out("hills", data.frame(time = hills$time, dist = hills$dist, climb = hills$climb,
                             w = 1/hills$dist^2))
hg <- glm(time ~ 0 + dist + climb, data = hills, weights = 1/dist^2)
fitrec("hills", hg, list(AIC = AIC(hg)))

## statsmodels' cpunish corpus (see the .t file), fitted by R as well so that
## the looser Stata figures have an exact counterpart.
cp <- data.frame(
  executions = c(37, 9, 6, 4, 3, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1),
  income = c(34453, 41534, 35802, 26954, 31468, 32552, 40873, 34861, 42562,
             31900, 37421, 33305, 32108, 45844, 34743, 29709, 36777),
  perpoverty = c(16.7, 12.5, 10.6, 18.4, 14.8, 18.8, 11.6, 13.1, 9.4, 14.3, 8.2,
                 16.4, 18.4, 9.3, 10, 15.2, 11.7),
  perblack = c(12.2, 20, 11.2, 16.1, 25.9, 3.5, 15.3, 30.1, 4.3, 15.4, 8.2, 7.2,
               32.1, 27.4, 4, 7.7, 1.8),
  vc = c(644, 351, 591, 524, 565, 632, 886, 997, 405, 1051, 537, 321, 929,
         931, 435, 597, 463),
  south = c(1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0),
  degree = c(0.16, 0.27, 0.21, 0.16, 0.19, 0.25, 0.25, 0.21, 0.31, 0.24, 0.19,
             0.16, 0.18, 0.29, 0.24, 0.21, 0.25),
  fweight = c(1, 1, 1, 2, 2, 2, 3, 3, 3, 1, 1, 1, 2, 2, 2, 3, 3))
fitrec("cpunish", glm(executions ~ income + perpoverty + perblack + log(vc) + south + degree,
                      family = poisson, data = cp, weights = fweight))

cat(");\n\n")

cat("my %EXPECT = (\n")
for (k in names(EXP)) {
  e <- EXP[[k]]
  cat(sprintf("  %s => {\n", k))
  for (f in names(e)) {
    v <- e[[f]]
    if (is.character(v)) cat(sprintf("    %s => %s,\n", f, str_(v)))
    else if (length(v) == 1 && f %in% c("deviance", "null", "aic", "loglik", "df", "dfnull",
                                          "theta", "se_theta", "twologlik", "nobs",
                                          "dispersion", "theta_used", "AIC"))
      cat(sprintf("    %s => %s,\n", f, fmt(v)))
    else cat(sprintf("    %s => %s,\n", f, num(v)))
  }
  cat("  },\n")
}
cat(");\n")
