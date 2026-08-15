# Generator for the R-side expected values in t/ks_test.R.scipy.t.
#
#   Rscript t/ks_test.R.scipy.R
#
# Prints one line per case:  <label> <TAB> <D> <TAB> <p> <TAB> <method>
# at 17 significant digits. The .t file carries the numbers as frozen
# literals and never runs this script.
#
# R 4.6.1 (2026-06-24) "Happy Hop".

options(digits = 17, warn = 1)

emit <- function(label, r) {
    cat(sprintf("%s\t%.17g\t%.17g\t%s\n",
                label, unname(r$statistic), r$p.value, r$method))
}

case <- function(label, x, y, ...) {
    r <- suppressWarnings(ks.test(x, y, ...))
    emit(label, r)
}

## ---- datasets ------------------------------------------------------------

# Hollander & Wolfe (1999) Example 5.4, from R's tests/reg-tests-1a.R
hw.x <- c(-0.15, 8.6, 5, 3.71, 4.29, 7.74, 2.48, 3.25, -1.15, 8.38)
hw.y <- c(2.55, 12.07, 0.46, 0.35, 2.69, -0.94, 1.73, 0.73, -0.35, -0.37)

# Schroeer & Trenkler (1995), from ?ks.test's examples
st.x <- c(1, 2, 2, 3, 3)
st.y <- c(1, 2, 3, 3, 4, 5, 6)

# Switzer (1976) knee-angle data, from ?qqplot's examples
switzer.f <- c(-31, -30, -25, -25, -23, -23, -22, -20, -20, -18,
               -18, -18, -16, -15, -15, -14, -13, -11, -10, - 9,
               - 8, - 7, - 7, - 7, - 6, - 6, - 4, - 4, - 3, - 2,
               - 2, - 1,   1,   1,   4,   5,  11,  12,  16,  34)
switzer.m <- c(-31, -20, -18, -16, -16, -16, -15, -14, -14, -14,
               -14, -13, -13, -11, -11, -10, - 9, - 9, - 8, - 7,
               - 7, - 6, - 6,  -5, - 5, - 5, - 4, - 2, - 2, - 2,
                 0,   0,   1,   1,   2,   4,   5,   5,   6,  17)

# airquality Ozone by Month, months 5 and 8, from ?ks.test's examples.
# NAs are dropped by ks.test itself; dump them so the Perl side can feed
# the raw column (with undef) through its own missing-value handling.
oz5 <- airquality$Ozone[airquality$Month == 5]
oz8 <- airquality$Ozone[airquality$Month == 8]

# SciPy's TestKSTwoSamples fixtures, reproduced exactly.
sp.d1  <- c(1.0, 2.0)
sp.d1p <- sp.d1 + 0.01
sp.d1m <- sp.d1 - 0.01
sp.d2  <- c(1.0, 2.0, 3.0)
sp.d2f <- c(1.0, 2.0, 3.0, 4.0)
x100        <- seq(1, 100, length.out = 100)
x100_2_p1   <- x100 + 2 + 0.1
x100_2_m1   <- x100 + 2 - 0.1
x110        <- seq(1, 100, length.out = 110)
x110_20_p1  <- x110 + 20 + 0.1
x110_20_m1  <- x110 + 20 - 0.1
x2233 <- c(rep(2, 3), rep(3, 4), rep(5, 5), rep(6, 4))
x3344 <- x2233 + 1
x2356 <- c(rep(2, 3), rep(3, 4), rep(5, 10), rep(6, 4))
x3467 <- c(rep(3, 10), rep(4, 2), rep(6, 10), rep(7, 4))
# TestKSTwoSamples.testLarge: 10000 vs 110
lg.n1 <- 10000; lg.n2 <- 110
lg.delta <- 1 / lg.n1 / lg.n2 / 2 / 2
lg.x <- seq(1, 200, length.out = lg.n1) - lg.delta
lg.y <- seq(2, 100, length.out = lg.n2)

# SciPy's TestKSOneSample fixtures.
sp1.a <- seq(-1, 1, length.out = 9)
sp1.b <- seq(-15, 15, length.out = 9)
sp1.c <- c(-1.23, 0.06, -0.60, 0.17, 0.66, -0.17, -0.08, 0.27, -0.98, -0.99)

