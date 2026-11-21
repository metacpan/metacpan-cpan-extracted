# Generator for the C10 expected values in t/binom_test.R.scipy.t (large n).
# Re-run with: python3 t/binom_test.large_n.py   (needs mpmath; the test never runs it.)
# Prints x, n, p, then the two-sided, less and greater p-values at 17 digits.
# Tails are I_x(a, b) integrated by quadrature about the mode, because mpmath betainc()
# does not converge at a, b ~ 1e12; the two-sided count is R rule, found by bisection
# on the exact pmf.
from mpmath import mp, mpf, loggamma, exp, log, quad, sqrt, ceil, floor
mp.dps = 40

def lpmf(i, n, p):
    return loggamma(n + 1) - loggamma(i + 1) - loggamma(n - i + 1) + i * log(p) + (n - i) * log(1 - p)

def ibeta(a, b, x):
    """regularized I_x(a,b) by quadrature of the density around its mode."""
    a = mpf(a); b = mpf(b); x = mpf(x)
    mu = a / (a + b)
    s = sqrt(a * b / ((a + b) ** 2 * (a + b + 1)))
    lnB = loggamma(a) + loggamma(b) - loggamma(a + b)
    f = lambda t: exp((a - 1) * log(t) + (b - 1) * log(1 - t) - lnB)
    L = max(mpf(0), mu - 40 * s); U = min(mpf(1), mu + 40 * s)
    if x <= L: return mpf(0)
    if x >= U: return mpf(1)
    pts = [L]
    k = 1
    while L + k * 2 * s < x:
        pts.append(L + k * 2 * s); k += 1
    pts.append(x)
    return quad(f, pts)

def le(k, n, p):
    if k >= n: return mpf(1)
    if k < 0: return mpf(0)
    return ibeta(n - k, k + 1, 1 - p)

def ge(k, n, p):
    if k <= 0: return mpf(1)
    if k > n: return mpf(0)
    return ibeta(k, n - k + 1, p)

def run(x, n, p):
    p = mpf(p)
    m = n * p
    d = exp(lpmf(x, n, p))
    lim = d * (1 + mpf(10) ** -7)
    pm = lambda i: exp(lpmf(i, n, p))
    if x < m:
        lo = int(ceil(m)); hi = n + 1
        while lo < hi:
            mid = (lo + hi) // 2
            if pm(mid) <= lim: hi = mid
            else: lo = mid + 1
        y = n + 1 - lo
        two = le(x, n, p) + ge(n - y + 1, n, p)
    else:
        lo = 0; hi = int(floor(m)) + 1
        while lo < hi:
            mid = (lo + hi) // 2
            if pm(mid) <= lim: lo = mid + 1
            else: hi = mid
        two = le(lo - 1, n, p) + ge(x, n, p)
    print(x, n, p, 'two', mp.nstr(min(two, 1), 17), 'less', mp.nstr(le(x, n, p), 17), 'greater', mp.nstr(ge(x, n, p), 17), flush=True)

for x, n, p in [(333363333, 10**9, 1/3), (500001000000, 10**12, 0.5), (250000300000, 10**12, 0.25),
                (500000001000000000, 10**18, 0.5), (499999999000000000, 10**18, 0.5),
                (300000001000000000, 10**18, 0.3), (300000000000000000, 10**18, 0.3)]:
    run(x, n, p)
