#!/usr/bin/env python3
"""Regenerate the @MP_NCP table in t/cohen_d.R.t.

    Rscript t/cohen_d.R.R | python3 t/cohen_d.mpmath.py

and paste the output over the section of the same name in the test.  The test
reads only the frozen literals; it never runs this script, and the
distribution needs neither python nor mpmath to install or test.  It reads
the generator's == @NCP_JOBS section -- each case's t statistic, df, and R's
two limits -- from standard input.  It took 17.5 minutes on 20 cores on
2026-10-17: each limit is about seventy bisection steps of a quadrature, and
the four at df = 19998 take 12 minutes each by themselves.

WHY A THIRD OPINION IS NEEDED
-----------------------------
cohen_d()'s default interval inverts the noncentral t in its noncentrality
parameter, and the XS and R disagree.  R's pnt() is a series accurate to
about 1e-12 in probability, which leaves its inverted limits good to about
2e-10; and for |ncp| > 37.62 it does not sum the series at all but returns a
normal approximation (nmath/pnt.c: del^2 > 2 log(2) * 1021), which puts
iris's upper limits 1e-4 to 1.6e-3 away from the XS.  mpmath decides.

METHOD
------
The defining equations, at mp.dps = 60: the lower limit solves
P(T > t; df, ncp) = alpha/2, the upper P(T <= t; df, ncp) = alpha/2, with
alpha = 1 - conf_level.  The CDF conditions on Z rather than integrating the
chi-square density, so that the spike that density becomes at large df is
handled exactly by the regularized incomplete gamma:

    t > 0:  P(T <= t) = Phi(-ncp) + int_{-ncp}^inf phi(z) Q(df/2, df (z + ncp)^2 / (2 t^2)) dz
    t < 0:  P(T <= t) = int_{-inf}^{-ncp} phi(z) P(df/2, df (z + ncp)^2 / (2 t^2)) dz

with the quadrature split at the points where the gamma factor turns over.
Each root is bisected, never taken from a library inverse, over R's value
+- 1% (or +- 0.01 near zero), to a bracket narrower than 1e-22.  t and
conf_level are read as the doubles R printed, exactly, not as decimals.

df > 4e5 is left out.  There both R and exact_pnt() use the same asymptotic
form, Abramowitz and Stegun 26.7.10, and mpmath's gammainc() raises
NoConvergence at df/2 = 2.5e5.
"""
import re
import sys
from multiprocessing import Pool

from mpmath import gammainc, mp, mpf, ncdf, npdf, quad, sqrt

mp.dps = 60


def cdf(t, nu, d):
    """P(T <= t) for the noncentral t on nu df with noncentrality d."""
    t, nu, d = mpf(t), mpf(nu), mpf(d)
    a = nu / 2
    if t == 0:
        return ncdf(-d)
    s = abs(t) / sqrt(2 * nu)      # width of the turn, in z, where (z + d)/t ~ 1
    centre = t - d
    pts = sorted(set([mpf(-40), -d, mpf(0), mpf(40)]
                     + [centre + k * s for k in range(-12, 13, 2)]))
    if t > 0:
        pts = [p for p in pts if -d <= p <= 40]
        f = lambda z: npdf(z) * gammainc(a, nu * (z + d) ** 2 / (2 * t * t), mp.inf,
                                         regularized=True)
        return ncdf(-d) + quad(f, pts)
    pts = [p for p in pts if -40 <= p <= -d]
    f = lambda z: npdf(z) * gammainc(a, 0, nu * (z + d) ** 2 / (2 * t * t), regularized=True)
    return quad(f, pts)


def limit(job):
    name, cl, t, nu, guess, upper = job
    half = (1 - mpf(cl)) / 2
    if upper:   # the lower limit: the upper tail at t is alpha/2
        g = lambda d: (1 - cdf(t, nu, d)) - half
    else:
        g = lambda d: cdf(t, nu, d) - half
    width = mpf('0.01') * max(1, abs(guess))
    lo, hi = mpf(guess) - width, mpf(guess) + width
    flo = g(lo)
    if (flo > 0) == (g(hi) > 0):
        raise SystemExit("no sign change for %s %s" % (name, cl))
    while hi - lo > mpf(10) ** -22:
        mid = (lo + hi) / 2
        fm = g(mid)
        if (fm > 0) == (flo > 0):
            lo, flo = mid, fm
        else:
            hi = mid
    return (lo + hi) / 2


def main():
    text = sys.stdin.read()
    section = text.split("== @NCP_JOBS\n", 1)[1]
    row = re.compile(r"\[ '([^']+)', ([^,]+), ([^,]+), (\d+), ([^,]+), ([^ ]+) \]")
    cases = []
    for m in row.finditer(section):
        name, cl, t, nu, rlo, rhi = m.groups()
        if int(nu) > 400000:
            continue
        # float() first: the double R printed, exactly; mpf(str) is the decimal
        cases.append((name, cl, mpf(float(t)), int(nu), mpf(float(rlo)), mpf(float(rhi))))
    jobs = []
    for name, cl, t, nu, rlo, rhi in cases:
        jobs.append((name, mpf(float(cl)), t, nu, rlo, True))
        jobs.append((name, mpf(float(cl)), t, nu, rhi, False))
    with Pool() as pool:
        roots = pool.map(limit, jobs, chunksize=1)
    print("== @MP_NCP")
    print("# [ set, conf_level, lower ncp, upper ncp ]")
    for k, (name, cl, *_rest) in enumerate(cases):
        print("\t[ '%s', %s, %s, %s ]," % (name, cl, mp.nstr(roots[2 * k], 20),
                                           mp.nstr(roots[2 * k + 1], 20)))


if __name__ == "__main__":
    main()
