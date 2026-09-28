# Generator for the frozen expected values in t/anova_fits.R.t.
#
# Re-run with
#
#     Rscript t/anova_fits.R.R > /tmp/anova_fits.pl
#
# and paste the printed %DATA and %EXPECT blocks over the ones in the .t
# file.  The test itself never runs this script, or R.
#
# Produced with R 4.6.1 and MASS 7.3-66.  Every comparison is one R's or
# MASS's own documentation or tests make:
#
#   lcs_*    src/library/stats/man/anova.lm.Rd -- LifeCycleSavings, fit0 to
#            fit4 compared with test = "F", and the "unconventional order"
#            anova(fit4, fit2, fit0); pinned to five figures in
#            tests/Examples/stats-Ex.Rout.save.
#   pr14960  tests/reg-tests-1b.R:1894 -- "anova.lmlist could fail", with
#            its set.seed(1) draws.
#   d93_*    src/library/stats/man/glm.Rd and anova.glm.Rd -- Dobson's
#            glm.D93 against glm.D93a (the saturated model), by the default
#            test and by "Chisq" and "F".
#   anorex_* the anorexia gaussian fits of tests/reg-tests-1a.R:419, where
#            the default test is F on the estimated dispersion.
#   quine_*  MASS man/anova.negbin.Rd -- glm.nb(Days ~ Eth*Age*Lrn*Sex)
#            against the model without the four-way interaction.

suppressMessages(library(MASS))
options(digits = 17)

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  if (is.infinite(v)) return(if (v > 0) "9**9**9" else "-9**9**9")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")
str_ <- function(x) paste0("[", paste0("'", x, "'", collapse = ", "), "]")
col <- function(v) if (is.numeric(v)) num(v) else str_(as.character(v))

cat("my %DATA = (\n")
data_out <- function(name, df) {
  cat(sprintf("  %s => {\n", name))
  for (nm in names(df)) cat(sprintf("    '%s' => %s,\n", nm, col(df[[nm]])))
  cat("  },\n")
}
EXP <- list()
tab <- function(key, a) {
  a <- as.data.frame(a)
  EXP[[key]] <<- lapply(a, function(v) if (is.numeric(v)) v else as.character(v))
}

L <- LifeCycleSavings
data_out("lcs", L)
fit0 <- lm(sr ~ 1, data = L)
fit1 <- update(fit0, . ~ . + pop15)
fit2 <- update(fit1, . ~ . + pop75)
fit3 <- update(fit2, . ~ . + dpi)
fit4 <- update(fit3, . ~ . + ddpi)
tab("lcs_all", anova(fit0, fit1, fit2, fit3, fit4, test = "F"))
tab("lcs_unconventional", anova(fit4, fit2, fit0, test = "F"))
tab("lcs_chisq", anova(fit0, fit2, fit4, test = "Chisq"))

set.seed(1)
y <- rnorm(20)
x <- rnorm(20)
f <- factor(rep(letters[1:2], each = 10))
data_out("pr14960", data.frame(y = y, x = x, f = as.character(f)))
tab("pr14960", anova(lm(y ~ x), lm(y ~ x + f), test = "F"))

counts <- c(18, 17, 15, 20, 10, 20, 25, 13, 12)
outcome <- gl(3, 1, 9)
treatment <- gl(3, 3)
d93 <- data.frame(counts, outcome = paste0("o", outcome), treatment = paste0("t", treatment))
data_out("d93", d93)
g <- glm(counts ~ outcome + treatment, family = poisson(), data = d93)
ga <- glm(counts ~ outcome * treatment, family = poisson(), data = d93)
g0 <- glm(counts ~ 1, family = poisson(), data = d93)
tab("d93_default", anova(g0, g, ga))
tab("d93_chisq", anova(g, ga, test = "Chisq"))
tab("d93_F", suppressWarnings(anova(g0, g, test = "F")))

A <- MASS::anorexia
data_out("anorexia", A)
a0 <- glm(Postwt ~ Prewt + offset(Prewt), data = A)
a1 <- glm(Postwt ~ Prewt + Treat + offset(Prewt), data = A)
tab("anorex_default", anova(a0, a1))
tab("anorex_chisq", anova(a0, a1, test = "Chisq"))

Q <- MASS::quine
data_out("quine", data.frame(Days = Q$Days, Eth = as.character(Q$Eth), Sex = as.character(Q$Sex),
                             Age = as.character(Q$Age), Lrn = as.character(Q$Lrn)))
m1 <- glm.nb(Days ~ Eth*Age*Lrn*Sex, Q, link = log)
m2 <- update(m1, . ~ . - Eth:Age:Lrn:Sex)
tab("quine_nb", anova(m2, m1))
EXP$quine_nb_fits <- list(theta = c(m2$theta, m1$theta), rank = c(m2$rank, m1$rank),
                         twologlik = c(m2$twologlik, m1$twologlik))
cat(");\n\n")

cat("my %EXPECT = (\n")
for (k in names(EXP)) {
  e <- EXP[[k]]
  cat(sprintf("  %s => {\n", k))
  for (f in names(e)) cat(sprintf("    '%s' => %s,\n", f, col(e[[f]])))
  cat("  },\n")
}
cat(");\n")
