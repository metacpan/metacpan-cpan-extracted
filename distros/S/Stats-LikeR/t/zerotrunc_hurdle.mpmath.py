#!/usr/bin/env python3
"""Exact optima for t/zerotrunc_hurdle.R.t, as a third opinion.

countreg and pscl maximise their likelihoods with optim(method = "BFGS") and
take standard errors from optim()'s finite-difference Hessian, so neither is
the MLE itself, only an approximation to it.  This script answers the
question they approximate, independently of them and of LikeR: each
log-likelihood is written out below from its definition, in mpmath at
mp.dps = 60, and maximised by Newton-Raphson (Levenberg-Marquardt damped
where the Hessian is not negative definite) on mpmath's numerical
derivatives -- solving the defining equation, score = 0, rather than
trusting any optimiser's stopping rule.  The standard errors are the square
roots of the diagonal of the inverse negative Hessian at that point.

Re-run with

    python3 t/zerotrunc_hurdle.mpmath.py > /tmp/zt_exact.pl

after t/zerotrunc_hurdle.R.R (which writes the CSV files read here), and
paste the printed %EXACT block over the one in the .t file.  The test never
runs this script.

The data are read as doubles and converted with mpf(float), so the optimum is
the one for exactly the numbers the test reads (see the note on mpf(str) in
t/distributions.mpmath.py).  Written for mpmath 1.3.0 and numpy 2.5.2
(numpy is only used for the double-precision starting values).
"""

import csv
import os
import sys

import numpy as np
from mpmath import mp, mpf, log, exp, loggamma, log1p, expm1, matrix, lu_solve, inverse, sqrt, diff

mp.dps = 60
T = os.path.join(os.path.dirname(os.path.abspath(__file__)))


def read(name):
    with open(os.path.join(T, name)) as f:
        rows = list(csv.DictReader(f))
    return {k: [r[k] for r in rows] for k in rows[0]}


def design(cols, intercept=True):
    n = len(cols[0])
    X = []
    for i in range(n):
        X.append(([1.0] if intercept else []) + [float(c[i]) for c in cols])
    return X


def mprows(X):
    return [[mpf(v) for v in row] for row in X]


def poisson_start(X, y, off=None, w=None):
    """Double-precision Poisson IRLS, for starting values only."""
    X = np.asarray(X, float); y = np.asarray(y, float)
    off = np.zeros(len(y)) if off is None else np.asarray(off, float)
    w = np.ones(len(y)) if w is None else np.asarray(w, float)
    b = np.zeros(X.shape[1]); b[0] = np.log(max(np.mean(y), 1e-3))
    for _ in range(50):
        eta = X @ b + off; mu = np.exp(eta)
        z = eta - off + (y - mu) / mu; W = w * mu
        b = np.linalg.solve(X.T @ (X * W[:, None]), X.T @ (W * z))
    return list(b)


def logit_start(X, z, w=None):
    X = np.asarray(X, float); z = np.asarray(z, float)
    w = np.ones(len(z)) if w is None else np.asarray(w, float)
    b = np.zeros(X.shape[1])
    for _ in range(50):
        eta = X @ b; p = 1 / (1 + np.exp(-eta))
        W = w * p * (1 - p); zz = eta + (z - p) / (p * (1 - p))
        b = np.linalg.solve(X.T @ (X * W[:, None]), X.T @ (W * zz))
    return list(b)


def ll_trunc(dist, X, y, off, w):
    """log f(y) - log(1 - f(0)), summed with weights; theta = exp(last) for negbin."""
    k = len(X[0])

    def f(*par):
        th = exp(par[k]) if dist == 'negbin' else (mpf(1) if dist == 'geometric' else None)
        tot = mpf(0)
        for i in range(len(y)):
            eta = off[i] + sum(X[i][j] * par[j] for j in range(k))
            mu = exp(eta)
            if th is None:
                lf = y[i] * eta - mu - loggamma(y[i] + 1)
                l0 = log(-expm1(-mu))
            else:
                lf = (loggamma(y[i] + th) - loggamma(th) - loggamma(y[i] + 1)
                      + th * log(th / (th + mu)) + y[i] * log(mu / (th + mu)))
                l0 = log(1 - (th / (th + mu)) ** th)
            tot += w[i] * (lf - l0)
        return tot
    return f


