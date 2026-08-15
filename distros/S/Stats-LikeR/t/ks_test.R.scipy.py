#!/usr/bin/env python3
"""Generator for the SciPy-side expected values in t/ks_test.R.scipy.t.

    python3 t/ks_test.R.scipy.py

Prints one line per case:  <label> <TAB> <D> <TAB> <p>
at repr() precision, plus one "#DATA <TAB> kn <TAB> v,v,..." line carrying
TestKSOneSample.test_known_examples' random fixture. The .t file carries the
numbers as frozen literals and never runs this script.

t/ks_test.R.scipy.R needs that fixture too, so that both references are pinned
against the same 100 numbers. Hand it over with

    python3 t/ks_test.R.scipy.py | grep '^#DATA.kn' | cut -f3 | tr , '\n' > kn.txt
    Rscript t/ks_test.R.scipy.R

SciPy 1.17.1 / NumPy 2.4.4.
"""

import numpy as np
from scipy import stats, special

def emit(label, res):
    print("%s\t%r\t%r" % (label, float(res.statistic), float(res.pvalue)))

def two(label, x1, x2, alternative, mode):
    emit(label, stats.ks_2samp(np.asarray(x1, dtype=float),
                               np.asarray(x2, dtype=float),
                               alternative=alternative, mode=mode))

def one(label, x, alternative, mode):
    emit(label, stats.ks_1samp(np.asarray(x, dtype=float), special.ndtr,
                               alternative=alternative, mode=mode))

def dump(label, v):
    print("#DATA\t%s\t%s" % (label, ",".join(repr(float(e)) for e in v)))

# ---- datasets ------------------------------------------------------------
# Hollander & Wolfe (1999) Example 5.4, from R's tests/reg-tests-1a.R
hw_x = [-0.15, 8.6, 5, 3.71, 4.29, 7.74, 2.48, 3.25, -1.15, 8.38]
hw_y = [2.55, 12.07, 0.46, 0.35, 2.69, -0.94, 1.73, 0.73, -0.35, -0.37]

# Schroeer & Trenkler (1995), from R's ?ks.test
st_x = [1, 2, 2, 3, 3]
st_y = [1, 2, 3, 3, 4, 5, 6]

# SciPy TestKSTwoSamples fixtures
d1  = np.array([1.0, 2.0])
d1p = d1 + 0.01
d1m = d1 - 0.01
d2  = np.array([1.0, 2.0, 3.0])
d2f = np.array([1.0, 2.0, 3.0, 4.0])
x100       = np.linspace(1, 100, 100)
x100_2_p1  = x100 + 2 + 0.1
x100_2_m1  = x100 + 2 - 0.1
x110       = np.linspace(1, 100, 110)
x110_20_p1 = x110 + 20 + 0.1
x110_20_m1 = x110 + 20 - 0.1
x2233 = np.array([2] * 3 + [3] * 4 + [5] * 5 + [6] * 4, dtype=float)
x3344 = x2233 + 1
x2356 = np.array([2] * 3 + [3] * 4 + [5] * 10 + [6] * 4, dtype=float)
x3467 = np.array([3] * 10 + [4] * 2 + [6] * 10 + [7] * 4, dtype=float)
lg_n1, lg_n2 = 10000, 110
lg_delta = 1.0 / lg_n1 / lg_n2 / 2 / 2
lg_x = np.linspace(1, 200, lg_n1) - lg_delta
lg_y = np.linspace(2, 100, lg_n2)

# SciPy TestKSOneSample fixtures
sp1_a = np.linspace(-1, 1, 9)
sp1_b = np.linspace(-15, 15, 9)
sp1_c = np.array([-1.23, 0.06, -0.60, 0.17, 0.66, -0.17, -0.08, 0.27,
                  -0.98, -0.99])
# TestKSOneSample.test_known_examples
kn = stats.norm.rvs(loc=0.2, size=100, random_state=987654321)
dump("kn", kn)

TWO_CASES = [
    ("hw",            hw_x,  hw_y),
    ("ks5",           [1, 2, 3, 4, 5], [2.5, 4.5]),
    ("one.01",        [0],   [1]),
    ("one.10",        [1],   [0]),
    ("d1p.d2",        d1p,   d2),
    ("d1m.d2",        d1m,   d2),
    ("d1p.d2f",       d1p,   d2f),
    ("d1m.d2f",       d1m,   d2f),
    ("eq.p1",         d2,    d2 + 1),
    ("eq.p05",        d2,    d2 + 0.5),
    ("eq.m05",        d2,    d2 - 0.5),
    ("st",            st_x,  st_y),
    ("x2233.x3344",   x2233, x3344),
    ("x2356.x3467",   x2356, x3467),
    ("100.100p1",     x100,  x100_2_p1),
    ("100.100m1",     x100,  x100_2_m1),
    ("100.110p1",     x100,  x110_20_p1),
    ("100.110m1",     x100,  x110_20_m1),
    ("two.const",     [0.0] * 5, [1.0] * 5),
    ("two.same",      [0.0] * 5, [0.0] * 5),
]

for alt in ("two-sided", "greater", "less"):
    rtag = alt.replace("-", ".")
    for mode in ("exact", "asymp"):
        for (label, a, b) in TWO_CASES:
            two("%s.%s.%s" % (label, rtag, mode), a, b, alt, mode)
    # 10000 x 110: exact would take minutes; pin the asymptotic value only.
    two("large.%s.asymp" % rtag, lg_x, lg_y, alt, "asymp")

ONE_CASES = [
    ("norm.a",     sp1_a),
    ("norm.b",     sp1_b),
    ("norm.c",     sp1_c),
    ("norm.hw",    hw_x),
    ("norm.kn",    kn),
    ("norm.n1",    [0.0]),
    ("norm.inf",   [-np.inf, 0.0, 1.0, np.inf]),
    ("norm.const", [0.0] * 5),
]
for alt in ("two-sided", "greater", "less"):
    rtag = alt.replace("-", ".")
    for mode in ("exact", "asymp"):
        for (label, x) in ONE_CASES:
            one("%s.%s.%s" % (label, rtag, mode), x, alt, mode)