## ---- data dumps ----------------------------------------------------------

dump.vec <- function(label, v) {
    cat(sprintf("#DATA\t%s\t%s\n", label,
                paste(ifelse(is.na(v), "NA", sprintf("%.17g", v)),
                      collapse = ",")))
}

dump.vec("oz5", oz5)
dump.vec("oz8", oz8)

# ?qqplot's "agreement with ks.test" example: set.seed(1) rnorm data.
set.seed(1)
qq.x <- rnorm(50)
qq.y <- rnorm(50, mean = .5, sd = .95)
dump.vec("qq.x", qq.x)
dump.vec("qq.y", qq.y)

## ---- two-sample ----------------------------------------------------------

for (alt in c("two.sided", "greater", "less")) {
    for (ex in c(TRUE, FALSE)) {
        tag <- paste0(alt, ".", ifelse(ex, "exact", "asymp"))
        case(paste0("hw.", tag),        hw.x,  hw.y,  alternative = alt, exact = ex)
        case(paste0("ks5.", tag),       1:5,   c(2.5, 4.5), alternative = alt, exact = ex)
        case(paste0("one.01.", tag),    0,     1,     alternative = alt, exact = ex)
        case(paste0("one.10.", tag),    1,     0,     alternative = alt, exact = ex)
        case(paste0("d1p.d2.", tag),    sp.d1p, sp.d2,  alternative = alt, exact = ex)
        case(paste0("d1m.d2.", tag),    sp.d1m, sp.d2,  alternative = alt, exact = ex)
        case(paste0("d1p.d2f.", tag),   sp.d1p, sp.d2f, alternative = alt, exact = ex)
        case(paste0("d1m.d2f.", tag),   sp.d1m, sp.d2f, alternative = alt, exact = ex)
        case(paste0("eq.p1.", tag),     sp.d2, sp.d2 + 1,   alternative = alt, exact = ex)
        case(paste0("eq.p05.", tag),    sp.d2, sp.d2 + 0.5, alternative = alt, exact = ex)
        case(paste0("eq.m05.", tag),    sp.d2, sp.d2 - 0.5, alternative = alt, exact = ex)
        case(paste0("st.", tag),        st.x,  st.y,  alternative = alt, exact = ex)
        case(paste0("switzer.", tag),   switzer.f, switzer.m, alternative = alt, exact = ex)
        case(paste0("oz.", tag),        oz5,   oz8,   alternative = alt, exact = ex)
        case(paste0("qq.", tag),        qq.x,  qq.y,  alternative = alt, exact = ex)
        case(paste0("x2233.x3344.", tag), x2233, x3344, alternative = alt, exact = ex)
        case(paste0("x2356.x3467.", tag), x2356, x3467, alternative = alt, exact = ex)
        case(paste0("100.100p1.", tag), x100, x100_2_p1, alternative = alt, exact = ex)
        case(paste0("100.100m1.", tag), x100, x100_2_m1, alternative = alt, exact = ex)
        case(paste0("100.110p1.", tag), x100, x110_20_p1, alternative = alt, exact = ex)
        case(paste0("100.110m1.", tag), x100, x110_20_m1, alternative = alt, exact = ex)
    }
    # 10000 x 110: exact is far too slow to be worth pinning; asymptotic only.
    case(paste0("large.", alt, ".asymp"), lg.x, lg.y, alternative = alt, exact = FALSE)
}

## ---- one-sample vs pnorm -------------------------------------------------

for (alt in c("two.sided", "greater", "less")) {
    for (ex in c(TRUE, FALSE)) {
        tag <- paste0(alt, ".", ifelse(ex, "exact", "asymp"))
        case(paste0("norm.a.", tag), sp1.a, "pnorm", alternative = alt, exact = ex)
        case(paste0("norm.b.", tag), sp1.b, "pnorm", alternative = alt, exact = ex)
        case(paste0("norm.c.", tag), sp1.c, "pnorm", alternative = alt, exact = ex)
        case(paste0("norm.hw.", tag), hw.x, "pnorm", alternative = alt, exact = ex)
    }
}

## ---- pathological one-sample --------------------------------------------

