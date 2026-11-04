# Regenerates the ADJUDICATED rows of t/pt.log_tail.R.t: the qt() and qf()
# points where R 4.6.1 and Stats::LikeR disagree and mpmath sides with the
# module.  Run:  python3 t/pt.log_tail.mpmath.py
# Each root is found by bisection on the defining regularized incomplete beta
# at mp.dps = 60 (pt: I_x(df/2, 1/2)/2 with x = df/(df+t^2); pf: I_x(d1/2, d2/2)
# or its complement through y), not through any library inverse.
from mpmath import mp, mpf, betainc, log
mp.dps = 60
def logpt(t, df):
    t, df = mpf(t), mpf(df)
    return log(betainc(df/2, mpf(1)/2, 0, df/(df+t*t), regularized=True)/2)
def qt_lower(lp, df):
    lo, hi = mpf(0), mpf(10)
    while logpt(-hi, df) > lp: hi *= 2
    for _ in range(200):
        mid = (lo+hi)/2
        if logpt(-mid, df) > lp: lo = mid
        else: hi = mid
    return -(lo+hi)/2
def logpf(f, d1, d2, lower):
    f, d1, d2 = mpf(f), mpf(d1), mpf(d2)
    x, y = d1*f/(d1*f+d2), d2/(d1*f+d2)
    if lower: return log(betainc(d1/2, d2/2, 0, x, regularized=True))
    return log(betainc(d2/2, d1/2, 0, y, regularized=True))
def qf(lp, d1, d2, lower):
    g = lambda f: logpf(f, d1, d2, lower) - lp
    lo, hi = mpf('1e-300'), mpf(1)
    while (g(hi) < 0) == lower: hi *= 4
    while (g(lo) > 0) == lower: lo /= 4
    for _ in range(300):
        mid = (lo*hi)**mpf('0.5')
        if (g(mid) < 0) == lower: lo = mid
        else: hi = mid
    return lo
for lp, df in [(-1000,1500),(-1000,2500),(-5000,2500),(-5000,14327.789749923935),(-7500,14327.789749923935)]:
    q = qt_lower(lp, df)
    print("qt", lp, repr(float(df)), 1, repr(float(q)))
    print("qt", lp, repr(float(df)), 0, repr(float(-q)))
for a in [(-10,1,2000,1),(-10,2,2000,1),(-10,1,100000,1),(-1,1,100000,0)]:
    print("qf", *a[:3], a[3], repr(float(qf(*a))))