def ll_zero(dist, X, y, off, w):
    """The zero hurdle: log P(y = 0) or log P(y > 0) per row."""
    k = len(X[0])

    def f(*par):
        tot = mpf(0)
        for i in range(len(y)):
            eta = off[i] + sum(X[i][j] * par[j] for j in range(k))
            if dist == 'binomial':
                lp1 = -log1p(exp(-eta)); lp0 = -log1p(exp(eta))
            else:
                mu = exp(eta)
                if dist == 'poisson':
                    lp0 = -mu
                elif dist == 'geometric':
                    lp0 = -log1p(mu)
                else:
                    th = exp(par[k]); lp0 = th * log(th / (th + mu))
                lp1 = log(-expm1(lp0))
            tot += w[i] * (lp1 if y[i] > 0 else lp0)
        return tot
    return f


def grad_hess(f, par):
    n = len(par)
    g = [diff(f, par, tuple(1 if j == a else 0 for j in range(n))) for a in range(n)]
    H = matrix(n, n)
    for a in range(n):
        for b in range(a, n):
            order = [0] * n
            order[a] += 1; order[b] += 1
            H[a, b] = H[b, a] = diff(f, par, tuple(order))
    return g, H


def maximise(f, par):
    """Damped Newton to a step below 1e-20 of each parameter's size.

    mpmath's diff() at mp.dps = 60 is good to far more than that, so the
    answer is exact for every purpose a double can see; asking for much less
    than the derivatives' own accuracy would never stop.  50 iterations is a
    bound; the corpora converge in 5 to 12."""
    par = [mpf(p) for p in par]
    n = len(par)
    ll = f(*par)
    for _ in range(50):
        g, H = grad_hess(f, par)
        lam = mpf(0)
        for _ in range(60):
            A = -H + lam * matrix([[abs(H[i, i]) if i == j else 0 for j in range(n)] for i in range(n)])
            try:
                mp.cholesky(A)
                break
            except (ValueError, ZeroDivisionError):
                lam = mpf('1e-4') if lam == 0 else lam * 10
        step = lu_solve(A, matrix(g))
        t = mpf(1)
        for _ in range(60):
            trial = [par[i] + t * step[i] for i in range(n)]
            ll_new = f(*trial)
            if ll_new >= ll - mpf('1e-40') * abs(ll):
                break
            t /= 2
        big = max(abs(t * step[i]) / (1 + abs(par[i])) for i in range(n))
        par, ll = trial, ll_new
        print('#   step %.3g ll %s' % (float(big), mp.nstr(ll, 20)), file=sys.stderr, flush=True)
        if lam == 0 and t == 1 and big < mpf('1e-20'):
            break
    g, H = grad_hess(f, par)
    V = inverse(-H)
    return par, [sqrt(V[i, i]) for i in range(n)], f(*par)


def fmt(v):
    v = float(v)
    for d in (15, 16, 17):
        s = '%.*g' % (d, v)
        if float(s) == v:
            return s
    return repr(v)


OUT = {}


def record(key, **kw):
    OUT[key] = kw


# ---------------------------------------------------------------- CrabSatellites
cs = read('CrabSatellites.csv')
Xa = design([cs['width'], cs['colorn']])
ya = [int(v) for v in cs['satellites']]
pos = [i for i, v in enumerate(ya) if v > 0]
Xp = [Xa[i] for i in pos]; yp = [ya[i] for i in pos]
Xp_m, Xa_m = mprows(Xp), mprows(Xa)
one_p, one_a = [mpf(1)] * len(yp), [mpf(1)] * len(ya)
zero_p, zero_a = [mpf(0)] * len(yp), [mpf(0)] * len(ya)
count = {}
for d in ('poisson', 'negbin', 'geometric'):
    st = poisson_start(Xp, yp) + ([0.0] if d == 'negbin' else [])
    par, se, ll = maximise(ll_trunc(d, Xp_m, [mpf(v) for v in yp], zero_p, one_p), st)
    count[d] = (par, se, ll)
    record('crab_zt_' + d, coef=par[:3], se=se[:3], ll=ll,
           theta=exp(par[3]) if d == 'negbin' else None, sel=se[3] if d == 'negbin' else None)
