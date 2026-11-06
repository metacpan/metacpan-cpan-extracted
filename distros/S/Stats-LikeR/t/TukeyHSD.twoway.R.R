# Reference values for t/TukeyHSD.twoway.R.t.
#
# Prints the Perl literal that the .t file holds in reference(); the test
# never runs this script.  Re-run it with
#
#   Rscript t/TukeyHSD.twoway.R.R > reference.pl
#
# and paste its output over the body of reference().  Generated under R 4.6.1.
#
# The model is TukeyHSD.Rd's own example, aov(breaks ~ wool + tension,
# warpbreaks).  Its factors are rebuilt from character vectors, because a Perl
# data frame holds strings and R orders the levels of a character vector
# alphabetically (H, L, M), not in warpbreaks' stored order (L, M, H).
# 'unbalanced' drops rows 1, 2, 3, 20, 40 and 41, which leaves the six
# wool:tension cells with 6 to 9 rows each.
options(digits = 17)
w <- data.frame(breaks = warpbreaks$breaks,
                wool = as.character(warpbreaks$wool),
                tension = as.character(warpbreaks$tension))
fits <- list(balanced = w, unbalanced = w[-c(1, 2, 3, 20, 40, 41), ])
for (name in names(fits)) {
	fm <- aov(breaks ~ wool + tension, data = fits[[name]])
	for (ord in c(FALSE, TRUE)) {
		h <- TukeyHSD(fm, ordered = ord)
		cat(sprintf("\t'%s, ordered => %d' => {\n", name, ord))
		for (f in c("wool", "tension")) {
			m <- h[[f]]
			cat(sprintf("\t\t%s => [\n", f))
			for (i in seq_len(nrow(m)))
				cat(sprintf("\t\t\t['%s', %s, %s, %s, %s],\n", rownames(m)[i],
				            format(m[i, 1], digits = 17), format(m[i, 2], digits = 17),
				            format(m[i, 3], digits = 17), format(m[i, 4], digits = 17)))
			cat("\t\t],\n")
		}
		cat("\t},\n")
	}
}
