#!/usr/bin/env Rscript
#
# Regenerates the frozen R side of t/density.R.scipy.t.  Re-run it with
#
#     Rscript t/density.R.scipy.R > /tmp/density.R.pl
#
# and paste the output over the "BEGIN GENERATED (R)" .. "END GENERATED (R)"
# block of t/density.R.scipy.t.  The test itself never runs R: everything this
# prints is a Perl literal.
#
# Written against R 4.6.1 (2026-06-24).  Every case here is either one of R's
# own regression tests (tests/reg-tests-1{a,b,c,d}.R), one of the examples in
# src/library/stats/man/density.Rd or man/bandwidth.Rd whose printed output is
# pinned in tests/Examples/stats-Ex.Rout.save, or a crossing of the argument
# space those two cover between them.

options(digits = 17, warn = 1)

nvq <- function(v) {                     # a numeric vector as a Perl list
    paste(vapply(v, function(z) {
        if (is.na(z))       "undef"
        else if (is.infinite(z)) if (z > 0) "9**9**9" else "-9**9**9"
        else sprintf("'%.17g'", z)
    }, ""), collapse = ", ")
}
pq <- function(s) paste0("'", gsub("'", "\\\\'", s), "'")

## ---------------------------------------------------------------- data sets
## All of these end up as frozen literals in the .t file.
set.seed(1)
DATA <- list(
    ## R's PR#8876 case (tests/reg-tests-1a.R): density() used to return
    ## slightly negative y here through rounding error.
    pr8876    = c(0.006, 0.002, 0.024, 0.02, 0.034, 0.09, 0.074, 0.072,
                  0.122, 0.048, 0.044, 0.168),
    ## R's PR#8033 case: an infinite observation is a point mass at +Inf.
    pr8033    = 1/0:2,
    ## man/density.Rd's very first example: IQR == 0, so bw.nrd0 falls back.
    iqr0      = c(-20, rep(0, 98), 20),
    ## man/density.Rd and man/bandwidth.Rd both work from these two.
    precip    = as.vector(precip),
    eruptions = faithful$eruptions,
    ## Dyadic pseudo-random samples: exactly representable at every NV width,
    ## so no branch that turns on an == can move between builds.
    z60       = round(rnorm(60) * 1024) / 1024,
    z200      = round(rnorm(200) * 1024) / 1024,
    z9        = round(rnorm(9) * 1024) / 1024,
    ## Degenerate shapes: zero variance, n == 2, and a tie-heavy sample.
    const     = rep(3, 10),
    two       = c(-1.5, 2.25),
    ties      = c(rep(1, 5), rep(2, 5), rep(4, 3)),
    ## An interior NaN, for na.rm.
    withna    = c(1, 2, NaN, 4),
    ## R's PR#18151 weights case.
    pr18151   = c(1, 2, NA, 4)
)
set.seed(7)
DATA$unif4096 <- round(runif(4096) * 1024) / 1024

cat("## BEGIN GENERATED (R) -- Rscript t/density.R.scipy.R\n")
cat("our %DATA = (\n")
for (nm in names(DATA)) cat("\t", nm, " => [", nvq(DATA[[nm]]), "],\n", sep = "")
cat(");\n\n")

## ------------------------------------------------------- density() cases
## Each case is an R argument list; the Perl argument list is derived from it,
## so the two can never drift apart.
pname <- c("na.rm" = "na_rm", "old.coords" = "old_coords",
           "give.Rkern" = "give_rkern", "warnWbw" = "warn_wbw")
perl_args <- function(a) {
    out <- character(0)
    for (k in names(a)) {
        v  <- a[[k]]
        pk <- if (!is.na(pname[k])) pname[k] else k
        pv <- if (is.character(v)) pq(v)
              else if (is.logical(v)) (if (v) "1" else "0")
              else if (length(v) > 1) paste0("[", nvq(v), "]")
              else sprintf("'%.17g'", v)
        out <- c(out, paste0(pq(pk), " => ", pv))
    }
    paste(out, collapse = ", ")
}

KERNELS <- c("gaussian", "epanechnikov", "rectangular", "triangular",
             "biweight", "cosine", "optcosine")

CASES <- list()
add <- function(data, ..., wt = NULL) {
    a <- list(...)
    CASES[[length(CASES) + 1L]] <<- list(data = data, args = a, wt = wt)
}

