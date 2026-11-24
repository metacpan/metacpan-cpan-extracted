# Generator for the frozen expected values in t/lmer.offset.weights.R.t.
#
# Re-run from the distribution root with
#
#     Rscript t/lmer.offset.weights.R.R > /tmp/lmer.ow.pl
#
# and paste the printed %EXPECT block over the one in the .t file.  It also
# writes the data the models are fitted to, t/lmer.pw.sim.csv,
# t/lmer.pw.small.csv, t/lmer.pw.sleep.csv and t/lme4.offset.sim.csv.  The
# test itself never runs this script, or R.
#
# Produced with R 4.6.1, lme4 2.0-6 and lmerTest 3.2-1.  The cases are lme4's
# own, from its source tarball's tests/ (/home/con/Scripts/r-pkg-sources/lme4):
#
#   pw_*      tests/priorWeights.R: the simulated 1000 rows in 100 groups with
#             residual variance v = (rpois + 1)^2 and weights w = 1/v, fitted
#             as its lmerMods ML1 .. REML3; then its sleepstudy with simulated
#             weights (sleepLmer); then its set.seed(2) example of 40 rows,
#             whose lme4.0 results the file records in a comment.  The random
#             numbers are drawn in the order that file draws them, under the
#             RNGkind it sets, so the data are its data.
#   pw5_ml    tests/priorWeights.R line 160: sleepstudy with every weight 5.
#   off_*     tests/offset.R: 2600 rows, y ~ x + (1|block) with and without
#             offset(3*x); the file checks that the slope moves by exactly 3.
#   sleep_off tests/modFormula.R: Reaction ~ Days + (Days|Subject) +
#             offset(0.5*Days) (its fm2Off).
#
# Each model is fitted twice, as in t/lmer.R.R: by lmer() with its default
# control (pkg_*), and tightly -- lme4's own criterion handed to nlminb() at its
# tightest tolerances and then to Nelder-Mead -- with lmerTest's Satterthwaite
# degrees of freedom on the tight fit.

suppressMessages({library(lme4); library(lmerTest)})
options(digits = 17)
if ("sample.kind" %in% names(formals(RNGkind)))
  suppressWarnings(RNGkind("Mersenne-Twister", "Inversion", "Rounding"))  # as tests/priorWeights.R

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")
str_ <- function(x) paste0("[", paste0("'", x, "'", collapse = ", "), "]")

## tests/priorWeights.R, in its order of random draws
set.seed(1)
nGroups <- 100; nObs <- 1000
explVar1 <- rnorm(nObs); explVar2 <- rnorm(nObs)
groupFac <- as.factor(rep(1:nGroups, each = nObs / nGroups))
randEff0 <- rep(rnorm(nGroups), each = nObs / nGroups)
randEff1 <- rep(rnorm(nGroups), each = nObs / nGroups)
randEff2 <- rep(rnorm(nGroups), each = nObs / nGroups)
residSD <- rpois(nObs, 1) + 1
residError <- rnorm(nObs, sd = residSD)
SIM <- data.frame(y = randEff0 + (1 + randEff1) * explVar1 + (1 + randEff2) * explVar2 + residError,
                  x = explVar1, z = explVar2, g = paste0("g", groupFac), w = 1 / residSD^2)
write.csv(SIM, "t/lmer.pw.sim.csv", row.names = FALSE)
n <- nrow(sleepstudy)
v <- rpois(n, 1) + 1
SL <- sleepstudy; SL$Subject <- paste0("s", SL$Subject); SL$w <- 1 / v
write.csv(SL, "t/lmer.pw.sleep.csv", row.names = FALSE)
set.seed(2)
n <- 40
w <- runif(n); x <- runif(n)
g <- factor(sample(1:10, n, replace = TRUE))
Z <- model.matrix(~g - 1)
y <- Z %*% rnorm(ncol(Z)) + x + rnorm(n) / w^.5
SM <- data.frame(y = as.vector(y), x = x, g = paste0("g", g), w = w)
write.csv(SM, "t/lmer.pw.small.csv", row.names = FALSE)

