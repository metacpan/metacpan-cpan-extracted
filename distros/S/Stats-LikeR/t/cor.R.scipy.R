#!/usr/bin/env Rscript
#
# Regenerates the frozen R side of t/cor.R.scipy.t.  Re-run it from the
# distribution root with
#
#     Rscript t/cor.R.scipy.R > /tmp/cor.R.pl
#
# and paste the output over the "BEGIN GENERATED (R)" .. "END GENERATED (R)"
# block of t/cor.R.scipy.t.  The test itself never runs R: everything this
# prints is a Perl literal.  It shells out to `python3 t/cor.R.scipy.py
# --draws` once, for SciPy's 500-pair normal sample, so that R's value is
# computed on exactly the doubles SciPy's is.
#
# Written against R 4.6.1 (2026-06-24).  Every value is cor(x, y, method = m)
# at R's default use = "everything", which is the only mode Stats::LikeR's
# cor() has, except Kendall's tau for the 200000-pair sample at the foot (see
# the comment there).  R's complete.obs and pairwise.complete.obs cases are
# reproduced by handing cor() the rows those modes would keep.  The data are:
#
#   * R's own: tests/reg-tests-1a.R (the zz r <= 1 case, the Spearman NA
#     ranking case below "Spearman correlations ranked missing values at end",
#     cor(longley) over every method, and PR#7116), tests/reg-tests-1b.R ("more
#     corner cases for cor()"), tests/reg-tests-2.R (the "corner cases for
#     cor" X <- cbind(NA, 1:3, rnorm(3)) block and PR#14488), and the longley
#     and swiss examples of src/library/stats/man/cor.Rd.
#   * SciPy 1.18.1's scipy/stats/tests -- test_stats.py (TestPearsonrWilkinson,
#     TestPearsonr, TestCorrSpearmanr, TestCorrSpearmanr2, TestKendallTau),
#     test_correlation.py (TestSpearmanRho) and test_mstats_basic.py (TestCorr)
#     -- whose inputs are re-typed here so that R's full-precision answer can
#     sit beside SciPy's own pinned literal in the .t file.
#   * Three regression cases for bugs fixed in Stats::LikeR's cor() itself.

options(digits = 17, warn = 1)

## A double as the shortest numeric literal that reads back to the same double
## in R, NA as undef.  Every value is well inside the exponent range (nothing
## below 1e-300 or above 1e300), where a current perl's parser lands on the
## same double; perl-5.10.1's lands one ulp away for a few, which the .t file's
## header measures and allows for.
num <- function(z) {
    if (is.na(z)) return("undef")
    if (is.infinite(z)) return(if (z > 0) "9**9**9" else "-9**9**9")
    for (d in 15:17) {
        s <- sprintf("%.*g", d, z)
        if (as.numeric(s) == z) return(s)
    }
    stop("no round-trip literal")
}
vec <- function(v) paste0("[", paste(vapply(v, num, ""), collapse = ", "), "]")
mat <- function(m) {                          # rows of a matrix, as an AoA
    m <- as.matrix(m)
    paste0("[", paste(apply(m, 1, vec), collapse = ", "), "]")
}
## An expected value: full precision, NA as undef.
ev <- function(z) if (is.na(z)) "undef" else sprintf("%.17g", z)
emat <- function(m) paste0("[", paste(apply(m, 1, function(r)
    paste0("[", paste(vapply(r, ev, ""), collapse = ", "), "]")), collapse = ", "), "]")
METHODS <- c("pearson", "spearman", "kendall")
cr <- function(x, y = NULL, m) suppressWarnings(cor(x, y, method = m))

## ------------------------------------------------------------------ vectors
## Each row is [ label, x, y, { pearson, spearman, kendall } ].
V <- list()
add <- function(label, x, y) V[[length(V) + 1]] <<- list(label = label, x = x, y = y)

## tests/reg-tests-1a.R: "fails in R <= 1.3.x" -- cor(zz, zz) must not exceed 1.
zz <- c(-1.30167, -0.4957, -1.46749, 0.46927)
add("reg-1a zz self", zz, zz)
## tests/reg-tests-1b.R "more corner cases for cor()": a scalar, not a 1x1.
add("reg-1b scalar", c(1, 2, 3), c(3, 4, 6))
## tests/reg-tests-1a.R PR#7116, as two vectors (the matrix form is below).
add("PR#7116 vectors", c(1, 2), c(1, 2))
## man/cor.Rd: cor(1:10, 2:11) # == 1
add("cor.Rd 1:10 vs 2:11", 1:10, 2:11)
## tests/reg-tests-2.R PR#14488 "missing values in rank correlations".
set.seed(1)
x14488 <- runif(10); y14488 <- runif(10)
x14488[3] <- NA; y14488[5] <- NA
add("PR#14488 everything", x14488, y14488)
ok <- complete.cases(x14488, y14488)
add("PR#14488 complete", x14488[ok], y14488[ok])

