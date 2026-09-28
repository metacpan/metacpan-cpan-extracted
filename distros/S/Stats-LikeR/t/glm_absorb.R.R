# Generator for the frozen expected values in t/glm_absorb.R.t.
#
# Re-run with
#
#     Rscript t/glm_absorb.R.R > /tmp/glm_absorb.pl
#
# and paste the printed %DATA and %EXPECT blocks over the ones in the .t file;
# it also rewrites t/base_did.csv.  The test itself never runs this script, or
# R.
#
# Produced with R 4.6.1, MASS 7.3-66, sandwich 3.1-3 and fixest 0.14.2.  The
# corpus and the loop over it are fixest's own, tests/fixest_tests.R, section
# "ESTIMATION": iris renamed, the same derived columns built after the same
# set.seed(0), and every model family crossed with weights, an offset and the
# fixed-effect specifications LikeR can express (fixest's id_fe 0, 1, 2 and 7;
# 3 to 6, 8 and 9 are varying slopes, which absorb => does not do).  fixest
# checks feglm() against glm() with the factors as dummies, at 1e-5; the
# reference here is the same glm() fit, taken at full precision.

suppressMessages({library(MASS); library(sandwich); library(fixest)})
options(digits = 17)

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")
str_ <- function(x) paste0("[", paste0("'", x, "'", collapse = ", "), "]")

## fixest_tests.R, lines 36-54, verbatim but for the combined factor
set.seed(0)
base = iris
names(base) = c("y", "x1", "x2", "x3", "species")
base$fe_2 = rep(1:5, 30)
base$fe_3 = sample(15, 150, TRUE)
base$constant = 5
base$y_int = as.integer(base$y)
base$w = as.vector(unclass(base$species) - 0.95)
base$offset_value = unclass(base$species) - 0.95
base$y_01 = 1 * ((scale(base$x1) + rnorm(150)) > 0)
base$y_01[1:5 + rep(c(0, 50, 100), each = 5)] = 1
base$y_01[6:10 + rep(c(0, 50, 100), each = 5)] = 0
base$y_int_null = base$y_int
base$y_int_null[base$fe_3 %in% 1:5] = 0
## species^fe_2, fixest's combined factor, as a column of its own
base$sp_fe2 = paste(base$species, base$fe_2)
base$species = as.character(base$species)
base$fe_2 = paste0("f", base$fe_2)
base$y_01 = as.vector(base$y_01)

cat("my %DATA = (\n  base => {\n")
for (nm in c("y", "x1", "x2", "y_int", "y_int_null", "y_01", "w", "offset_value"))
  cat(sprintf("    %s => %s,\n", nm, num(base[[nm]])))
for (nm in c("species", "fe_2", "sp_fe2")) cat(sprintf("    %s => %s,\n", nm, str_(base[[nm]])))
cat("  },\n);\n\n")

EXP <- list()
rec <- function(key, fit, keep, extra = list(), V = vcov(fit)) {
  cf <- coef(fit)[keep]
  EXP[[key]] <<- c(list(names = keep, coef = unname(cf),
                        se = unname(sqrt(diag(V))[keep]),
                        deviance = deviance(fit), df = fit$df.residual,
                        loglik = as.numeric(logLik(fit))), extra)
}

