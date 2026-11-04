# Regenerates the frozen tables in t/pt.log_tail.R.t.
#   Rscript t/pt.log_tail.R.R > /tmp/pt.log_tail.tables
# and paste the output over the tables in the test.  The test never runs this.
# Everything is on the log scale with large degrees of freedom, where
# incbeta_xy_core() hands a shape >= 1000 and a shape <= 1 to TOMS 708's
# bpser() or bgrat().  df stays at or below 4e5: above that R's pt() switches
# to a normal approximation (pt.c, "n > 4e5") and is no longer the exact
# function the module computes.
options(digits = 17, scipen = 500)
row <- function(...) cat(sprintf("\t[%s],\n", paste(c(...), collapse = ", ")))
cat("# pt: t, df, lower_tail, log pt\n")
ts <- c(-0.5, -2, -5, -10, -20, -40, -60, 0.5, 2, 5, 10, 20, 40, 60)
for (df in c(1500, 2508.3, 5000, 14327.789749923935, 1e5)) {
  for (k in ts) {
    t <- k * sqrt(df)
    for (lt in c(TRUE, FALSE)) {
      v <- pt(t, df, lower.tail = lt, log.p = TRUE)
      if (is.finite(v) && v != 0) row(sprintf("%.17g", t), sprintf("%.17g", df), as.integer(lt), sprintf("%.17g", v))
    }
  }
}
for (a in list(c(-960, 2508.3), c(-3000, 5000), c(-3008.9140148087536, 14327.789749923935))) {
  v <- pt(a[1], a[2], log.p = TRUE)
  row(sprintf("%.17g", a[1]), sprintf("%.17g", a[2]), 1, sprintf("%.17g", v))
}
cat("# pf: f, df1, df2, lower_tail, log pf\n")
for (d1 in c(2000, 1e5)) for (d2 in c(0.5, 1, 2, 3)) {
  for (f in c(0.01, 0.1, 0.5, 1, 2, 10, 100, 1e4)) for (lt in c(TRUE, FALSE)) {
    v <- pf(f, d1, d2, lower.tail = lt, log.p = TRUE)
    if (is.finite(v) && v != 0) row(sprintf("%.17g", f), sprintf("%.17g", d1), sprintf("%.17g", d2), as.integer(lt), sprintf("%.17g", v))
  }
}
for (d1 in c(0.5, 1, 2, 3)) for (d2 in c(2000, 1e5)) {
  for (f in c(0.01, 0.1, 0.5, 1, 2, 10, 100, 1e4)) for (lt in c(TRUE, FALSE)) {
    v <- pf(f, d1, d2, lower.tail = lt, log.p = TRUE)
    if (is.finite(v) && v != 0) row(sprintf("%.17g", f), sprintf("%.17g", d1), sprintf("%.17g", d2), as.integer(lt), sprintf("%.17g", v))
  }
}
cat("# qt: log p, df, lower_tail, qt\n")
for (df in c(1500, 2500, 14327.789749923935, 1e5)) for (lp in c(-1, -10, -100, -1000, -5000, -7500)) {
  for (lt in c(TRUE, FALSE)) {
    v <- qt(lp, df, lower.tail = lt, log.p = TRUE)
    if (is.finite(v) && v != 0) row(sprintf("%.17g", lp), sprintf("%.17g", df), as.integer(lt), sprintf("%.17g", v))
  }
}
cat("# qf: log p, df1, df2, lower_tail, qf\n")
for (d in list(c(2000, 1), c(2000, 2), c(1, 2000), c(2, 2000), c(1e5, 1), c(1, 1e5))) for (lp in c(-1, -10, -100, -1000)) {
  for (lt in c(TRUE, FALSE)) {
    v <- qf(lp, d[1], d[2], lower.tail = lt, log.p = TRUE)
    if (is.finite(v) && v > 0) row(sprintf("%.17g", lp), sprintf("%.17g", d[1]), sprintf("%.17g", d[2]), as.integer(lt), sprintf("%.17g", v))
  }
}
