# Generator for the frozen expected values in t/glm_vcov.R.t.
#
# Re-run with
#
#     Rscript t/glm_vcov.R.R > /tmp/glm_vcov.pl
#
# and paste the printed %DATA and %EXPECT blocks over the ones in the .t file.  The test
# itself never runs this script, or R.
#
# Produced with R 4.6.1 and sandwich 3.1-3.  It also (re)writes
# t/PetersenCL.csv from sandwich's own PetersenCL data set, and then fits
# everything on the CSV as read back, so the frozen values belong to exactly
# the numbers the test reads rather than to the unrounded originals.

suppressMessages(library(sandwich))
options(digits = 17)

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")

EXP <- list()
rec <- function(key, fit, V) {
  cf <- coef(fit)
  nm <- sub("^\\(Intercept\\)$", "Intercept", names(cf))
  EXP[[key]] <<- list(names = nm, coef = unname(cf), vcov = as.vector(V))
}

## sandwich tests/vcovCL.R -- Petersen's simulated firm/year panel, the linear
## model (fitted here as a gaussian glm, which sandwich treats identically:
## estfun.glm and bread.glm reduce to estfun.lm and bread.lm) and the logit on
## (y > 0), one-way by firm and two-way by firm and year.
data("PetersenCL", package = "sandwich")
write.csv(PetersenCL, "t/PetersenCL.csv", row.names = FALSE)
P <- read.csv("t/PetersenCL.csv")
P$yb <- as.numeric(P$y > 0)
m <- glm(y ~ x, data = P)
b <- glm(yb ~ x, data = P, family = binomial)
for (tp in c("HC0", "HC1")) {
  rec(paste0("pet_m_firm_", tp), m, vcovCL(m, cluster = ~ firm, type = tp))
  rec(paste0("pet_m_fy_", tp),   m, vcovCL(m, cluster = ~ firm + year, type = tp))
  rec(paste0("pet_b_firm_", tp), b, vcovCL(b, cluster = ~ firm, type = tp))
  rec(paste0("pet_b_fy_", tp),   b, vcovCL(b, cluster = ~ firm + year, type = tp))
}
for (tp in c("HC0", "HC1", "HC2", "HC3")) {
  rec(paste0("pet_m_", tp), m, vcovHC(m, type = tp))
  rec(paste0("pet_b_", tp), b, vcovHC(b, type = tp))
}

## sandwich man/vcovOPG.Rd example, whose output is pinned in
## tests/Examples/sandwich-Ex.Rout.save; R CMD check runs each example after
## set.seed(1), which is what reproduces it.
set.seed(1)
x <- sin(1:100)
y <- rpois(100, exp(1 + x))
opg <- data.frame(x = x, y = y)
fm <- glm(y ~ x, family = poisson, data = opg)
rec("opg_model", fm, vcov(fm))
for (tp in c("HC0", "HC1", "HC2", "HC3")) rec(paste0("opg_", tp), fm, vcovHC(fm, type = tp))

## statsmodels' discrete/tests/results/ships.csv -- the corpus of its
## TestPoissonClu* classes -- fitted by R too, so that the Stata figures
## the .t file also carries have an exact counterpart.
ships <- data.frame(
  ship = c(1,1,1,1,1,1,1,2,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,4,4,4,5,5,5,5,5,5),
  yr_con = c(1,1,2,2,3,3,4,1,1,2,2,3,3,4,1,1,2,2,3,3,4,1,1,2,2,3,3,4,1,2,2,3,3,4),
  service = c(127,63,1095,1095,1512,3353,2244,44882,17176,28609,20370,7064,13099,
              7117,1179,552,781,676,783,1948,274,251,105,288,192,349,1208,2051,45,
              789,437,1157,2161,542),
  accident = c(0,0,3,4,6,18,11,39,29,58,53,12,44,18,1,1,0,1,6,2,1,0,0,0,0,2,11,4,
               0,7,7,5,12,1),
  op_75_79 = c(0,1,0,1,0,1,1,0,1,0,1,0,1,1,0,1,0,1,0,1,1,0,1,0,1,0,1,1,0,0,1,0,1,1))
sp <- glm(accident ~ yr_con + op_75_79, family = poisson, data = ships)
se <- glm(accident ~ yr_con + op_75_79 + offset(log(service)), family = poisson, data = ships)
rec("ships_clu_HC1", sp, vcovCL(sp, cluster = ~ ship, type = "HC1"))
rec("ships_HC0",     sp, vcovHC(sp, type = "HC0"))
rec("ships_exp_model",   se, vcov(se))
rec("ships_exp_HC0",     se, vcovHC(se, type = "HC0"))
rec("ships_exp_clu_HC1", se, vcovCL(se, cluster = ~ ship, type = "HC1"))

## Zou (2004), Am J Epidemiol 159:702 -- the "modified Poisson" risk ratio: a
## poisson fit to a 0/1 outcome with sandwich standard errors.  On R's own
## infert data (datasets, ?infert), the case indicator on the two abortion
## counts.
ip <- glm(case ~ spontaneous + induced, family = poisson, data = infert)
rec("infert_HC0", ip, vcovHC(ip, type = "HC0"))
rec("infert_clu_HC0", ip, vcovCL(ip, cluster = ~ stratum, type = "HC0"))

cat("my %DATA = (\n")
cat(sprintf("  opg => { x => %s,\n          y => %s },\n", num(opg$x), num(opg$y)))
cat(sprintf("  infert => { case => %s,\n    spontaneous => %s,\n    induced => %s,\n    stratum => %s },\n",
            num(infert$case), num(infert$spontaneous), num(infert$induced), num(infert$stratum)))
cat(");\n\n")
cat("my %EXPECT = (\n")
for (k in names(EXP)) {
  e <- EXP[[k]]
  cat(sprintf("  %s => {\n", k))
  cat(sprintf("    names => [%s],\n", paste0("'", e$names, "'", collapse = ", ")))
  cat(sprintf("    coef  => %s,\n", num(e$coef)))
  cat(sprintf("    vcov  => %s,\n", num(e$vcov)))
  cat("  },\n")
}
cat(");\n")
