# Regenerates the frozen tables in t/smd.R.t.
#   Rscript t/smd.R.R > /tmp/smd.txt
# then paste each section over the one of the same name in the test.  The test
# never runs this; it reads the literals that were pasted from it.
#
# Written against R 4.6.1 (2026-06-24) and survey 4.5, whose nhanes data
# tableone's tests use.  tableone 0.13.2 (2022-04-15) is not installed here,
# so StdDiff() and CheckNaOnlyStrata() below are copied verbatim from
# R/modules-smd.R in its CRAN source tarball.  The cases are those of its
# tests/testthat/test-modules-smd.R:
#
#   "continuous standardized difference is correct (nhanes unweighted)"
#       HI_CHOL by RIAGENDR (one contrast) and by race (six)
#   "binary standardized difference is correct", its continuous half
#       variable <- c(1,0,0,0,0, 1,1,0,0,0, 1,1,1,0,0), group <- rep(1:3, each = 5)
#   "decent results are returned for anomalous/difficult data"
#       onlyOne <- 1, which StdDiff() redefines from 0/0 to 0
#
# and from smd 0.8.0's tests/testthat/helper_smd.R, the data its
# compare_packages() holds to tableone::ExtractSmd(): set.seed(123), then
# rnorm(60) split into groups A and B of 30 ('numeric'), and
# rep(rep(1:3, each = 10), times = 2) ('integer'), whose two groups are equal.
#
# HI_CHOL is 0, 1 or NA, so a group is fully described by its three counts,
# and that is what @NHANES holds; the test rebuilds the vectors from them.
#
# StdDiff() returns abs(); the signed value is the tests' own expression,
# (means[a] - means[b]) / sqrt((vars[a] + vars[b]) / 2), with a before b.
options(digits = 17, scipen = 500)

suppressMessages(library(survey))
data(nhanes)

CheckNaOnlyStrata <- function(variable, group) {

    unlist(lapply(split(variable, group),
                  function(var) {
                      ## TRUE if only NA's within stratum
                      all(is.na(var))
                  }))
}

StdDiff <- function(variable, group, binary = FALSE, na.rm = TRUE) {

    ## Check strata for all NA strata
    logiAllNaStrata <- CheckNaOnlyStrata(variable, group)
    ## If ANY strata have only NA's do not remove NA's
    if (any(logiAllNaStrata)) {
        warning("Variable has only NA's in at least one stratum. na.rm turned off.")
        na.rm = FALSE
    }

    ## Proportion of 1 is the mean of variable
    means <- tapply(variable, group, mean, na.rm = na.rm)

    ## Variance is p(1-p)
    if (binary) {
        vars  <- means * (1 - means)
    } else {
        vars  <- tapply(variable, group, var, na.rm = na.rm)
    }

    ## Outer to obtain all pairwise differences
    meanDiffs  <- outer(X = means, Y = means, FUN = "-")
    ## Outer to obtain all pairwise variance mean
    varMeans   <- outer(X = vars, Y = vars, FUN = "+") / 2

    out <- meanDiffs / sqrt(varMeans)

    ## If mean difference is zero and variance is zero,
    ## only one constant exists across two groups.
    ## In this case, the SMD can be defined zero, rather than NaN from 0/0.
    out[is.na(out) & !is.na(meanDiffs) & (meanDiffs == 0) & !is.na(varMeans) & (varMeans == 0)] <- 0

    ## This lower.tri() approach is actually giving 2vs1, 3vs1, etc
    ## opposite of stated 1vs2, 1vs3. Only correct if abs() is used.
    abs(out[lower.tri(out)])
}

# Every pair a < b of the groups, in StdDiff()'s lower.tri() order, which is
# also the order of the tests' meanDiffs vectors.
pairs_of <- function(variable, group, set) {
    means <- tapply(variable, group, mean, na.rm = TRUE)
    vars  <- tapply(variable, group, var,  na.rm = TRUE)
    lv <- names(means)
    sd <- StdDiff(variable, group)
    k <- 0
    for (a in seq_along(lv)) for (b in seq_along(lv)) if (a < b) {
        k <- k + 1
        signed <- (means[a] - means[b]) / sqrt((vars[a] + vars[b]) / 2)
        cat(sprintf("\t[ '%s', '%s', '%s', %.17g, %.17g ],\n",
                    set, lv[a], lv[b], signed, sd[k]))
    }
}

# [ grouping, level, zeros, ones, NAs ]
cat("== @NHANES\n")
for (by in c("RIAGENDR", "race")) {
    tab <- table(factor(nhanes$HI_CHOL, levels = c(0, 1)), nhanes[[by]], useNA = "ifany")
    for (lv in colnames(tab))
        cat(sprintf("\t[ '%s', '%s', %d, %d, %d ],\n", by, lv,
                    tab["0", lv], tab["1", lv], tab[is.na(rownames(tab)), lv]))
}

# [ set, group a, group b, signed smd(a, b), StdDiff()'s abs value ]
cat("== @R_PAIRS\n")
pairs_of(nhanes$HI_CHOL, nhanes$RIAGENDR, "RIAGENDR")
pairs_of(nhanes$HI_CHOL, nhanes$race, "race")
variable <- c(1,0,0,0,0, 1,1,0,0,0, 1,1,1,0,0)
group    <- rep(1:3, each = 5)
pairs_of(variable, group, "binary_toy")
set.seed(123)
num <- rnorm(60)
g60 <- rep(c("A", "B"), each = 30)
pairs_of(num, g60, "smd_numeric")
pairs_of(rep(rep(1:3, each = 10), times = 2), g60, "smd_integer")

cat("== smd_numeric data\n")
cat(sprintf("\t%s\n", paste(sprintf("%.17g", num), collapse = ", ")))

# The degenerate cases, through StdDiff() itself: a column that is one
# constant in every group (tableone's onlyOne), and one that is constant
# within each group but differs between them, where meanDiffs / sqrt(0) is
# Inf and StdDiff() leaves it so.
cat("== degenerate\n")
cat(sprintf("# onlyOne by RIAGENDR: %s; by race: %s\n",
            paste(StdDiff(rep(1, nrow(nhanes)), nhanes$RIAGENDR), collapse = " "),
            paste(StdDiff(rep(1, nrow(nhanes)), nhanes$race), collapse = " ")))
cat(sprintf("# c(1,1,1) vs c(2,2,2): %s\n",
            StdDiff(c(1, 1, 1, 2, 2, 2), rep(1:2, each = 3))))
