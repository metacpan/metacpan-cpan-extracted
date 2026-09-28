# Generator for the frozen expected values in t/ivreg.R.t.
#
# Re-run with
#
#     Rscript t/ivreg.R.R > /tmp/ivreg.pl
#
# and paste the printed %EXPECT block over the one in the .t file.  It also
# writes t/Kmenta.csv, t/CigaretteDemand.csv, t/CigarettesSW.csv and
# t/SchoolingReturns.csv, and converts statsmodels' griliches76.dta to
# t/griliches76.csv.  The test itself never runs this script, or R.
#
# Produced with R 4.6.1, ivreg 0.6-8 and sandwich 3.1-3 (AER's CigarettesSW
# data only; AER itself is not attached, since it masks ivreg's methods).

suppressMessages({library(ivreg); library(sandwich)})
options(digits = 17)

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")
str_ <- function(x) paste0("[", paste0("'", x, "'", collapse = ", "), "]")

data("Kmenta", package = "ivreg"); data("CigaretteDemand", package = "ivreg")
data("SchoolingReturns", package = "ivreg"); data("CigarettesSW", package = "AER")
write.csv(Kmenta, "t/Kmenta.csv", row.names = FALSE)
write.csv(CigaretteDemand, "t/CigaretteDemand.csv", row.names = FALSE)
SR <- SchoolingReturns[, c("wage", "education", "experience", "ethnicity", "smsa", "south",
                           "age", "nearcollege")]
for (v in c("ethnicity", "smsa", "south", "nearcollege")) SR[[v]] <- as.character(SR[[v]])
write.csv(SR, "t/SchoolingReturns.csv", row.names = FALSE)
## AER's ?CigarettesSW: the real price, per-capita real income, and the two
## tax instruments, both years
CS <- CigarettesSW
CS <- data.frame(state = as.character(CS$state), year = paste0("y", CS$year), packs = CS$packs,
                 rprice = CS$price / CS$cpi, rincome = CS$income / CS$population / CS$cpi,
                 tdiff = (CS$taxs - CS$tax) / CS$cpi, rtax = CS$tax / CS$cpi)
write.csv(CS, "t/CigarettesSW.csv", row.names = FALSE)
G <- foreign::read.dta(file.path("/home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages",
                                 "statsmodels/sandbox/regression/tests/griliches76.dta"))
## the year as a factor, with a letter so that it reads back as one
G$year <- paste0("y", G$year)
write.csv(G[, c("lw", "s", "iq", "expr", "tenure", "rns", "smsa", "year", "med", "kww", "age", "mrt")],
          "t/griliches76.csv", row.names = FALSE)
K <- read.csv("t/Kmenta.csv"); CD <- read.csv("t/CigaretteDemand.csv")
SR <- read.csv("t/SchoolingReturns.csv"); CS <- read.csv("t/CigarettesSW.csv")
G <- read.csv("t/griliches76.csv")

EXP <- list()
rec <- function(key, m, vc = NULL) {
  s <- if (is.null(vc)) summary(m) else summary(m, vcov. = vc)
  ct <- coef(s)
  d <- s$diagnostics
  e <- list(names = sub("^\\(Intercept\\)$", "Intercept", rownames(ct)),
            coef = unname(ct[, 1]), se = unname(ct[, 2]), t = unname(ct[, 3]), p = unname(ct[, 4]),
            sigma = m$sigma, df = m$df.residual, r2 = s$r.squared, adj = s$adj.r.squared,
            wald = unname(s$waldtest[1]), wald_p = unname(s$waldtest[2]),
            ci = as.vector(t(if (is.null(vc)) confint(m) else confint(m, vcov. = vc))))
  if (!is.null(d)) {
    e$diag_rows <- rownames(d)
    e$diag_df1 <- unname(d[, 1]); e$diag_df2 <- unname(d[, 2])
    e$diag_stat <- unname(d[, 3]); e$diag_p <- unname(d[, 4])
  }
  EXP[[key]] <<- e
}

## ivreg tests/testthat/test-ivreg.R
rec("kmenta", ivreg(Q ~ P + D | D + F + A, data = K))
rec("kmenta_hc0", ivreg(Q ~ P + D | D + F + A, data = K), function(o, ...) vcovHC(o, type = "HC0"))
## ivreg man/summary.ivreg.Rd: the three-part formula, and HC1 through a
## function so the diagnostics are robust too
m <- ivreg(log(packs) ~ log(rincome) | log(rprice) | salestax, data = CD)
rec("cig", m)
rec("cig_hc1", m, function(o, ...) vcovHC(o, type = "HC1"))
rec("cig_two", ivreg(log(packs) ~ log(rprice) + log(rincome) | salestax + cigtax + log(rincome), data = CD))
## ivreg man/ivreg.Rd, SchoolingReturns: experience as a raw quadratic in
## place of poly(), which this module's formulas do not have
rec("school", ivreg(log(wage) ~ education + experience + I(experience^2) + ethnicity + smsa + south |
                      nearcollege + age + I(age^2) + ethnicity + smsa + south, data = SR))
## AER ?CigarettesSW / ?ivreg: 1995 alone, and both years clustered by state
C95 <- subset(CS, year == "y1995")
rec("cigsw95", ivreg(log(packs) ~ log(rprice) + log(rincome) | log(rincome) + tdiff + rtax, data = C95))
mcs <- ivreg(log(packs) ~ log(rprice) + log(rincome) + year | log(rincome) + year + tdiff + rtax, data = CS)
rec("cigsw_cluster", mcs, function(o, ...) vcovCL(o, cluster = CS$state, type = "HC0"))
rec("cigsw_cluster1", mcs, function(o, ...) vcovCL(o, cluster = CS$state, type = "HC1"))
## weights
CDw <- CD; CDw$w <- seq(0.5, 2, length.out = nrow(CD))
write.csv(CDw, "t/CigaretteDemand.csv", row.names = FALSE)
CDw <- read.csv("t/CigaretteDemand.csv")
rec("cig_weighted", ivreg(log(packs) ~ log(rincome) | log(rprice) | salestax, data = CDw, weights = w))
## statsmodels' TestIV2SLSSt1 corpus (Stata ivreg2 results in .t)
rec("griliches", ivreg(lw ~ s + iq + expr + tenure + rns + smsa + year |
                         expr + tenure + rns + smsa + year + med + kww + age + mrt, data = G))

cat("my %EXPECT = (\n")
for (k in names(EXP)) {
  e <- EXP[[k]]
  cat(sprintf("  %s => {\n", k))
  for (f in names(e)) cat(sprintf("    %s => %s,\n", f,
      if (is.character(e[[f]])) str_(e[[f]]) else if (length(e[[f]]) == 1 && f %in% c("sigma", "df", "r2", "adj", "wald", "wald_p")) fmt1(e[[f]]) else num(e[[f]])))
  cat("  },\n")
}
cat(");\n")