## -- R's own regression tests -------------------------------------------
add("pr8033", kernel = "rectangular", bw = 1, from = 0, to = 1, n = 2)
add("pr8876", n = 20, from = -1, to = 1)
## -- man/density.Rd examples --------------------------------------------
add("iqr0")
add("eruptions", bw = "sj")
add("eruptions", bw = 0.15)
add("precip", n = 1000)
for (k in KERNELS) add("precip", bw = "SJ", kernel = k)
for (b in c("nrd0", "nrd", "ucv", "bcv", "SJ-ste", "SJ-dpi")) add("precip", bw = b)
## -- kernels in R's own parametrisation, and in S's ---------------------
for (k in KERNELS) add("const", bw = 1, kernel = k)      # density(0, bw=1, ...)
for (k in KERNELS) add("const", width = 2, kernel = k)   # S parametrisation
add("const", from = -1.2, to = 1.2, width = 2, kernel = "gaussian")
## -- the argument space -------------------------------------------------
for (k in KERNELS) add("z60", kernel = k)
for (k in KERNELS) add("z200", kernel = k, adjust = 0.5)
for (a in c(0.25, 1, 4))    add("z60", adjust = a)
for (nn in c(1, 2, 10, 100, 511, 512, 513, 1000, 1024, 2048)) add("z60", n = nn)
for (cc in c(0, 1, 3, 10))  add("z60", cut = cc)
for (ee in c(1, 4, 8))      add("z60", ext = ee)
add("z60", from = -1)
add("z60", to = 1)
add("z60", from = -1, to = 1)
add("z60", from = -1, to = 1, n = 37)
for (b in c("nrd0", "nrd", "ucv", "bcv", "sj", "SJ-ste", "SJ-dpi", "NRD0", "Sj"))
    add("z200", bw = b)
add("z9", bw = "nrd")
add("z9", bw = "SJ")
add("const")
add("two")
add("ties")
add("ties", kernel = "epanechnikov", adjust = 2)
add("withna", na.rm = TRUE)
add("withna", na.rm = TRUE, bw = 0.5)
add("pr8033", bw = 0.5)
add("pr8033", bw = 0.5, kernel = "cosine")
add("unif4096")
add("unif4096", old.coords = TRUE)
add("z200", old.coords = TRUE)
add("z200", old.coords = TRUE, kernel = "biweight")
add("z60", kernel = "c")                    # match.arg abbreviations
add("z60", kernel = "o")
add("z60", window = "epanechnikov")
add("z60", width = 1.5)
add("z60", width = "SJ")
## -- weights ------------------------------------------------------------
add("z9", wt = rep(1/9, 9))
add("z9", wt = (1:9)/45)
add("z9", wt = rep(1/18, 9), subdensity = TRUE)
add("pr18151", na.rm = TRUE, wt = rep(1/4, 4))
add("eruptions", bw = "sj", wt = rep(1/272, 272))
add("pr8033", wt = c(0.5, 0.25, 0.25))
add("pr8033", wt = c(0.5, 0.25, 0.25), subdensity = TRUE)

## The weighted example from man/density.Rd: the same estimate from 126 unique
## values weighted by their counts as from all 272 observations.
fe   <- sort(faithful$eruptions)
ufe  <- unique(fe)
wfe  <- as.vector(table(fe)) / length(fe)
bwsj <- bw.SJ(faithful$eruptions)

## Spot indices at which y is frozen, plus sum(y) and max(y): together these
## pin the whole grid without writing 512 numbers per case.
spots <- function(n) {
    s <- unique(pmin(n, c(1, 2, 3, 7, 64, 128, 200, 256, 333, 400, n - 1, n)))
    sort(s[s >= 1])
}

cat("our @R_DENSITY = (\n")
for (cs in CASES) {
    x <- DATA[[cs$data]]
    a <- c(list(x = x), cs$args)
    if (!is.null(cs$wt)) a$weights <- cs$wt
    d <- suppressWarnings(do.call(stats::density, a))
    nn <- length(d$y)
    sp <- spots(nn)
    pa <- perl_args(cs$args)
    if (!is.null(cs$wt)) pa <- paste0(pa, if (nchar(pa)) ", " else "",
                                      "'weights' => [", nvq(cs$wt), "]")
    ## Did the bandwidth come out of a search (bw.ucv/bw.bcv/bw.SJ)?  If so
    ## the whole result is only pinned to that search's own tolerance, and the
    ## Perl test loosens accordingly.
    rule <- c(cs$args$bw, cs$args$width)
    srch <- if (is.character(rule) &&
                any(grepl("^(ucv|bcv|sj)", tolower(rule)))) 1 else 0
    cat("\t{ data => ", pq(cs$data), ", args => [", pa, "], search => ", srch,
        ",\n", sep = "")
    cat("\t  bw => '", sprintf("%.17g", d$bw), "', n => ", d$n,
        ", len => ", nn, ",\n", sep = "")
    cat("\t  x1 => '", sprintf("%.17g", d$x[1]), "', xn => '",
        sprintf("%.17g", d$x[nn]), "',\n", sep = "")
    cat("\t  ysum => '", sprintf("%.17g", sum(d$y)), "', ymax => '",
        sprintf("%.17g", max(d$y)), "',\n", sep = "")
    cat("\t  at => [", paste(sp, collapse = ", "), "],\n", sep = "")
    cat("\t  y  => [", nvq(d$y[sp]), "],\n", sep = "")
    cat("\t  xs => [", nvq(d$x[sp]), "] },\n", sep = "")
}
cat(");\n\n")

