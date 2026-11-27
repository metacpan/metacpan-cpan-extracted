# Generator for t/group_by.R.pandas.t (R half).  Run with
#     Rscript t/group_by.R.pandas.R
# R 4.6.2 split(x, f), the cases of
#   tests/reg-tests-1c.R   "recycling in split()": split(1:6, 1:2)
#   tests/reg-tests-2.R    split(as.list(1:3), c(1,1,2)); split of
#                          charToRaw("A test string") by
#                          rep(1:5, times = c(1,1,4,1,6))  (as characters)
#   tests/reg-tests-1a.R   PR#6672: x <- c(NA, 1, 2); split(x, as.factor(x))
#   src/library/base/man/split.Rd, datasets::airquality split by Month
#   README.md: split(mtcars$mpg, mtcars$cyl)
# split() keeps an NA value inside its group; group_by() leaves it out (README),
# so the airquality expectation drops NAs from each group.  split() drops an NA
# level, as group_by() does.
options(digits = 17)
pl <- function(v) paste0("[", paste(ifelse(is.na(v), "undef", if (is.character(v)) sprintf("'%s'", v) else format(v, trim = TRUE)), collapse = ", "), "]")
show <- function(name, l, dropna = FALSE) {
	cat(sprintf("\t%s => {\n", name))
	for (k in names(l)) { v <- l[[k]]; if (dropna) v <- v[!is.na(v)]
		cat(sprintf("\t\t'%s' => %s,\n", k, pl(v))) }
	cat("\t},\n")
}
cat("my %R = (\n")
show("recycle", split(1:6, 1:2))
x <- as.list(1:3); show("list", lapply(split(x, c(1, 1, 2)), unlist))
y <- charToRaw("A test string"); z <- split(y, rep(1:5, times = c(1, 1, 4, 1, 6)))
show("raw", lapply(z, function(r) strsplit(rawToChar(r), "")[[1]]))
xn <- c(NA, 1, 2); show("pr6672", split(xn, as.factor(xn)))
show("airquality", split(airquality$Ozone, airquality$Month), dropna = TRUE)
show("mtcars", split(mtcars$mpg, mtcars$cyl))
cat(");\n")
cat("# airquality Ozone, Month\n")
cat("my $OZONE = ", pl(airquality$Ozone), ";\nmy $MONTH = ", pl(airquality$Month), ";\n")
cat("my $MPG = ", pl(mtcars$mpg), ";\nmy $CYL = ", pl(mtcars$cyl), ";\n")
