# Generator for the frozen expected values in t/aov.R.t.
#
# Re-run with
#
#     Rscript t/aov.R.R > /tmp/aov.pl
#
# and paste the printed %DATA and %EXPECT blocks over the ones in the .t file.
# The test itself never runs this script, or R.
#
# Produced with R 4.6.1 (MASS 7.3 for oats).  Every model is one of R's own,
# from its documentation and regression tests:
#
#   npk_full  src/library/stats/man/aov.Rd: aov(yield ~ block + N*P*K, npk),
#             whose N:P:K is confounded with blocks and so aliased.  The Rd
#             sets Helmert contrasts; the module has treatment contrasts only,
#             so the coefficients here are R's under its default
#             contr.treatment.  The table does not depend on the coding.
#   npk_npk   aov.Rd and tests/reg-tests-3.R:101 (PR#13505):
#             aov(yield ~ block + N * P + K, npk).
#   wb        src/library/datasets/man/warpbreaks.Rd: breaks ~ wool*tension.
#   br        tests/reg-tests-1b.R:2081: warpbreaks with every tension "M"
#             response set to NA, aov(breaks ~ wool + tension).  R drops the
#             now-empty level M; the module keeps it, as an aliased column.
#
# wb and br re-level wool and tension alphabetically (warpbreaks has tension
# L, M, H), since the module orders a column of strings that way, and so has
# reference level H where warpbreaks has L.  Coefficients are
# coef(fit, complete = TRUE), lm()'s convention: coef.aov() leaves out an
# aliased coefficient, and the module reports it as NaN.
#   oats      tests/reg-tests-3.R:40 (PR#7829): aov(Y ~ B + V + N + V:N,
#             data = oats[-1,]), MASS's oats without its first row; the row
#             names are R's, "2".."72".
#   tg_slope  ToothGrowth (src/library/datasets/man/ToothGrowth.Rd) with dose
#             numeric, len ~ supp + supp:dose: a slope per supplement.
#   tg_off    the same data, len ~ supp + offset(dose).
#   dd, dd0   tests/reg-tests-2.R:3016 (PR#16437): num ~ F and num ~ 0 + F.
#   pg, pg_n  src/library/datasets/man/PlantGrowth.Rd's weight by group, as the
#             no-formula form stacks it: stack() of a named list, groups in
#             sorted order, then aov(values ~ ind).  pg_n renames the groups
#             "1", "10" and "2", which look like numbers and are still a factor.
#
# Factors are written as strings that do not look like numbers (npk's block
# "b1".."b6", N "N0"/"N1"), since a column of numbers is a covariate here.
#
# group.stats is, per factor of the model, tapply(y, f, mean) and table(f)
# over the rows the model was fitted on.

options(digits = 17)
suppressMessages(library(MASS))

fmt1 <- function(v) {
  if (is.na(v)) return("undef")
  for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
  s
}
num <- function(x) paste0("[", paste(vapply(x, fmt1, ""), collapse = ", "), "]")
str_ <- function(x) paste0("[", paste0("'", x, "'", collapse = ", "), "]")
col <- function(v) if (is.numeric(v)) num(v) else str_(as.character(v))
named <- function(x) paste0("{", paste0("'", names(x), "' => ", vapply(unname(x), fmt1, ""), collapse = ", "), "}")

DATA <- list()
cat("my %DATA = (\n")
data_out <- function(name, df) {
  cat(sprintf("  %s => {\n", name))
  for (nm in names(df)) cat(sprintf("    '%s' => %s,\n", nm, col(df[[nm]])))
  cat("  },\n")
}
groups_out <- function(name, lst) {
  cat(sprintf("  %s => {\n", name))
  for (nm in names(lst)) cat(sprintf("    '%s' => %s,\n", nm, col(lst[[nm]])))
  cat("  },\n")
}

EXP <- list()
# rename: R's coefficient prefix -> the module's (the stacked form's ind -> Group)
fit_out <- function(key, data, formula, fit, y, factors, rename = NULL) {
  a <- anova(fit)
  rn <- rownames(a)
  if (!is.null(rename)) rn[rn == rename[1]] <- rename[2]
  tab <- lapply(seq_len(nrow(a)), function(i) list(term = rn[i], v = unlist(a[i, ])))
  co <- coef(fit, complete = TRUE)   # coef.aov() drops aliased coefficients; lm's keep them as NA
  names(co)[names(co) == "(Intercept)"] <- "Intercept"
  if (!is.null(rename)) names(co) <- sub(paste0("^", rename[1]), rename[2], names(co))
  mf <- model.frame(fit)
  gs <- lapply(factors, function(f) {
    fv <- if (!is.null(rename) && f == rename[2]) mf[[rename[1]]] else mf[[f]]
    yv <- model.response(mf)
    list(mean = tapply(yv, fv, mean), size = c(table(fv)))
  })
  names(gs) <- factors
  EXP[[key]] <<- list(data = data, formula = formula, tab = tab, coef = co,
                      fitted = fitted(fit), gs = gs)
}

