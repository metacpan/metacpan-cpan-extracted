# Generator for the frozen expected values in t/glmer.binomial.R.t,
# t/glmer.poisson.R.t, t/glmer.negbin.R.t and t/glmer.negbin_epil.R.t.
#
# Re-run from the distribution root with
#
#     Rscript t/glmer.R.R > /tmp/glmer.pl
#
# and paste each printed %EXPECT block (each follows a "## ---- t/<file>" line)
# over the one in that file.  It also
# writes the data the models are fitted to, t/glmer.*.csv (t/lme4.offset.sim.csv
# comes from t/lmer.offset.weights.R.R).  The test itself never runs this
# script, or R.
#
# Produced with R 4.6.1, lme4 2.0-6, MASS 7.3-66 and numDeriv 2016.8-1.1.  The
# models are lme4's own examples and tests (its source tarball,
# /home/con/Scripts/r-pkg-sources/lme4):
#
#   cbpp_*        man/glmer.Rd: incidence/size ~ period + (1 | herd), binomial
#                 with the herd sizes as weights, by the Laplace approximation
#                 (gm1), nAGQ = 0 (gm1a) and nAGQ = 9; and gm2, with an
#                 observation-level (1 | obs) as well.
#   gsim_*        tests/glmmWeights.R: lme4's gSim() (inst/testdata/
#                 lme-tst-funs.R) under set.seed(101), Bernoulli (g1),
#                 Poisson (g2) and Poisson with every weight 2 (g2W), and the
#                 binomial of 10 trials (g3).
#   off_pois*     tests/offset.R: the Poisson half, y ~ x + (1|block) with and
#                 without offset(3*x).
#   grouse*       man/grouseticks.Rd: TICKS ~ YEAR + HEIGHT + (1|BROOD) +
#                 (1|INDEX) + (1|LOCATION), Poisson (its full_mod1, with HEIGHT
#                 centered and scaled as lme4's tests do), and the same with
#                 (1|BROOD) alone.
#   epil_*        tests/nbinom.R: MASS's epil, y ~ Base*trt + Age + Visit +
#                 (Visit|subject), Poisson and negative binomial (its g4,
#                 run there only at testLevel > 2; glmmADMB's values in that
#                 file are theta 7.4702 and logLik -624.551).
#   nb_rd         man/glmer.nb.Rd: y ~ f1*f2 + (1|g) on its set.seed(101) data.
#   nb_ref        tests/test-glmernbref.R: y ~ x + (1|f), set.seed(101).
#   nb_fixed      nb_ref's model with the negative-binomial theta fixed at 2
#                 (glmer(family = negative.binomial(2))).
#
# Every model is fitted twice.  Once with lme4's defaults, which is what a user
# of lme4 sees (pkg_*); its PIRLS stops at a relative change of 1e-7 in the
# penalized deviance (tolPwrss), which leaves cbpp's log-likelihood 2.8e-4 below
# the optimum and its standard errors 0.5% out.  And once tightly, as the
# reference: tolPwrss = 1e-13, and lme4's own deviance function minimized by
# nlminb() at its tightest tolerances and Nelder-Mead in turn until neither
# improves, then ten restarts near the best point.
# The standard errors are lme4's vcov.merMod() formula, 2 H^-1 for the Hessian
# H of that deviance function in (theta, beta), with H taken by numDeriv's
# Richardson extrapolation rather than lme4's deriv12() central differences.
#
# "That deviance function" is lme4's, made exact by exactify() below: lme4
# factors L with the working weights of the step before the mode, which on
# grouseticks leaves log|L|^2 1.1e-5 high however small tolPwrss is made (it
# fails below 1e-13); one more call of its native routine from the converged
# mode removes that.  Everything the tight fit reports -- the optimum, logLik,
# the Hessian, and glmer.nb's profile over its theta, through refit() -- is on
# the exact deviance; lme4_loglik is what logLik() of the same fit says.
# glmer.nb's theta is optimize()d again, by lme4:::optTheta(), to 1e-10 on the
# log scale rather than glmer.nb()'s default 5e-5.

suppressMessages({library(lme4); library(MASS); library(numDeriv)})
options(digits = 17)

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")
str_ <- function(x) paste0("[", paste0("'", x, "'", collapse = ", "), "]")

## ------------------------------------------------------------------ the data
cb <- cbpp; cb$herd <- paste0("h", cb$herd); cb$period <- paste0("p", cb$period)
cb$prop <- cb$incidence / cb$size; cb$obs <- paste0("o", seq_len(nrow(cb)))
write.csv(cb, "t/glmer.cbpp.csv", row.names = FALSE)

