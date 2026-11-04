# Generator for the frozen expected values in t/lm.collinear.R.t.
#
# Re-run with
#
#     Rscript t/lm.collinear.R.R > /tmp/lm.collinear.pl
#
# and paste the printed blocks over the ones in the .t file.  The test itself
# never runs this script, or R.
#
# Produced with R 4.6.1.  Sources of the cases, as the .t file's header lists:
# longley is R's own data set (tests/reg-tests-1b.R line 205); PR#2776 is
# tests/reg-tests-2.R line 885; x and y of `shifted` are SciPy 1.18.0
# scipy/stats/tests/test_stats.py TestRegression.test_regress_against_R, and
# X, BIG and LITTLE are that file's Wilkinson NASTY arrays.

options(digits = 17)

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")

emit <- function(key, fit) {
  s  <- suppressWarnings(summary(fit))
  cf <- coef(fit)
  nm <- gsub("\\.", "_", sub("^\\(Intercept\\)$", "Intercept", names(cf)))
  ct <- s$coefficients        # aliased rows are absent here, NA in cf
  se <- vapply(names(cf), function(n) if (n %in% rownames(ct)) ct[n, 2] else NA, 0)
  cat(sprintf("\t%s => {\n", key))
  cat(sprintf("\t\tnames    => [%s],\n", paste0("'", nm, "'", collapse = ", ")))
  cat(sprintf("\t\testimate => %s,\n", num(unname(cf))))
  cat(sprintf("\t\tse       => %s,\n", num(unname(se))))
  cat(sprintf("\t\trank => %d, df => %d,\n", fit$rank, fit$df.residual))
  if (inherits(fit, "glm")) cat(sprintf("\t\tdeviance => %s,\n", fmt1(deviance(fit))))
  else cat(sprintf("\t\trss => %s,\n", fmt1(sum(residuals(fit)^2))))
  cat("\t},\n")
}

L <- longley
names(L) <- gsub("\\.", "_", names(L))
cat("my %LONGLEY = (\n")
for (n in names(L)) cat(sprintf("\t%s => %s,\n", n, num(L[[n]])))
cat(");\n\n")

set.seed(123)
x2 <- x1 <- 1:10
x3 <- 0.1*(1:10)^2
y <- x1 + rnorm(10)
cat(sprintf("my @PR2776_Y = @{ %s };\n\n", num(y)))
pr <- data.frame(y = y, x1 = x1, x2 = x2, x3 = x3)

sx <- c(151, 174, 138, 186, 128, 136, 179, 163, 152, 131)
sy <- c(63, 81, 56, 91, 47, 57, 76, 72, 62, 48)
shifted <- data.frame(x = sx + 1e7, y = sy)

X      <- 1:9
BIG    <- 99999990 + X
LITTLE <- c(0.99999991, 0.99999992, 0.99999993, 0.99999994, 0.99999995,
            0.99999996, 0.99999997, 0.99999998, 0.99999999)
nasty <- data.frame(X = X, BIG = BIG, LITTLE = LITTLE)

cat("my %EXPECT = (\n")
emit("longley_lm",  lm(Employed ~ ., data = L))
emit("longley_glm", glm(Employed ~ ., data = L))
emit("pr2776_lm",   lm(y ~ x1 + x2 + x3, data = pr))
emit("pr2776_glm",  glm(y ~ x1 + x2 + x3, data = pr))
emit("against_r",   lm(y ~ x, data = data.frame(x = sx, y = sy)))
emit("shifted_lm",  lm(y ~ x, data = shifted))
emit("shifted_glm", glm(y ~ x, data = shifted))
emit("shifted_poisson", glm(y ~ x, family = poisson, data = shifted))
emit("big_on_x",    lm(BIG ~ X, data = nasty))
emit("x_on_big",    lm(X ~ BIG, data = nasty))
emit("x_on_little", lm(X ~ LITTLE, data = nasty))
emit("x_on_big_little", lm(X ~ BIG + LITTLE, data = nasty))
cat(");\n")
