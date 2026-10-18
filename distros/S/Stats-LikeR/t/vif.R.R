# Regenerates the frozen tables in t/vif.R.t.
#   Rscript t/vif.R.R > /tmp/vif.txt
# then paste each section over the one of the same name in the test.  The test
# never runs this; it reads the literals that were pasted from it.
#
# Written against R 4.6.1 (2026-06-24), car 3.1-5 and carData 3.0-6, which
# are installed here; every expected value is car::vif() itself at its
# default type = "terms".  The cases:
#
#   Duncan       car's own man/vif.Rd examples: prestige ~ income +
#                education, then + type (a 3-level factor, so a GVIF table),
#                then (income + education)*type, which the test writes out
#                as its expansion because this module's parser has no
#                parentheses in a formula
#   mtcars       the three formula shapes TODO.md listed as failing through
#                0.3217 -- an interaction, a removed term ('- x3' for a term
#                that is not there, as car's case had it, and one that is),
#                and '.' -- plus a model with no intercept
#   warpbreaks   breaks ~ wool * tension (?warpbreaks): factors crossed, so
#                every term past wool is a multi-df GVIF
#   airquality   Ozone ~ Solar.R + Wind + Temp: Ozone and Solar.R both have
#                NAs, and car's model drops a row missing either
#
# statsmodels 0.14.6's test_outliers_influence.py::test_reset_stata pins a
# sixth, written into the test by hand: Stata's VIF of 16.4394 for urban,
# regressed on the other six statecrime columns with no constant.
options(digits = 17, scipen = 500)
suppressMessages(library(car))

num <- function(v) paste(ifelse(is.na(v), "undef", sprintf("%.17g", v)), collapse = ", ")
str <- function(v) paste0("'", as.character(v), "'", collapse = ", ")
col <- function(d, nm) if (is.numeric(d[[nm]])) num(d[[nm]]) else str(d[[nm]])

frames <- list(
    Duncan     = Duncan[, c("type", "income", "education", "prestige")],
    mtcars     = mtcars[, c("mpg", "wt", "hp", "disp", "qsec")],
    warpbreaks = warpbreaks,
    airquality = airquality[, c("Ozone", "Solar.R", "Wind", "Temp")]
)

cat("== %DATA\n")
for (f in names(frames)) {
    d <- frames[[f]]
    cat(sprintf("\t%s => {\n", f))
    for (nm in names(d)) cat(sprintf("\t\t'%s' => [ %s ],\n", nm, col(d, nm)))
    cat("\t},\n")
}

# [ frame, formula as R reads it, formula as the test passes it ]
cases <- list(
    c("Duncan", "prestige ~ income + education", NA),
    c("Duncan", "prestige ~ income + education + type", NA),
    c("Duncan", "prestige ~ (income + education)*type",
                "prestige ~ income + education + type + income:type + education:type"),
    c("mtcars", "mpg ~ wt*hp + disp", NA),
    c("mtcars", "mpg ~ wt + hp - disp", NA),
    c("mtcars", "mpg ~ wt + hp + disp + qsec - qsec", NA),
    c("mtcars", "mpg ~ .", NA),
    c("mtcars", "mpg ~ wt + hp + disp - 1", NA),
    c("warpbreaks", "breaks ~ wool * tension", NA),
    c("airquality", "Ozone ~ Solar.R + Wind + Temp", NA)
)

# [ frame, formula, warns, rows used, [ term, GVIF, Df ] ... ]: warns is
# 'interactions' or 'intercept' for the message car gives, '' for none
cat("== @R_CASES\n")
for (cs in cases) {
    d <- frames[[cs[1]]]
    msgs <- character(0)
    fit <- lm(as.formula(cs[2]), data = d)
    v <- withCallingHandlers(vif(fit),
        message = function(m) { msgs <<- c(msgs, "interactions"); invokeRestart("muffleMessage") },
        warning = function(w) { msgs <<- c(msgs, "intercept"); invokeRestart("muffleWarning") })
    if (is.matrix(v)) { g <- v[, 1]; df <- v[, 2] } else { g <- v; df <- rep(1, length(v)) }
    terms <- sprintf("[ '%s', %.17g, %d ]", names(g), g, as.integer(df))
    cat(sprintf("\t[ '%s', '%s', '%s', %d, %s ],\n", cs[1],
                if (is.na(cs[3])) cs[2] else cs[3], paste(msgs, collapse = ","),
                nobs(fit), paste(terms, collapse = ", ")))
}

# statsmodels' variance_inflation_factor() regresses one column on the others
# as given, here with no constant, so its VIF is 1 / (1 - R^2) with R^2
# uncentred, which is what summary.lm() reports for a model without an
# intercept.  The data are statsmodels' own statecrime.csv.
cat("== statecrime\n")
sc <- read.csv(file.path("/home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages",
                         "statsmodels/datasets/statecrime/statecrime.csv"))
fit <- lm(urban ~ violent + murder + hs_grad + poverty + single + white - 1, data = sc)
cat(sprintf("# urban: %.17g (Stata, as pinned: 16.4394)\n", 1 / (1 - summary(fit)$r.squared)))

# car's two refusals, for the messages vif() mirrors
cat("== refusals\n")
for (f in c("mpg ~ wt", "mpg ~ wt + hp + I(2 * wt)")) {
    e <- tryCatch(vif(lm(as.formula(f), data = mtcars)), error = function(e) conditionMessage(e))
    cat(sprintf("# %s: %s\n", f, e))
}
