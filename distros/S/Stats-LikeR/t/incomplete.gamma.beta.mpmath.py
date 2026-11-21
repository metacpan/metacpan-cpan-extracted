#!/usr/bin/env python3
"""Reference values for t/incomplete.gamma.beta.mpmath.t, and the constant
tables LikeR.xs carries for a wide NV.

Re-run:

    python3 t/incomplete.gamma.beta.mpmath.py cases     > /tmp/cases.pl
    python3 t/incomplete.gamma.beta.mpmath.py constants > /tmp/constants.txt

`cases` prints the three Perl arrays (@GAMMA, @BETA, @QUANT) that are pasted
between the BEGIN/END GENERATED markers of the test; it needs mpmath
(1.3.0 was used) and takes a few minutes, nearly all of it the a = 1e10
series. `constants` prints the C literals behind NVK_*, lgamma1p()'s 60
coefficients, stirlerr()'s half-integer table and Stirling coefficients, all
at 42 digits. The test never runs this script.

Every input is an exact binary number m * 2**e (m < 2**53), written to the
file as the pair (m, e) so that Perl builds the identical NV at every width
and mpmath gets the identical rational; no input passes through a decimal
string. The references are NOT mpmath's own gammainc()/betainc(), which give
up (NoConvergence) once the shape is a few thousand: they are the defining
series and continued fractions, summed at mp.dps = 110 (the prefactor is
exp(a log x - x - loggamma(a + 1)), whose argument is ~1e10 at a = 1e8, hence
the working precision), and checked against mpmath's gammainc()/betainc()
wherever those converge. Expected values are printed at 40 digits.

    P(a, x)  = x^a e^-x / Gamma(a + 1) sum_n x^n / ((a + 1) ... (a + n))   x < a + 1
    Q(a, x)  = x^a e^-x / Gamma(a) 1/(x + 1 - a - 1(1 - a)/(x + 3 - a - ...))   x >= a + 1
    I_x(a,b) = x^a (1-x)^b / (a B(a, b)) betacf(a, b, x)        x < (a + 1)/(a + b + 2)
               1 - (the same with a <-> b, x <-> y)             otherwise

(Lentz's evaluation of Numerical Recipes' betacf, at 110 digits.) The other
tail is 1 minus the one summed, which is exact at 110 digits for any tail
above 1e-60; the log of a tail within 1e-30 of 1 is its Taylor series, not a
log() of a number that has lost its digits.
"""
import math
import sys
from fractions import Fraction

from mpmath import mp, mpf, log, exp, loggamma, nstr, zeta, bernoulli, sqrt, pi, euler, gammainc, betainc, inf

mp.dps = 110


# ---------------------------------------------------------------- references
def gam_lower_series(a, x):
    s = mpf(1); t = mpf(1); n = 0
    eps = mpf(10) ** (-mp.dps + 5)
    while True:
        n += 1
        t *= x / (a + n)
        s += t
        if t < eps * s and n > x - a:
            break
    return exp(a * log(x) - x - loggamma(a + 1)) * s


def gam_upper_cf(a, x):
    tiny = mpf(10) ** (-mp.dps * 3)
    b = x + 1 - a
    c = 1 / tiny
    d = 1 / b
    h = d
    eps = mpf(10) ** (-mp.dps + 5)
    i = 1
    while True:
        an = -i * (i - a)
        b += 2
        d = an * d + b
        if abs(d) < tiny: d = tiny
        c = b + an / c
        if abs(c) < tiny: c = tiny
        d = 1 / d
        de = d * c
        h *= de
        i += 1
        if abs(de - 1) < eps:
            break
    return exp(a * log(x) - x - loggamma(a)) * h


def gam_ref(a, x):
    """(P, Q)"""
    if x < a + 1:
        P = gam_lower_series(a, x)
        return P, 1 - P
    Q = gam_upper_cf(a, x)
    return 1 - Q, Q


