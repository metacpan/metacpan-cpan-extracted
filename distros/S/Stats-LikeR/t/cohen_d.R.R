# Regenerates the frozen tables in t/cohen_d.R.t.
#   Rscript t/cohen_d.R.R > /tmp/cohen_d.txt
# then paste each section over the one of the same name in the test.  The test
# never runs this; it reads the literals that were pasted from it.
#
# Written against R 4.6.1 (2026-06-24).  Neither package is installed here, so
# what is used of each is copied below from its CRAN source tarball:
#
#   effsize 0.8.1     R/CohenD.R, cohen.d.default(): the pooled two-sample
#                     branch -- stdev, dd, J and S_d -- and compute_ncp()'s
#                     defining equations, solved here by uniroot() instead of
#                     its bracket walk
#   effectsize 1.0.3  R/cohens_d.R, .effect_size_difference(): t1 and hn, and
#                     R/utils_ci.R, .get_ncp_t(), copied verbatim to show how
#                     far its optim() stops from the root
#
# The data are the two packages' own test data, from
# tests/testthat/testCohenD.R (effsize) and tests/testthat/test-cohens_d.R
# (effectsize):
#
#   mtcars      cohens_d(wt ~ am, data = mtcars), "cohens_d - pooled" and
#               "hedges_g"
#   iris        cohens_d(iris$Sepal.Length, iris$Sepal.Width, ci = 0.80),
#               "cohens_d errors and warnings"
#   issue23     effsize issue #23, a and b written out in the test
#   sleep       cohen.d(extra ~ group, data = sleep, noncentral = TRUE)
#   cheese      cohen.d(c(2,3,4,5,6,7), factor(rep(c("a","b"), each = 3)))
#   howell      "confidence interval with non-central distribution for two
#               samples": Howell's Confidence Intervals on Effect Size, data
#               of Adams, Wright and Lohr (1996), drawn by generate_data()
#               under set.seed(537)
#   borenstein  "Two independent samples with Hedges G, example from
#               Borenstein et al, Introduction to Meta-Analysis", set.seed(321)
#
# and two edge cases that are not from either suite: 'zero', two samples
# holding the same four values, so d = 0 and the interval is symmetric; and
# 'two', two observations a group, the fewest cohen_d() takes (df = 2).
#
# effectsize's "fixed values" test, on bayestestR::distribution_normal() data,
# is the == @FIXED section.  bayestestR 0.20.0's R/distribution.R defines
# distribution_normal(n, mean, sd) as qnorm(ppoints(n), mean, sd), so the test
# builds those vectors itself with qnorm() rather than reading 2e4 literals.
# n = 2.5e5 is not effectsize's; it is there to put df past 4e5, where
# exact_pnt() switches to its asymptotic form.
options(digits = 17, scipen = 500)

num <- function(v) paste(sprintf("%.17g", v), collapse = ", ")

# effsize 0.8.1, R/CohenD.R, verbatim from the pooled, unpaired branch of
# cohen.d.default.  n1, n2, m and s are computed as it computes them from d
# and f; its ns = as.numeric(table(f)) makes the counts doubles, so n1 * n2
# cannot overflow R's integers at n = 2.5e5.
effsize_pooled <- function(x, y) {
    n1 <- as.numeric(length(x)); n2 <- as.numeric(length(y))
    m <- c(mean(x), mean(y)); s <- c(sd(x), sd(y))
    delta.m <- as.numeric(m[1] - m[2])
    stdev = sqrt(((n1-1)*s[1]^2+(n2-1)*s[2]^2)/(n1+n2-2))
    dd = delta.m / stdev
    df = n1+n2-2
    J = 1 - 3 / ( 4 * (n1+n2) - 9)
    S_d = sqrt((n1+n2)/(n1*n2) + .5*dd^2/(n1+n2))
    list(d = dd, sd = stdev, g = dd * J, se = S_d, df = df, n1 = n1, n2 = n2)
}

# effectsize 1.0.3, R/utils_ci.R, verbatim
.get_ncp_t <- function(t, df_error, conf.level = 0.95) {
  if (!is.finite(t) || !is.finite(df_error)) {
    return(c(NA, NA))
  }

  alpha <- 1 - conf.level
  probs <- c(alpha / 2, 1 - alpha / 2)
  init <- rep(ifelse(abs(t) < 2, sign(t) * 2, t / 2), 2)
  ncp <- suppressWarnings(stats::optim(
    par = init,
    fn = function(x) {
      quan <- stats::qt(p = probs, df = df_error, ncp = x)
      sum(abs(quan - t))
    },
    control = list(abstol = 1e-09)
  ))

  t_ncp <- unname(sort(ncp$par))

  return(t_ncp)
}

# The limits .get_ncp_t() and compute_ncp() both look for, solved to the
# precision of R's pt(): the lower limit puts t at the upper alpha/2 point of
# the noncentral t, the upper limit at the lower one.
nct_limits <- function(t, df, cl) {
    a <- (1 - cl) / 2
    lo <- uniroot(function(ncp) pt(t, df, ncp, lower.tail = FALSE) - a,
                  c(t - 1, t), extendInt = "upX", tol = .Machine$double.eps,
                  maxiter = 10000)$root
    hi <- uniroot(function(ncp) pt(t, df, ncp) - a,
                  c(t, t + 1), extendInt = "downX", tol = .Machine$double.eps,
                  maxiter = 10000)$root
    c(lo, hi)
}

