# Generator for the frozen literals in t/formula.parser.R.t.  Re-run with
#   Rscript t/formula.parser.R.R
# (R 4.6.1) and paste the output over the expectations in the test; the test
# itself never runs R.
options(digits = 17)
d <- data.frame(
	y   = c(1.5, 2.25, 3.75, 3.0, 5.5, 4.25, 7.0, 6.5, 8.25, 9.0),
	x   = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
	z   = c(0.5, 0.25, 1.0, 0.75, 1.5, 1.25, 2.0, 1.75, 2.5, 2.25),
	u   = c(2, 4, 6, 8, 10, 12, 14, 16, 18, 20),
	a   = c("p", "q", "p", "q", "p", "q", "p", "q", "p", "q"),
	cnt = c(1, 2, 2, 4, 3, 6, 5, 9, 8, 12),
	stringsAsFactors = FALSE)
show <- function(label, f, fit) {
	cf <- coef(fit)
	names(cf) <- sub("(Intercept)", "Intercept", names(cf), fixed = TRUE)
	cat(label, ":", f, "\n")
	for (n in sort(names(cf))) cat("  ", n, "=", cf[[n]], "\n")
}
for (f in c("y~x+offset(z)", "y~x+offset(u/2)", "y~x+offset(-z)", "y~x+offset(u+z)",
            "y~x+offset(u-z)", "y~x+offset(z)+offset(u/2)", "y~x*offset(z)",
            "y~x-offset(z)", "y~a+offset(z)-1")) {
	fit <- lm(as.formula(f), data = d)
	show("lm", f, fit)
	cat("   rss =", sum(residuals(fit)^2), " r2 =", summary(fit)$r.squared,
	    " fitted1 =", fitted(fit)[1], " resid1 =", residuals(fit)[1],
	    " df =", df.residual(fit), "\n")
}
for (f in c("cnt~x+offset(z)*a", "cnt~x-offset(z)", "cnt~x+offset(u/2)", "cnt~x+offset(-z)")) {
	show("glm", f, glm(as.formula(f), data = d, family = poisson))
}
for (f in c("log(y)~.", "I(y+x)~.", "log(y)~.-x", "y~.")) {
	dd <- d[, c("y", "x", "z")]
	show("dot", f, lm(as.formula(f), data = dd))
}
for (f in c("y~x-1+1", "y~0+x+1", "y~x+0+1", "y~x+1-1", "y~1+x-1", "y~x-1+0", "y~0+1")) {
	show("int", f, lm(as.formula(f), data = d))
}
