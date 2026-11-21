# Regenerates the frozen tables in t/formula_groups.R.t.
#   Rscript t/formula_groups.R.R > /tmp/formula_groups.txt
# then paste each "== name" section over the one of the same name in the test.
# The test never runs this; it reads the literals that were pasted from it.
#
# Written against R 4.6.1 (2026-06-24), lme4 2.0-6, survival 3.8-12, survey
# 4.5, ivreg 0.6-8, pscl 1.5.9 and countreg 0.3-0, installed here.  Every value
# is R's own, at options(digits = 17).
#
# The formulas are R's formula algebra for a parenthesised group of terms, in
# the forms R's documentation and regression tests give:
#   src/library/stats/man/formula.Rd   (a+b+c)^2, (a+b+c)^2 - a:b, a/b,
#                                      a %in% b, y ~ a + log(x)
#   tests/reg-tests-2.R:707            lm(y ~ (A + B) : (U + V) - 1)
#   car's man/vif.Rd                   (income + education)*type
# and the same groups through every function that reads a formula:
# lm, glm, aov, anova, zerotrunc, hurdle, svyglm, ivreg, lmer, coxph, vif.
options(digits = 17, scipen = 500)
suppressMessages({
    library(survival); library(lme4); library(survey); library(ivreg)
    library(pscl); library(countreg); library(car)
})

num <- function(v) paste(ifelse(is.na(v), "undef", sprintf("%.17g", v)), collapse = ", ")
str <- function(v) if (length(v)) paste0("'", as.character(v), "'", collapse = ", ") else ""
col <- function(d, nm) if (is.numeric(d[[nm]])) num(d[[nm]]) else str(d[[nm]])
frame_out <- function(name, d) {
    cat(sprintf("\t%s => {\n", name))
    for (nm in names(d)) cat(sprintf("\t\t'%s' => [ %s ],\n", nm, col(d, nm)))
    cat("\t},\n")
}
# R's coefficient name, in this module's spelling
nm <- function(x) ifelse(x == "(Intercept)", "Intercept", x)
coefs <- function(b) {
    b <- b[!is.na(b)]
    paste(sprintf("[ '%s', %.17g ]", nm(names(b)), b), collapse = ", ")
}

# mtcars, with cyl and am read as strings (so as factors, as R reads them)
d <- mtcars[, c("mpg", "wt", "hp", "disp", "qsec", "cyl", "am", "carb", "gear")]
d$cyl <- factor(paste0("c", d$cyl))
d$am  <- factor(paste0("m", d$am))
d$ncarb <- d$carb - 1          # a count with zeros, for hurdle()
d$w <- rep(c(1, 2, 3, 4), length.out = nrow(d))   # survey weights
dd <- d[, c("mpg", "disp", "hp", "wt")]           # '.' is these three, in the sorted order the module expands it in

# the first six subjects of lme4's sleepstudy, with a between-subject factor
ss <- droplevels(subset(sleepstudy, Subject %in% c("308", "309", "310", "330", "331", "333")))
ss$Subject <- as.character(ss$Subject)
ss$grp <- ifelse(ss$Subject %in% c("308", "309", "310"), "g1", "g2")

# survival's lung, the first 70 complete rows of the columns used
lg <- na.omit(lung[, c("time", "status", "age", "sex", "ph.karno")])[1:70, ]

cat("== %DATA\n")
frame_out("cars", d); frame_out("dd", dd); frame_out("sleep", ss); frame_out("lung", lg)