for zd in ('binomial', 'poisson', 'geometric', 'negbin'):
    if zd in ('binomial', 'geometric'):
        st = logit_start(Xa, [1.0 if v > 0 else 0.0 for v in ya])
    else:
        st = poisson_start(Xa, ya)
    if zd == 'negbin':
        st = st + [0.0]
    zpar, zse, zll = maximise(ll_zero(zd, Xa_m, ya, zero_a, one_a), st)
    for cd in ('poisson', 'negbin', 'geometric'):
        par, se, ll = count[cd]
        record('crab_h_%s_%s' % (cd, zd), count=par[:3], zero=zpar[:3], count_se=se[:3],
               zero_se=zse[:3], ll=ll + zll,
               theta=exp(par[3]) if cd == 'negbin' else None,
               theta_zero=exp(zpar[3]) if zd == 'negbin' else None)

# ---------------------------------------------------------------- docvis
dv = read('docvis.csv')
Xd = design([dv['aget'], dv['totchr']])
yd = [int(v) for v in dv['docvis']]
posd = [i for i, v in enumerate(yd) if v > 0]
Xdp = [Xd[i] for i in posd]; ydp = [yd[i] for i in posd]
Xdp_m = mprows(Xdp)
for d in ('poisson', 'negbin'):
    st = poisson_start(Xdp, ydp) + ([0.0] if d == 'negbin' else [])
    par, se, ll = maximise(ll_trunc(d, Xdp_m, [mpf(v) for v in ydp], [mpf(0)] * len(ydp),
                                    [mpf(1)] * len(ydp)), st)
    record('docvis_zt_' + d, coef=par[:3], se=se[:3], ll=ll,
           theta=exp(par[3]) if d == 'negbin' else None, sel=se[3] if d == 'negbin' else None)
    if d == 'poisson':
        cpar, cse, cll = par, se, ll
zpar, zse, zll = maximise(ll_zero('poisson', mprows(Xd), yd, [mpf(0)] * len(yd), [mpf(1)] * len(yd)),
                          poisson_start(Xd, yd))
record('docvis_h_poisson_poisson', count=cpar, zero=zpar, count_se=cse, zero_se=zse, ll=cll + zll)

# ---------------------------------------------------------------- bioChemists
bc = read('bioChemists.csv')
fem = [1.0 if v == 'Women' else 0.0 for v in bc['fem']]
mar = [1.0 if v == 'Single' else 0.0 for v in bc['mar']]
Xb = design([fem, mar, bc['kid5'], bc['phd'], bc['ment']])
yb = [int(v) for v in bc['art']]
posb = [i for i, v in enumerate(yb) if v > 0]
Xbp = [Xb[i] for i in posb]; ybp = [yb[i] for i in posb]
par, se, ll = maximise(ll_trunc('negbin', mprows(Xbp), [mpf(v) for v in ybp], [mpf(0)] * len(ybp),
                                [mpf(1)] * len(ybp)), poisson_start(Xbp, ybp) + [0.0])
zpar, zse, zll = maximise(ll_zero('binomial', mprows(Xb), yb, [mpf(0)] * len(yb), [mpf(1)] * len(yb)),
                          logit_start(Xb, [1.0 if v > 0 else 0.0 for v in yb]))
record('bio_h_negbin', count=par[:6], zero=zpar, count_se=se[:6], zero_se=zse, ll=ll + zll,
       theta=exp(par[6]), sel=se[6])
# with the offset and weights
lexpo = [np.log(float(v)) for v in bc['expo']]
wt = [float(v) for v in bc['wt']]
Zb = design([fem, bc['kid5']])
par, se, ll = maximise(ll_trunc('poisson', mprows(Xbp), [mpf(v) for v in ybp],
                                [mpf(lexpo[i]) for i in posb], [mpf(wt[i]) for i in posb]),
                       poisson_start(Xbp, ybp, [lexpo[i] for i in posb], [wt[i] for i in posb]))
zpar, zse, zll = maximise(ll_zero('binomial', mprows(Zb), yb, [mpf(0)] * len(yb), [mpf(v) for v in wt]),
                          logit_start(Zb, [1.0 if v > 0 else 0.0 for v in yb], wt))
record('bio_h_off_w', count=par, zero=zpar, count_se=se, zero_se=zse, ll=ll + zll)

print('my %EXACT = (')
for key, rec in OUT.items():
    print('  %s => {' % key)
    for f, v in rec.items():
        if v is None:
            continue
        if isinstance(v, (list, tuple)):
            print('    %s => [%s],' % (f, ', '.join(fmt(x) for x in v)))
        else:
            print('    %s => %s,' % (f, fmt(v)))
    print('  },')
print(');')
