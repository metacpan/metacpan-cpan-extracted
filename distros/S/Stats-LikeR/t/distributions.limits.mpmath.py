# Third opinion for the rows of t/distributions.limits.R.t where R 4.6.1 and
# Stats::LikeR disagree by more than the table's tolerance.
#
# Re-run with:   python3 t/distributions.limits.mpmath.py
# and copy the printed rows into %MPMATH in t/distributions.limits.R.t. The
# test never invokes this script.
#
# mpmath at mp.dps = 60. Each probability is the regularized incomplete beta or
# gamma written out from its definition (mpmath's betainc/gammainc, which sum
# the hypergeometric series to the working precision), and each quantile is
# found by BISECTING THAT DEFINING EQUATION on log x, not by any library
# inverse, so the arbiter shares no inversion code with either side. Every
# argument is the exact double the test passes: they are all dyadic, and are
# built here from the same ratios.
import mpmath as mp

mp.mp.dps = 60


def chisq_tail(q, df, lower):
    a, x = mp.mpf(df) / 2, mp.mpf(q) / 2
    return mp.gammainc(a, 0, x, regularized=True) if lower else mp.gammainc(a, x, mp.inf, regularized=True)


def t_tail(q, df, lower):
    # P(T <= q) for q < 0 is I_{df/(df+q^2)}(df/2, 1/2) / 2; the rest by symmetry
    q, df = mp.mpf(q), mp.mpf(df)
    small = mp.betainc(df / 2, mp.mpf(1) / 2, 0, df / (df + q * q), regularized=True) / 2
    want_small = (q < 0) == lower
    return small if want_small else 1 - small


def f_tail(x, d1, d2, lower):
    x, d1, d2 = mp.mpf(x), mp.mpf(d1), mp.mpf(d2)
    den = d1 * x + d2
    if lower:
        return mp.betainc(d1 / 2, d2 / 2, 0, d1 * x / den, regularized=True)
    return mp.betainc(d2 / 2, d1 / 2, 0, d2 / den, regularized=True)


def solve(cdf_log, lp, lo, hi, increasing):
    # bisection on log x for log(tail(x)) == lp
    llo, lhi = mp.log(lo), mp.log(hi)
    for _ in range(400):
        mid = (llo + lhi) / 2
        v = cdf_log(mp.exp(mid))
        if (v < lp) == increasing:
            llo = mid
        else:
            lhi = mid
    return mp.exp((llo + lhi) / 2)


ROWS = [
    # (label, kind, args...)
    ("qt", -700, 5, 1),
    ("qt", -700, 1, 1),
    ("qf", -mp.mpf(2) ** -66, 1, 1, 0),
    ("qf", -64, 1, 1, 1),
    ("qf", -64, 3, 5, 1),
    ("qf", -mp.mpf(2) ** -66, 3, 5, 0),
    ("qf", -64, 10, 100, 1),
    ("qf", -mp.mpf(2) ** -10, 1, 1, 0),
    ("qf", -mp.mpf(2) ** -66, 10, 100, 0),
    ("pt", -mp.mpf(2) ** 30, 30, 0),
    ("pf", mp.mpf(2) ** 20, 10, 100, 1),
]

for row in ROWS:
    kind = row[0]
    if kind == "qt":
        lp, df, lower = mp.mpf(row[1]), row[2], row[3]
        # lower tail at a negative quantile: solve on |q|
        f = lambda a: mp.log(t_tail(-a, df, True))
        r = -solve(f, lp, mp.mpf(1), mp.mpf(10) ** 400, False)
        if not lower:
            r = -r
    elif kind == "qf":
        lp, d1, d2, lower = mp.mpf(row[1]), row[2], row[3], row[4]
        f = lambda x: mp.log(f_tail(x, d1, d2, lower))
        r = solve(f, lp, mp.mpf(10) ** -400, mp.mpf(10) ** 400, bool(lower))
    elif kind == "pt":
        q, df, lower = row[1], row[2], row[3]
        # these rows are the tail near 1: its log is log1p(-other tail)
        r = mp.log1p(-t_tail(q, df, not lower))
    elif kind == "pf":
        x, d1, d2, lower = row[1], row[2], row[3], row[4]
        r = mp.log1p(-f_tail(x, d1, d2, not lower))
    print(kind, [mp.nstr(a, 17) for a in row[1:]], mp.nstr(r, 20))
