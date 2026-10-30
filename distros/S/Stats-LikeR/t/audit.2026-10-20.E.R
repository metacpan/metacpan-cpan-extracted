# Generator for the R values frozen in t/audit.2026-10-20.E.t.
#   Rscript t/audit.2026-10-20.E.R
# The .t file carries the numbers as frozen literals and never runs this.
# R 4.6.1.  Prints label, statistic, num df, denom df, p at 17 digits.
options(digits = 17)
ow <- function(label, y, g, ve) {
    r <- oneway.test(y ~ g, data.frame(y = y, g = factor(g, levels = unique(g))), var.equal = ve)
    cat(sprintf("%s\t%.17g\t%.17g\t%.17g\t%.17g\n", label, unname(r$statistic),
        r$parameter[1], r$parameter[2], r$p.value))
}
ab.y <- c(1, 2, 3, 4, 5, 7); ab.g <- rep(c("a", "b"), each = 3)
ow("ab.welch", ab.y, ab.g, FALSE)
ow("ab.pooled", ab.y, ab.g, TRUE)
# NaN is NA to R: model.frame()'s na.omit drops the row
nan.y <- c(1, 2, 3, NaN, 5, 6, 8); nan.g <- c("a", "a", "a", "b", "b", "b", "b")
ow("nan.welch", nan.y, nan.g, FALSE)
ow("nan.pooled", nan.y, nan.g, TRUE)
# a level whose every response is NaN disappears with it
gone.y <- c(1, 2, NaN, NaN, 5, 6, 8); gone.g <- c("a", "a", "b", "b", "c", "c", "c")
ow("gone.welch", gone.y, gone.g, FALSE)
# 1100 groups of two, past the 1024 that 0.33's formula path allowed
i <- 0:2199
big.g <- i %/% 2; big.y <- ((i * 7) %% 13) / 4 + 2 * (big.g %% 3)
ow("big.welch", big.y, big.g, FALSE)
ow("big.pooled", big.y, big.g, TRUE)
sw <- shapiro.test(c(2.1, 3.4, 1.2, 5.5, 4.4, 0.3, 2.2))
cat(sprintf("shapiro.tied\t%.17g\t%.17g\n", unname(sw$statistic), sw$p.value))