# ---- lm: formula, R's term labels, R's coefficients ----
lm_formulas <- c(
    "mpg ~ (wt + hp)*disp",
    "mpg ~ wt*(hp + disp)",
    "mpg ~ (wt + hp):disp",
    "mpg ~ (wt + hp + disp)^2",
    "mpg ~ (wt + hp + disp + qsec)^3",
    "mpg ~ (wt + hp + disp)^2 - wt:hp",
    "mpg ~ (wt + hp + disp)^2 - (wt:hp + hp:disp)",
    "mpg ~ (wt + hp)^3",
    "mpg ~ (wt + hp)/disp",
    "mpg ~ wt/(hp + disp)",
    "mpg ~ wt/hp/disp",
    "mpg ~ wt + hp %in% wt",
    "mpg ~ (wt + hp) %in% disp",
    "mpg ~ wt*hp - (wt + hp)",
    "mpg ~ wt + hp + disp - (hp + disp)",
    "mpg ~ wt*hp*disp - wt:hp - hp:disp",
    "mpg ~ ((wt + hp) + disp)^2",
    "mpg ~ wt + (hp + disp)*qsec",
    "mpg ~ (wt + hp)*(disp + qsec)",
    "mpg ~ (wt + hp):(disp + qsec)",
    "mpg ~ (wt + hp) + (disp + qsec):hp",
    "mpg ~ (log(wt) + I(hp^2))*disp",
    "mpg ~ (log(wt + 1) + hp)^2",
    "mpg ~ (wt + I(hp/disp))*qsec",
    "mpg ~ (cyl + wt)*hp",
    "mpg ~ (cyl + am)^2",
    "mpg ~ cyl*(wt + am)",
    "mpg ~ hp + wt:hp",
    "mpg ~ wt:hp + hp",
    "mpg ~ (wt + hp)*disp - 1",
    "mpg ~ -1 + (wt + hp)*disp",
    "mpg ~ (wt + hp)*disp + 0",
    "mpg ~ (wt)",
    "mpg ~ ((wt)) + (hp)",
    "mpg ~ +wt + hp",
    "mpg ~ (wt + hp)^2.9",
    "mpg ~ wt^2 + hp",
    "mpg ~ (wt + hp)*disp - 0",
    "mpg ~ log(wt + hp)*disp"
)
cat("== @LM_CASES\n")
cat("# [ formula, [ R's term labels ], [ coefficient, value ] ... ]\n")
worst_n <- 0
for (f in lm_formulas) {
    fit <- lm(as.formula(f), data = d)
    labs <- attr(terms(fit), "term.labels")
    cat(sprintf("\t[ '%s', [ %s ], %s ],\n", f, str(labs), coefs(coef(fit))))
}

# '.' stands for every other column, in a group too
dot_formulas <- c("mpg ~ (.)^2", "mpg ~ .^2", "mpg ~ (. - hp)^2", "mpg ~ . - (hp + wt) + hp:wt",
                  "mpg ~ (.)*disp")
cat("== @DOT_CASES\n")
cat("# [ formula, [ R's term labels ], [ coefficient, value ] ... ], on %DATA's dd\n")
for (f in dot_formulas) {
    fit <- lm(as.formula(f), data = dd)
    cat(sprintf("\t[ '%s', [ %s ], %s ],\n", f, str(attr(terms(fit), "term.labels")), coefs(coef(fit))))
}

# ---- every function that reads a formula ----
cat("== @GLM_CASES\n")
cat("# [ formula, family, [ coefficient, value ] ... ]\n")
for (cs in list(c("carb ~ (wt + hp)*disp", "poisson"), c("carb ~ (wt + hp)*cyl", "poisson"),
                c("mpg ~ (wt + hp)^2", "gaussian"))) {
    fit <- glm(as.formula(cs[1]), family = get(cs[2])(), data = d)
    cat(sprintf("\t[ '%s', '%s', %s ],\n", cs[1], cs[2], coefs(coef(fit))))
}

cat("== @AOV_CASES\n")
cat("# [ formula, [ term, Df, Sum Sq, F value ] ..., Residuals Df, Sum Sq ]; aov() and anova() both\n")
for (f in c("mpg ~ (cyl + am)^2", "mpg ~ cyl*(wt + am)", "mpg ~ (wt + hp)*disp", "mpg ~ (cyl + am + wt)^2 - cyl:am")) {
    tb <- anova(lm(as.formula(f), data = d))
    n <- nrow(tb)
    rows <- sprintf("[ '%s', %d, %.17g, %.17g ]", rownames(tb)[-n], as.integer(tb$Df[-n]), tb[["Sum Sq"]][-n], tb[["F value"]][-n])
    cat(sprintf("\t[ '%s', %s, %d, %.17g ],\n", f, paste(rows, collapse = ", "), as.integer(tb$Df[n]), tb[["Sum Sq"]][n]))
}

cat("== @ZT_CASES\n")
cat("# [ formula, dist, [ coefficient, value ] ... ]: zerotrunc() on carb, which has no zeros\n")
for (cs in list(c("carb ~ (wt + hp)*cyl", "poisson"), c("carb ~ (wt + hp)^2", "poisson"))) {
    fit <- zerotrunc(as.formula(cs[1]), data = d, dist = cs[2])
    cat(sprintf("\t[ '%s', '%s', %s ],\n", cs[1], cs[2], coefs(coef(fit))))
}

cat("== @HURDLE_CASES\n")
cat("# [ formula, [ count coefficient, value ] ..., [ zero coefficient, value ] ... ], poisson both parts\n")
for (f in c("ncarb ~ (wt + hp)*am | wt + hp", "ncarb ~ (wt + hp)^2 | (wt + hp)^2")) {
    fit <- hurdle(as.formula(f), data = d, dist = "poisson", zero.dist = "binomial")
    cf <- coef(fit)
    cat(sprintf("\t[ '%s', [ %s ], [ %s ] ],\n", f, coefs(cf[grepl("^count_", names(cf))]), coefs(cf[grepl("^zero_", names(cf))])))
}

