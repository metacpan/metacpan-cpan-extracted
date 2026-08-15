#!/usr/bin/env python3
"""High-precision tie-breaker for t/ks_test.R.scipy.t.

    python3 t/ks_test.mpmath.py

Where ks_test() and a reference disagree, this is the third opinion CLAUDE.md
asks for: mpmath at mp.dps = 60-80, solving the *defining* series or running
the defining recursion rather than calling any library inverse.  Two paths need
it, and the .t file carries the numbers printed here as frozen literals -- the
test never runs this script.

1. The limiting two-sided two-sample distribution.  R's psmirnov_asymp() calls
   its K2l() with tol = 1e-6, which for z < 1 truncates the small-argument
   series after one term; ks_test() passes 1e-9.  kolm_sf() below sums the
   defining alternating series to convergence, and says ks_test() is right.
   @MP_TWO in the .t is pinned to these values, not R's.

2. The exact two-sided one-sample distribution.  Both R and ks_test() form the
   p-value as 1 - K2x(n, D), and K2x returns the lower tail, so a significant
   result is pure cancellation: the answer is absolutely, never relatively,
   accurate.  k2x_sf() below runs the same Marsaglia-Tsang-Wang recursion at 60
   digits, where the subtraction still leaves ~45 good ones, and quantifies the
   loss.  That is where $TOL_P_ABS comes from.

mpmath is not a dependency of Stats::LikeR and is not needed to run the tests.
"""

from mpmath import mp, mpf, matrix, sqrt, exp, nsum, inf

mp.dps = 80


def kolm_sf(z):
    """Upper tail of the limiting Kolmogorov distribution,
    1 - sum_{k=-inf}^{inf} (-1)^k exp(-2 k^2 z^2)."""
    z = mpf(z)
    if z <= 0:
        return mpf(1)
    lower = 1 + 2 * nsum(lambda k: (-1) ** int(k) * exp(-2 * k * k * z * z),
                         [1, inf])
    return 1 - lower


def k2x_sf(n, d):
    """Upper tail P(D_n >= d) of the exact two-sided one-sample statistic, via
    the Marsaglia, Tsang & Wang (2003) matrix recursion -- the same algorithm
    LikeR.xs's K2x() runs, but at mp.dps digits."""
    d = mpf(d)
    k = int(n * d) + 1
    m = 2 * k - 1
    h = k - n * d
    H = [[mpf(1) if i - j + 1 >= 0 else mpf(0) for j in range(m)]
         for i in range(m)]
    for i in range(m):
        H[i][0] -= h ** (i + 1)
        H[m - 1][i] -= h ** (m - i)
    H[m - 1][0] += (2 * h - 1) ** m if 2 * h - 1 > 0 else mpf(0)
    for i in range(m):
        for j in range(m):
            if i - j + 1 > 0:
                for g in range(1, i - j + 2):
                    H[i][j] /= g
    Q = matrix(H) ** n
    s = Q[k - 1, k - 1]
    for i in range(1, n + 1):
        s = s * mpf(i) / mpf(n)
    return 1 - s


# ---- 1. asymptotic two-sided two-sample: label, D, n1, n2 -----------------
# One row per @MP_TWO row.  z = D * sqrt(n1*n2/(n1+n2)).
ASYMP = [
    ('100.100m1',   '0.02',                  100,   100),
    ('100.100p1',   '0.029999999999999999',  100,   100),
    ('100.110m1',   '0.20818181818181825',   100,   110),
    ('100.110p1',   '0.21090909090909091',   100,   110),
    ('d1m.d2',      '0.66666666666666674',     2,     3),
    ('d1m.d2f',     '0.75',                    2,     4),
    ('d1p.d2',      '0.33333333333333337',     2,     3),
    ('d1p.d2f',     '0.5',                     2,     4),
    ('eq.m05',      '0.33333333333333331',     3,     3),
    ('eq.p05',      '0.33333333333333331',     3,     3),
    ('eq.p1',       '0.33333333333333331',     3,     3),
    ('hw',          '0.60000000000000009',    10,    10),
    ('ks5',         '0.40000000000000002',     5,     2),
    ('large',       '0.50249999999999995',  10000,  110),
    ('one.01',      '1',                       1,     1),
    ('one.10',      '1',                       1,     1),
    ('oz',          '0.53846153846153855',    26,    26),
    ('qq',          '0.23999999999999999',    50,    50),
    ('st',          '0.42857142857142866',     5,     7),
    ('switzer',     '0.22500000000000001',    40,    40),
    ('two.const',   '1',                       5,     5),
    ('two.same',    '0',                       5,     5),
    ('x2233.x3344', '0.3125',                 16,    16),
    ('x2356.x3467', '0.34798534798534791',    21,    26),
]

print("# asymptotic two-sided two-sample upper tail (pinned in @MP_TWO)")
for (label, d, n1, n2) in ASYMP:
    en = mpf(n1) * n2 / (n1 + n2)
    p = kolm_sf(mpf(d) * sqrt(en))
    print("%-30s %.17g" % (label + '.two.sided.asymp', float(p)))

# ---- 2. exact two-sided one-sample: label, n, D, what R and ks_test say ---
EXACT1 = [
    ('norm.a',      9,  '0.15865525393145705',  '0.95164069201518386'),
    ('norm.b',      9,  '0.44435602715924361',  '0.038850140086788665'),
    ('norm.c',     10,  '0.29358012680196055',  '0.29340846368436124'),
    ('norm.const',  5,  '0.5',                  '0.11199999999999988'),
    ('norm.hw',    10,  '0.79343088086445324',  '3.1106659148516513e-07'),
    ('norm.kn',   100,  '0.12464329735846891',  '0.0819733523354228'),
    ('auto-gate',  99,  '0.5039893563146316',   '1.9984014443252818e-15'),
]

print("\n# exact two-sided one-sample upper tail: 1 - K2x(n, D) loses digits")
print("# %-14s %-24s %-24s %-10s %s" % ('label', 'true', 'R and ks_test',
                                        'rel err', 'abs err'))
for (label, n, d, dbl) in EXACT1:
    truth = k2x_sf(n, d)
    dbl = mpf(dbl)
    print("  %-14s %-24.17g %-24.17g %-10.2e %.2e" % (
        label, float(truth), float(dbl),
        float(abs(truth - dbl) / truth), float(abs(truth - dbl))))
