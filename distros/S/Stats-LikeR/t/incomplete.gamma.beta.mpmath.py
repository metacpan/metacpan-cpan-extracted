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

Past a gamma shape of 1e10 and a larger beta shape of 1e7 the series and
fractions need tens of sqrt(shape) terms, too many at 110 digits, and the
reference is instead the defining integral, by mpmath's tanh-sinh quad() at the
same precision (gam_ref_quad(), beta_ref_quad()): the integrand about its
mean, scaled by the standard deviation, over 60 pieces out to where it has
fallen by e^-300, the smaller tail integrated and the other 1 minus it.
sanity() checks the integrals against the series and fractions at shapes both
reach (1e6 to 1e10 gamma, 1e4 to 1e7 beta); they agreed to 1e-101. These cases
take about two of the generator's minutes.
"""
import math
import sys
from fractions import Fraction

from mpmath import mp, mpf, log, log1p, exp, loggamma, nstr, zeta, bernoulli, sqrt, pi, euler, gammainc, betainc, inf, quad

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


def tail_integral(lf, lo, hi, peak, scale):
    """The integral of exp(lf(u)) over [lo, hi] (hi may be inf), for an lf that is
    unimodal with its maximum at peak (clipped into [lo, hi]) and falls by about 1
    over `scale` near it. The range is cut where lf has fallen 300 below its
    maximum (e^-300 = 1e-130, past the 110 digits), and the rest is split into
    60 pieces for mpmath's tanh-sinh quadrature."""
    m = min(max(peak, lo), hi)
    top = lf(m)

    def edge(direction, bound):
        step, u = scale, m
        while True:
            v = u + direction * step
            if (direction > 0 and v >= bound) or (direction < 0 and v <= bound):
                return bound
            if lf(v) < top - 300:
                return v
            u, step = v, step * 2

    left = edge(-1, lo) if m > lo else lo
    right = edge(+1, hi) if m < hi else hi
    pts = sorted(set([left + (right - left) * k / 60 for k in range(61)] + [m]))
    return quad(lambda u: exp(lf(u) - top), pts) * exp(top)


def gam_ref_quad(a, x):
    """(P, Q) for a shape the series cannot reach in reasonable time (past 1e10 it needs
    tens of sqrt(a) terms), as the integral of t^(a-1) e^-t / Gamma(a) with
    t = a + sqrt(a) u, the smaller tail integrated and the other 1 minus it."""
    s = sqrt(a)
    c = (a - 1) * log(a) - a - loggamma(a) + log(s)

    def lf(u):
        r = u / s
        return c + (a - 1) * log1p(r) - a * r
    ux = (x - a) / s
    if x < a - 1:
        P = tail_integral(lf, -s, ux, -1 / s, 1 / max(1, abs(ux)))
        return P, 1 - P
    Q = tail_integral(lf, ux, inf, -1 / s, 1 / max(1, abs(ux)))
    return 1 - Q, Q


def beta_ref_quad(a, b, x, y):
    """(I_x(a, b), 1 - I_x(a, b)) past the shapes the fraction reaches in reasonable
    time, as the integral of t^(a-1) (1-t)^(b-1) / B(a, b) with t = mean + sd u."""
    n = a + b
    mu = a / n
    sd = sqrt(a * b / (n * n * (n + 1)))
    c = -(loggamma(a) + loggamma(b) - loggamma(n)) + log(sd)

    def lf(u):
        t = mu + sd * u
        return c + (a - 1) * log(t) + (b - 1) * log1p(-t)
    ux = (x - mu) / sd
    lo, hi = -mu / sd, (1 - mu) / sd
    mode_t = (a - 1) / (n - 2) if a > 1 and b > 1 else (mpf(0) if a < 1 else mpf(1))
    mode = (mode_t - mu) / sd
    if x < mode_t:
        I = tail_integral(lf, lo, ux, mode, 1 / max(1, abs(ux)))
        return I, 1 - I
    J = tail_integral(lf, ux, hi, mode, 1 / max(1, abs(ux)))
    return 1 - J, J