def beta_cf(a, b, x):
    tiny = mpf(10) ** (-mp.dps * 3)
    qab = a + b; qap = a + 1; qam = a - 1
    c = mpf(1); d = 1 - qab * x / qap
    if abs(d) < tiny: d = tiny
    d = 1 / d; h = d
    eps = mpf(10) ** (-mp.dps + 5)
    m = 0
    while True:
        m += 1
        m2 = 2 * m
        aa = m * (b - m) * x / ((qam + m2) * (a + m2))
        d = 1 + aa * d
        if abs(d) < tiny: d = tiny
        c = 1 + aa / c
        if abs(c) < tiny: c = tiny
        d = 1 / d; h *= d * c
        aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
        d = 1 + aa * d
        if abs(d) < tiny: d = tiny
        c = 1 + aa / c
        if abs(c) < tiny: c = tiny
        d = 1 / d; de = d * c; h *= de
        if abs(de - 1) < eps:
            break
    return h


def beta_ref(a, b, x, y):
    """(I_x(a,b), 1 - I_x(a,b)) for y = 1 - x exactly"""
    lf = a * log(x) + b * log(y) - (loggamma(a) + loggamma(b) - loggamma(a + b))
    if x < (a + 1) / (a + b + 2):
        I = exp(lf) * beta_cf(a, b, x) / a
        return I, 1 - I
    J = exp(lf) * beta_cf(b, a, y) / b
    return 1 - J, J


def lg(v, other):
    """log(v) where other = 1 - v"""
    if other < mpf(10) ** -30:
        return -(other + other ** 2 / 2 + other ** 3 / 3)
    return log(v)


def sanity():
    """the references against mpmath's own, where mpmath converges"""
    for a, x in [(mpf('0.5'), mpf('0.25')), (mpf(10), mpf(30)), (mpf(1000), mpf(1100)), (mpf('0.001'), mpf(2))]:
        P, Q = gam_ref(a, x)
        assert abs(P / gammainc(a, 0, x, regularized=True) - 1) < mpf(10) ** -90
        assert abs(Q / gammainc(a, x, inf, regularized=True) - 1) < mpf(10) ** -90
    for a, b, x in [(mpf(2), mpf(3), mpf('0.4')), (mpf('0.5'), mpf('0.7'), mpf('0.9')), (mpf(100), mpf(200), mpf('0.3'))]:
        I, _ = beta_ref(a, b, x, 1 - x)
        assert abs(I / betainc(a, b, 0, x, regularized=True) - 1) < mpf(10) ** -90


# --------------------------------------------------------------------- cases
def me(v, bits=24):
    """a positive rational as (m, e), v ~ m * 2**e with m < 2**bits (rounded)"""
    v = Fraction(v)
    e = math.floor(math.log2(float(v))) - (bits - 1)
    m = round(v / Fraction(2) ** e)
    while m % 2 == 0 and m > 0:
        m //= 2; e += 1
    return (m, e)


def val(p):
    return mpf(p[0]) * mpf(2) ** p[1]


def fmt(v):
    return nstr(v, 40, min_fixed=-30, max_fixed=30)


def gamma_cases():
    # a: shapes from 2^-10 through 1e10; x from z standard deviations about the mean a, z = -60 .. 60, plus fixed x
    A = [Fraction(1, 1024), Fraction(1, 8), Fraction(1, 2), 1, Fraction(3, 2), 3, Fraction(21, 2), 30, 100, 199, 250, 1000,
         Fraction(20001, 2), 10 ** 5, 10 ** 6, 3 * 10 ** 7, 10 ** 8, 10 ** 10]
    out = []
    for a in A:
        a = Fraction(a)
        zs = [-60, -10, -3, 0, 3, 10, 60] if a < 10 ** 9 else [-3, 0, 3]
        xs = set()
        for z in zs:
            x = a + z * Fraction(math.sqrt(a))
            if x > 0: xs.add(x)
        if a < 10 ** 9:
            for u in (Fraction(1, 100), Fraction(9, 10), Fraction(5, 4), 20):
                xs.add(a * u)
            for x in (Fraction(1, 2 ** 40), Fraction(99, 100), Fraction(101, 100), Fraction(6, 5), Fraction(13, 10)):
                xs.add(Fraction(x))
        for x in sorted(xs):
            out.append((me(a), me(x)))
    return out


