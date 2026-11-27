# Generator for t/skew_kurtosis.scipy.t: prints the frozen SciPy values.
# Re-run with
#     /home/con/.pyenv/versions/3.14.2/bin/python3 -I t/skew_kurtosis.scipy.py
# (SciPy 1.18.1, NumPy 2.4.6 printed the values committed in the test on
# 2026-11-26.)  Type 3 (e1071's b1 and b2) is not in SciPy; it is computed here
# from its definition, m3 / s**3 and m4 / s**4 - 3 with s the n - 1 standard
# deviation, which is independent of the README's (n-1)/n rewrite.
import numpy as np
from scipy import stats
import scipy
R = lambda v: repr(float(v))
print("scipy", scipy.__version__, "numpy", np.__version__)
mw = [1.165, 0.6268, 0.0751, 0.3516, -0.6965]
tc = [1., 2., 3., 4.]
print("skew mw bias=True ", R(stats.skew(mw)))
print("skew mw bias=False", R(stats.skew(mw, bias=False)))
print("skew tc           ", R(stats.skew(tc)))
print("kurt mw fisher=0 bias=1", R(stats.kurtosis(mw, 0, fisher=0, bias=1)))
print("kurt mw fisher=0 bias=0", R(stats.kurtosis(mw, fisher=0, bias=0)))
print("kurt tc fisher=0       ", R(stats.kurtosis(tc, 0, 0)))
x = np.arange(10.); x[9] = np.nan
print("skew omit nan", R(stats.skew(x, nan_policy='omit')))
print("kurt omit nan", R(stats.kurtosis(x, nan_policy='omit')))
a = np.arange(8).reshape(2, -1).astype(float)
print("kurt row0", R(stats.kurtosis(a[0])))
def t3s(v):
    v = np.asarray(v, float); m3 = np.mean((v - v.mean())**3); return m3 / v.std(ddof=1)**3
def t3k(v):
    v = np.asarray(v, float); m4 = np.mean((v - v.mean())**4); return m4 / v.std(ddof=1)**4 - 3
for name, v in (("mw", mw), ("tc", tc), ("x2", [2, 4, 4, 4, 5, 5, 7, 9]), ("x124", [1, 2, 4]), ("x1_2_3_10", [1, 2, 3, 10])):
    print(name, "skew types", R(stats.skew(v)), R(stats.skew(v, bias=False)), R(t3s(v)))
    if len(v) > 3:
        print(name, "kurt types", R(stats.kurtosis(v)), R(stats.kurtosis(v, bias=False)), R(t3k(v)))
rng = np.random.default_rng(1283413549926)
xs = rng.random((3, 4, 5))
print("SKEWX", [R(v) for v in xs.ravel()])
for bias in (False, True):
    print("skew vectorization axis=None bias=%s" % bias, R(stats.skew(xs, axis=None, bias=bias)))
print("skew axis=-1 bias=True row0,0", R(stats.skew(xs, axis=-1, bias=True)[0, 0]))
rng = np.random.default_rng(1283413549926)
xk = rng.random((4, 5, 6))
print("KURTX", [R(v) for v in xk.ravel()])
for bias in (False, True):
    for fisher in (False, True):
        print("kurt vectorization axis=None bias=%s fisher=%s" % (bias, fisher), R(stats.kurtosis(xk, axis=None, bias=bias, fisher=fisher)))
print("kurt axis=-1 row0,0 bias=True fisher", R(stats.kurtosis(xk, axis=-1)[0, 0]))
print("type3 skew xs", R(t3s(xs.ravel())), "kurt xk", R(t3k(xk.ravel())))
