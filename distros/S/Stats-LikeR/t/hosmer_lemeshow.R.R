# Regenerates the frozen tables in t/hosmer_lemeshow.R.t.
#   Rscript t/hosmer_lemeshow.R.R > /tmp/hl.txt
# then paste each section over the one of the same name in the test.  The test
# never runs this; it reads the literals that were pasted from it.
#
# Written against R 4.6.1 (2026-06-24) and ResourceSelection 0.3-6
# (2023-06-27).  That package is not installed here, so hoslem.test() below is
# its R/hoslem.test.R copied verbatim from the CRAN source tarball
# ResourceSelection_0.3-6.tar.gz.  The package's own test of it, tests/tests.R,
# only runs example(hoslem.test); that example -- man/hoslem.test.Rd -- is the
# first dataset here, and its 500 outcomes and fitted values are written out in
# full so the test reads the same numbers R did.
options(digits = 17, scipen = 500)

hoslem.test <- function (x, y, g = 10) {
    if (g < 2L)
        stop("Argument g must be at least 2.")
    DNAME <- paste(deparse(substitute(x)), deparse(substitute(y)),
        sep = ", ")
    METHOD <- "Hosmer and Lemeshow goodness of fit (GOF) test"
    yhat <- y
    y <- x
    qq <- unique(quantile(yhat, probs = seq(0, 1, 1/g)))
    cutyhat <- cut(yhat, breaks = qq, include.lowest = TRUE)
    observed <- xtabs(cbind(y0 = 1 - y, y1 = y) ~ cutyhat)
    expected <- xtabs(cbind(yhat0 = 1 - yhat, yhat1 = yhat) ~
        cutyhat)
    chisq <- sum((observed - expected)^2/expected)
    G <- length(unique(cutyhat))
    if (G < 2L)
        stop("The number of bins led to negative df.")
    PVAL = 1 - pchisq(chisq, G - 2)
    PARAMETER <- G - 2
    names(chisq) <- "X-squared"
    names(PARAMETER) <- "df"
    if (G < g)
        warning("The data did not allow for the requested number of bins.")
    structure(list(statistic = chisq, parameter = PARAMETER,
        p.value = PVAL, method = METHOD, data.name = DNAME, observed = observed,
        expected = expected), class = "htest")
}

# The same test with hosmer_lemeshow()'s two departures: a cell whose observed
# and expected counts are both 0 -- every cell of an empty bin, and the
# events column of a bin whose predictions are all exactly 0 -- adds 0 rather
# than 0/0, and the last break is max(yhat) rather than the quantile at seq()'s
# last element, which is 1 - 2^-53 for g = 49.  Where hoslem.test() is finite
# and bins every row, the two agree to the bit.
hl.dropped <- function(y, yhat, g) {
    probs <- seq(0, 1, 1/g)
    qq <- quantile(yhat, probs = probs)
    qq[length(qq)] <- max(yhat)
    qq <- unique(qq)
    cutyhat <- cut(yhat, breaks = qq, include.lowest = TRUE)
    O <- xtabs(cbind(y0 = 1 - y, y1 = y) ~ cutyhat)
    E <- xtabs(cbind(yhat0 = 1 - yhat, yhat1 = yhat) ~ cutyhat)
    k <- rowSums(O) > 0
    cell <- (O - E)^2/E
    cell[O == 0 & E == 0] <- 0
    chisq <- sum(cell[k, , drop = FALSE])
    G <- sum(k)
    c(chisq, G - 2, pchisq(chisq, G - 2, lower.tail = FALSE), G)
}

row <- function(name, g, v) cat(sprintf("\t[ '%s', %d, %.17g, %d, %.17g, %d ],\n",
    name, g, v[1], as.integer(v[2]), v[3], as.integer(v[4])))

# man/hoslem.test.Rd \examples
set.seed(123)
n <- 500
x <- rnorm(n)
y <- rbinom(n, 1, plogis(0.1 + 0.5*x))
m <- glm(y ~ x, family=binomial)
doc.y <- m$y
doc.p <- unname(fitted(m))

# Every set has n - 1 prime and above every g it is tested at (499, 37, 41, 19),
# so no break's index 1 + (n - 1) * k/g is an integer for 0 < k < g.  At an
# integer index the break is a sorted prediction itself, and whether the
# arithmetic lands on it or one ulp below decides which bin that prediction
# joins -- in R's double arithmetic one way, and on a long-double or quadmath
# perl possibly the other.

