#!/usr/bin/env python3
#
# Regenerates the frozen SciPy side of t/cor.R.scipy.t.  Re-run it with
#
#     python3 t/cor.R.scipy.py > /tmp/cor.py.pl
#
# and paste the output over the "BEGIN GENERATED (Python)" ..
# "END GENERATED (Python)" block of t/cor.R.scipy.t.  The test itself never
# runs Python: everything printed here is a Perl literal.
#
#     python3 t/cor.R.scipy.py --draws
#
# prints only the 500 x 2 sample below, one pair per line, which is how
# t/cor.R.scipy.R reads the same data to compute R's value for it.
#
# Written against SciPy 1.18.1 / NumPy 2.4.6 (Python 3.14.2).
#
# Two data sets live here rather than in the R generator, because SciPy's
# expected values are tied to how they were drawn:
#
#   * draws -- the sample in scipy/stats/tests/test_stats.py,
#     TestCorrSpearmanr2::test_normal_draws and TestKendallTau::test_large_arrays
#     (the same recipe in both): RandomState(7546), two rows of 500 N(1, 1)
#     draws, mixed by the Cholesky factor of [[1, 0.3], [0.3, 1]].  SciPy pins
#     spearmanr at 0.28659685838743354 and kendalltau at 0.19291382765531062.
#   * wh200k -- a 200000-pair, seven-level sample modelled on
#     TestKendallTau::test_kendalltau_gh18139_overflow.  SciPy's own data come
#     from Python's random.choices(), which nothing in Perl can reproduce, so
#     this is built instead from two Wichmann-Hill components that the .t file
#     regenerates in plain integer arithmetic (every intermediate stays below
#     5.2e6, so it is exact on a 32-bit IV).  What it keeps from gh-18139 is
#     the point of that test: n(n-1)/2 = 2e10 pairs, past 2**32, all of them
#     tied in big blocks.

import sys
import numpy as np
from scipy import stats


def draws():
    rng = np.random.RandomState(7546)
    x = np.array([rng.normal(loc=1, scale=1, size=500),
                  rng.normal(loc=1, scale=1, size=500)])
    corr = [[1.0, 0.3], [0.3, 1.0]]
    x = np.dot(np.linalg.cholesky(corr), x)
    return x[0], x[1]


def wh200k():
    s, t = 12345, 6789
    x, y = [], []
    for _ in range(200000):
        s = (171 * s) % 30269
        t = (172 * t) % 30307
        x.append(s % 7 + 1)
        y.append(t % 7 + 1)
    return np.array(x, dtype=float), np.array(y, dtype=float)


def plist(v):
    return ", ".join(repr(float(z)) for z in v)


if len(sys.argv) > 1 and sys.argv[1] == "--draws":
    a, b = draws()
    for p, q in zip(a, b):
        print(repr(float(p)), repr(float(q)))
    sys.exit(0)

a, b = draws()
w1, w2 = wh200k()
print("## BEGIN GENERATED (Python) -- python3 t/cor.R.scipy.py")
print("our %PY_DRAWS = (")
print("\tx => [" + plist(a) + "],")
print("\ty => [" + plist(b) + "],")
print(");")
print("our %PY = (")
for label, (x, y) in (("draws", (a, b)), ("wh200k", (w1, w2))):
    print("\t'%s pearson' => %r," % (label, float(stats.pearsonr(x, y).statistic)))
    print("\t'%s spearman' => %r," % (label, float(stats.spearmanr(x, y).statistic)))
    print("\t'%s kendall' => %r," % (label, float(stats.kendalltau(x, y).statistic)))
print(");")
print("## END GENERATED (Python)")