# Single observation, and a sample containing both -Inf and +Inf
# (SciPy's test_pm_inf_gh20386, re-run against pnorm).
case("norm.n1.two.sided.exact", 0, "pnorm", alternative = "two.sided", exact = TRUE)
case("norm.inf.two.sided.exact", c(-Inf, 0, 1, Inf), "pnorm",
     alternative = "two.sided", exact = TRUE)
case("norm.inf.two.sided.asymp", c(-Inf, 0, 1, Inf), "pnorm",
     alternative = "two.sided", exact = FALSE)
# All-identical values: D is driven entirely by the single jump.
case("norm.const.two.sided.exact", rep(0, 5), "pnorm",
     alternative = "two.sided", exact = TRUE)
case("two.const.two.sided.exact", rep(0, 5), rep(1, 5),
     alternative = "two.sided", exact = TRUE)
case("two.const.two.sided.asymp", rep(0, 5), rep(1, 5),
     alternative = "two.sided", exact = FALSE)
case("two.same.two.sided.exact", rep(0, 5), rep(0, 5),
     alternative = "two.sided", exact = TRUE)
case("two.same.two.sided.asymp", rep(0, 5), rep(0, 5),
     alternative = "two.sided", exact = FALSE)

## ---- the inline (non-corpus) cases in the .t file ------------------------
##
## These are the numbers written out by hand in the .t rather than living in a
## table, so they belong here too or the file is only half-regenerable.

# The exact/asymptotic auto-gates, probed either side of both boundaries.
a <- (1:100) * 1.0
case("gate.2s.10000", a, (1:100) + 0.5)    # 100*100 = 10000 -> asymptotic
case("gate.2s.9900",  a, (1: 99) + 0.5)    # 100* 99 =  9900 -> exact
case("gate.1s.99",  (1: 99) / 100, "pnorm")            # n =  99 -> exact
case("gate.1s.100", (1:100) / 100, "pnorm")            # n = 100 -> asymptotic

# Forced exact past ks_test's KS_EXACT_MAX_PRODUCT of 1e7: 3200*3200 = 1.024e7.
# Only the statistic is used from this one; R has no such cap.
case("gate.forced.huge", (1:3200) * 1.0, (1:3200) + 0.5, exact = FALSE)

# Missing-value handling.  R drops NA and NaN alike with x[!is.na(x)], so
# these are the values ks_test must reach from inputs padded with undef, a
# non-numeric string, or a NaN.
case("drop.3v4", c(1, 2, 3), c(5, 6, 7, 8))
case("drop.1s.3", c(1, 2, 3), "pnorm")

# Call-form and one-sample smoke values.
case("form.4v4", c(1, 2, 3, 4), c(5, 6, 7, 8))
case("form.1s.m101",       c(-1, 0, 1), "pnorm")
case("form.1s.m101.asymp", c(-1, 0, 1), "pnorm", exact = FALSE)

# One-sample auto-gate with ties: R's rule is (n < 100) && !TIES, so R's
# automatic answer is its exact=FALSE one.  ks_test stays exact, and its value
# is R's exact=TRUE one.
case("ties1.exact", c(1, 1, 2, 2, 3, 3), "pnorm", exact = TRUE)
case("ties1.asymp", c(1, 1, 2, 2, 3, 3), "pnorm", exact = FALSE)

# 10000 x 110 forced exact.  R has no product cap either, and this is the
# pair whose two-sided value SciPy cannot reach.
for (alt in c("two.sided", "greater", "less"))
    case(paste0("large.", alt, ".exact"), lg.x, lg.y,
         alternative = alt, exact = TRUE)

# TestKSOneSample.test_known_examples' fixture, read back from the dump
# t/ks_test.R.scipy.py writes, so both sides pin the same 100 numbers.
if (file.exists("kn.txt")) {
    kn <- scan("kn.txt", quiet = TRUE)
    for (alt in c("two.sided", "greater", "less"))
        for (ex in c(TRUE, FALSE))
            case(paste0("norm.kn.", alt, ".", ifelse(ex, "exact", "asymp")),
                 kn, "pnorm", alternative = alt, exact = ex)
} else {
    cat("#NOTE\tkn.txt absent; run",
        "`python3 t/ks_test.R.scipy.py | grep '^#DATA.kn' | cut -f3",
        "| tr , '\\n' > kn.txt` first for the norm.kn.* rows\n")
}
