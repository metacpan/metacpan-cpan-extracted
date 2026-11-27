# Generator for t/table_one.R.datasets.t.  Run with
#     Rscript t/table_one.R.datasets.R > /some/scratch/file
# and paste the output into the .t (the data block and the @CASES block).
# R 4.6.2 datasets: mtcars, sleep, iris, ToothGrowth, airquality.  The R
# tableone package is not installed, so nothing here is tableone's own output;
# each expectation is what base R computes for the statistic table_one
# documents (README): per-group mean (sd) and n (percent) strings, and the
# group-comparison p-value from
#   2 groups, continuous      t.test(x ~ g)                (Welch; R default)
#   2 groups, nonparametric   wilcox.test(x ~ g)           (R default)
#   >2 groups, continuous     summary(aov(x ~ factor(g)))  (one-way F)
#   >2 groups, nonparametric  kruskal.test(x ~ g)
#   categorical               chisq.test(table(level, g))  (R default, so Yates
#                             on a 2 x 2)
# Missing values are dropped per variable, as table_one drops undef.
options(digits = 17, warn = -1)
pl <- function(v) {
	if (is.factor(v)) v <- as.character(v)
	paste0("[", paste(ifelse(is.na(v), "undef", if (is.character(v)) sprintf("'%s'", v) else format(v, digits = 17, trim = TRUE)), collapse = ", "), "]")
}
frame <- function(name, df, cols) {
	cat(sprintf("my %%%s = (\n", name))
	for (c in cols) cat(sprintf("\t'%s' => %s,\n", c, pl(df[[c]])))
	cat(");\n")
}
frame("MTCARS", mtcars, c("mpg", "wt", "cyl", "vs", "am", "gear"))
frame("SLEEP", sleep, c("extra", "group"))
frame("IRIS", iris, c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width", "Species"))
frame("TOOTH", ToothGrowth, c("len", "supp", "dose"))
frame("AIR", airquality, c("Ozone", "Temp", "Month"))
cat("# [data, by, var, type, nonpar, test, p, overall, {group => string}]\n")
fmt <- function(x, d = 2) sprintf("%.*f (%.*f)", d, mean(x, na.rm = TRUE), d, sd(x, na.rm = TRUE))
cont <- function(dn, df, by, var, nonpar = FALSE, digits = 2) {
	g <- factor(df[[by]]); x <- df[[var]]
	ok <- !is.na(g) & !is.na(x)
	k <- nlevels(droplevels(g[ok]))
	if (k == 2) {
		p <- if (nonpar) wilcox.test(x[ok] ~ g[ok])$p.value else t.test(x[ok] ~ g[ok])$p.value
		tn <- if (nonpar) "wilcoxon" else "t-test"
	} else {
		p <- if (nonpar) kruskal.test(x[ok] ~ g[ok])$p.value
		     else summary(aov(x[ok] ~ factor(g[ok])))[[1]][["Pr(>F)"]][1]
		tn <- if (nonpar) "kruskal-wallis" else "anova"
	}
	cells <- sapply(levels(g), function(l) sprintf("'%s' => '%s'", l, fmt(x[ok & g == l], digits)))
	cat(sprintf("\t[ '%s', '%s', '%s', 'continuous', %d, '%s', %s, '%s', { %s } ],\n",
		dn, by, var, nonpar, tn, format(p, digits = 17), fmt(x[!is.na(x)], digits), paste(cells, collapse = ", ")))
}
cat1 <- function(dn, df, by, var) {
	g <- factor(df[[by]]); v <- factor(df[[var]], levels = sort(unique(df[[var]])))
	tb <- table(v, g)
	p <- chisq.test(tb)$p.value
	cat(sprintf("\t[ '%s', '%s', '%s', 'categorical', 0, 'chi-squared', %s, undef, {} ],\n",
		dn, by, var, format(p, digits = 17)))
	for (l in levels(v)) {
		cells <- sapply(levels(g), function(gg) sprintf("'%s' => '%d (%.1f%%)'", gg, tb[l, gg], 100 * tb[l, gg] / sum(tb[, gg])))
		cat(sprintf("\t[ '%s', '%s', '%s', 'level', 0, '', undef, '%d (%.1f%%)', { %s } ],\n",
			dn, by, var, sum(tb[l, ]), 100 * sum(tb[l, ]) / sum(tb), paste(cells, collapse = ", ")))
	}
}
cat("my @CASES = (\n")
cont("MTCARS", mtcars, "am", "mpg"); cont("MTCARS", mtcars, "am", "wt")
cont("MTCARS", mtcars, "am", "mpg", TRUE)
cont("MTCARS", mtcars, "cyl", "mpg"); cont("MTCARS", mtcars, "cyl", "wt", TRUE)
cont("SLEEP", sleep, "group", "extra"); cont("SLEEP", sleep, "group", "extra", TRUE)
for (v in c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width")) {
	cont("IRIS", iris, "Species", v); cont("IRIS", iris, "Species", v, TRUE) }
cont("TOOTH", ToothGrowth, "supp", "len")
cont("AIR", airquality, "Month", "Ozone"); cont("AIR", airquality, "Month", "Temp", TRUE)
cat1("MTCARS", mtcars, "am", "cyl"); cat1("MTCARS", mtcars, "am", "vs")
cat1("MTCARS", mtcars, "cyl", "gear"); cat1("TOOTH", ToothGrowth, "supp", "dose")
cat(");\n")
