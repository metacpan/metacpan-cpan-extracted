# Generator for t/format.ties.R.t: R's sprintf() on a glibc system, which
# rounds a value exactly halfway between two results to the even one.
# Run: Rscript t/format.ties.R.R   and paste its output into the .t file.
# The .t file never runs R.
options(digits = 17)

# Each double as n / 2**s, n an odd integer below 2^53 and s an integer,
# which every perl reads exactly; a decimal literal goes through perl's
# string-to-NV conversion, which old perls do not round correctly, and a tie
# read 1 ulp off is no tie.  The decimal is the trailing comment.
exact <- function(x) {
	if (x == 0) return(c(0, 0))
	s <- 52 - floor(log2(abs(x)))
	n <- x * 2^s
	while (n %% 2 == 0) { n <- n / 2; s <- s - 1 }
	c(n, s)
}

row <- function(style, prec, x) {
	ns <- exact(x)
	cat(sprintf("\t['%s', %d, %.0f, %d, '%s'], # %.17g\n", style, prec, ns[1], ns[2],
		sprintf(paste0("%.", prec, style), x), x))
}

cat("# from R ", R.version$major, ".", R.version$minor, "\n", sep = "")

# Round.Rd's example, round(.5 + -2:4), "IEEE / IEC rounding": ties at 0
# decimals.  Divided by 2^k they are ties at k decimals, (2j+1)/2^(k+1).
base <- .5 + -2:4
for (k in 0:6) for (x in base / 2^k) row("f", k, x)

# The same values scaled by powers of ten: (2j+1) * 5 * 10^(e-1).  For e >= 0
# an integer, so a tie at one significant digit; for e < 0 not a binary
# fraction (0.15 is Round.Rd's own example), so a near-tie the library must
# round by its stored value.
for (e in -3:4) for (x in base * 10^e) row("g", 1, x)

# Four significant digits, as summary() and write_table(tex_format => 1) use.
for (x in c(1.0625, 1.1875, -1.0625, 12345, 12355, -12345, 6173.5, 99.5,
            0.375, 0.0009765625, 1023.5))
	row("g", 4, x)
for (x in c(99.5, 0.375, 0.125)) row("g", 2, x)

# tests/reg-tests-3.R: sprintf("%.7g"/"%.5g"/"%.4g", 12345.6789), not ties.
for (p in c(7, 5, 4)) row("g", p, 12345.6789)

# Ties at 1 to 3 decimals, with non-ties (2.675 and 0.15 are stored below the
# half) beside them.  123456789012345.25 is a tie at 1 decimal with 17
# significant digits, the most LikeR.xs rounds itself (NV_EVEN_SIG_MAX).
for (x in c(56.25, 43.75, 0.125, 2.375, 123456789012345.25, 2.675, 0.15))
	for (p in 1:3) row("f", p, x)

# Exponent widths, none a tie.  0.35 under the MSVCRT (Strawberry Perl 5.24)
# printed "1.234e+004" for R's "1.234e+04"; a two-digit exponent either side of
# zero, and a three-digit one, which must stay three.
for (x in c(1e5, -1e5, 2^-30, 2^400, -2^400, 2^-900))
	for (p in c(1, 4, 15)) row("g", p, x)

# table_one(): mean of c(2, 2.25) is 2.125, and 18 of 32 is 56.25%.
cat("# table_one\n")
cat(sprintf("# mean %s sd %s pct %s\n", sprintf("%.2f", mean(c(2, 2.25))),
	sprintf("%.2f", sd(c(2, 2.25))), sprintf("%.1f", 100 * 18 / 32)))

# summary(): R's statistics of c(1.0625, 2, 12345), each as %.4g.
v <- c(1.0625, 2, 12345)
q <- quantile(v, c(.25, .75))
cat("# summary", sprintf("%.4g", c(min(v), q[1], median(v), mean(v), q[2], max(v))), "\n")