## TestPearsonrWilkinson / TestCorrSpearmanr (Wilkinson's W.II.D): every pair
## of X, BIG, LITTLE, HUGE, TINY and ROUND correlates exactly 1.
W <- list(
    X      = 1:9,
    BIG    = 99999991:99999999,
    LITTLE = c(0.99999991, 0.99999992, 0.99999993, 0.99999994, 0.99999995,
               0.99999996, 0.99999997, 0.99999998, 0.99999999),
    HUGE   = (1:9) * 1e12,
    TINY   = c(1e-12, 2e-12, 3e-12, 4e-12, 5e-12, 6e-12, 7e-12, 8e-12, 9e-12),
    ROUND  = (1:9) - 0.5)
wn <- names(W)
for (i in seq_along(wn)) for (j in i:length(wn))
    add(paste("Wilkinson", wn[i], wn[j]), W[[wn[i]]], W[[wn[j]]])

## TestPearsonr
add("pearsonr arange3 self", 0:2, 0:2)
add("pearsonr arange3 neg", 0:2, -(0:2))
add("pearsonr basic", c(-1, 0, 1), c(0, 0, 3))
add("pearsonr very small", c(0.004434375, 0.004756007, 0.003911996, 0.0038005, 0.003409971),
    c(2.48e-188, 7.41e-181, 4.09e-208, 2.08e-223, 2.66e-245))
add("pearsonr very large", 1e90 * c(0, 0, 0, 1, 1, 1, 1), 1e90 * (0:6))
add("pearsonr extremely large", c(2.3e200, 4.5e200, 6.7e200, 8e200),
    c(1.2e199, 5.5e200, 3.3e201, 1.0e200))
add("pearsonr length two pos", c(1, 2), c(3, 5))
add("pearsonr length two neg", c(2, 1), c(3, 5))
add("pearsonr basic example +", c(1, 2, 3, 4), c(0, 1, 0.5, 1))
add("pearsonr basic example -", c(1, 2, 3, 4), -c(0, 1, 0.5, 1))
add("pearsonr gh17795", 0:9, -(0:9))
add("pearsonr length3 exact -1", c(1, 2, 3), c(5, -4, -13))
## test_mstats_basic.py TestCorr::test_pearsonr_misaligned_mask, unmasked part
add("mstats pearsonr misaligned", c(1, 4, 5, 6), c(9, 6, 5, 9))

## TestCorrSpearmanr / TestCorrSpearmanr2 / TestSpearmanRho / mstats
add("spearmanr vs R", c(1, 2, 3, 4, 5), c(5, 6, 7, 8, 7))
add("spearmanr 1d_vs_2d", c(1, 2, 3, 4, 5, 6), c(1, 2, 3, 4, 6, 5))
add("spearmanr 1d_vs_2d nans", c(1, NA, 3, 4, 5, 6), c(1, 2, 3, 4, 6, NA))
add("spearmanr corr_1", c(1, 1, 2), c(1, 1, 2))
add("spearmanr tie1", c(1, 2, 3, 4), c(1, 2, 2, 3))
add("spearmanr tie1 ranks", c(1, 2, 3, 4), c(1, 2.5, 2.5, 4))
add("spearmanr tie2", c(1, 2, 2.5, 2), c(1, 3, 2.5, 4))
add("spearmanr tie2 nan", c(1, 2, 2.5, 2, NA), c(1, 3, 2.5, 4, NA))
add("spearmanr 3cols x1 x3", 0:5, c(0, 1, 2, 3, 5, 4))
xn <- c(0:8, NA)
add("spearmanr nan_policy self", xn, xn)
add("spearmanr alternative nan", c(1, 2, 3, 4, 5, NA), c(5, 6, 7, 8, 7, NA))
g6061 <- 0:1999
g6061[c(1, 10)] <- g6061[c(10, 1)]
g6061[c(11, 435)] <- g6061[c(435, 11)]
g6061[c(436, 1510)] <- g6061[c(1510, 436)]
add("spearmanr gh6061", 0:1999, g6061)
add("spearmanrho vs R", c(0.11027287231363914, 0.8154770102474279, 0.7073943466920335,
    0.6651317324378386, 0.6905752850115503, 0.06115250587536558, 0.5209906494474178,
    0.3155763519785274, 0.18405731803625924, 0.8613557911541495),
    c(0.8402081904493103, 0.5946972833914318, 0.23481606164114155, 0.49754786197715384,
      0.9146460831206026, 0.5848057749217579, 0.7620801065573549, 0.31410063302647495,
      0.7935620302236199, 0.5423085761365468))