def beta_cases():
    ZS = [-10, -3, 0, 3, 10]
    # a shape of 1/2 or 3/2 (a t test, a binomial tail) against each size, both ways round; the diagonal; a few
    # unequal big pairs, which are where bfrac() and basym() meet
    pairs = []
    for small in (Fraction(1, 2), Fraction(3, 2)):
        for big in (5, 50, 500, 1000, 10 ** 4, 10 ** 6):
            pairs.append((small, Fraction(big)))
            pairs.append((Fraction(big), small))
    for d in (5, 100, 1000, 10 ** 5, 10 ** 7):
        pairs.append((Fraction(d), Fraction(d)))
    for a, b in ((3000, 1000), (999, 1000), (Fraction(21, 2), 100), (10 ** 5, 10 ** 4), (2, 5), (5, 2)):
        pairs.append((Fraction(a), Fraction(b)))
    out = []
    for a, b in pairs:
        mean = a / (a + b)
        sd = math.sqrt(float(a * b / ((a + b) ** 2 * (a + b + 1))))
        xs = set()
        for z in ZS:
            x = mean + z * Fraction(sd)
            if 0 < x < 1: xs.add(x)
        for x in (Fraction(1, 1000), Fraction(1, 3), Fraction(9, 10)):
            xs.add(x)
        for x in sorted(xs):
            mx = me(x, 24)
            xv = Fraction(mx[0]) * Fraction(2) ** mx[1]
            y = 1 - xv
            if y.denominator > 2 ** 52 or not (0 < xv < 1): continue
            out.append((me(a), me(b), mx, me(y, 53)))
    # tiny shapes: a shape of 1/1024 is where the Numerical Recipes fraction and bpser's complement are worst
    for a, b in [(Fraction(1, 1024), 5), (Fraction(1, 1024), 500), (Fraction(1, 1024), Fraction(1, 2))]:
        for x in (Fraction(1, 10), Fraction(1, 2), Fraction(9, 10)):
            mx = me(x, 24); xv = Fraction(mx[0]) * Fraction(2) ** mx[1]
            out.append(('tiny', me(a), me(Fraction(b)), mx, me(1 - xv, 53)))
            out.append(('tiny', me(Fraction(b)), me(a), mx, me(1 - xv, 53)))
    return out


def quant_cases():
    PS = [Fraction(1, 2 ** 20), Fraction(1, 40), Fraction(3, 10), Fraction(9, 10), Fraction(999, 1000)]
    out = []
    for p in PS:
        for df in (1, 3, Fraction(21, 2), 100, 1000):
            for lower in (1, 0):
                out.append(('chisq', me(p), me(Fraction(df)), None, lower))
        for df in (1, 5, 30, 1000):
            for lower in (1, 0):
                out.append(('t', me(p), me(Fraction(df)), None, lower))
        for d1, d2 in ((3, 7), (10, 30), (100, 5), (1000, 1000)):
            for lower in (1, 0):
                out.append(('f', me(p), me(Fraction(d1)), me(Fraction(d2)), lower))
    return out


def quantile(c):
    k, pp, d1, d2, lower = c
    p = val(pp)
    if k == 'chisq':
        a = val(d1) / 2
        f = lambda q: gam_ref(a, q / 2)[0 if lower else 1]
        lo, hi = mpf(10) ** -30, mpf(10) ** 7
        for _ in range(500):
            mid = sqrt(lo * hi)
            if (f(mid) < p) == bool(lower): lo = mid
            else: hi = mid
            if hi / lo < 1 + mpf(10) ** -45: break
        return sqrt(lo * hi)
    if k == 't':
        df = val(d1)
        tail = p if p < mpf(1) / 2 else 1 - p
        neg = (p < mpf(1) / 2) if lower else (p > mpf(1) / 2)
        def upper(t):
            return beta_ref(df / 2, mpf(1) / 2, df / (df + t * t), t * t / (df + t * t))[0] / 2
        lo, hi = mpf(10) ** -30, mpf(10) ** 20
        for _ in range(500):
            mid = sqrt(lo * hi)
            if upper(mid) > tail: lo = mid
            else: hi = mid
            if hi / lo < 1 + mpf(10) ** -45: break
        t = sqrt(lo * hi)
        return -t if neg else t
    if k == 'f':
        a, b = val(d1) / 2, val(d2) / 2
        def f(q):
            I, J = beta_ref(a, b, val(d1) * q / (val(d1) * q + val(d2)), val(d2) / (val(d1) * q + val(d2)))
            return I if lower else J
        lo, hi = mpf(10) ** -30, mpf(10) ** 30
        for _ in range(800):
            mid = sqrt(lo * hi)
            if (f(mid) < p) == bool(lower): lo = mid
            else: hi = mid
            if hi / lo < 1 + mpf(10) ** -45: break
        return sqrt(lo * hi)


