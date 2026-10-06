# Regenerates the R expected values in t/read_table.quoted_comment.R.t.
#
#   Rscript t/read_table.quoted_comment.R
#
# R's ?scan: "If comment.char occurs (except inside a quoted character field),
# it signals that the rest of the line should be regarded as a comment". R's
# own suite has no case of a quoted field that starts with the comment
# character, so the inputs are written here, each the shape write_table gives
# a field or a record that would otherwise read back as a comment or a blank
# line. colClasses = "character" keeps every cell as the text R read, and
# check.names = FALSE keeps a header name as written ("#a", not "X.a"), which
# is what read_table returns. The test never runs this: copy what it prints
# into the test's table by hand.
options(stringsAsFactors = FALSE, warn = 1)
show <- function(tag, txt, ...) {
	cat("==", tag, "\n")
	r <- tryCatch(read.table(text = txt, colClasses = "character", check.names = FALSE, ...),
		error = function(e) paste("ERROR:", conditionMessage(e)))
	dput(r)
}
show("Q1 quoted #a header",        '"#a",b\n1,2\n',             sep = ",", header = TRUE)
show("Q2 quoted '# a' header",     '"# a",b\n1,2\n',            sep = ",", header = TRUE)
show("Q3 one quoted #a column",    '"#a"\nx\ny\n',              sep = ",", header = TRUE)
show("Q4 comment, quoted header",  '#x,y\n"#a",b\nfoo,bar\n',   sep = ",", header = TRUE)
show("Q5 quoted # data",           'a,b\n"#x",2\n"# y",3\n',    sep = ",", header = TRUE)
show("Q6 quoted # data, no header", '"#x",2\n"# y",3\n',        sep = ",", header = FALSE)
show("Q7 tab",                     '"#a"\t"b"\nx\ty\n',         sep = "\t", header = TRUE)
show("Q8 whitespace",              '"#a" b\n1 2\n',             header = TRUE)
show("Q9 quoted empty and blank",  'a\n""\n"  "\n1\n',          sep = ",", header = TRUE, strip.white = FALSE)
show("Q10 quoted blank header",    '"  "\n1\n',                 sep = ",", header = TRUE, strip.white = FALSE)
show("Q11 quoted '#' alone",       'a\n"#"\n"# z"\n',           sep = ",", header = TRUE)
