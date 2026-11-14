# Generator for the frozen tables in t/zerotrunc.large_counts.R.t.
# Re-run:  Rscript t/zerotrunc.large_counts.R.R   (R 4.6.1, countreg 0.3-0,
# pscl 1.5.9); paste the printed Perl hash literals into the .t file.
# The data are simulated here (set.seed(7)), zero-truncated negative binomial
# counts around 8000 and, for hurdle(), the same with a binary zero part.
suppressMessages({library(countreg); library(pscl)})
options(digits = 17)
set.seed(7)
n <- 40
x <- round(runif(n), 6)
mu <- 8000 * exp(0.3 * x)
y <- rnbinom(n, mu = mu, size = 14)
y[y < 1] <- 1
d <- data.frame(y = y, x = x)
zt <- zerotrunc(y ~ x, data = d, dist = "negbin")
emit <- function(nm, v) cat(sprintf("\t%s => %s,\n", nm, paste0("[", paste(sprintf("%.17g", v), collapse = ", "), "]")))
cat("my %ZT = (\n"); emit("y", d$y); emit("x", d$x)
emit("coef", coef(zt)[1:2]); emit("se", sqrt(diag(vcov(zt)))[1:2]); emit("theta", zt$theta)
emit("ll", as.numeric(logLik(zt))); cat(");\n")
# hurdle: zeros from a Bernoulli on x, positives as above
z <- rbinom(n, 1, plogis(1 - 2 * x))
yh <- ifelse(z == 1, y, 0)
dh <- data.frame(y = yh, x = x)
h <- hurdle(y ~ x | x, data = dh, dist = "negbin", zero.dist = "binomial")
cat("my %HU = (\n"); emit("y", dh$y)
emit("count", coef(h, "count")[1:2]); emit("zero", coef(h, "zero")); emit("theta", h$theta)
emit("ll", as.numeric(logLik(h))); cat(");\n")