add("spearmanrho vs R exact", c(0.11027287231363914, 0.8154770102474279,
    0.7073943466920335, 0.6651317324378386, 0.6905752850115503, 0.06115250587536558),
    c(0.5209906494474178, 0.3155763519785274, 0.18405731803625924, 0.8613557911541495,
      0.8402081904493103, 0.5946972833914318))
add("mstats spearmanr 4", c(5.05, 6.75, 3.21, 2.66), c(1.65, 2.64, 2.64, 6.95))
add("mstats spearmanr 4 nan", c(5.05, 6.75, 3.21, 2.66, NA), c(1.65, 2.64, 2.64, 6.95, NA))
s15x <- c(2.0, 47.4, 42.0, 10.8, 60.1, 1.7, 64.0, 63.1, 1.0, 1.4, 7.9, 0.3, 3.9, 0.3, 6.7)
s15y <- c(22.6, 8.3, 44.4, 11.9, 24.6, 0.6, 5.7, 41.6, 0.0, 0.6, 6.7, 3.8, 1.0, 1.2, 1.4)
add("mstats spearmanr 15", s15x, s15y)
add("mstats spearmanr 15 nan", c(s15x, NA), c(s15y, NA))

## TestKendallTau::test_kendalltau_no_ties -- "Reference values result from R".
add("kendalltau no ties 1", c(5, 2, 1, 3, 6, 4, 7, 8), c(5, 2, 6, 3, 1, 8, 7, 4))
add("kendalltau no ties 2", c(0, 5, 2, 1, 3, 6, 4, 7, 8), c(5, 2, 0, 6, 3, 1, 8, 7, 4))
add("kendalltau no ties 3", c(5, 2, 1, 3, 6, 4, 7), c(5, 2, 6, 3, 1, 7, 4))
add("kendalltau no ties 4", c(2, 1, 3, 6, 4, 7, 8), c(2, 6, 3, 1, 8, 7, 4))
add("kendalltau no ties 5", 0:9, 0:9)
add("kendalltau no ties 6", 0:9, c(0, 2, 1, 3, 4, 5, 6, 7, 8, 9))
add("kendalltau no ties 7", 0:9, c(0, 2, 1, 3, 4, 6, 5, 7, 8, 9))
add("kendalltau no ties 8", 0:9, 9:0)
add("kendalltau no ties 9", 0:9, c(9, 7, 8, 6, 5, 4, 3, 2, 1, 0))
add("kendalltau no ties 10", 0:9, c(9, 7, 8, 6, 5, 3, 4, 2, 1, 0))
add("kendalltau Kendall 1970", c(1, 2, 2, 4, 4, 6, 6, 8, 9, 9), c(1, 2, 4, 4, 4, 4, 8, 8, 8, 10))
add("kendalltau ties vs R", c(12, 2, 1, 12, 2), c(1, 4, 7, 1, 0))
add("kendalltau 1,1,2 self", c(1, 1, 2), c(1, 1, 2))
add("kendalltau attributes", c(1, 2, 2, 4, 4, 6, 6, 8, 9, 9), c(1, 2, 2, 4, 4, 4, 8, 8, 8, 10))
add("kendalltau nan_policy self", xn, xn)
add("kendalltau gh6134", c(1, 2, 3, 4), c(NA, 2.4, 3.4, 3.4))
add("kendalltau gh6134 complete", c(2, 3, 4), c(2.4, 3.4, 3.4))
add("mstats kendalltau p=1", c(9, 2, 5, 6), c(4, 7, 9, 11))
k5x <- c(5.05, 6.75, 3.21, 2.66); k5y <- c(1.65, 26.5, -5.93, 7.96); k5z <- c(1.65, 2.64, 2.64, 6.95)
add("mstats kendalltau x y", k5x, k5y)
add("mstats kendalltau x z", k5x, k5z)
add("mstats kendalltau x y nan", c(k5x, NA), c(k5y, NA))
k22x <- c(0, 0, 0, 0, 20, 20, 0, 60, 0, 20, 10, 10, 0, 40, 0, 20, 0, 0, 0, 0, 0, NA)
k22y <- c(0, 80, 80, 80, 10, 33, 60, 0, 67, 27, 25, 80, 80, 80, 80, 80, 80, 0, 10, 45, NA, 0)
add("mstats kendalltau 22 nan", k22x, k22y)
ok <- complete.cases(k22x, k22y)
add("mstats kendalltau 22 complete", k22x[ok], k22y[ok])

