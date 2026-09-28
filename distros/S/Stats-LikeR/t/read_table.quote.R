# Regenerates the R 4.6.1 values quoted in t/read_table.quote.R.pandas.t.
#
#   Rscript t/read_table.quote.R
#
# Each input is one of pandas' (named in that test's header), plus R's own
# write.csv() output and the mid-field-quote file the test starts from. R is
# asked with read.csv(colClasses = "character") so that no cell is converted.
# The test never runs this: copy what it prints into the test's comments and
# tables by hand.
options(warn = 1, stringsAsFactors = FALSE)
show <- function(tag, txt, ...) {
	cat("==", tag, "\n")
	f <- tempfile(); cat(txt, file = f)
	r <- tryCatch(read.csv(f, colClasses = "character", ...),
	              error = function(e) paste("ERROR:", conditionMessage(e)))
	dput(r)
}
show("test_unbalanced_quoting balanced",   'a,b,c\n1,2,"3"')
show("test_unbalanced_quoting unbalanced", 'a,b,c\n1,2,"3')
show("IN_QUOTED_FIELD",                    'a,b,c\n4,5,6\n"')
show("GH 62739",                           'a b\n"\n1 3\n', sep = " ")
show("test_data_after_quote",              'a\n1\n"b"a')
show("test_skiprows_infield_quote",        'a"\nb"\na\n1')
show("write.csv",                          '"a","b"\n1,"x"\n2,"y"\n')
show("write.csv quote none",               '"a","b"\n1,"x"\n2,"y"\n', quote = "")
show("mid-field",                          "name,height,wt\nann,5'10\",150\nbob,6'1\",180\n")