QUAD_GAMMA = 10 ** 10   # gamma shapes above this take gam_ref_quad()
QUAD_BETA = 10 ** 7     # beta pairs whose larger shape is above this take beta_ref_quad()


def gam_ref_any(a, x):
    return gam_ref_quad(a, x) if a > QUAD_GAMMA else gam_ref(a, x)


def beta_ref_any(a, b, x, y):
    return beta_ref_quad(a, b, x, y) if max(a, b) > QUAD_BETA else beta_ref(a, b, x, y)


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
    # the quadrature against the series and fraction where both reach (they agreed to 1e-101 when this was written)
    for a, x in [(10 ** 6, 10 ** 6 - 3000), (10 ** 8, 10 ** 8 + 30000), (10 ** 8, 10 ** 8 - 600000), (10 ** 10, 10 ** 10 + 300000)]:
        P1, Q1 = gam_ref(mpf(a), mpf(x))
        P2, Q2 = gam_ref_quad(mpf(a), mpf(x))
        assert abs(P2 / P1 - 1) < mpf(10) ** -90 and abs(Q2 / Q1 - 1) < mpf(10) ** -90
    for a, b, x in [(10 ** 7, 10 ** 7, mpf('0.5003')), (mpf('1.5'), 10 ** 4, mpf('0.0002')), (10 ** 4, mpf('1.5'), mpf('0.9997')),
                    (mpf('0.5'), 10 ** 6, mpf('1e-6')), (3 * 10 ** 5, 10 ** 6, mpf('0.2306'))]:
        I1, J1 = beta_ref(mpf(a), mpf(b), x, 1 - x)
        I2, J2 = beta_ref_quad(mpf(a), mpf(b), x, 1 - x)
        assert abs(I2 / I1 - 1) < mpf(10) ** -90 and abs(J2 / J1 - 1) < mpf(10) ** -90


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
    # a < 1 with x from 1 to 3, where the continued fraction runs longest (300 to 400 terms)
    for a in (Fraction(1, 1024), Fraction(1, 8), Fraction(1, 2), Fraction(15, 16)):
        for x in (Fraction(21, 20), Fraction(3, 2), 2, Fraction(5, 2), 3):
            if (me(a), me(Fraction(x))) not in out:
                out.append((me(a), me(Fraction(x))))
    # past the series' reach, through Temme's expansion: gam_ref_quad(); x to 40 bits, as 24 cannot resolve sqrt(a)
    for a in (10 ** 11, 10 ** 12, 10 ** 13, 10 ** 14, 10 ** 15, 2 ** 50 + 2 ** 20):
        a = Fraction(a)
        for z in (-1000, -100, -30, -3, 0, 3, 30, 100, 1000):
            out.append((me(a, 53), me(a + z * Fraction(math.isqrt(int(a))), 40)))
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
            out.append(('', me(a), me(b), mx, me(y, 53)))
    # tiny shapes: a shape of 1/1024 is where the Numerical Recipes fraction and bpser's complement are worst
    for a, b in [(Fraction(1, 1024), 5), (Fraction(1, 1024), 500), (Fraction(1, 1024), Fraction(1, 2))]:
        for x in (Fraction(1, 10), Fraction(1, 2), Fraction(9, 10)):
            mx = me(x, 24); xv = Fraction(mx[0]) * Fraction(2) ** mx[1]
            out.append(('tiny', me(a), me(Fraction(b)), mx, me(1 - xv, 53)))
            out.append(('tiny', me(Fraction(b)), me(a), mx, me(1 - xv, 53)))

    def both_ways(tag, a0, b0, x0):
        """I_x0(a0, b0) and the same probability turned round, I_(1-x0)(b0, a0)"""
        mx = me(Fraction(x0), 24); xv = Fraction(mx[0]) * Fraction(2) ** mx[1]
        my = me(1 - xv, 53)
        out.append((tag, me(Fraction(a0)), me(Fraction(b0)), mx, my))
        out.append((tag, me(Fraction(b0)), me(Fraction(a0)), my, mx))
    # "bup": TOMS 708's bup() + bgrat(), which R's bratio() takes for a smaller shape a0 <= 1 against a larger
    # b0 <= 15 with x0 in [0.1, 0.29) and (x0 b0)^a0 > 0.7, and for both shapes <= 1 with a0 < 0.2, x0^a0 > 0.9
    # and x0 < 0.3. Up to 0.3428 both went to the Numerical Recipes fraction.
    for a0 in (Fraction(1, 1024), Fraction(1, 2), 1):
        for b0 in (Fraction(15, 2), 15):
            for x0 in (Fraction(1, 10), Fraction(1, 5), Fraction(7, 25)):
                both_ways('bup', a0, b0, x0)
    for a0 in (Fraction(1, 1024), Fraction(1, 64)):
        for b0 in (Fraction(1, 4), 1):
            for x0 in (Fraction(1, 100), Fraction(1, 10), Fraction(1, 5)):
                both_ways('bup', a0, b0, x0)
    # "eps": a shape below NV_EPSILON (TOMS 708's apser() and fpser(), and the b/(a + b) of two shapes below
    # NV_EPSILON/1000). 2^-70 is below a long double's epsilon and above a __float128's; 2^-130 is below both.
    for t in (Fraction(1, 2 ** 70), Fraction(1, 2 ** 130)):
        for b0 in (Fraction(1, 2), 3, 1000):
            for x0 in (Fraction(1, 100), Fraction(1, 4), Fraction(1, 2)):
                both_ways('eps', t, b0, x0)
    for x0 in (Fraction(1, 4), Fraction(1, 2)):
        both_ways('eps', Fraction(1, 2 ** 140), Fraction(1, 2 ** 150), x0)
    # past the fraction's reach (beta_ref_quad()): the diagonal to 1e15 (basym()), unequal huge pairs (basym() with
    # its r1 != 0), and a small shape against a huge one both ways round (bfrac(), bpser(), bgrat()). x is a
    # multiple of 2^-53, so that 1 - x is exact however small the mean.
    for a, b in [(10 ** 8, 10 ** 8), (10 ** 10, 10 ** 10), (10 ** 12, 10 ** 12), (10 ** 15, 10 ** 15), (3 * 10 ** 11, 10 ** 12),
                 (10 ** 13, 10 ** 9), (Fraction(1, 2), 10 ** 9), (10 ** 12, Fraction(1, 2)), (Fraction(3, 2), 10 ** 10),
                 (10 ** 10, Fraction(3, 2)), (5, 10 ** 12), (Fraction(1, 1024), 10 ** 9)]:
        a, b = Fraction(a), Fraction(b)
        mean = a / (a + b)
        sd = math.sqrt(float(a * b / ((a + b) ** 2 * (a + b + 1))))
        for z in (-30, -10, -3, 0, 3, 10, 30):
            xv = Fraction(round((mean + z * Fraction(sd)) * 2 ** 53), 2 ** 53)
            if not (0 < xv < 1): continue
            out.append(('', me(a, 53), me(b, 53), me(xv, 53), me(1 - xv, 53)))
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
        P, Q = gam_ref_any(val(a), val(x))
        print("\t[%s, %s, '%s', '%s', '%s', '%s']," % (pl(a), pl(x), fmt(P), fmt(Q), fmt(lg(P, Q)), fmt(lg(Q, P))))
    print(');')
    print('# each row: [a, b, x, y = 1 - x, I_x(a,b), 1 - I_x(a,b), log, log of the complement]; "tiny", "bup" and "eps" rows lead with that word')
    print('my @BETA = (')
    for c in beta_cases():
        tag = "'%s', " % c[0] if c[0] else ''
        a, b, x, y = c[1:]
        I, J = beta_ref_any(val(a), val(b), val(x), val(y))
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
