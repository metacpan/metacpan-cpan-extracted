#!/usr/bin/env python3
"""Reference values for t/pnorm.qnorm.mpmath.t.

Re-run:

    python3 t/pnorm.qnorm.mpmath.py > /tmp/cases.pl

and paste the output between the BEGIN/END GENERATED markers of the test. It
needs mpmath (1.3.0 was used) and takes a few seconds. The test never runs this
script.

Every input is an exact binary number m * 2**e (m < 2**53), written to the file
as the pair (m, e) so that Perl builds the identical NV at every width and
mpmath gets the identical rational; no input passes through a decimal string.
Work is at mp.dps = 110 and expected values are printed at 40 digits.

    Phi(z)      = erfc(-z / sqrt(2)) / 2, mpmath's erfc() at 110 digits
    log Phi(z)  = log of that for z <= 0, log1p(-(the upper tail)) for z > 0
    qnorm       = the root z of log Phi(z) = log p (lower tail; an upper-tail p, and
                  a log p above log 1/2, is the negated root for the other
                  tail), by Newton on the defining
                  equation from z = -sqrt(-2 log p), then checked by bisection's
                  test: log Phi changes sign about log p across z (1 +- 1e-90).
                  No library inverse is called.
"""
from fractions import Fraction

from mpmath import mp, mpf, erfc, sqrt, log, log1p, exp, expm1, nstr, pi

mp.dps = 110


def pair(v):
    """(m, e) with v == m * 2**e exactly, m odd or zero."""
    f = Fraction(v)
    if f == 0:
        return (0, 0)
    e = 0
    while f.denominator != 1:
        f *= 2
        e -= 1
    m = f.numerator
    while m % 2 == 0:
        m //= 2
        e += 1
    assert abs(m) < 2 ** 53, v
    return (m, e)


def val(p):
    m, e = p
    return mpf(m) * mpf(2) ** e


def s(x):
    return nstr(x, 40, strip_zeros=True, min_fixed=-4, max_fixed=4) if x != 0 else '0'


def phi_lower(z):
    return erfc(-z / sqrt(2)) / 2


def log_phi_lower(z):
    if z > 0:
        u = erfc(z / sqrt(2)) / 2  # the upper tail
        return log1p(-u)
    return log(phi_lower(z))


def fmt_pair(p):
    return '[%d,%d]' % p


# ------------------------------------------------------------------ pnorm
# z: the body, both sides of the double cut-off at -38.4674 (R's), the point
# (10) where LikeR.xs's wide path changes method, the x87/quad underflow near
# -150, and the far log tail.
Z = [0.0, 2.0 ** -60, 2.0 ** -20, 0.125, 0.5, 0.75, 1.0, 1.5, 1.96, 2.0, 2.5,
     3.0, 4.0, 5.0, 5.5, 6.0, 7.5, 8.0, 9.0, 9.9375, 10.0, 10.0625, 12.5, 15.0,
     20.0, 26.0, 30.0, 37.5, 38.4375, 38.5, 40.0, 50.0, 64.0, 100.0, 140.0,
     150.0, 1000.0, 2.0 ** 20, 1e9, 2.0 ** 40, 1e15, 2.0 ** 100, 1e150]
print('# each row: [z, Phi(z), 1 - Phi(z), log Phi(z), log(1 - Phi(z))]; z as [m, e] = m * 2**e')
print('my @PNORM = (')
for z0 in Z:
    for z in ([z0] if z0 == 0 else [-z0, z0]):
        p = pair(z)
        zz = val(p)
        lo = phi_lower(zz)
        up = phi_lower(-zz)
        llo = log_phi_lower(zz)
        lup = log_phi_lower(-zz)
        print("\t[%s, '%s', '%s', '%s', '%s']," % (fmt_pair(p), s(lo), s(up), s(llo), s(lup)))
print(');')