## Regression: an incomplete pair is NA for every method (was 0.82857 for
## Spearman and 0.6 for Kendall), and the complete-case answer for contrast.
add("bug NA rank", c(1, 2, NA, 4, 5, 6), c(2, 1, 4, 3, 6, 5))
add("bug NA rank complete", c(1, 2, 4, 5, 6), c(2, 1, 3, 6, 5))

## Infinite values: NaN for Pearson, ordinary ranks for the rank methods.
add("Inf", c(1, 2, Inf, 4), c(2, 1, 4, 3))
add("-Inf", c(1, -Inf, 3, 4), c(2, 1, 4, 3))
add("Inf both", c(1, 2, Inf, 4), c(2, -Inf, Inf, 3))

## ----------------------------------------------------------------- matrices
## Each row is [ label, X, Y or undef, { pearson, spearman, kendall } ].
M <- list()
addm <- function(label, x, y = NULL) M[[length(M) + 1]] <<- list(label = label, x = x, y = y)

L <- as.matrix(longley)
dimnames(L) <- NULL
S <- as.matrix(swiss); dimnames(S) <- NULL
swM <- S
swM[1, 2] <- swM[7, 3] <- swM[25, 5] <- NA     # man/cor.Rd's "swM"
addm("longley", "longley")
addm("longley cross", "longley[0..2]", "longley[3..6]")
addm("swiss", "swiss")
addm("swM everything", "swM")
addm("swM complete", "swM complete")
## tests/reg-tests-1a.R: Spearman ranked missing values at the end <= 1.8.1.
X1a <- cbind(c(1, 3, 4, NA), c(1, 4, 2, NA))
addm("reg-1a spearman NA", X1a)
addm("reg-1a spearman NA complete cross", X1a[-4, ], X1a[-4, ])
## tests/reg-tests-1a.R PR#7116: a one-column matrix against itself.
addm("PR#7116 1x1", cbind(c(1, 2)), cbind(c(1, 2)))
## tests/reg-tests-2.R "corner cases for cor": columns 2 and 3 only; column 1
## is all NA (or NA but for one value), which cor() refuses -- see the .t.
set.seed(1)
X2 <- cbind(NA, 1:3, rnorm(3))
addm("reg-2 corner cols 2,3", X2[, 2:3])
## SciPy: test_3cols, test_gh_9103, test_constant_input_gh22816 (columns 2
## and 3), test_1d_vs_2d.
addm("spearmanr 3cols", cbind(0:5, -(0:5), c(0, 1, 2, 3, 5, 4)))
addm("spearmanr gh9103", cbind(c(NA, 3.0, 4.0, 5.0, 5.1, 6.0, 9.2),
                               c(5.0, NA, 4.1, 4.8, 4.9, 5.0, 4.1),
                               c(0.5, 4.0, 7.1, 3.8, 8.0, 5.1, 7.6)))
addm("spearmanr gh22816 cols 2,3", cbind(0:9, -(0:9)))
addm("spearmanr 1d_vs_2d", cbind(c(1, 2, 3, 4, 5, 6), c(1, 2, 3, 4, 6, 5)))
## Regression: NA in a column makes its row and column NA, diagonal kept.
addm("bug NA matrix", rbind(c(1, 1), c(NA, 2), c(3, 4), c(4, 3)))
## A cross matrix with an NA in one y column.
YNA <- L[, 6:7]; YNA[5, 2] <- NA
addm("cross y NA", "longley[0..1]", YNA)
## SciPy's 500-pair normal sample as a two-column matrix, and crossed.
addm("draws", "draws")
addm("draws cross", "draws[0]", "draws[1]")

## ------------------------------------------------------------------ output
dr <- as.matrix(read.table(pipe("python3 t/cor.R.scipy.py --draws")))
dimnames(dr) <- NULL
DATA <- list(longley = L, swiss = S, swM = swM,
             "swM complete" = swM[complete.cases(swM), ], draws = dr)
resolve <- function(z) {
    if (is.null(z)) return(NULL)
    if (!is.character(z)) return(as.matrix(z))
    m <- regmatches(z, regexec("^(.*)\\[(\\d+)(?:\\.\\.(\\d+))?\\]$", z, perl = TRUE))[[1]]
    if (length(m) == 0) return(DATA[[z]])
    hi <- if (m[4] == "") m[3] else m[4]
    DATA[[m[2]]][, (as.integer(m[3]):as.integer(hi)) + 1, drop = FALSE]
}
ref <- function(z) {                        # how the .t names a matrix
    if (is.null(z)) return("undef")
    if (is.character(z)) return(sprintf("'%s'", z))
    mat(z)
}