## ---------------------------------------------------------------- bw.* cases
BW <- list()
addbw <- function(fn, data, ...) BW[[length(BW) + 1L]] <<- list(fn = fn, data = data, args = list(...))
for (dn in c("precip", "eruptions", "z60", "z200", "z9", "unif4096", "two", "ties")) {
    addbw("bw.nrd0", dn); addbw("bw.nrd", dn)
}
for (dn in c("precip", "eruptions", "z60", "z200", "unif4096")) {
    addbw("bw.ucv", dn); addbw("bw.bcv", dn)
    addbw("bw.SJ", dn); addbw("bw.SJ", dn, method = "dpi")
}
addbw("bw.nrd0", "iqr0"); addbw("bw.nrd", "iqr0")
addbw("bw.nrd0", "const"); addbw("bw.nrd", "const")
## R's own regression tests for bw.SJ:
##   tests/reg-tests-1a.R -- bw.SJ(1:20) must not error ("no solution in the
##     specified range of bandwidths" for R <= 2.5.0)
##   tests/reg-tests-1b.R -- bw.SJ(c(1:99, 1e6), tol = 1e-3) == 0.725
DATA$seq20 <- 1:20
DATA$out99 <- c(1:99, 1e6)
cat("our %DATA2 = (\n\tseq20 => [", nvq(DATA$seq20), "],\n\tout99 => [",
    nvq(DATA$out99), "],\n);\n\n", sep = "")
addbw("bw.SJ", "seq20")
addbw("bw.SJ", "out99", tol = 1e-3)
addbw("bw.SJ", "out99", tol = 1e-3, method = "dpi")
## non-default nb / lower / upper, which density() never reaches
addbw("bw.ucv", "z200", nb = 64)
addbw("bw.bcv", "z200", nb = 64)
addbw("bw.SJ",  "z200", nb = 64)
addbw("bw.ucv", "z200", lower = 0.05, upper = 2)
addbw("bw.SJ",  "z200", lower = 0.05, upper = 2)
addbw("bw.ucv", "z200", tol = 1e-6)
addbw("bw.bcv", "z200", tol = 1e-6)
addbw("bw.SJ",  "z200", tol = 1e-6)
## the binned pair-count route (n > nb/2)
addbw("bw.SJ",  "z200", nb = 100)
addbw("bw.ucv", "z200", nb = 100)
addbw("bw.bcv", "z200", nb = 100)
## Tight-tolerance variants.  R's defaults stop the search at tol = 0.1*lower,
## which is of order a percent of the answer, so a default-tolerance result is
## only reproducible while the arithmetic is bit-identical.  These ask both
## implementations to converge properly, so the comparison stops depending on
## the iterates and starts depending on the answer.
for (dn in c("precip", "eruptions", "z60", "z200", "unif4096")) {
    addbw("bw.ucv", dn, tol = 1e-10)
    addbw("bw.bcv", dn, tol = 1e-10)
    addbw("bw.SJ",  dn, tol = 1e-10)
    addbw("bw.SJ",  dn, tol = 1e-10, method = "dpi")
}

pfn <- c("bw.nrd0" = "bw_nrd0", "bw.nrd" = "bw_nrd", "bw.ucv" = "bw_ucv",
         "bw.bcv" = "bw_bcv", "bw.SJ" = "bw_sj")
cat("our @R_BW = (\n")
for (b in BW) {
    x <- if (!is.null(DATA[[b$data]])) DATA[[b$data]] else stop("no data")
    v <- suppressWarnings(do.call(get(b$fn, envir = asNamespace("stats")),
                                  c(list(x), b$args)))
    ## A search told to converge properly, rather than stopped at R's default
    ## tol, gives an answer the Perl side can pin tightly.
    tight <- if (!is.null(b$args$tol) && b$args$tol <= 1e-9) 1 else 0
    cat("\t{ fn => ", pq(pfn[[b$fn]]), ", data => ", pq(b$data),
        ", args => [", perl_args(b$args), "], tight => ", tight, ", val => '",
        sprintf("%.17g", v), "' },\n", sep = "")
}
cat(");\n\n")

## ---------------------------------------------------------- give.Rkern
cat("our %R_KERN = (\n")
for (k in KERNELS)
    cat("\t", k, " => '", sprintf("%.17g", density(kernel = k, give.Rkern = TRUE)),
        "',\n", sep = "")
cat(");\n")
cat("## END GENERATED (R)\n")
