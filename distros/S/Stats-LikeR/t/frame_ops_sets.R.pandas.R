# Generator for the R expectations frozen in t/frame_ops_sets.R.pandas.t
# (csort against order(), the set functions against sets.Rd).  Re-run with
#     Rscript t/frame_ops_sets.R.pandas.R
# R 4.6.2 printed the values on 2026-11-26.  The .t never runs this.
options(digits = 17)
cat(R.version.string, "\n")
# sets.Rd \examples, with the random samples replaced by fixed vectors
# (no NA: Stats::LikeR dies on undef, see the .t header).
x <- c(2, 5, 9, 11, 14, 17, 19, 3, 5)
y <- c(5, 7, 11, 12, 20, 22, 3, 9, 9)
cat("union", union(x, y), "\n")
cat("intersect", intersect(x, y), "\n")
cat("setdiff x y", setdiff(x, y), "\n")
cat("setdiff y x", setdiff(y, x), "\n")
cat("setequal x y", setequal(x, y), "\n")
cat("setequal 3-way", setequal(union(x, y), c(setdiff(x, y), intersect(x, y), setdiff(y, x))), "\n")
# sets.Rd factors example, and reg-tests-1e.R union() of factors
fx <- as.factor(c("A", "B", "A")); fy <- as.factor(c("B", "b"))
cat("fac union", as.character(union(fx, fy)), "\n")
cat("fac intersect", as.character(intersect(fx, fy)), "\n")
cat("fac setdiff x y", as.character(setdiff(fx, fy)), "\n")
cat("fac setdiff y x", as.character(setdiff(fy, fx)), "\n")
ux <- factor(c("a", "b", "a")); uy <- factor(c("b", "c"))
cat("fac1e union", as.character(union(ux, uy)), "\n")
# three lists, by Reduce
a <- c(1, 2, 3, 4, 5); b <- c(3, 4, 5, 6, 7); cc <- c(5, 6, 7, 8)
cat("Lonly3", Reduce(setdiff, list(a, b, cc)), "\n")
cat("Ronly3", Reduce(setdiff, list(cc, b, a)), "\n")
cat("union3", Reduce(union, list(a, b, cc)), "\n")
cat("intersect3", Reduce(intersect, list(a, b, cc)), "\n")
cat("setequal dup", setequal(c(1, 1, 2), c(2, 1)), setequal(c(1, 2, 3), c(1, 2)), setequal(c(), c()), "\n")
# order(): ties, decreasing, NA/NaN last (order.Rd; method = "radix" is stable)
v <- c(3, 1, NA, 2, 1, NaN, 3)
cat("order asc", order(v) - 1, "\n")
cat("order desc", order(v, decreasing = TRUE) - 1, "\n")
s <- c("b", "a", "C", "a", NA, "B")
cat("order chr C", order(s, method = "radix") - 1, "\n")
cat("order chr desc C", order(s, decreasing = TRUE, method = "radix") - 1, "\n")
# multiple keys with ties
k1 <- c(2, 1, 2, 1, 2); k2 <- c(5, 9, 5, 3, 1)
cat("order k1,k2", order(k1, k2) - 1, "\n")
cat("order k1,-k2", order(k1, -k2) - 1, "\n")
cat("order -k1,k2", order(-k1, k2) - 1, "\n")
