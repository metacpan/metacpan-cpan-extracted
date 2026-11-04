# Generator for the frozen expected values in t/glm_mu_floor.R.t.
#
# Re-run with
#
#     Rscript t/glm_mu_floor.R.R
#
# and paste the printed block over %EXPECT in the .t file.  The test never
# runs this script, or R.
#
# Produced with R 4.6.1 and MASS 7.3-66.  Each fit prints its coefficients,
# deviance, iteration count and residual degrees of freedom at 17 digits.

suppressMessages(library(MASS))
options(digits = 17)

fmt1 <- function(v) {
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")

emit <- function(name, f) {
  cat(sprintf("\t%s => { coef => %s, deviance => %s, iter => %d, df => %d },\n",
              name, num(unname(coef(f))), fmt1(f$deviance), f$iter, f$df.residual))
}

cat("my %EXPECT = (\n")

## Poisson, fitted rates down to exp(-60) ~ 1e-26: far below the 1e-10 floor
## glm() used through 0.3413, but above R's .Machine$double.eps floor only
## where the fit puts them.  The audit of 2026-11-03 found this case.
x <- c(-60, -50, -45, -40, -35, -30, -25, -20, 0, 1, 2, 3, 4)
y <- c(0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 9, 30, 80)
emit("pois_tiny", glm(y ~ x, family = poisson()))
emit("negbin_tiny", glm(y ~ x, family = negative.binomial(theta = 2)))
## the same data with an offset, so eta - offset and eta differ
emit("pois_tiny_off", glm(y ~ x, family = poisson(), offset = rep(-1, 13)))

## Complete separation, binomial: eta runs past the +-30 clamp of
## logit_linkinv() in R's family.c, where mu is exp(30)/(1+exp(30)) and
## mu.eta is DBL_EPSILON.
xs <- 1:10
ys <- c(0, 0, 0, 0, 0, 1, 1, 1, 1, 1)
emit("binom_sep", suppressWarnings(glm(ys ~ xs, family = binomial())))
ys2 <- c(0, 0, 0, 1, 0, 1, 1, 1, 1, 1)
emit("binom_quasisep", suppressWarnings(glm(ys2 ~ xs, family = binomial())))

## glm.control.Rd:55, the Dobson (1990) example.
counts <- c(18,17,15,20,10,20,25,13,12)
outcome <- gl(3,1,9)
treatment <- gl(3,3)
emit("D93", glm(counts ~ outcome + treatment, family = poisson()))
cat(");\n")
