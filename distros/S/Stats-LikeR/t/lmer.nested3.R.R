# Generator for the frozen tables in t/lmer.nested3.R.t.
# Re-run:  Rscript t/lmer.nested3.R.R   (R 4.6.1, lme4 as installed there) and
# paste the printed Perl literals into the .t file.
# Data: 4 a x 3 b within a x 2 c within b, 3 rows each (72 rows), simulated
# with set.seed(11); fitted with lme4::lmer(REML = TRUE) the way lme4 expands
# (1|a/b/c) itself, to (1|a) + (1|a:b) + (1|a:b:c).
suppressMessages(library(lme4))
options(digits = 17)
set.seed(11)
d <- expand.grid(r = 1:3, c = 1:2, b = 1:3, a = 1:4)
d$x <- round(runif(nrow(d)), 6)
ea <- rnorm(4, sd = 2)[d$a]
eb <- rnorm(12, sd = 1.5)[(d$a - 1) * 3 + d$b]
ec <- rnorm(24, sd = 1)[((d$a - 1) * 3 + d$b - 1) * 2 + d$c]
d$y <- round(10 + 2 * d$x + ea + eb + ec + rnorm(nrow(d)), 6)
d$ga <- paste0("a", d$a); d$gb <- paste0("b", d$b); d$gc <- paste0("c", d$c)
emit <- function(nm, v) cat(sprintf("\t%s => [%s],\n", nm, paste(v, collapse = ", ")))
q <- function(v) sprintf("'%s'", v)
cat("my %D = (\n"); emit("a", q(d$ga)); emit("b", q(d$gb)); emit("c", q(d$gc))
emit("x", sprintf("%.17g", d$x)); emit("y", sprintf("%.17g", d$y)); cat(");\n")
m <- lmer(y ~ x + (1 | ga/gb/gc), data = d, REML = TRUE)
vc <- as.data.frame(VarCorr(m))
cat("my %REF = (\n")
emit("fixef", sprintf("%.17g", fixef(m)))
emit("se", sprintf("%.17g", sqrt(diag(vcov(m)))))
cat(sprintf("\tvar_names => [%s],\n", paste(q(vc$grp), collapse = ", ")))
emit("var", sprintf("%.17g", vc$vcov))
emit("REML", sprintf("%.17g", REMLcrit(m)))
cat(");\n")
# random slopes in a nested term, diagonal: lme4 expands (x || ga/gb) to
# (1 | ga/gb) + (0 + x | ga/gb)
m2 <- lmer(y ~ x + (x || ga/gb), data = d, REML = TRUE)
vc2 <- as.data.frame(VarCorr(m2))
cat("my %REF2 = (\n")
emit("fixef", sprintf("%.17g", fixef(m2)))
cat(sprintf("\tvar_names => [%s],\n", paste(q(paste(vc2$grp, vc2$var1)), collapse = ", ")))
emit("var", sprintf("%.17g", vc2$vcov))
emit("REML", sprintf("%.17g", REMLcrit(m2)))
cat(");\n")
