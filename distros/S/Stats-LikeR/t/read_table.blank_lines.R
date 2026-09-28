# Regenerates the R 4.6.1 values quoted in t/read_table.blank_lines.R.pandas.t.
#
#   Rscript t/read_table.blank_lines.R
#
# The same inputs as t/read_table.blank_lines.pandas.py, read with
# read.table(header = TRUE, colClasses = "character", comment.char = "") so that
# no cell is converted; an empty cell of a character column prints as "", and
# na.strings is left at its "NA" default, which none of these inputs holds
# except the one "NaN", which is not "NA". The test never runs this: copy what
# it prints into the test's tables by hand.
options(warn = 1, stringsAsFactors = FALSE)
show <- function(tag, txt, sep) {
	cat("==", tag, "\n")
	f <- tempfile(); cat(txt, file = f)
	r <- tryCatch(read.table(f, header = TRUE, sep = sep, colClasses = "character",
	                         comment.char = ""),
	              error = function(e) paste("ERROR:", conditionMessage(e)))
	dput(r)
}
show("test_empty_lines ,",    "A,B,C\n1,2.,4.\n\n\n5.,NaN,10.0\n\n-70,.4,1\n", ",")
show("test_empty_lines \\s+", "A  B  C\n1  2.  4.\n\n\n5.  NaN  10.0\n\n-70  .4  1\n", "")
show("test_whitespace_lines", "\n\n\t  \t\t\n\t\nA,B,C\n\t    1,2.,4.\n5.,NaN,10.0\n", ",")
show("tab row",          "a\tb\n1\t2\n\t\n3\t4\n", "\t")
show("tab row x3",       "a\tb\tc\n1\t2\t3\n\t\t\n4\t5\t6\n", "\t")
show("tab row crlf",     "a\tb\r\n1\t2\r\n\t\r\n3\t4\r\n", "\t")
show("tab row last",     "a\tb\n1\t2\n\t", "\t")
show("comma row",        "a,b\n1,2\n,\n3,4\n", ",")
show("space row",        "a b\n1 2\n \n3 4\n", " ")
show("spaces under tab", "a\tb\n1\t2\n  \n3\t4\n", "\t")
show("one column",       "a\n1\n\n2\n", "\t")
