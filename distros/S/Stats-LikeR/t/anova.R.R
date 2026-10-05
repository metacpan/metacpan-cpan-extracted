# Generator for the frozen expected values in t/anova.R.t.
#
# Re-run with
#
#     Rscript t/anova.R.R > /tmp/anova.pl
#
# and paste the printed %DATA and %EXPECT blocks over the ones in the .t
# file.  The test itself never runs this script, or R.
#
# Produced with R 4.6.1.  The models are R's own, from its documentation and
# regression tests; where a model below is not literally one of those, it is
# one of those data sets refitted to cross a path the module took wrongly up
# to 0.3212, and says so.
#
#   lcs_*   src/library/stats/man/anova.lm.Rd -- LifeCycleSavings: anova(fit)
#           for sr ~ ., the chain fit0 .. fit4, and the "unconventional order"
#           anova(fit4, fit2, fit0) that tests/Examples/stats-Ex.Rout.save
#           pins.  lcs_dot is sr ~ . in the column order the module expands
#           '.' in (sorted; see get_all_columns() in LikeR.xs); lcs_negF a
#           pair that is not nested, for stat.anova()'s F < 0 rule.
#   wb_*    src/library/datasets/man/warpbreaks.Rd -- lm(breaks ~ wool*tension)
#           and anova(fm1); then the same data with the interaction nested in
#           wool (wool + wool:tension), alone (wool:tension), written before
#           its main effects, and without an intercept: the margin rule and
#           R's term order, which the module did not follow.
#   npk     src/library/datasets/man/npk.Rd -- aov(yield ~ block + N*P*K),
#           whose N:P:K is confounded with blocks and so aliased.
#   tg_*    ToothGrowth (src/library/datasets/man/ToothGrowth.Rd) with dose
#           numeric: a slope per supplement (supp + supp:dose), and dose - 1.
#   pr8049  tests/reg-tests-2.R:1574, "add1.lm and drop.lm did not know about
#           offsets": set.seed(2), anova(lm(y ~ 1, offset = 1:10),
#           lm(y ~ z, offset = 1:10)).
#   rank0_* tests/reg-tests-2.R:942, "examples of 0-rank models": lm(y ~ 0)
#           and lm(y ~ x + 0) with x all zero.  The test draws y <- rnorm(10)
#           with no seed of its own; set.seed(1) here.

options(digits = 17)

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  if (is.infinite(v)) return(if (v > 0) "9**9**9" else "-9**9**9")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")
str_ <- function(x) paste0("[", paste0("'", x, "'", collapse = ", "), "]")
col <- function(v) if (is.numeric(v)) num(v) else str_(as.character(v))

cat("my %DATA = (\n")
data_out <- function(name, df) {
  cat(sprintf("  %s => {\n", name))
  for (nm in names(df)) cat(sprintf("    '%s' => %s,\n", nm, col(df[[nm]])))
  cat("  },\n")
}
EXP <- list()
# A single-model table, by term: [Df, Sum Sq, Mean Sq, F value, Pr(>F)].
one <- function(key, fit) {
  a <- anova(fit)
  EXP[[key]] <<- list(kind = "one", rows = lapply(seq_len(nrow(a)), function(i)
    list(term = rownames(a)[i], v = unlist(a[i, ]))))
}
# A comparison table, column by column.
cmp <- function(key, a) {
  a <- as.data.frame(a)
  EXP[[key]] <<- list(kind = "cmp", cols = lapply(a, as.numeric))
}

L <- LifeCycleSavings
data_out("lcs", L)
one("lcs_fit", lm(sr ~ pop15 + pop75 + dpi + ddpi, data = L))
one("lcs_dot", lm(sr ~ ddpi + dpi + pop15 + pop75, data = L))
fit0 <- lm(sr ~ 1, data = L)
fit1 <- update(fit0, . ~ . + pop15)
fit2 <- update(fit1, . ~ . + pop75)
fit3 <- update(fit2, . ~ . + dpi)
fit4 <- update(fit3, . ~ . + ddpi)
cmp("lcs_chain", anova(fit0, fit1, fit2, fit3, fit4, test = "F"))
cmp("lcs_unconventional", anova(fit4, fit2, fit0, test = "F"))
# Not nested: one more parameter and a larger RSS, so F < 0, which
# stat.anova() reports as NA rather than as p = 1.
cmp("lcs_negF", anova(lm(sr ~ pop15, data = L), lm(sr ~ dpi + ddpi, data = L)))

W <- warpbreaks
W$wool <- as.character(W$wool); W$tension <- as.character(W$tension)
data_out("wb", W)
W$tension <- factor(W$tension, levels = c("L", "M", "H"))  # the data set's own level order
one("wb_fm1",        lm(breaks ~ wool*tension, data = W))
one("wb_nested",     lm(breaks ~ wool + wool:tension, data = W))
one("wb_cells",      lm(breaks ~ wool:tension, data = W))
one("wb_late_mains", lm(breaks ~ tension:wool + wool + tension, data = W))
one("wb_noint",      lm(breaks ~ 0 + wool + tension, data = W))

N <- npk
N$block <- paste0("b", N$block)
for (v in c("N", "P", "K")) N[[v]] <- paste0(v, N[[v]])
data_out("npk", N)
one("npk", lm(yield ~ block + N*P*K, data = N))

TG <- ToothGrowth
TG$supp <- as.character(TG$supp)
data_out("tg", TG)
one("tg_slopes", lm(len ~ supp + supp:dose, data = TG))
one("tg_noint",  lm(len ~ dose - 1, data = TG))

set.seed(2)
y <- rnorm(10)
z <- 1:10
data_out("pr8049", data.frame(y = y, z = z))
cmp("pr8049", anova(lm(y ~ 1, offset = z), lm(y ~ z, offset = z)))

set.seed(1)
y <- rnorm(10)
x <- rep(0, 10)
data_out("rank0", data.frame(y = y, x = x))
one("rank0_empty", lm(y ~ 0))
one("rank0_zero",  lm(y ~ x + 0))
cat(");\n\n")

cat("my %EXPECT = (\n")
for (k in names(EXP)) {
  e <- EXP[[k]]
  if (e$kind == "one") {
    cat(sprintf("  %s => { one => {\n", k))
    for (r in e$rows) cat(sprintf("    '%s' => %s,\n", trimws(r$term), num(r$v)))
    cat("  } },\n")
  } else {
    cat(sprintf("  %s => { cmp => {\n", k))
    for (nm in names(e$cols)) cat(sprintf("    '%s' => %s,\n", nm, num(e$cols[[nm]])))
    cat("  } },\n")
  }
}
cat(");\n")