# effsize's tests/testthat/testCohenD.R, verbatim
generate_data <- function(n,m,stdev){
  x <- rnorm(n,m,stdev)
  sd.adj = stdev/sd(x)
  x <- x * sd.adj
  m.adj = m - mean(x)
  x <- x + m.adj
  return(x)
}

sets <- list()
sets$mtcars <- list(x = mtcars$wt[mtcars$am == 0], y = mtcars$wt[mtcars$am == 1])
sets$iris <- list(x = iris$Sepal.Length, y = iris$Sepal.Width)
sets$issue23 <- list(
    x = c(9.81605624621576, 8.93891560898168, 9.05436620537713, 6.01771305071382,
          8.98575772172126, 7.2595761413452, 13.7537304479165, 9.89861975363729,
          7.37246838418731, 8.33888742066376),
    y = c(8.62798051757027, 5.25390514295654, 12.0869496333763, 7.20553319908951,
          6.99017188584104, 8.22363490828756, 8.05485287987422, 6.50534569228974,
          8.68871033652186, 4.62897740315003))
sets$sleep <- list(x = sleep$extra[sleep$group == 1], y = sleep$extra[sleep$group == 2])
sets$cheese <- list(x = c(2, 3, 4), y = c(5, 6, 7))
set.seed(537)
hf <- generate_data(35, 24, sqrt(148.87))
nhf <- generate_data(29, 16.5, sqrt(139.16))
sets$howell <- list(x = hf, y = nhf)
set.seed(321)
x1 <- generate_data(50, 103, 5.5)
x2 <- generate_data(50, 100, 4.5)
sets$borenstein <- list(x = x1, y = x2)
sets$zero <- list(x = c(1, 2, 3, 4), y = c(4, 2, 3, 1))
sets$two <- list(x = c(1, 2), y = c(4, 7))

levels <- c(0.8, 0.9, 0.95, 0.99, 0.999)

cat("== %DATA\n")
for (s in names(sets))
    cat(sprintf("\t%s => {\n\t\tx => [ %s ],\n\t\ty => [ %s ],\n\t},\n",
                s, num(sets[[s]]$x), num(sets[[s]]$y)))

# [ set, conf_level, d, pooled_sd, hedges_g, se, nct_lo, nct_hi, normal_lo, normal_hi ]
cat("== @R_ROWS\n")
worst_optim <- 0
for (s in names(sets)) {
    e <- effsize_pooled(sets[[s]]$x, sets[[s]]$y)
    hn <- 1 / e$n1 + 1 / e$n2            # effectsize's hn
    t1 <- e$d / sqrt(hn)                 # its t1, (d - mu) / se with mu = 0
    for (cl in levels) {
        ncp <- nct_limits(t1, e$df, cl)
        ci <- ncp * sqrt(hn)
        z <- qnorm((1 + cl) / 2)
        cat(sprintf("\t[ '%s', %s, %.17g, %.17g, %.17g, %.17g, %.17g, %.17g, %.17g, %.17g ],\n",
                    s, sprintf("%g", cl), e$d, e$sd, e$g, e$se, ci[1], ci[2],
                    e$d - z * e$se, e$d + z * e$se))
        opt <- .get_ncp_t(t1, e$df, cl) * sqrt(hn)
        worst_optim <- max(worst_optim, abs(opt - ci) / abs(ci), na.rm = TRUE)
    }
}
cat(sprintf("# effectsize's optim() limits stray from the uniroot() ones by up to %.2g relative\n",
            worst_optim))

# [ n, mean2, sd2, conf_level, d, nct_lo, nct_hi ]: x1 = qnorm(ppoints(n)),
# x2 = qnorm(ppoints(n), mean2, sd2), as effectsize's "fixed values" test
cat("== @FIXED\n")
jobs <- character(0)
for (f in list(c(1e4, 1, 1), c(1e4, 1.5, 2), c(2.5e5, 1, 1))) {
    n <- f[1]
    x <- qnorm(ppoints(n)); y <- qnorm(ppoints(n), f[2], f[3])
    e <- effsize_pooled(x, y)
    hn <- 1 / n + 1 / n
    ncp <- nct_limits(e$d / sqrt(hn), e$df, 0.95)
    cat(sprintf("\t[ %d, %s, %s, 0.95, %.17g, %.17g, %.17g ],\n",
                as.integer(n), sprintf("%g", f[2]), sprintf("%g", f[3]), e$d,
                ncp[1] * sqrt(hn), ncp[2] * sqrt(hn)))
    jobs <- c(jobs, sprintf("\t[ 'fixed_%d_%g_%g', 0.95, %.17g, %d, %.17g, %.17g ],",
                            as.integer(n), f[2], f[3], e$d / sqrt(hn), as.integer(e$df),
                            ncp[1], ncp[2]))
}

# For t/cohen_d.mpmath.py, which solves the same two equations at
# mp.dps = 60 as the third opinion:
#   Rscript t/cohen_d.R.R | python3 t/cohen_d.mpmath.py
# [ set, conf_level, t, df, R's lower ncp, R's upper ncp ]
cat("== @NCP_JOBS\n")
for (s in names(sets)) {
    e <- effsize_pooled(sets[[s]]$x, sets[[s]]$y)
    hn <- 1 / e$n1 + 1 / e$n2
    t1 <- e$d / sqrt(hn)
    for (cl in levels) {
        ncp <- nct_limits(t1, e$df, cl)
        cat(sprintf("\t[ '%s', %g, %.17g, %d, %.17g, %.17g ],\n",
                    s, cl, t1, as.integer(e$df), ncp[1], ncp[2]))
    }
}
cat(paste(jobs, collapse = "\n"), "\n", sep = "")
