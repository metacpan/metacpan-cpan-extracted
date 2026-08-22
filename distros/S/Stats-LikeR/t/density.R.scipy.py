#!/usr/bin/env python3
#
# Regenerates the frozen SciPy/NumPy side of t/density.R.scipy.t.  Re-run it
# with
#
#     python3 t/density.R.scipy.py > /tmp/density.py.pl
#
# and paste the output over the "BEGIN GENERATED (Python)" ..
# "END GENERATED (Python)" block of t/density.R.scipy.t.  The test itself never
# runs Python: everything printed here is a Perl literal.
#
# Written against SciPy 1.18.0 / NumPy 2.5.2.
#
# SciPy has no port of R's density(): scipy.stats.gaussian_kde evaluates the
# kernel density estimate *exactly*, summing one Gaussian per observation,
# where R disperses the data onto a grid, convolves with the FFT and
# interpolates back.  That makes it the right kind of second opinion -- it
# checks the whole binning/FFT/interpolation pipeline against the quantity that
# pipeline is approximating, not against another copy of the same code.  What
# it cannot do is pin the last digit: the two differ by the discretisation
# error, which is measured below and frozen alongside the values so the test
# can assert against a number that was observed rather than guessed.
#
# gaussian_kde scales its kernel by factor**2 * cov(x), so bw_method =
# bw / sd(x) makes its kernel standard deviation exactly R's bw.
#
# NumPy/SciPy also give an independent reading of bw.nrd0 and bw.nrd, whose
# ingredients (sd with ddof=1 and the type-7 interquartile range) both exist
# there as primitives.  Note that statsmodels' bw_silverman/bw_scott are NOT
# these: they divide the IQR by 1.349 where R's bw.nrd0/bw.nrd divide by 1.34,
# so they answer a slightly different question and are deliberately not used.

import numpy as np
from scipy.stats import gaussian_kde, iqr

# The same data sets the R generator freezes, rebuilt here from the same
# recipes so the two files cannot drift apart.
rng_r = None


def nvq(v):
    return ", ".join("'%s'" % repr(float(z)) for z in v)


# Values that came out of R's RNG: read them back from the R generator's own
# output rather than trying to reproduce Mersenne-Twister streams here.
import subprocess

RS = r"""
options(digits = 17)
set.seed(1)
z60  <- round(rnorm(60)  * 1024) / 1024
z200 <- round(rnorm(200) * 1024) / 1024
z9   <- round(rnorm(9)   * 1024) / 1024
cat(z60,  sep = " "); cat("\n")
cat(z200, sep = " "); cat("\n")
cat(z9,   sep = " "); cat("\n")
cat(as.vector(precip), sep = " "); cat("\n")
cat(faithful$eruptions, sep = " "); cat("\n")
"""
out = subprocess.run(["Rscript", "-e", RS], capture_output=True, text=True,
                     check=True).stdout.strip().split("\n")
names = ["z60", "z200", "z9", "precip", "eruptions"]
DATA = {nm: np.array([float(v) for v in ln.split()])
        for nm, ln in zip(names, out)}

print("## BEGIN GENERATED (Python) -- python3 t/density.R.scipy.py")

# --- bw.nrd0 / bw.nrd rebuilt from NumPy and SciPy primitives -------------
print("our @PY_NRD = (")
for nm, x in DATA.items():
    n = len(x)
    sd = float(np.std(x, ddof=1))
    q = float(iqr(x, interpolation="linear"))       # R's quantile type 7
    nrd0 = 0.9 * min(sd, q / 1.34) * n ** -0.2
    nrd = 1.06 * min(sd, q / 1.34) * n ** (-1 / 5)
    print("\t{ data => '%s', nrd0 => '%s', nrd => '%s' }," % (nm, repr(nrd0), repr(nrd)))
print(");\n")

# --- the exact Gaussian KDE at R's own grid ------------------------------
# For each (data set, n) the grid is R's: from = min(x) - 3*bw, to = max(x) +
# 3*bw, n equally spaced points.  bw is R's bw.nrd0, recomputed here.
print("our @PY_EXACT = (")
for nm in ("z60", "z200", "precip", "eruptions"):
    x = DATA[nm]
    n = len(x)
    sd = float(np.std(x, ddof=1))
    q = float(iqr(x, interpolation="linear"))
    bw = 0.9 * min(sd, q / 1.34) * n ** -0.2
    for ngrid in (512, 8192):
        lo, hi = x.min() - 3 * bw, x.max() + 3 * bw
        grid = np.linspace(lo, hi, ngrid)
        kde = gaussian_kde(x, bw_method=bw / sd)
        e = kde(grid)
        # freeze a spread of grid points rather than the whole grid
        at = sorted(set(int(round(t)) for t in
                        np.linspace(0, ngrid - 1, 24)))
        print("\t{ data => '%s', n => %d, bw => '%s'," % (nm, ngrid, repr(bw)))
        print("\t  at => [%s]," % ", ".join(str(i + 1) for i in at))
        print("\t  y  => [%s] }," % nvq(e[at]))
print(");\n")

# --- how far the exact estimate is from R's discretised one --------------
# Measured against R itself, so the tolerance the Perl test uses is a number
# that was observed here rather than one picked to make a failure go away.
RS2 = r"""
options(digits = 17)
set.seed(1)
z60  <- round(rnorm(60)  * 1024) / 1024
z200 <- round(rnorm(200) * 1024) / 1024
z9   <- round(rnorm(9)   * 1024) / 1024
for (nm in c("z60","z200","precip","eruptions")) {
    x <- switch(nm, z60 = z60, z200 = z200, precip = as.vector(precip),
                eruptions = faithful$eruptions)
    for (n in c(512, 8192)) {
        d <- density(x, n = n)
        cat(nm, n, "\n"); cat(d$y, sep = " "); cat("\n")
    }
}
"""
lines = subprocess.run(["Rscript", "-e", RS2], capture_output=True, text=True,
                       check=True).stdout.strip().split("\n")
i = 0
worst_abs = {}
worst_rel = {}
while i < len(lines):
    nm, ngrid = lines[i].split()[0], int(lines[i].split()[1])
    yr = np.array([float(v) for v in lines[i + 1].split()])
    i += 2
    x = DATA[nm]
    n = len(x)
    sd = float(np.std(x, ddof=1))
    q = float(iqr(x, interpolation="linear"))
    bw = 0.9 * min(sd, q / 1.34) * n ** -0.2
    lo, hi = x.min() - 3 * bw, x.max() + 3 * bw
    grid = np.linspace(lo, hi, ngrid)
    e = gaussian_kde(x, bw_method=bw / sd)(grid)
    a = float(np.max(np.abs(yr - e)))
    m = float(np.max(e))
    worst_abs[ngrid] = max(worst_abs.get(ngrid, 0.0), a / m)
    big = e > 0.01 * m
    worst_rel[ngrid] = max(worst_rel.get(ngrid, 0.0),
                           float(np.max(np.abs(yr[big] - e[big]) / e[big])))
for ngrid in sorted(worst_abs):
    print("our $PY_DISCRETISATION_%d_ABS = '%s';   # worst |R - exact| / max(exact)"
          % (ngrid, repr(worst_abs[ngrid])))
    print("our $PY_DISCRETISATION_%d_REL = '%s';   # worst relative, where exact > 1%% of its max"
          % (ngrid, repr(worst_rel[ngrid])))
print("## END GENERATED (Python)")
