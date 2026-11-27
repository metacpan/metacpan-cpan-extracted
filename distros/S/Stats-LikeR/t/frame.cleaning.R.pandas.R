# Generator for the R half of the frozen expectations in
# t/frame.cleaning.R.pandas.t (drop_duplicates, dropna, value_counts).
#
# Re-run with
#
#     Rscript t/frame.cleaning.R.pandas.R
#
# and compare its output with the %R hash in the .t file (each line below is one
# hash entry, key => value).  The test never
# runs this, or R.
#
# R 4.6.1 sources (/home/con/Scripts/r-source), run under R 4.6.2:
#   src/library/base/man/duplicated.Rd   \examples (x, warpbreaks, fromLast)
#   tests/reg-tests-1a.R:264             duplicated(iris)[143]
#   tests/reg-tests-1d.R:2130            PR#17485, d <- data.frame(f=gl(3,5), i=1:3)
#   tests/reg-tests-1d.R:1602            PR#17369, 0.3 + 0.6 versus 0.9
#   src/library/stats/man/na.fail.Rd     \examples (na.omit(DF))
#   src/library/stats/man/complete.cases.Rd  \examples (airquality)
#   src/library/base/man/table.Rd        \examples (table of one variable)
options(digits = 17)
q <- function(v) {
	if (is.na(v)) return("undef")
	if (is.character(v) || is.factor(v)) return(sprintf("'%s'", as.character(v)))
	if (is.logical(v)) return(if (v) "'TRUE'" else "'FALSE'")
	if (is.infinite(v)) return(if (v > 0) "9**9**9" else "-9**9**9")
	sprintf("%.17g", v)
}
vec <- function(x) paste0("[", paste(vapply(x, q, ""), collapse = ", "), "]")
idx <- function(l) paste0("[", paste(which(l) - 1L, collapse = ", "), "]")
e <- function(key, val) cat(sprintf("\t'%s' => %s,\n", key, val))
cat("my %R = (\n")
x <- c(9:20, 1:5, 3:7, 0:8)
e("x", vec(x))
e("x first", idx(!duplicated(x)))
e("x last", idx(!duplicated(x, fromLast = TRUE)))
e("x none", idx(!duplicated(x) & !duplicated(x, fromLast = TRUE)))
wb <- warpbreaks
for (v in names(wb)) e(paste0("warpbreaks$", v), vec(wb[[v]]))
e("warpbreaks first", idx(!duplicated(wb)))
e("warpbreaks last", idx(!duplicated(wb, fromLast = TRUE)))
e("warpbreaks none", idx(!duplicated(wb) & !duplicated(wb, fromLast = TRUE)))
for (v in names(iris)) e(paste0("iris$", v), vec(iris[[v]]))
e("iris first", idx(!duplicated(iris)))
e("iris last", idx(!duplicated(iris, fromLast = TRUE)))
e("iris none", idx(!duplicated(iris) & !duplicated(iris, fromLast = TRUE)))
d <- data.frame(f = gl(3, 5), i = 1:3)
e("d$f", vec(d$f)); e("d$i", vec(d$i))
e("d first", idx(!duplicated(d)))
e("d last", idx(!duplicated(d, fromLast = TRUE)))
d22 <- data.frame(x = c(.3 + .6, .9), y = 1)
e("d22$x", vec(d22$x)); e("d22$y", vec(d22$y))
e("d22 first", idx(!duplicated(d22)))
DF <- data.frame(x = c(1, 2, 3), y = c(0, 10, NA))
e("DF$x", vec(DF$x)); e("DF$y", vec(DF$y))
e("DF keep", idx(complete.cases(DF)))
aq <- airquality
for (v in names(aq)) e(paste0("aq$", v), vec(aq[[v]]))
e("aq keep all", idx(complete.cases(aq)))
e("aq keep -Ozone", idx(complete.cases(aq[, -1])))
e("aq keep Ozone,Solar.R", idx(complete.cases(aq[, c("Ozone", "Solar.R")])))
e("aq keep any Ozone,Solar.R", idx(rowSums(!is.na(aq[, c("Ozone", "Solar.R")])) > 0))
tb <- function(nm, v) {
	t <- table(v)
	e(paste0("table ", nm), paste0("{ ", paste(sprintf("'%s' => %d", names(t), t), collapse = ", "), " }"))
}
tb("warpbreaks$wool", warpbreaks$wool)
tb("warpbreaks$tension", warpbreaks$tension)
e("state.division", vec(state.division)); tb("state.division", state.division)
e("state.region", vec(state.region)); tb("state.region", state.region)
a <- rep(c(NA, 1/0:3), 10)
e("a", vec(a)); tb("a", a)
tb("aq$Month", aq$Month)
e("aq$Ozone>80", vec(aq$Ozone > 80)); tb("aq$Ozone>80", aq$Ozone > 80)
cat(");\n")