def pl(p):
    return '[%d,%d]' % p


def emit_cases():
    sanity()
    print('# BEGIN GENERATED by t/incomplete.gamma.beta.mpmath.py cases')
    print('# each row: [a, x, P(a,x), Q(a,x), log P, log Q]; a, x as [m, e] = m * 2**e')
    print('my @GAMMA = (')
    for a, x in gamma_cases():
        P, Q = gam_ref(val(a), val(x))
        print("\t[%s, %s, '%s', '%s', '%s', '%s']," % (pl(a), pl(x), fmt(P), fmt(Q), fmt(lg(P, Q)), fmt(lg(Q, P))))
    print(');')
    print('# each row: [a, b, x, y = 1 - x, I_x(a,b), 1 - I_x(a,b), log, log of the complement]; "tiny" rows lead with that word')
    print('my @BETA = (')
    for c in beta_cases():
        tag = ''
        if c[0] == 'tiny':
            tag = "'tiny', "; c = c[1:]
        a, b, x, y = c
        I, J = beta_ref(val(a), val(b), val(x), val(y))
        print("\t[%s%s, %s, %s, %s, '%s', '%s', '%s', '%s']," % (tag, pl(a), pl(b), pl(x), pl(y), fmt(I), fmt(J), fmt(lg(I, J)), fmt(lg(J, I))))
    print(');')
    print('# each row: [kind, p, df1, df2 or undef, lower_tail, q]')
    print('my @QUANT = (')
    for c in quant_cases():
        k, pp, d1, d2, lower = c
        print("\t['%s', %s, %s, %s, %d, '%s']," % (k, pl(pp), pl(d1), pl(d2) if d2 else 'undef', lower, fmt(quantile(c))))
    print(');')
    print('# END GENERATED')


# ----------------------------------------------------------------- constants
def emit_constants():
    def f42(v):
        return nstr(v, 42, min_fixed=-5, max_fixed=5)
    print('// NVK_*')
    for n, v in [('PI', pi), ('LN_2PI', log(2 * pi)), ('LN_SQRT_2PI', log(sqrt(2 * pi))), ('1_SQRT_2PI', 1 / sqrt(2 * pi)),
                 ('2_SQRT_PI', 2 / sqrt(pi)), ('EULER', euler), ('LN2', log(2))]:
        print('NVK_%s %s' % (n, f42(v)))
    print('// lgamma1p coefficients (zeta(i + 2) - 1)/(i + 2), i = 0..59, and c = zeta(62) - 1')
    for i in range(60):
        print('NV_LIT(%s),' % f42((zeta(i + 2) - 1) / (i + 2)))
    print('c =', f42(zeta(62) - 1))
    print('// stirlerr(n) = lgamma(n + 1) - (n + 1/2) log n + n - log sqrt(2 pi), n = 0.5, 1, ..., 15')
    for k in range(1, 31):
        n = mpf(k) / 2
        print('NV_LIT(%s), //%s' % (f42(loggamma(n + 1) - (n + mpf(1) / 2) * log(n) + n - log(sqrt(2 * pi))), n))
    print('// Stirling coefficients |B_2k|/(2k(2k - 1)), k = 1..30')
    for k in range(1, 31):
        print('NV_LIT(%s),' % f42(abs(bernoulli(2 * k)) / (2 * k * (2 * k - 1))))


if __name__ == '__main__':
    if len(sys.argv) != 2 or sys.argv[1] not in ('cases', 'constants'):
        sys.exit(__doc__)
    emit_cases() if sys.argv[1] == 'cases' else emit_constants()