source(system.file("testdata/lme-tst-funs.R", package = "lme4", mustWork = TRUE))
set.seed(101)
invisible(gSim())                                   # g0's Gamma data, drawn and not used
g1d <- gSim(family = binomial(), nbinom = 1)
g2d <- gSim(family = poisson())
g3d <- gSim(family = binomial(), nbinom = 10)
mkg <- function(d) { d <- as.data.frame(d); d$block <- paste0("b", d$block); d }
G1 <- mkg(g1d); G2 <- mkg(g2d); G3 <- mkg(g3d)
G2$w2 <- 2; G3$size <- 10
## gSim()'s Bernoulli y is a factor and its binomial-of-10 y a cbind(succ, fail)
## matrix; written as the 0/1 number and the proportion of 10 trials (with the
## trials as weights), which is the same model to glmer()
G1$y <- as.numeric(as.character(G1$y))
G3$prop <- G3$y[, "succ"] / G3$size; G3$y <- NULL
write.csv(G1, "t/glmer.gsim.bern.csv", row.names = FALSE)
write.csv(G2, "t/glmer.gsim.pois.csv", row.names = FALSE)
write.csv(G3, "t/glmer.gsim.binom10.csv", row.names = FALSE)

gt <- grouseticks
gt <- data.frame(TICKS = gt$TICKS, YEAR = paste0("y", gt$YEAR), cHEIGHT = as.numeric(scale(gt$HEIGHT)),
                 BROOD = paste0("b", gt$BROOD), INDEX = paste0("i", gt$INDEX), LOCATION = paste0("l", gt$LOCATION))
write.csv(gt, "t/glmer.grouseticks.csv", row.names = FALSE)

data(epil, package = "MASS")
ep <- transform(epil, Visit = (period - 2.5) / 5, Base = log(base / 4), Age = log(age))
ep <- data.frame(y = ep$y, Base = ep$Base, trt = as.character(ep$trt), Age = ep$Age, Visit = ep$Visit,
                 subject = paste0("s", ep$subject))
write.csv(ep, "t/glmer.epil.csv", row.names = FALSE)

set.seed(101)
dd <- expand.grid(f1 = factor(1:3), f2 = LETTERS[1:2], g = 1:9, rep = 1:15, KEEP.OUT.ATTRS = FALSE)
mu <- 5 * (-4 + with(dd, as.integer(f1) + 4 * as.numeric(f2)))
dd$y <- rnbinom(nrow(dd), mu = mu, size = 0.5)
NBRD <- data.frame(y = dd$y, f1 = paste0("a", dd$f1), f2 = as.character(dd$f2), g = paste0("g", dd$g))
write.csv(NBRD, "t/glmer.nbrd.csv", row.names = FALSE)

set.seed(101)
dr <- data.frame(x = runif(200), f = rep(1:20, each = 10))
b <- rnorm(20)
dr <- transform(dr, y = rnbinom(200, mu = exp(1 + 2 * x + b[f]), size = 2))
NBREF <- data.frame(y = dr$y, x = dr$x, f = paste0("f", dr$f))
write.csv(NBREF, "t/glmer.nbref.csv", row.names = FALSE)

## read everything back, so that the fits see exactly what the Perl test reads
rd <- function(f) read.csv(file.path("t", f), stringsAsFactors = FALSE)
cb <- rd("glmer.cbpp.csv"); G1 <- rd("glmer.gsim.bern.csv"); G2 <- rd("glmer.gsim.pois.csv")
G3 <- rd("glmer.gsim.binom10.csv"); gt <- rd("glmer.grouseticks.csv"); ep <- rd("glmer.epil.csv")
NBRD <- rd("glmer.nbrd.csv"); NBREF <- rd("glmer.nbref.csv"); OFF <- rd("lme4.offset.sim.csv")

