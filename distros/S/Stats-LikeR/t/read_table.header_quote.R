# Regenerates the R expected values in t/read_table.header_quote.R.pandas.t.
#
#   Rscript t/read_table.header_quote.R
#
# Every input is taken from R 4.6.1's own test suite (the file and case are
# named at each show() below); the quote = "" reads are the same inputs with
# quote = "" added. colClasses = "character" keeps every cell as the text R
# read, which is what read_table returns. The test never runs this: copy what
# it prints into the test's tables by hand.
options(stringsAsFactors = FALSE, warn = 1)
setwd(tempdir())
show <- function(tag, expr) { cat("==", tag, "\n"); r <- tryCatch(expr, error=function(e) paste("ERROR:", conditionMessage(e))); dput(r) }
cc <- "character"
## tests/reg-IO2.R: empty file, header only, header detection
file.create("foo1"); show("R13 empty col.names", read.table("foo1", col.names=LETTERS[1:4])); unlink("foo1")
cat("head\n", file = "foo2"); show("R1 foo2", read.table("foo2", colClasses=cc)); unlink("foo2")
cat("head\n", 1:2, "\n", 3:4, "\n", file = "foo3")
show("R2 foo3 V1", read.table("foo3", header=TRUE, col.names="V1", colClasses=cc))
show("R3 foo3 letters", read.table("foo3", header=TRUE, col.names=letters[1:4]))
cat(readLines("foo3"), sep="|\n"); unlink("foo3")
## tests/reg-IO2.R: tests of allowEscape
writeLines("1 2 3 \\ab\\c", "test.dat"); show("R4 escapes", read.table("test.dat", header=FALSE, allowEscapes=FALSE, colClasses=cc)); unlink("test.dat")
## tests/reg-IO2.R: comment chars in headers
cat('#comment\n\n#another\n#\n#\n',
    'C1\tC2\tC3\n"Panel"\t"Area Examined"\t"# Blemishes"\n',
    '"1"\t"0.8"\t"3"\n', '"2"\t"0.6"\t"2"\n', '"3"\t"0.8"\t"3"\n',
    file = "test.dat", sep="")
show("R5", read.table("test.dat", colClasses=cc))
show("R5 tab", read.table("test.dat", sep="\t", colClasses=cc))
show("R5 tab quote none", read.table("test.dat", sep="\t", quote="", colClasses=cc))
unlink("test.dat")
cat('%comment\n\n%another\n%\n%\n',
    'C1\tC2\tC3\n"Panel"\t"Area Examined"\t"% Blemishes"\n',
    '"1"\t"0.8"\t"3"\n', '"2"\t"0.6"\t"2"\n', '"3"\t"0.8"\t"3"\n',
    file = "test.dat", sep="")
show("R6", read.table("test.dat", comment.char = "%", colClasses=cc))
show("R6 quote none", read.table("test.dat", comment.char = "%", sep="\t", quote="", colClasses=cc))
unlink("test.dat")
## tests/reg-tests-2.R: extensions to read.table
Mat <- matrix(c(1:3, letters[1:3], 1:3, LETTERS[1:3],
                c("2004-01-01", "2004-02-01", "2004-03-01"),
                c("2004-01-01 12:00", "2004-02-01 12:00", "2004-03-01 12:00")), 3, 6)
write.table(Mat, "foo", col.names = FALSE, row.names = FALSE)
cat(readLines("foo"), sep="|\n")
show("R7", read.table("foo", colClasses=cc))
show("R7 quote none", read.table("foo", colClasses=cc, quote="", sep=" "))
unlink("foo")
## tests/reg-tests-1d.R: an opening quote may be preceded by non-space
show("R8", read.table(text="=\"Total\t\"\t1\n", sep="\t", colClasses=cc))
show("R8 quote none", read.table(text="=\"Total\t\"\t1\n", sep="\t", quote="", colClasses=cc))
show("R9", read.table(text="=\"CJ01 \"\t550\n", sep="\t", colClasses=cc))
show("R9 quote none", read.table(text="=\"CJ01 \"\t550\n", sep="\t", quote="", colClasses=cc))
show("R10", read.table(text="HO5\'\'\tH", colClasses=cc))
## tests/reg-tests-1a.R: the na.strings = "foo" example
tmp <- "t11"; cat(c("1", "foo", "\n", "2", "NA", "\n"), file = tmp); cat(readLines(tmp), sep="|\n")
show("R11", read.table(tmp, na.strings="foo", colClasses=cc)); unlink(tmp)
## tests/reg-tests-1b.R: PR#13433
show("R12", read.table(text="field1\tfield2\n 1\ta\n 2\tb", blank.lines.skip = FALSE, colClasses=cc))
