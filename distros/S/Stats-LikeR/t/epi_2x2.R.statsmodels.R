# Generator for t/epi_2x2.R.statsmodels.t (R half): the Wald odds ratio from
# a logistic regression, which is the sample odds ratio and a Wald interval on
# exp(coef) with SE sqrt(1/a + 1/b + 1/c + 1/d).  R 4.6.2 stats::glm
# (binomial, epsilon = 1e-14 so IRLS has converged to the closed form) and confint.default.  Run with
#     Rscript t/epi_2x2.R.statsmodels.R
# Tables as in t/epi_2x2.R.statsmodels.py (no zero cells, 95% only).
options(digits = 17)
T <- list(
	convictions = c(2, 15, 10, 3), performance = c(794, 150, 86, 570),
	tea = c(3, 1, 1, 3), readme = c(30, 70, 20, 80), rare = c(3, 997, 1, 999),
	protective = c(10, 90, 40, 60), smokers12 = c(83, 3, 90, 3))
for (k in names(T)) {
	v <- T[[k]]; a <- v[1]; b <- v[2]; c <- v[3]; d <- v[4]
	df <- data.frame(y = c(a, c), n = c(a + b, c + d), x = c(1, 0))
	f <- glm(cbind(y, n - y) ~ x, family = binomial, data = df,
		control = glm.control(epsilon = 1e-14, maxit = 100))
	ci <- exp(confint.default(f, "x", level = 0.95))
	cat(sprintf("\t[ '%s', %s, %s, %s ],\n", k, format(exp(coef(f)[["x"]]), digits = 17),
		format(ci[1], digits = 17), format(ci[2], digits = 17)))
}