cat("## BEGIN GENERATED (R) -- Rscript t/cor.R.scipy.R\n")
cat("our %DATA = (\n")
for (k in c("longley", "swiss", "swM", "swM complete"))
    cat(sprintf("\t'%s' => %s,\n", k, mat(DATA[[k]])))
cat(");\n")
cat("our @VEC = (\n")
for (v in V) {
    r <- vapply(METHODS, function(m) cr(v$x, v$y, m), 0)
    cat(sprintf("\t[ '%s', %s, %s, { pearson => %s, spearman => %s, kendall => %s } ],\n",
                v$label, vec(v$x), vec(v$y), ev(r[1]), ev(r[2]), ev(r[3])))
}
cat(");\n")
cat("our @MAT = (\n")
for (m in M) {
    x <- resolve(m$x); y <- resolve(m$y)
    r <- lapply(METHODS, function(me) cr(x, y, me))
    cat(sprintf("\t[ '%s', %s, %s, { pearson => %s, spearman => %s, kendall => %s } ],\n",
                m$label, ref(m$x), ref(m$y), emat(r[[1]]), emat(r[[2]]), emat(r[[3]])))
}
cat(");\n")

## man/cor.Rd's use = "pairwise" on swM, which the .t rebuilds pair by pair.
cat("our %SWM_PAIRWISE = (\n")
for (me in METHODS)
    cat(sprintf("\t%s => %s,\n", me,
                emat(suppressWarnings(cor(swM, method = me, use = "pairwise")))))
cat(");\n")

## man/cor.Rd: "How much do they differ?" -- the correlation of the three
## lower triangles of cor(longley) under each method.
Cl <- cor(longley); clS <- cor(longley, method = "spearman")
clK <- cor(longley, method = "kendall"); i <- lower.tri(Cl)
cat(sprintf("our $LONGLEY_PSK = %s;\n", emat(cor(cbind(P = Cl[i], S = clS[i], K = clK[i])))))

## tests/reg-tests-2.R "corner cases for cor": the whole matrices, which
## Stats::LikeR refuses (a column with fewer than two non-NA values).
cat(sprintf("our @REG2_CORNER_X = (%s, %s);\n", mat(X2), {X2b <- X2; X2b[1, 1] <- 1; mat(X2b)}))

## The 200000-pair wh200k sample (see t/cor.R.scipy.py).
n <- 200000L; s <- 12345; t <- 6789
wx <- numeric(n); wy <- numeric(n)
for (k in seq_len(n)) {
    s <- (171 * s) %% 30269; t <- (172 * t) %% 30307
    wx[k] <- s %% 7 + 1; wy[k] <- t %% 7 + 1
}
## cor(method = "kendall") is R's O(n^2) pair loop, which takes over ten
## minutes for 2e10 pairs, so Kendall's tau-b comes from the 7 x 7 table
## instead: concordant and discordant pair counts are sums of cell products,
## exact in doubles (each is below 2e10 < 2^53), and tau-b is
## (C - D) / sqrt((n0 - n1)(n0 - n2)) with n0 = n(n-1)/2 and n1, n2 the pairs
## tied on x and on y.  R 4.6.1's cor(wx, wy, method = "kendall"), left to
## run once, took 628 s and printed the same 0.00020561663689276635.
tb <- unclass(table(wx, wy))
C <- 0; D <- 0
for (a in seq_len(nrow(tb))) for (b in seq_len(ncol(tb))) {
    if (a < nrow(tb) && b < ncol(tb)) C <- C + tb[a, b] * sum(tb[(a + 1):nrow(tb), (b + 1):ncol(tb)])
    if (a < nrow(tb) && b > 1)        D <- D + tb[a, b] * sum(tb[(a + 1):nrow(tb), 1:(b - 1)])
}
n0 <- n * (n - 1) / 2
n1 <- sum(rowSums(tb) * (rowSums(tb) - 1) / 2)
n2 <- sum(colSums(tb) * (colSums(tb) - 1) / 2)
cat(sprintf("our %%R_WH200K = (pearson => %s, spearman => %s, kendall => %s);\n",
            ev(cor(wx, wy)), ev(cor(wx, wy, method = "spearman")),
            ev((C - D) / sqrt((n0 - n1) * (n0 - n2)))))
cat("## END GENERATED (R)\n")