np <- npk
np$block <- paste0("b", np$block)
np$N <- paste0("N", np$N); np$P <- paste0("P", np$P); np$K <- paste0("K", np$K)
data_out("npk", np)
fit_out("npk_full", "npk", "yield ~ block + N*P*K",
        aov(yield ~ block + N*P*K, np), "yield", c("block", "N", "P", "K"))
fit_out("npk_npk", "npk", "yield ~ block + N * P + K",
        aov(yield ~ block + N * P + K, np), "yield", c("block", "N", "P", "K"))

# Levels in sorted order, as the module orders a column of strings; warpbreaks
# itself has tension's in the order L, M, H.
wb <- warpbreaks
wb$wool <- factor(as.character(wb$wool)); wb$tension <- factor(as.character(wb$tension))
data_out("wb", wb)
fit_out("wb", "wb", "breaks ~ wool*tension",
        aov(breaks ~ wool*tension, wb), "breaks", c("wool", "tension"))

# lm() builds its model frame with drop.unused.levels = TRUE, so R drops M
# once its rows are gone; the module keeps it (see %DIVERGE in t/aov.R.t).
br <- wb
br[br$tension == "M", "breaks"] <- NA
data_out("br", br)
fit_out("br", "br", "breaks ~ wool + tension",
        aov(breaks ~ wool + tension, br), "breaks", c("wool", "tension"))

oa <- oats[-1, ]
oa$B <- as.character(oa$B); oa$V <- as.character(oa$V); oa$N <- as.character(oa$N)
oa_out <- oa
oa_out[["row_names"]] <- rownames(oa)
data_out("oats", oa_out)
fit_out("oats", "oats", "Y ~ B + V + N + V:N",
        aov(Y ~ B + V + N + V:N, oa), "Y", c("B", "V", "N"))

data_out("tg", ToothGrowth)
fit_out("tg_slope", "tg", "len ~ supp + supp:dose",
        aov(len ~ supp + supp:dose, ToothGrowth), "len", "supp")
fit_out("tg_off", "tg", "len ~ supp + offset(dose)",
        aov(len ~ supp + offset(dose), ToothGrowth), "len", "supp")

dd <- data.frame(F = rep(c("A", "B", "C"), each = 3), num = 1:9)
data_out("dd", dd)
fit_out("dd", "dd", "num ~ F", aov(num ~ F, dd), "num", "F")
fit_out("dd0", "dd", "num ~ 0 + F", aov(num ~ 0 + F, dd), "num", "F")

pg <- split(PlantGrowth$weight, as.character(PlantGrowth$group))
pg <- pg[sort(names(pg), method = "radix")]
groups_out("pg", pg)
st <- stack(pg)
fit_out("pg", "pg", NULL, aov(values ~ ind, st), "values", "Group", c("ind", "Group"))
pgn <- setNames(pg, c("1", "10", "2"))
groups_out("pg_n", pgn)
st <- stack(pgn)
fit_out("pg_n", "pg_n", NULL, aov(values ~ ind, st), "values", "Group", c("ind", "Group"))
cat(");\n\n")

cat("my %EXPECT = (\n")
for (key in names(EXP)) {
  e <- EXP[[key]]
  cat(sprintf("  %s => {\n    data => '%s',\n    formula => %s,\n", key, e$data,
              if (is.null(e$formula)) "undef" else paste0("'", e$formula, "'")))
  cat("    table => {\n")
  for (r in e$tab) cat(sprintf("      '%s' => %s,\n", r$term, num(r$v)))
  cat("    },\n")
  cat(sprintf("    coef => %s,\n", named(e$coef)))
  cat(sprintf("    fitted => %s,\n", named(e$fitted)))
  cat("    gs => {\n")
  for (f in names(e$gs))
    cat(sprintf("      '%s' => { mean => %s, size => %s },\n", f,
                named(e$gs[[f]]$mean), named(e$gs[[f]]$size)))
  cat("    },\n  },\n")
}
cat(");\n")