cat("== @SVYGLM_CASES\n")
cat("# [ formula, family, [ coefficient, value ] ... ], svydesign(ids = ~1, weights = ~w)\n")
des <- svydesign(ids = ~1, weights = ~w, data = d)
for (cs in list(c("mpg ~ (wt + hp)*am", "gaussian"), c("carb ~ (wt + hp)^2", "poisson"))) {
    fit <- svyglm(as.formula(cs[1]), design = des, family = get(cs[2])())
    cat(sprintf("\t[ '%s', '%s', %s ],\n", cs[1], cs[2], coefs(coef(fit))))
}

cat("== @IVREG_CASES\n")
cat("# [ formula, [ coefficient, value ] ... ]\n")
for (f in c("mpg ~ (wt + hp)*am | (qsec + disp + hp)*am", "mpg ~ (wt + hp)^2 | (qsec + disp + hp)^2")) {
    fit <- ivreg(as.formula(f), data = d)
    cat(sprintf("\t[ '%s', %s ],\n", f, coefs(coef(fit))))
}

cat("== @LMER_CASES\n")
cat("# [ formula, [ fixed effect, value ] ... ], REML\n")
for (f in c("Reaction ~ (Days + grp)^2 + (1 | Subject)", "Reaction ~ (Days + I(Days^2))*grp + (1 | Subject)")) {
    fit <- lmer(as.formula(f), data = ss)
    cat(sprintf("\t[ '%s', %s ],\n", f, coefs(fixef(fit))))
}

cat("== @COXPH_CASES\n")
cat("# [ formula, [ coefficient, value ] ... ]\n")
for (f in c("Surv(time, status) ~ (age + sex)*ph.karno", "Surv(time, status) ~ (age + sex + ph.karno)^2")) {
    fit <- coxph(as.formula(f), data = lg)
    cat(sprintf("\t[ '%s', %s ],\n", f, coefs(coef(fit))))
}

# ---- R's regression test, tests/reg-tests-2.R:707 ----
# set.seed(1); y <- rnorm(18); lm(y ~ (A + B) : (U + V) - 1)
cat("== %REG2\n")
U <- gl(3, 6, 18, labels = letters[1:3]); V <- gl(3, 2, 18, labels = letters[1:3])
A <- rep(c(0, 1), 9); B <- rep(c(1, 0), 9)
set.seed(1); y <- rnorm(18)
r2 <- data.frame(y = y, A = A, B = B, U = as.character(U), V = as.character(V))
frame_out("reg2", r2)
fit <- lm(y ~ (A + B) : (U + V) - 1)
cat(sprintf("# labels: %s\n", paste(attr(terms(fit), "term.labels"), collapse = " | ")))
cat(sprintf("\t[ 'y ~ (A + B) : (U + V) - 1', [ %s ], %s ],\n", str(attr(terms(fit), "term.labels")), coefs(coef(fit))))

# ---- terms() alone: labels for forms the fit cannot take ----
cat("== @LABELS_ONLY\n")
cat("# [ formula, [ R's term labels ] ], terms(f)\n")
for (f in c("y ~ (a + b + c)^2", "y ~ (a + b + c)^2 - a:b", "y ~ a + b + c + b:c + a:c", "y ~ (a + b + c)*(a + b + c)", "y ~ (a + b)*a",
            "y ~ a %in% b", "y ~ a:b:c %in% d", "y ~ a*b %in% c", "y ~ a/b/c", "y ~ (a + b)/c", "y ~ (a + b)^2:c",
            "y ~ -(a + b)", "y ~ a + b + c - (a + b)", "y ~ (a + b + c + d)^2 - (a + b)^2",
            "y ~ a + log(x) + (b + c)^2", "y ~ (a + b)^2 + (c + d)^2", "y ~ b + a:b", "y ~ a:c + b + b:c")) {
    cat(sprintf("\t[ '%s', [ %s ] ],\n", f, str(attr(terms(as.formula(f)), "term.labels"))))
}

# ---- the forms R refuses, with R's message ----
cat("== refusals\n")
for (f in c("y ~ (a + b)^1", "y ~ a^0", "y ~ a^b", "y ~ (a + b)^2^2", "y ~ (a + b")) {
    e <- tryCatch({ terms(as.formula(f)); "accepted" }, error = function(e) conditionMessage(e))
    cat(sprintf("# %s: %s\n", f, e))
}
