# Generator for the Case 12 expected values in t/fisher_test.R.scipy.t (totals above 2^31).
# Re-run with: python3 t/fisher_test.big_total.py   (needs mpmath; the test never runs it.)
# Exact central-hypergeometric sums by ratio recursion from the mode at mp.dps = 60; the
# two-sided rule is R: pmf <= pmf(x) * (1 + 1e-7).  Only tables with a narrow support are
# listed; the walk stops once a term is 1e-40 of the mode.
import sys
from mpmath import mp, mpf, loggamma, exp
mp.dps = 60

def lnC(n, k):
    return loggamma(n + 1) - loggamma(k + 1) - loggamma(n - k + 1)

def run(a, b, c, d):
    m = a + c; n = b + d; k = a + b; N = m + n
    lo = max(0, k - n); hi = min(k, m)
    # mode of the central hypergeometric
    mode = ((k + 1) * (m + 1)) // (N + 2)
    lp = lnC(m, mode) + lnC(n, k - mode) - lnC(N, k)
    pm = exp(lp)
    pm_up = {mode: pm}
    # walk outward by ratio until negligible
    x = mode; p = pm
    while x < hi and p > pm * mpf(10) ** -40:
        p = p * (m - x) * (k - x) / ((x + 1) * (n - k + x + 1)); x += 1
        pm_up[x] = p
    x = mode; p = pm
    while x > lo and p > pm * mpf(10) ** -40:
        p = p * x * (n - k + x) / ((m - x + 1) * (k - x + 1)); x -= 1
        pm_up[x] = p
    pmf = pm_up
    less = sum(v for xx, v in pmf.items() if xx <= a)
    greater = sum(v for xx, v in pmf.items() if xx >= a)
    pa = pmf.get(a, mpf(0))
    relerr = 1 + mpf(10) ** -7
    two = sum(v for v in pmf.values() if v <= pa * relerr)
    tot = sum(pmf.values())
    print(a, b, c, d, 'less', mp.nstr(less / tot, 17), 'greater', mp.nstr(greater / tot, 17), 'two', mp.nstr(two / tot, 17), flush=True)

for cse in [(2147483647, 5, 2147483647, 3)]:
    run(*cse)