# pnorm(x, mean, sd): the standardization (x - mean) / sd at the NV's width.
# Each is an exact case: mean and sd dyadic, x chosen so the z above is one of
# a few values, and the reference takes the exact rational (x - mean) / sd.
MS = [(100.0, 15.0, 70.0), (100.0, 15.0, 160.0), (-3.25, 0.125, -8.5),
      (1e6, 2.0 ** -10, 1e6 - 0.0390625), (0.0, 1e-300, -1e-299),
      (5.0, 3.0, -100.0)]
print('# each row: [x, mean, sd, Phi, 1 - Phi, log Phi, log(1 - Phi)]')
print('my @PNORM_MS = (')
for mu, sd, x in MS:
    px, pm, ps = pair(x), pair(mu), pair(sd)
    zz = (val(px) - val(pm)) / val(ps)
    print("\t[%s, %s, %s, '%s', '%s', '%s', '%s']," % (
        fmt_pair(px), fmt_pair(pm), fmt_pair(ps), s(phi_lower(zz)), s(phi_lower(-zz)),
        s(log_phi_lower(zz)), s(log_phi_lower(-zz))))
print(');')


# ------------------------------------------------------------------ qnorm
def qnorm_lower_log(lp):
    """The z with log Phi(z) = lp, by Newton on the defining equation."""
    lp = mpf(lp)
    if lp > log(mpf('0.5')):  # above the median: the negated root for the other tail
        return -qnorm_lower_log(log(-expm1(lp)))
    z = -sqrt(-2 * lp)
    for _ in range(400):
        lc = log_phi_lower(z)
        dens = exp(-z * z / 2) / sqrt(2 * pi)
        step = (lc - lp) * exp(lc) / dens  # d log Phi / dz = phi / Phi
        z -= step
        if abs(step) <= abs(z) * mpf(10) ** (-mp.dps + 8) + mpf(10) ** (-mp.dps + 8):
            break
    else:
        raise RuntimeError('no convergence at lp=%s' % lp)
    d = abs(z) * mpf(10) ** -90 + mpf(10) ** -100
    assert (log_phi_lower(z - d) - lp) * (log_phi_lower(z + d) - lp) <= 0, lp
    return mpf(0) if abs(z) < mpf(10) ** -90 else z  # p = 1/2: Newton's last step leaves 1e-112


# p (linear scale), both tails: dyadic p and the doubles of common decimal ones
P = [0.5, 0.5 - 2.0 ** -30, 0.5 + 2.0 ** -30, 0.4, 0.25, 0.1, 0.05, 0.025,
     0.01, 0.005, 1e-3, 1e-5, 1e-10, 2.0 ** -40, 1e-20, 1e-50, 1e-100, 1e-200,
     1e-299, 2.0 ** -1000, 1e-305, 2.0 ** -1022, 2.0 ** -1074,
     0.9, 0.95, 0.975, 0.99, 0.995, 0.999, 1 - 2.0 ** -16, 1 - 2.0 ** -40, 1 - 2.0 ** -53]
print('# each row: [p, lower_tail, z]; p as [m, e]')
print('my @QNORM = (')
for p0 in P:
    pp = pair(p0)
    pv = val(pp)
    for lower in (1, 0):
        z = qnorm_lower_log(log(pv))
        if not lower:
            z = -z
        print("\t[%s, %d, '%s']," % (fmt_pair(pp), lower, s(z)))
print(');')

# log p, both tails: past a double's exp() underflow, and near 0
LP = [-2.0 ** -60, -2.0 ** -20, -0.5, -1.0, -10.0, -100.0, -700.0, -745.0,
      -800.0, -1000.0, -5000.0, -11000.0, -1e5, -1e8, -1e10, -1e15, -1e20,
      -1e100]
print('# each row: [log p, lower_tail, z]; log p as [m, e]')
print('my @QNORM_LOG = (')
for l0 in LP:
    lpp = pair(l0)
    lp = val(lpp)
    z = qnorm_lower_log(lp)
    print("\t[%s, 1, '%s']," % (fmt_pair(lpp), s(z)))
    print("\t[%s, 0, '%s']," % (fmt_pair(lpp), s(-z)))
print(');')
