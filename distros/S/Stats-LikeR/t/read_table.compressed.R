# Writes the compressed fixtures t/read_table.compressed.R.t reads.
#
#   cd t && Rscript read_table.compressed.R
#
# Run from t/, where it writes next to itself. Each fixture is written the way
# R 4.6.1's own tests/reg-tests-1b.R writes its compressed input, so that what
# read_table is asked to read is what R made:
#
#   morley.tab            readLines() of datasets' data/morley.tab, as is
#   morley.tab.gz         the same lines through gzfile(), then bzfile()
#   morley.tab.bz2          (reg-tests-1b.R, "tests of read.table with
#                           different types of compressed input")
#   append70.gz           1:50 through gzfile(, "w"), then 51:70 through
#   append70.bz2            gzfile(, "a"); the same with bzfile() ("tests of
#                           append mode on compressed connections"). Appending
#                           starts a second member, so each file holds two.
#   morley.tab.bgz        morley.tab through bgzip (htslib), the BGZF blocks
#                           of every .vcf.gz: one data block, then the empty
#                           end-of-file block, so two gzip members again.
#
# It also prints what R's read.table() makes of each, which is what the test's
# expected values are checked against. The test never runs this.
options(warn = 1)
ll <- readLines(system.file("data/morley.tab", package = "datasets"))
writeLines(ll, "morley.tab")
writeLines(ll, con <- gzfile("morley.tab.gz")); close(con)
writeLines(ll, con <- bzfile("morley.tab.bz2")); close(con)
stopifnot(identical(read.table("morley.tab.gz"), morley),
          identical(read.table("morley.tab.bz2"), morley))

con <- gzfile("append70.gz", "w"); writeLines(as.character(1:50), con)
close(con); con <- gzfile("append70.gz", "a")
writeLines(as.character(51:70), con); close(con)
con <- bzfile("append70.bz2", "w"); writeLines(as.character(1:50), con)
close(con); con <- bzfile("append70.bz2", "a")
writeLines(as.character(51:70), con); close(con)
stopifnot(identical(readLines("append70.gz"), as.character(1:70)),
          identical(readLines("append70.bz2"), as.character(1:70)))

stopifnot(system2("bgzip", c("-c", "morley.tab"), stdout = "morley.tab.bgz") == 0)
stopifnot(identical(read.table("morley.tab.bgz"), morley))

cat(R.version.string, "\n")
print(dim(morley)); print(morley[c(1, 100), ])
for (f in c("morley.tab.gz", "morley.tab.bz2", "append70.gz",
            "append70.bz2", "morley.tab.bgz"))
	cat(f, file.info(f)$size, "bytes\n")
