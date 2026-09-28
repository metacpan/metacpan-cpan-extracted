# Generator for the frozen expected values in t/lm.edge.R.t.
#
# Re-run with
#
#     Rscript t/lm.edge.R.R > /tmp/lm.edge.pl
#
# and paste the printed %EXPECT block over the one in the .t file.  The test
# itself never runs this script, or R.
#
# Produced with R 4.6.1.  mtcars is R's own data set; the test carries the four
# columns it uses as literals, which read back as exactly the doubles R holds
# (none has more than three decimals, far from perl's atof trouble at the
# exponent extremes).

options(digits = 17)

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  if (is.infinite(v)) return(if (v > 0) "$INF" else "-$INF")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")

emit <- function(key, fit) {
  s  <- suppressWarnings(summary(fit))
  cf <- coef(fit)
  nm <- sub("^\\(Intercept\\)$", "Intercept", names(cf))
  ct <- s$coefficients        # aliased rows are absent here, NA in cf
  col <- function(j) vapply(names(cf), function(n) if (n %in% rownames(ct)) ct[n, j] else NA, 0)
  cat(sprintf("\t%s => {\n", key))
  cat(sprintf("\t\tnames    => [%s],\n", paste0("'", nm, "'", collapse = ", ")))
  cat(sprintf("\t\testimate => %s,\n", num(unname(cf))))
  cat(sprintf("\t\tse       => %s,\n", num(unname(col(2)))))
  cat(sprintf("\t\tt        => %s,\n", num(unname(col(3)))))
  cat(sprintf("\t\tp        => %s,\n", num(unname(col(4)))))
  cat(sprintf("\t\trank => %d, df => %d,\n", fit$rank, fit$df.residual))
  cat(sprintf("\t\tr2 => %s, adj => %s,\n", fmt1(s$r.squared), fmt1(s$adj.r.squared)))
  f <- if (is.null(s$fstatistic)) NA else s$fstatistic[1]
  cat(sprintf("\t\tfstat => %s,\n", fmt1(unname(f))))
  cat(sprintf("\t\trss => %s,\n", fmt1(sum(residuals(fit)^2))))
  cat("\t},\n")
}

cat("my %EXPECT = (\n")
emit("sqrt_hp",  lm(mpg ~ I(hp^0.5),   data = mtcars))
emit("inv_wt",   lm(mpg ~ I(wt^-1),    data = mtcars))
emit("disp_1_5", lm(mpg ~ I(disp^1.5) + wt, data = mtcars))
# SciPy 1.18.0 TestRegression.test_regressZEROX, Wilkinson W.IV.D: ZERO on X.
emit("zero_x",   lm(y ~ x, data = data.frame(x = 1:9, y = rep(0, 9))))
# Fewer rows than columns, but a rank that leaves one residual df.
emit("short_aliased", lm(y ~ x + z, data = data.frame(y = c(1, 2, 4), x = 1:3, z = c(2, 4, 6))))
cat(");\n")
