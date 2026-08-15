#  Generator for the %DATA and @CORPUS tables in t/wilcox_test.R.scipy.t.
#
#  Re-run with:   R --vanilla --slave -f t/wilcox_test.R.scipy.R
#  and paste the output over the "BEGIN GENERATED CORPUS" block in the .t file.
#
#  The test itself never runs this: the expected values are frozen literals in
#  the .t so that it passes on a machine with no R installed.  This script is
#  kept only so the table can be regenerated deliberately, and so that the
#  exact calls it made are on the record.
#
#  R 4.6.1 (2026-06-24) "Happy Hop", stats::wilcox.test.

options(digits = 17, warn = -1)
set.seed(20260814)

##  Named samples, chosen so that between them the corpus reaches every branch
##  of wilcox.test():
##
##    a*  no ties and no zeroes -- the closed-form exact distributions
##        (R's csignrank / cwilcox)
##    b*  coarse enough to tie, so the exact test switches to the conditional
##        distribution given the observed ranks (R >= 4.6.0,
##        Streitberg-Roehmel)
##    c*  small integers: heavy ties, and exact zeroes once mu is subtracted
##    d*  shifted, so the two one-sided tails are far apart
##    e*  degenerate: one point, two points, all-identical, all-zero
##
##  Every value is a dyadic rational -- a whole number of 1024ths or of
##  quarters -- and so is every mu.  This matters: whether two differences tie
##  decides which branch runs, and 1.6 - 2 - 0.5 does not round the same way in
##  a double, an x87 long double and a __float128.  Values the format can hold
##  exactly make the tie structure, and therefore the expected answer, the same
##  on every NV width.  (R's digits.rank exists for the same reason; see the
##  man page's own worked example.)
dy   <- function(n) round(rnorm(n) * 1024) / 1024   # distinct, exact
dyt  <- function(n) round(rnorm(n) * 4) / 4         # quarters, plenty of ties
mk <- list(
    a4  = dy(4),  a9  = dy(9),  a15 = dy(15), a7 = dy(7),
    b9  = dyt(9), b15 = dyt(15), b12 = dyt(12),
    c9  = as.numeric(sample(-2:2, 9,  replace = TRUE)),
    c15 = as.numeric(sample(-2:2, 15, replace = TRUE)),
    c12 = as.numeric(sample(-2:2, 12, replace = TRUE)),
    d9  = dy(9)  + 1.5,
    d15 = dy(15) + 1.5,
    d12 = dy(12) + 1.5,
    e1  = 2.5,
    e2  = c(1.5, 4.25),
    eflat = rep(3, 6),
    ezero = rep(0, 5),
    emix  = c(-1, 0, 1, 0, 2)
)

fmt <- function(v) {
    ## %.17g round-trips a double exactly; the non-finite spellings are what
    ## the .t file's own reader expects.
    ifelse(is.na(v), "'NaN'",
    ifelse(is.infinite(v) & v > 0, "'Inf'",
    ifelse(is.infinite(v) & v < 0, "'-Inf'", sprintf("%.17g", v))))
}
vec <- function(v) paste0("[", paste(fmt(v), collapse = ","), "]")

rows <- character(0)
emit <- function(xn, yn, paired, alt, mu, correct, exact, ci, conf.level) {
    x <- mk[[xn]]; y <- if (is.null(yn)) NULL else mk[[yn]]
    args <- list(x = x, alternative = alt, mu = mu, correct = correct)
    if (!is.null(y)) args$y <- y
    if (paired) args$paired <- TRUE
    if (!is.na(exact)) args$exact <- exact
    ## tol.root far below its 1e-4 default: the asymptotic interval is only
    ## ever determined to tol.root, so at the default a long-double build
    ## legitimately stops somewhere else and the frozen limit is a property of
    ## the arithmetic rather than of the data.  The .t passes the same value.
    if (ci) { args$conf.int <- TRUE; args$conf.level <- conf.level
              args$tol.root <- 1e-12 }
    r <- try(do.call(wilcox.test, args), silent = TRUE)
    if (inherits(r, "try-error")) return(invisible(NULL))
    tail <- if (ci)
        sprintf("%s,%s,%s,%s", fmt(r$estimate), fmt(r$conf.int[1]),
                fmt(r$conf.int[2]), fmt(attr(r$conf.int, "conf.level")))
    else "undef,undef,undef,undef"
    rows <<- c(rows, sprintf(
        "\t['%s','%s',%d,'%s',%s,%d,%s,%d,%s,%s,%s,'%s',%s],",
        xn, if (is.null(yn)) "" else yn,
        as.integer(paired), alt, fmt(mu), as.integer(correct),
        if (is.na(exact)) "undef" else as.integer(exact),
        as.integer(ci), fmt(conf.level),
        fmt(r$statistic), fmt(r$p.value), r$method, tail))
}

pairs2 <- list(c("a4","a9"), c("a9","b9"), c("b9","c9"), c("c9","d9"),
               c("a15","d15"), c("b15","c15"), c("d12","b12"), c("c12","a7"),
               c("e1","a9"), c("e2","c9"), c("eflat","eflat"),
               c("ezero","emix"), c("a9","a9"), c("b12","c12"))
paired2 <- list(c("a9","b9"), c("b9","c9"), c("a15","d15"), c("b15","c15"),
                c("d12","b12"), c("eflat","eflat"), c("ezero","emix"),
                c("a9","a9"), c("b12","c12"))
one1 <- c("a4","a9","a15","b9","b15","c9","c15","d9","d15",
          "e1","e2","eflat","ezero","emix")

i <- 0
nxt <- function() { i <<- i + 1; i }
for (alt in c("two.sided", "less", "greater"))
    for (ex in c(NA, TRUE, FALSE))
        for (cor in c(TRUE, FALSE)) {
            for (p in pairs2) {
                k <- nxt()
                emit(p[1], p[2], FALSE, alt, c(0,0,0.5,-1)[(k %% 4) + 1], cor, ex,
                     (k %% 3) == 0, c(0.95,0.9,0.99)[(k %% 3) + 1])
            }
            for (p in paired2) {
                k <- nxt()
                emit(p[1], p[2], TRUE, alt, c(0,0,0.5,-1)[(k %% 4) + 1], cor, ex,
                     (k %% 3) == 0, c(0.95,0.9,0.99)[(k %% 3) + 1])
            }
            for (xn in one1) {
                k <- nxt()
                emit(xn, NULL, FALSE, alt, c(0,0,0.5,-1)[(k %% 4) + 1], cor, ex,
                     (k %% 3) == 0, c(0.95,0.9,0.99)[(k %% 3) + 1])
            }
        }

cat("# BEGIN GENERATED CORPUS -- regenerate with t/wilcox_test.R.scipy.R\n")
cat("my %DATA = (\n")
for (n in names(mk)) cat(sprintf("\t%-6s => %s,\n", n, vec(mk[[n]])))
cat(");\n")
cat("my @CORPUS = (\n")
cat(paste(rows, collapse = "\n"), "\n")
cat(");\n")
cat("# END GENERATED CORPUS\n")
cat(sprintf("# %d cases\n", length(rows)))