## ------------------------------------------------------------- tight fitting
## lme4's deviance function, made exact.  Its PIRLS (src/external.cpp,
## internal_glmerWrkIter()) updates the working weights, factors L, and only
## then moves the mode, so the log|L|^2 it returns is that of the weights one
## step before the mode; and it stops on a relative change in the penalized
## deviance, which is quadratic in the step, so tolPwrss = 1e-12 still allows a
## last step of about 1e-5 in u.  On grouseticks that left log|L|^2 1.1e-5 high.
## Calling the native routine once more from the converged mode refactors L
## with the weights there and changes nothing else: the result is lme4's
## Laplace (or Gauss-Hermite) deviance as defined, which is what LikeR
## computes.
exactify <- function(fn) {
  r <- environment(fn)
  agq <- !is.null(r$fac) && NROW(r$GQmat) > 1
  nt <- length(r$pp$theta)
  function(p) {
    d <- fn(p)
    if (!is.finite(d)) return(d)
    if (agq) .Call(lme4:::glmerAGQ, r$pp$ptr(), r$resp$ptr(), 1e-13, 100L, r$GQmat, r$fac, 0L)
    else .Call(lme4:::glmerLaplace, r$pp$ptr(), r$resp$ptr(), as.integer(length(p) > nt), 1e-13, 100L, 0L)
  }
}
tightopt <- function(par, fn, lower, upper, control, ...) {
  fn <- exactify(fn)
  ctl <- list(eval.max = 1e5, iter.max = 1e5, rel.tol = 1e-15, x.tol = 1e-15, step.min = 1e-12)
  nl <- function(p) { o <- nlminb(p, fn, lower = lower, upper = upper, control = ctl); list(par = o$par, f = o$objective) }
  best <- nl(par)
  ## nlminb() and Nelder-Mead in turn until neither improves: on epil's Poisson
  ## fit one pass of each stopped 4e-5 short in the log-likelihood
  for (pass in 1:20) {
    f0 <- best$f
    if (length(par) > 1) {
      o2 <- suppressWarnings(optim(best$par, fn, method = "Nelder-Mead", control = list(reltol = 1e-16, maxit = 1e5)))
      if (all(o2$par >= lower) && o2$value < best$f) best <- list(par = o2$par, f = o2$value)
    }
    o3 <- nl(best$par)
    if (o3$f < best$f) best <- o3
    if (f0 - best$f <= 1e-13 * abs(best$f)) break
  }
  ## and ten restarts near the best point, which have never found a better
  ## one on these models but would show a second minimum
  set.seed(20261122)
  for (i in 1:10) {
    st <- pmax(lower, best$par + rnorm(length(par), sd = 0.1 * (abs(best$par) + 0.1)))
    o4 <- tryCatch(nl(st), error = function(e) NULL)
    if (!is.null(o4) && o4$f < best$f - 1e-13 * abs(best$f)) best <- nl(o4$par)
  }
  list(par = best$par, fval = best$f, conv = 0, message = "")
}
## by name: lme4's refit(), which optTheta() calls, compares the optimizer with
## == and cannot when it is a function
tctl <- glmerControl(optimizer = c("tightopt", "tightopt"), tolPwrss = 1e-13, calc.derivs = FALSE)

EXP <- list()
rec <- function(key, fit, pkg, nb = FALSE) {
  th <- unname(getME(fit, "theta")); be <- unname(fixef(fit)); nt <- length(th)
  nagq <- fit@devcomp$dims[["nAGQ"]]
  ef <- exactify(update(fit, devFunOnly = TRUE))
  ll <- if (nagq > 0) -ef(c(th, be)) / 2 else -ef(th) / 2  # nAGQ = 0: the stage 1 deviance, of theta
  if (nagq > 0) {
    H <- numDeriv::hessian(ef, c(th, be))
    Vh <- solve(H); i <- -seq_len(nt)
    V <- Vh[i, i] + t(Vh[i, i])
  } else V <- as.matrix(vcov(fit))
  se <- sqrt(diag(V))
  vc <- as.data.frame(VarCorr(fit))
  e <- list(
    names = sub("^\\(Intercept\\)$", "Intercept", names(fixef(fit))),
    coef = be, se = se, z = be / se, p = 2 * pnorm(-abs(be / se)),
    theta = th, loglik = ll, lme4_loglik = as.numeric(logLik(fit)), df = attr(logLik(fit), "df"),
    vc_grp = vc$grp, vc_var1 = ifelse(is.na(vc$var1), "", vc$var1), vc_var2 = ifelse(is.na(vc$var2), "", vc$var2),
    vc_sdcor = vc$sdcor,
    fitted = unname(fitted(fit))[c(1, 2, length(fitted(fit)))],
    pkg_coef = unname(fixef(pkg)), pkg_se = unname(sqrt(diag(as.matrix(vcov(pkg))))),
    pkg_theta = unname(getME(pkg, "theta")), pkg_loglik = as.numeric(logLik(pkg)))
  if (nb) { e$nb_theta <- getME(fit, "glmer.nb.theta"); e$pkg_nb_theta <- getME(pkg, "glmer.nb.theta") }
  EXP[[key]] <<- e
}
## wcol names the weights column; do.call() puts the values themselves into the
## call, so that update(devFunOnly = TRUE) re-evaluates it anywhere
fitboth <- function(key, formula, data, family = NULL, wcol = NULL, nAGQ = 1L, nb = FALSE) {
  message(key)  # progress, on stderr
  args <- list(formula = formula, data = data)
  if (!is.null(wcol)) args$weights <- data[[wcol]]
  if (nb) {
    pkg <- do.call(glmer.nb, args)
    ## glmer.nb(tol = ) would reach glmer() through its match.call() and be
    ## refused there ("unused argument"), so its theta is refined afterwards by
    ## the function glmer.nb() itself ends with, lme4:::optTheta()
    fit <- do.call(glmer.nb, c(args, list(control = tctl, nb.control = tctl)))
    fit <- lme4:::optTheta(fit, interval = log(getME(fit, "glmer.nb.theta")) + c(-0.5, 0.5),
                           tol = 1e-10, control = tctl)
  } else {
    args$family <- family; args$nAGQ <- nAGQ
    pkg <- do.call(glmer, args)
    fit <- do.call(glmer, c(args, list(control = tctl)))
  }
  rec(key, fit, pkg, nb)
}

