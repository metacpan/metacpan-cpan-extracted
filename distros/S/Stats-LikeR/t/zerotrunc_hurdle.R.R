# Generator for the frozen expected values in t/zerotrunc_hurdle.R.t.
#
# Re-run with
#
#     Rscript t/zerotrunc_hurdle.R.R > /tmp/zt.pl
#
# and paste the printed %PKG block over the one in the .t file.  It also
# rewrites t/CrabSatellites.csv, t/docvis.csv and t/bioChemists.csv, which
# t/zerotrunc_hurdle.mpmath.py then reads; run that second.  The test itself
# never runs either script, or R, or python.
#
# Produced with R 4.6.1, countreg 0.3-0 (R-Forge) and pscl 1.5.9.  Each model
# is fitted by the package itself with its default control --
# optim(method = "BFGS"), standard errors from optim()'s finite-difference
# Hessian -- which is what a user of countreg or pscl sees.  The exact
# optimum those approximate comes from the mpmath script.

suppressMessages({library(countreg); library(pscl)})
options(digits = 17)

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  if (is.infinite(v)) return(if (v > 0) "9**9**9" else "-9**9**9")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")
str_ <- function(x) paste0("[", paste0("'", x, "'", collapse = ", "), "]")

EXP <- list()
add <- function(key, ...) EXP[[key]] <<- list(...)

## ---------------------------------------------------------------- CrabSatellites
## countreg inst/tinytest/test_zerotrunc.R: color as a number, the positive
## counts only; and test_hurdle.R: the whole data, color as the ordered
## factor it is.
data("CrabSatellites", package = "countreg")
cs <- CrabSatellites[, c("satellites", "width", "color")]
cs$colorn <- as.numeric(cs$color)
cs$color <- as.character(cs$color)
write.csv(cs, "t/CrabSatellites.csv", row.names = FALSE)
cs <- read.csv("t/CrabSatellites.csv")
pos <- subset(cs, satellites > 0)
for (d in c("poisson", "negbin", "geometric")) {
  m <- zerotrunc(satellites ~ width + colorn, data = pos, dist = d)
  add(paste0("crab_zt_", d),
      coef = unname(coef(m)), se = unname(sqrt(diag(vcov(m)))),
      ll = as.numeric(logLik(m)), theta = if (d == "negbin") m$theta else NA,
      sel = if (d == "negbin") m$SE.logtheta else NA)
}
## the hurdles: countreg's binomial-logit/poisson and negbin-negbin references,
## plus every count distribution under a logit hurdle
for (cd in c("poisson", "negbin", "geometric")) for (zd in c("binomial", "poisson", "geometric", "negbin")) {
  h <- hurdle(satellites ~ width + colorn | width + colorn, data = cs, dist = cd, zero.dist = zd)
  add(sprintf("crab_h_%s_%s", cd, zd),
      count = unname(coef(h, "count")), zero = unname(coef(h, "zero")),
      ll = as.numeric(logLik(h)))
}

## ---------------------------------------------------------------- docvis
## statsmodels' sandbox/regression/tests/racd10data_with_transformed.csv, as
## its test_gmm_poisson.get_data() filters it (neither both private and
## medicaid, docvis <= 70) -- the corpus of discrete/tests/test_truncated_model.py.
dt <- read.csv(file.path("/home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages",
                         "statsmodels/sandbox/regression/tests/racd10data_with_transformed.csv"))
dt <- dt[!(dt$private == 1 & dt$medicaid == 1) & dt$docvis <= 70, c("docvis", "aget", "totchr")]
write.csv(dt, "t/docvis.csv", row.names = FALSE)
dt <- read.csv("t/docvis.csv")
dp <- subset(dt, docvis > 0)
for (d in c("poisson", "negbin")) {
  m <- zerotrunc(docvis ~ aget + totchr, data = dp, dist = d)
  add(paste0("docvis_zt_", d), coef = unname(coef(m)), ll = as.numeric(logLik(m)))
}

## ---------------------------------------------------------------- bioChemists
## pscl's own ?hurdle example: hurdle(art ~ ., data = bioChemists, dist = "negbin").
data("bioChemists", package = "pscl")
bc <- bioChemists
bc$fem <- as.character(bc$fem); bc$mar <- as.character(bc$mar)
write.csv(bc, "t/bioChemists.csv", row.names = FALSE)
bc <- read.csv("t/bioChemists.csv")
h <- hurdle(art ~ ., data = bc, dist = "negbin")
add("bio_h_negbin", count = unname(coef(h, "count")), zero = unname(coef(h, "zero")),
    ll = as.numeric(logLik(h)), theta = unname(h$theta))
## and with an offset and weights, which pscl passes to both halves' glm.fit
## starts and to the count likelihood (offset) and both likelihoods (weights)
set.seed(5)
bc$expo <- round(runif(nrow(bc), 0.5, 2), 2); bc$wt <- sample(1:3, nrow(bc), TRUE)
write.csv(bc, "t/bioChemists.csv", row.names = FALSE)
bc <- read.csv("t/bioChemists.csv")
h <- hurdle(art ~ fem + mar + kid5 + phd + ment | fem + kid5, data = bc, dist = "poisson",
            offset = log(expo), weights = wt)
add("bio_h_off_w", count = unname(coef(h, "count")), zero = unname(coef(h, "zero")),
    ll = as.numeric(logLik(h)))

cat("my %PKG = (\n")
for (k in names(EXP)) {
  e <- EXP[[k]]
  cat(sprintf("  %s => {\n", k))
  for (f in names(e)) {
    v <- e[[f]]
    if (is.character(v)) cat(sprintf("    %s => %s,\n", f, str_(v)))
    else if (length(v) == 1 && !grepl("^(coef|count|zero|se)$", f)) cat(sprintf("    %s => %s,\n", f, fmt1(v)))
    else cat(sprintf("    %s => %s,\n", f, num(v)))
  }
  cat("  },\n")
}
cat(");\n")
