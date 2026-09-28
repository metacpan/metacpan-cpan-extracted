# Generator for the frozen expected values in t/svyglm.R.t.
#
# Re-run with
#
#     Rscript t/svyglm.R.R > /tmp/svyglm.pl
#
# and paste the printed %EXPECT block over the one in the .t file.  It also
# writes t/apistrat.csv, t/apiclus1.csv, t/apiclus2.csv and t/survey_fpc.csv
# from survey's own data sets.  The test itself never runs this script, or R.
#
# Produced with R 4.6.1 and survey 4.5.  The designs and models are survey's
# own examples and tests, named above each.

suppressMessages(library(survey))
options(digits = 17)

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")
str_ <- function(x) paste0("[", paste0("'", x, "'", collapse = ", "), "]")

data(api)
data(fpc)
keep <- c("snum", "dnum", "stype", "pw", "fpc", "api00", "api99", "ell", "meals", "mobility",
          "enroll", "api.stu", "acs.k3", "comp.imp", "sch.wide")
S <- apistrat[, keep]; S$stype <- as.character(S$stype); S$comp.imp <- as.character(S$comp.imp)
S$sch.wide <- as.numeric(S$sch.wide == "Yes")
C1 <- apiclus1[, keep]; C1$stype <- as.character(C1$stype); C1$comp.imp <- as.character(C1$comp.imp)
C1$sch.wide <- as.numeric(C1$sch.wide == "Yes")
C2 <- apiclus2[, c("snum", "dnum", "pw", "api00", "ell", "meals", "mobility")]
F <- fpc; F$gt4 <- ifelse(F$x > 4, "TRUE", "FALSE")
write.csv(S, "t/apistrat.csv", row.names = FALSE)
write.csv(C1, "t/apiclus1.csv", row.names = FALSE)
write.csv(C2, "t/apiclus2.csv", row.names = FALSE)
write.csv(F, "t/survey_fpc.csv", row.names = FALSE)
S <- read.csv("t/apistrat.csv"); C1 <- read.csv("t/apiclus1.csv")
C2 <- read.csv("t/apiclus2.csv"); F <- read.csv("t/survey_fpc.csv")

dstrat <- svydesign(id = ~1, strata = ~stype, weights = ~pw, data = S, fpc = ~fpc)
dstrat_nofpc <- svydesign(id = ~1, strata = ~stype, weights = ~pw, data = S)
dclus1 <- svydesign(id = ~dnum, weights = ~pw, data = C1, fpc = ~fpc)
dclus2 <- svydesign(id = ~dnum + snum, weights = ~pw, data = C2)
dfpc <- svydesign(id = ~psuid, strat = ~stratid, weight = ~weight, data = F, nest = TRUE)
dstrat_nest <- svydesign(id = ~dnum, strata = ~stype, weights = ~pw, data = S, nest = TRUE)

EXP <- list()
rec <- function(key, m) {
  s <- summary(m)
  ct <- coef(s)
  EXP[[key]] <<- list(names = sub("^\\(Intercept\\)$", "Intercept", rownames(ct)),
                      coef = unname(ct[, 1]), se = unname(ct[, 2]), t = unname(ct[, 3]),
                      p = unname(ct[, 4]), df = m$df.residual, dispersion = unname(s$dispersion[1]),
                      deviance = deviance(m),
                      ci = as.vector(t(confint(m))))
}
## man/svyglm.Rd
rec("strat_api00", svyglm(api00 ~ ell + meals + mobility, design = dstrat))
rec("clus2_api00", svyglm(api00 ~ ell + meals + mobility, design = dclus2))
rec("strat_schwide", svyglm(sch.wide ~ ell + meals + mobility, design = dstrat, family = quasibinomial()))
rec("strat_apistu", svyglm(api.stu ~ enroll, design = dstrat))
## tests/domain.R
rec("fpc_domain", svyglm(x ~ gt4 + 0, design = dfpc))
rec("strat_domain", svyglm(enroll ~ comp.imp - 1, design = dstrat))
## man/svydesign.Rd's one-stage cluster sample, with its fpc
rec("clus1_api00", svyglm(api00 ~ ell + meals + mobility, design = dclus1))
rec("clus1_poisson", svyglm(api.stu ~ ell + meals, design = dclus1, family = quasipoisson()))
## no fpc; nested PSUs; and a covariate with missing values, whose rows the
## model drops while their PSUs stay in the design
rec("strat_nofpc", svyglm(api00 ~ ell + meals + mobility, design = dstrat_nofpc))
rec("strat_nest", svyglm(api00 ~ ell + meals, design = dstrat_nest))
rec("strat_missing", svyglm(api00 ~ acs.k3 + ell, design = dstrat))
rec("strat_factor", svyglm(api00 ~ stype + ell, design = dstrat))

cat("my %EXPECT = (\n")
for (k in names(EXP)) {
  e <- EXP[[k]]
  cat(sprintf("  %s => {\n", k))
  for (f in names(e)) cat(sprintf("    %s => %s,\n", f,
      if (is.character(e[[f]])) str_(e[[f]]) else if (length(e[[f]]) == 1 && f %in% c("df", "dispersion", "deviance")) fmt1(e[[f]]) else num(e[[f]])))
  cat("  },\n")
}
cat(");\n")