# A prediction tied at the floor: 15 of 38 share the lowest value, so the 0.1
# and 0.2 quantiles both equal it and unique() merges them.  Dyadic values,
# exact at every NV width.
tie.p <- c(rep(0.0625, 15), seq(0.125, 0.8125, length.out = 23))
tie.y <- c(1,0,0,0,0,0,0,0,0,0,0,0,0,0,1, 0,0,1,0,0,1,0,0,1,0,1,0,1,1,0,1,1,
           0,1,1,1,0,1)

# Predictions from a model with only a 4-level factor: four distinct values.
cat.p <- rep(c(0.125, 0.25, 0.5, 0.75), times = c(12, 11, 11, 8))
cat.y <- c(0,0,0,1,0,0,0,0,0,0,1,1, 0,0,0,0,0,0,1,0,0,0,1, 1,0,1,0,1,0,1,1,1,0,0,
           1,1,0,1,0,1,1,0)

# Two distinct predictions: g = 4 gives two groups (df 0), g = 3 one.
two.p <- rep(c(0.25, 0.75), each = 10)
two.y <- c(0,0,1,0,0,0,1,0,0,0, 1,1,0,1,1,1,0,1,1,1)

# Predictions of exactly 0 and exactly 1, each with outcomes that agree, so
# the first bin expects no events and sees none and the last expects no
# non-events and sees none: hoslem.test() is NaN.  n - 1 = 24, and 24k/5 is
# not an integer for 0 < k < 5.
zero.p <- rep(c(0, 0.25, 0.5, 0.75, 1), each = 5)
zero.y <- c(0,0,0,0,0, 0,1,0,0,0, 1,0,1,0,0, 1,1,0,1,1, 1,1,1,1,1)

cat("== @DOC_Y\n"); cat(paste(doc.y, collapse = ","), "\n")
cat("== @DOC_P\n"); cat(paste(sprintf("%.17g", doc.p), collapse = ","), "\n")

# [ set, g, statistic, df, p.value, G ] straight from hoslem.test(), for every
# case where it is finite and bins every row.
cat("== @R_ROWS\n")
sets <- list(doc = list(doc.y, doc.p), tie = list(tie.y, tie.p),
             cat = list(cat.y, cat.p), two = list(two.y, two.p),
             zero = list(zero.y, zero.p))
gs <- list(doc = c(3:12, 15, 20, 25, 30, 40, 48), tie = 3:10, cat = 3:10,
           two = 4:10, zero = 5)
stops <- character()
for (s in names(sets)) for (g in gs[[s]]) {
    yy <- sets[[s]][[1]]; pp <- sets[[s]][[2]]
    h <- tryCatch(suppressWarnings(hoslem.test(yy, pp, g = g)),
                  error = function(e) conditionMessage(e))
    if (is.character(h)) { stops <- c(stops, sprintf("%s g=%d: %s", s, g, h)); next }
    G <- h$parameter + 2
    if (is.finite(h$statistic) && sum(h$observed) == length(yy))
        row(s, g, c(h$statistic, h$parameter, 1 - pchisq(h$statistic, h$parameter), G))
}

# [ set, g, statistic, df, p, G ] where hoslem.test() is NaN (an empty bin) or
# leaves a row unbinned (g = 49): hl.dropped(), the third opinion.
cat("== @DIVERGE\n")
for (s in names(sets)) for (g in c(gs[[s]], 49)) {
    yy <- sets[[s]][[1]]; pp <- sets[[s]][[2]]
    if (g >= length(yy)) next
    h <- tryCatch(suppressWarnings(hoslem.test(yy, pp, g = g)),
                  error = function(e) NULL)
    if (!is.null(h) && (!is.finite(h$statistic) || sum(h$observed) != length(yy)))
        row(s, g, hl.dropped(yy, pp, g))
}

# Where hoslem.test() stops: its "The number of bins led to negative df."
cat("== R stops\n"); cat(paste0("# ", stops, "\n"), sep = "")

# hoslem.test()'s own answer at g = 49, for the comment in the test.
h <- hoslem.test(doc.y, doc.p, g = 49)
cat(sprintf("== g = 49: hoslem.test bins %d of %d rows, df %d\n",
            sum(h$observed), n, h$parameter))

# The per-group table at the default g = 10: n, observed and expected events.
h <- hoslem.test(doc.y, doc.p)
cat("== @DOC_TABLE\n")
for (i in seq_len(nrow(h$observed)))
    cat(sprintf("\t[ %d, %d, %.17g ],\n", as.integer(sum(h$observed[i, ])),
                as.integer(h$observed[i, 2]), h$expected[i, 2]))