fitboth("cbpp_laplace", prop ~ period + (1 | herd), cb, binomial, wcol = "size")
fitboth("cbpp_nagq0",   prop ~ period + (1 | herd), cb, binomial, wcol = "size", nAGQ = 0)
fitboth("cbpp_nagq9",   prop ~ period + (1 | herd), cb, binomial, wcol = "size", nAGQ = 9)
fitboth("cbpp_obs",     prop ~ period + (1 | herd) + (1 | obs), cb, binomial, wcol = "size")
fitboth("gsim_bern",    y ~ x + (1 | block), G1, binomial)
fitboth("gsim_pois",    y ~ x + (1 | block), G2, poisson)
fitboth("gsim_pois_w2", y ~ x + (1 | block), G2, poisson, wcol = "w2")
fitboth("gsim_binom10", prop ~ x + (1 | block), G3, binomial, wcol = "size")
fitboth("off_pois",     ycount ~ x + (1 | block), OFF, poisson)
fitboth("off_pois3x",   ycount ~ x + (1 | block) + offset(3 * x), OFF, poisson)
fitboth("grouse_brood", TICKS ~ YEAR + cHEIGHT + (1 | BROOD), gt, poisson)
fitboth("grouse_full",  TICKS ~ YEAR + cHEIGHT + (1 | BROOD) + (1 | INDEX) + (1 | LOCATION), gt, poisson)
fitboth("epil_pois",    y ~ Base * trt + Age + Visit + (Visit | subject), ep, poisson)
fitboth("epil_nb",      y ~ Base * trt + Age + Visit + (Visit | subject), ep, nb = TRUE)
fitboth("nb_rd",        y ~ f1 * f2 + (1 | g), NBRD, nb = TRUE)
fitboth("nb_ref",       y ~ x + (1 | f), NBREF, nb = TRUE)
fitboth("nb_fixed",     y ~ x + (1 | f), NBREF, MASS::negative.binomial(theta = 2))

## One block per test file, the models split so that no one file is the long
## pole of a parallel run on a __float128 perl (epil's negative binomial alone
## takes 52 s there)
GROUPS <- list(
  binomial = c("cbpp_laplace", "cbpp_nagq0", "cbpp_nagq9", "cbpp_obs", "gsim_bern", "gsim_binom10"),
  poisson = c("gsim_pois", "gsim_pois_w2", "off_pois", "off_pois3x", "grouse_brood", "grouse_full", "epil_pois"),
  negbin = c("nb_rd", "nb_ref", "nb_fixed"),
  negbin_epil = c("epil_nb"))
stopifnot(setequal(unlist(GROUPS), names(EXP)))
for (g in names(GROUPS)) {
cat(sprintf("## ---- t/glmer.%s.R.t\n", g))
cat("my %EXPECT = (\n")
for (k in GROUPS[[g]]) {
  e <- EXP[[k]]
  cat(sprintf("  %s => {\n", k))
  for (f in names(e)) cat(sprintf("    %s => %s,\n", f,
      if (is.character(e[[f]])) str_(e[[f]]) else if (length(e[[f]]) == 1 && !(f %in% c("theta", "pkg_theta", "coef", "se", "z", "p", "pkg_coef", "pkg_se", "vc_sdcor"))) fmt1(e[[f]]) else num(e[[f]])))
  cat("  },\n")
}
cat(");\n")
}
