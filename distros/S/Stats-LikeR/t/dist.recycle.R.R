# Generator for the frozen R values in t/dist.recycle.R.t.
#
# Re-run with
#
#     Rscript --vanilla t/dist.recycle.R.R
#
# and paste its output over the %R table in the .t file.  The test never runs
# this, or R.  Last run under R 4.6.2; the cases are from the R 4.6.1 sources:
#   TDist.Rd \examples: qt(.975, df = c(1:10,20,50,100,1000))
#   tests/d-p-q-r-tst-2.R, "pf() with large df1 or df2": pf(1, 1, nu) for
#     nu <- 2^seq(25, 34, 0.5), which R asserts is increasing and whose first
#     value is pchisq(1, 1) - 7.21129e-9 within 1e-11
#   tests/reg-tests-1a.R, PR#8560: pbinom(c(-1,0,1,2), size = 0, p = 0.5) is
#     c(0,1,1,1)
# and, for R's recycling rule itself (arithmetic.c, math2()/math3(): the
# longest argument sets the length, shorter ones are reused from the start
# with no warning, a zero-length argument gives numeric(0), NA in any argument
# is NA there), calls of every function Stats::LikeR recycles.
options(digits = 17)
num <- function(v) paste0("[", paste(ifelse(is.na(v), "undef", sprintf("%.17g", v)), collapse = ", "), "]")
out <- function(name, v) cat(sprintf("\t'%s' => %s,\n", name, num(v)))

cat("my %R = (\n")
out("qt(.975, df = c(1:10,20,50,100,1000))", qt(.975, df = c(1:10, 20, 50, 100, 1000)))
nu <- 2^seq(25, 34, 0.5)
out("nu", nu)
out("pf(1, 1, nu)", pf(1, 1, nu))
out("pchisq(1, 1)", pchisq(1, 1))
out("pbinom(c(-1,0,1,2), size = 0, p = 0.5)", pbinom(c(-1, 0, 1, 2), size = 0, p = 0.5))
out("dnorm(c(0,1), mean = c(0,1), sd = c(1,2))", dnorm(c(0, 1), mean = c(0, 1), sd = c(1, 2)))
out("dnorm(1:3, mean = 1:2)", dnorm(1:3, mean = 1:2))
out("dnorm(0, sd = c(1,-1,2))", suppressWarnings(dnorm(0, sd = c(1, -1, 2))))
out("dnorm(c(-1,0,2), mean = 1, sd = c(0.5,2), log = TRUE)", dnorm(c(-1, 0, 2), mean = 1, sd = c(0.5, 2), log = TRUE))
out("pnorm(c(0,1), mean = c(0,1,2,3))", pnorm(c(0, 1), mean = c(0, 1, 2, 3)))
out("pnorm(1, sd = c(1,-1))", suppressWarnings(pnorm(1, sd = c(1, -1))))
out("pnorm(c(-2,2), mean = c(0,1), lower.tail = FALSE, log.p = TRUE)", pnorm(c(-2, 2), mean = c(0, 1), lower.tail = FALSE, log.p = TRUE))
out("qnorm(c(0.1,0.9), mean = c(1,2,3), sd = 2)", qnorm(c(0.1, 0.9), mean = c(1, 2, 3), sd = 2))
out("pt(2, df = c(1,NA,3))", pt(2, df = c(1, NA, 3)))
out("pt(c(-1,1), df = c(2,5,10,30))", pt(c(-1, 1), df = c(2, 5, 10, 30)))
out("qt(c(0.025,0.975), df = c(3,30))", qt(c(0.025, 0.975), df = c(3, 30)))
out("pchisq(3, df = c(1,2,5))", pchisq(3, df = c(1, 2, 5)))
out("qchisq(c(0.5,0.95), df = c(1,10))", qchisq(c(0.5, 0.95), df = c(1, 10)))
out("pf(3, df1 = c(2,4), df2 = 10)", pf(3, df1 = c(2, 4), df2 = 10))
out("qf(0.95, df1 = c(1,2,3), df2 = c(10,20))", qf(0.95, df1 = c(1, 2, 3), df2 = c(10, 20)))
out("pbinom(3, size = c(5,10), prob = c(0.25,0.5,0.75))", pbinom(3, size = c(5, 10), prob = c(0.25, 0.5, 0.75)))
cat(");\n")
cat("# length(dnorm(numeric(0), mean = 1:2)) =", length(dnorm(numeric(0), mean = 1:2)), "\n")
cat("# length(dnorm(1, mean = numeric(0))) =", length(dnorm(1, mean = numeric(0))), "\n")
w <- 0; withCallingHandlers(dnorm(0, sd = c(-1, -2, 1)), warning = function(m) { w <<- w + 1; invokeRestart("muffleWarning") })
cat("# warnings from dnorm(0, sd = c(-1,-2,1)) =", w, "\n")
w <- 0; withCallingHandlers(dnorm(1:3, mean = 1:2), warning = function(m) { w <<- w + 1; invokeRestart("muffleWarning") })
cat("# warnings from dnorm(1:3, mean = 1:2) =", w, "\n")
