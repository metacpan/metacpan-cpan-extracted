#!/usr/bin/env python3
# Exact two-sided Fisher r x c p-values, as rational numbers, for the "exact"
# columns of t/fisher_test.R.scipy.t (Cases 6, 7, 8 and 11).  The test never
# runs this; it holds the values frozen.
#
# Re-run (each table is one line "name row;row;..." on stdin, cells comma
# separated):
#
#   echo 'job 1,3,10,6;2,3,10,7;1,6,14,12;0,1,9,11' |
#       python3 t/fisher_test.rxc.exact.py 3.45254e-7
#
# The argument is the "as or more extreme" tolerance: a table counts when
# P(T) <= P(observed) * exp(tol), and 3.45254e-7 is the TOL of R 4.6.1's
# src/library/stats/src/fexact.c, f2xact(), which fisher_test() uses too.
#
# Method: the same column-by-column network as fisher_rxc_pvalue() in LikeR.xs,
# but with no bounds and no pruning, and with every path weight kept as an
# exact integer (a product of multinomial coefficients), so equal weights merge
# by integer equality and the sum is a Fraction.  No floating point is used
# except to print, and to write exp(tol) as a 55-digit rational (mpmath).  It is
# slow and memory-hungry: Job Satisfaction takes seconds, a 5x5 such as
# Case 11's s2 does not finish in 50 minutes, and Case 11's 3x6 w1 runs out of
# memory, which is why those two are checked against R alone.
import sys, math
from fractions import Fraction
import mpmath
mpmath.mp.dps = 60

def comps(n, caps):
    if len(caps) == 1:
        if n <= caps[0]: yield (n,)
        return
    rest = sum(caps[1:])
    for v in range(max(0, n - rest), min(caps[0], n) + 1):
        for t in comps(n - v, caps[1:]): yield (v,) + t

def multinom(n, xs):
    r = math.factorial(n)
    for x in xs: r //= math.factorial(x)
    return r

def pvalue(tab, tol):
    nr, nc = len(tab), len(tab[0])
    rs = [sum(r) for r in tab]; cs = [sum(tab[i][j] for i in range(nr)) for j in range(nc)]
    N = sum(rs)
    if nr > nc: node, stage = sorted(cs), sorted(rs)
    else: node, stage = sorted(rs), sorted(cs)
    # observed integer weight W = prod C! / prod t!  over stage side
    Wobs = Fraction(1)
    for c in stage: Wobs *= math.factorial(c)
    for row in tab:
        for t in row: Wobs /= math.factorial(t)
    # threshold factor exp(tol) as a 60-digit rational
    thr = Wobs * Fraction(mpmath.nstr(mpmath.exp(mpmath.mpf(tol)), 55))
    layer = {tuple(node): {1: 1}}
    for s, c in enumerate(stage[:-1]):
        nxt = {}
        for m, pasts in layer.items():
            for x in comps(c, list(m)):
                d = tuple(sorted(mi - xi for mi, xi in zip(m, x)))
                w = multinom(c, x)
                tgt = nxt.setdefault(d, {})
                for p, cnt in pasts.items():
                    q = p * w
                    tgt[q] = tgt.get(q, 0) + cnt
        layer = nxt
    total = Fraction(0)
    last = stage[-1]
    for m, pasts in layer.items():
        w = multinom(last, m)
        for p, cnt in pasts.items():
            W = p * w
            if W <= thr: total += cnt * W
    # P = W * prod node! / N!
    f = Fraction(1)
    for r in node: f *= math.factorial(r)
    f /= math.factorial(N)
    return total * f

if __name__ == '__main__':
    tol = float(sys.argv[1])
    for line in sys.stdin:
        name, t = line.split()[:2]
        tab = [[int(v) for v in r.split(',')] for r in t.split(';')]
        p = pvalue(tab, tol)
        print(name, repr(float(p)), mpmath.nstr(mpmath.mpf(p.numerator)/p.denominator, 25), flush=True)
