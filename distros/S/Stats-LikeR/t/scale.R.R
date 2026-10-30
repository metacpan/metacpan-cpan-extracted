# Generator for the frozen expected values in t/scale.R.t.
#
#   Rscript t/scale.R.R
#
# Prints the Perl data table that file carries; the test never runs this
# script and never calls R.  Re-run it only to regenerate the table, and paste
# the output over the table in the .t file.  Written against R 4.6.1.
#
# Provenance: base::scale() (scale.default, src/library/base/R/scale.R), on
# scale.Rd's own example matrix(1:10, ncol = 2) and on small dyadic matrices
# built to reach each branch of scale.default: logical and numeric center,
# logical and numeric scale, a numeric center with scale = TRUE (which divides
# by sqrt(sum(x^2)/(n-1)) of the centred column, not by its sd), NA cells
# (colMeans(na.rm = TRUE), v[!is.na(v)], NA kept in place), a column with one
# non-NA value (R's max(1, length(v) - 1)), and a zero in a scale vector.
#
# Each case prints label, then the result row by row; "NA" marks an NA cell,
# and NaN/Inf print as R spells them.

options(digits = 17)
m1 <- matrix(c(1, 3, 5, 2, 4, 7, -1.5, 0.25, 8), nrow = 3)
mna <- matrix(c(1, NA, 5, 9, 2, 4, 7, NA, NA, 0.5, NA, NA), nrow = 4)
f <- function(label, r) {
	r <- as.matrix(r)
	cat(sprintf("\t[ '%s', [ %s ] ],\n", label, paste(apply(r, 1, function(row)
		sprintf("[ %s ]", paste(ifelse(is.na(row) & !is.nan(row), "undef",
			ifelse(is.nan(row), "'NaN'", ifelse(is.infinite(row),
				ifelse(row > 0, "'Inf'", "'-Inf'"), sprintf("%.17g", row)))),
			collapse = ", "))), collapse = ", ")))
}
f("rd_noscale",      scale(matrix(1:10, ncol = 2), scale = FALSE))
f("rd_default",      scale(matrix(1:10, ncol = 2)))
f("m1_default",      scale(m1))
f("m1_cvec_svec",    scale(m1, center = c(1, 2, -1), scale = c(2, 0.5, 4)))
f("m1_cvec",         scale(m1, center = c(1, 2, -1)))
f("m1_nocenter",     scale(m1, center = FALSE))
f("m1_nocenter_svec", scale(m1, center = FALSE, scale = c(2, 0.5, 4)))
f("m1_svec",         scale(m1, scale = c(2, 0.5, 4)))
f("m1_cvec_noscale", scale(m1, center = c(1, 2, -1), scale = FALSE))
f("m1_svec_zero",    scale(m1, center = c(3, 4, 1), scale = c(0, 1, 0)))
f("mna_default",     scale(mna))
f("mna_nocenter",    scale(mna, center = FALSE))
f("mna_cvec",        scale(mna, center = c(1, 2, 3)))
f("flat_na",         scale(c(1, NA, 3, 6)))
f("flat_cvec",       scale(c(1, 2, 3, 4, 5), center = 2))
f("flat_svec",       scale(c(1, 2, 3, 4, 5), center = c(2), scale = c(4)))
