# R 4.6.1 values for the r x c tables of t/fisher_test.R.scipy.t, Case 11.
# The test never runs this; it holds the values frozen.  Re-run with
#
#   Rscript t/fisher_test.rxc.R
#
# It prints, per table, its name, its rows, fisher.test()'s p-value at 17
# significant digits (NA where R refuses the table at its default
# workspace = 200000) and the seconds R took, which is where the timings in
# the comment on FT_NET_WORK_CAP in LikeR.xs come from.  The random tables are
# drawn after set.seed(1), in this order; only those R answers are in the test.
options(digits = 17)
tabs <- list(
    audit = matrix(c(0,1,8,4, 4,7,6,3, 4,0,8,7, 7,4,5,5), 4, byrow = TRUE),
    MP6   = rbind(c(1,2,2,1,1,0,1), c(2,0,0,2,3,0,0), c(0,1,1,1,2,7,3),
                  c(1,1,2,0,0,0,1), c(0,1,1,1,1,0,0)))
set.seed(1)
for (i in 1:6) tabs[[paste0("r", i)]] <- matrix(rpois(20, 5), 4, 5)
for (i in 1:4) tabs[[paste0("s", i)]] <- matrix(rpois(25, 4), 5, 5)
for (i in 1:3) tabs[[paste0("w", i)]] <- matrix(rpois(18, 12), 3, 6)
for (i in 1:3) tabs[[paste0("t", i)]] <- matrix(rpois(16, 9), 4, 4)
for (n in names(tabs)) {
    x <- tabs[[n]]
    t0 <- proc.time()[3]
    p <- tryCatch(fisher.test(x)$p.value, error = function(e) NA)
    cat(n, "\t", paste(apply(x, 1, paste, collapse = ","), collapse = ";"), "\t",
        sprintf("%.17g", p), "\t", sprintf("%.3f", proc.time()[3] - t0), "\n")
}
