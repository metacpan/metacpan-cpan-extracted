# Generator for t/filter.R.pandas.t (R half).  Run with
#     Rscript t/filter.R.pandas.R
# R 4.6.2 subset(), the examples in src/library/base/man/subset.Rd on
# datasets::airquality: subset(airquality, Temp > 80, select = c(Ozone, Temp)),
# subset(airquality, Day == 1, select = -Temp), with(airquality, subset(Ozone,
# Temp > 80)), plus the same rows under the other comparison operators and
# the Rd's rule that "missing values are taken as false".  Prints the airquality
# frame and, per predicate, the 0-based row indices subset() keeps.
options(digits = 17)
aq <- airquality
pl <- function(v) paste0("[", paste(ifelse(is.na(v), "undef", format(v, trim = TRUE)), collapse = ", "), "]")
for (c in names(aq)) cat(sprintf("\t'%s' => %s,\n", c, pl(aq[[c]])))
ix <- function(name, lg) cat(sprintf("\tq{%s} => %s,\n", name, pl(which(lg & !is.na(lg)) - 1)))
cat("# cases\n")
ix("Temp > 80", aq$Temp > 80)
ix("Day == 1", aq$Day == 1)
ix("Temp > 80 & Month > 7", aq$Temp > 80 & aq$Month > 7)
ix("Temp >= 90 | Day == 31", aq$Temp >= 90 | aq$Day == 31)
ix("!(Temp > 80)", !(aq$Temp > 80))
ix("Ozone > 100", aq$Ozone > 100)
ix("Ozone <= 10", aq$Ozone <= 10)
ix("Ozone != 18", aq$Ozone != 18)
ix("Ozone == 18", aq$Ozone == 18)
ix("Ozone < 20 & Wind > 12", aq$Ozone < 20 & aq$Wind > 12)
ix("Solar.R > 300 | Ozone > 100", aq$Solar.R > 300 | aq$Ozone > 100)
cat("# with(airquality, subset(Ozone, Temp > 80)) =", pl(with(aq, subset(Ozone, Temp > 80))), "\n")
cat("# length of subset(airquality, Temp > 80):", nrow(subset(aq, Temp > 80)), "\n")
