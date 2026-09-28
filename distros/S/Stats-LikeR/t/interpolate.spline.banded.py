# Generator for t/interpolate.spline.banded.t -- see that file's header.
import numpy as np
from scipy.interpolate import CubicSpline, make_interp_spline
def col(n):
    y = np.array([np.nan if (i % 10 == 5 or i % 23 == 7) else np.sin(i/13.0) + i/500.0
                  for i in range(n)], dtype=float)
    y[0] = 0.25; y[-1] = 4.5
    return y
for n in (200, 2000, 20000):
    y = col(n); x = np.arange(n, dtype=float)
    ok = ~np.isnan(y); xa, ya = x[ok], y[ok]
    gaps = np.flatnonzero(~ok)
    cs = CubicSpline(xa, ya, bc_type='not-a-knot')
    q  = make_interp_spline(xa, ya, k=2)   # scipy interp1d 'quadratic' == degree-2 B-spline
    sample = gaps[:: max(1, len(gaps)//12)][:12]
    print("\t# n = %d, %d anchors, %d gaps" % (n, ok.sum(), len(gaps)))
    print("\t[ %d, [" % n)
    for i in sample:
        print("\t\t[ %d, %.17g, %.17g ]," % (i, cs(float(i)), q(float(i))))
    print("\t] ],")