for (model in c("ols", "pois", "logit", "negbin")) {
  for (use_weights in c(FALSE, TRUE)) for (use_offset in c(FALSE, TRUE)) for (id_fe in c(0, 1, 2, 7)) {
    if (model == "negbin" && (use_weights || use_offset || id_fe > 2)) next
    resp <- switch(model, ols = "y", pois = "y_int_null", logit = "y_01", negbin = "y_int")
    rhs <- switch(as.character(id_fe), "0" = "x1", "1" = "x1 + factor(species)",
                  "2" = "x1 + factor(species) + factor(fe_2)", "7" = "x1 + x2 + factor(sp_fe2)")
    keep <- if (id_fe == 7) c("x1", "x2") else "x1"
    f <- as.formula(paste(resp, "~", rhs))
    base$ww <- if (use_weights) base$w else rep(1, 150)
    base$oo <- if (use_offset) base$offset_value else rep(0, 150)
    key <- sprintf("%s_w%d_o%d_fe%d", model, use_weights, use_offset, id_fe)
    if (model == "ols") {
      fit <- glm(f, data = base, weights = ww, offset = oo)
    } else if (model == "pois") {
      fit <- glm(f, data = base, weights = ww, offset = oo, family = poisson)
    } else if (model == "logit") {
      fit <- glm(f, data = base, weights = ww, offset = oo, family = binomial)
    } else {
      fit <- glm.nb(f, data = base)
    }
    extra <- list(resp = resp, id_fe = id_fe, weights = use_weights, offset = use_offset, model = model)
    if (model == "negbin") extra$theta <- fit$theta
    if (id_fe > 0) extra$cl <- list(names = keep,
                                    se = unname(sqrt(diag(vcovCL(fit, cluster = ~ species, type = "HC0")))[keep]))
    rec(key, fit, keep, extra)
  }
}

## the fixest estimates themselves, where feglm() and glm() fit the same model
fx <- list(
  pois_fe1  = fepois(y_int_null ~ x1 | species, base),
  pois_fe2  = fepois(y_int_null ~ x1 | species + fe_2, base),
  logit_fe1 = feglm(y_01 ~ x1 | species, base, family = binomial),
  ols_fe2   = feols(y ~ x1 | species + fe_2, base))
FX <- lapply(fx, function(m) list(coef = unname(coef(m)["x1"])))

## fixest_tests.R, "obs removal": base_did with the first ten ids' outcomes
## set to zero, fixef.rm = "infinite" -- which removes exactly the
## observations whose fixed effect is minus infinity, as absorb => does.
## (The test's singleton periods come from runif() and test fixef.rm =
## "singletons", which absorb => does not do.)
data(base_did, package = "fixest")
base_rm = base_did
base_rm$y = abs(base_rm$y)
is_only_0 = base_rm$id <= 10
base_rm$y[is_only_0] = 0
write.csv(base_rm[, c("y", "x1", "id", "period")], "t/base_did.csv", row.names = FALSE)
B <- read.csv("t/base_did.csv")
est_inf = fepois(y ~ x1 | id + period, B, fixef.rm = "infinite")
Bk <- B[B$id > 10, ]
gd <- suppressWarnings(glm(y ~ x1 + factor(id) + factor(period), family = poisson, data = Bk))
DID <- list(nobs = nobs(est_inf), removed = sum(B$id <= 10),
            fixest = unname(coef(est_inf)["x1"]), glm = unname(coef(gd)["x1"]),
            glm_se = unname(sqrt(diag(vcov(gd)))["x1"]), deviance = deviance(gd),
            df = gd$df.residual)

cat("my %EXPECT = (\n")
for (k in names(EXP)) {
  e <- EXP[[k]]
  cat(sprintf("  %s => {\n", k))
  for (f in names(e)) {
    v <- e[[f]]
    if (is.list(v)) cat(sprintf("    %s => { names => %s, se => %s },\n", f, str_(v$names), num(v$se)))
    else if (is.character(v)) cat(sprintf("    %s => %s,\n", f, if (length(v) > 1 || f == "names") str_(v) else paste0("'", v, "'")))
    else if (is.logical(v)) cat(sprintf("    %s => %d,\n", f, as.integer(v)))
    else if (f %in% c("coef", "se")) cat(sprintf("    %s => %s,\n", f, num(v)))
    else cat(sprintf("    %s => %s,\n", f, fmt1(v)))
  }
  cat("  },\n")
}
cat(");\n\n")
cat("my %FIXEST = (\n")
for (k in names(FX)) cat(sprintf("  %s => %s,\n", k, fmt1(FX[[k]]$coef)))
cat(");\n\n")
cat("my %DID = (\n")
for (k in names(DID)) cat(sprintf("  %s => %s,\n", k, fmt1(DID[[k]])))
cat(");\n")