## tests/offset.R
set.seed(101)
d <- expand.grid(block = LETTERS[1:26], rep = 1:100)
d$x <- runif(nrow(d))
reff_f <- rnorm(length(levels(d$block)), sd = 1)
d$eta0 <- 4 + 3 * d$x
d$eta <- d$eta0 + reff_f[d$block]
d$mu <- d$eta
d$y <- rnorm(nrow(d), mean = d$mu, sd = 1)
d$mu <- exp(d$eta)                       # the file's glmer() half, for t/glmer.poisson.R.t
d$ycount <- rpois(nrow(d), d$mu)
OFF <- data.frame(block = as.character(d$block), x = d$x, y = d$y, ycount = d$ycount)
write.csv(OFF, "t/lme4.offset.sim.csv", row.names = FALSE)

SIM <- read.csv("t/lmer.pw.sim.csv"); SL <- read.csv("t/lmer.pw.sleep.csv")
SM <- read.csv("t/lmer.pw.small.csv"); OFF <- read.csv("t/lme4.offset.sim.csv")
S <- SL; S$w5 <- 5

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

EXP <- list()
## wcol: the name of the weights column, or NULL
rec <- function(key, formula, data, REML = TRUE, wcol = NULL) {
  data$.w <- if (is.null(wcol)) 1 else data[[wcol]]
  pkg <- if (is.null(wcol)) lmer(formula, data = data, REML = REML)
         else lmer(formula, data = data, REML = REML, weights = .w)
  ctl <- lmerControl(optimizer = tightopt, calc.derivs = FALSE)
  fm <- if (is.null(wcol)) lmerTest::lmer(formula, data = data, REML = REML, control = ctl)
        else lmerTest::lmer(formula, data = data, REML = REML, weights = .w, control = ctl)
  ct <- coef(summary(fm))
  vc <- as.data.frame(VarCorr(fm))
  EXP[[key]] <<- list(
    names = sub("^\\(Intercept\\)$", "Intercept", rownames(ct)),
    coef = unname(ct[, "Estimate"]), se = unname(ct[, "Std. Error"]),
    df = unname(ct[, "df"]), t = unname(ct[, "t value"]), p = unname(ct[, "Pr(>|t|)"]),
    logp = log(unname(ct[, "Pr(>|t|)"])),  # off_none's p is 7.6e-305, a literal perl 5.10.1 reads 7% low
    theta = unname(getME(fm, "theta")), sigma = sigma(fm),
    crit = if (REML) REMLcrit(fm) else deviance(fm), loglik = as.numeric(logLik(fm)),
    vc_sdcor = vc$sdcor,
    fitted = unname(fitted(fm))[c(1, 2, nrow(data))],
    pkg_coef = unname(fixef(pkg)), pkg_se = unname(sqrt(diag(as.matrix(vcov(pkg))))),
    pkg_theta = unname(getME(pkg, "theta")), pkg_crit = if (REML) REMLcrit(pkg) else deviance(pkg))
}

rec("pw_ML1",   y ~ x + (1 | g),         SIM, REML = FALSE, wcol = "w")
rec("pw_REML1", y ~ x + (1 | g),         SIM, REML = TRUE,  wcol = "w")
rec("pw_ML2",   y ~ x + (x | g),         SIM, REML = FALSE, wcol = "w")
rec("pw_REML2", y ~ x + (x | g),         SIM, REML = TRUE,  wcol = "w")
rec("pw_ML3",   y ~ x + z + (x + z | g), SIM, REML = FALSE, wcol = "w")
rec("pw_REML3", y ~ x + z + (x + z | g), SIM, REML = TRUE,  wcol = "w")
rec("pw_sleep_ml", Reaction ~ Days + (Days | Subject), SL, REML = FALSE, wcol = "w")
rec("pw_small_reml", y ~ x + (1 | g), SM, REML = TRUE, wcol = "w")
rec("pw5_ml", Reaction ~ Days + (Days | Subject), S, REML = FALSE, wcol = "w5")
rec("off_none", y ~ x + (1 | block), OFF)
rec("off_3x",   y ~ x + (1 | block) + offset(3 * x), OFF)
rec("sleep_off", Reaction ~ Days + (Days | Subject) + offset(0.5 * Days), SL)

cat("my %EXPECT = (\n")
for (k in names(EXP)) {
  e <- EXP[[k]]
  cat(sprintf("  %s => {\n", k))
  for (f in names(e)) cat(sprintf("    %s => %s,\n", f,
      if (is.character(e[[f]])) str_(e[[f]]) else if (length(e[[f]]) == 1 && f %in% c("sigma", "crit", "loglik", "pkg_crit")) fmt1(e[[f]]) else num(e[[f]])))
  cat("  },\n")
}
cat(");\n")
