# Generator for t/interpolate.nan.pandas.t -- see that file's header.
# Re-run: python3 -I t/interpolate.nan.pandas.py   (pandas 3.0.4, scipy 1.18.1)
# and paste the output over the @CASES table in the .t file.
import itertools
import numpy as np
import pandas as pd

nan = np.nan
# (source in pandas/tests/series/methods/test_interpolate.py, series)
SERIES = [
    ("test_interp_limit",                   [1, 3, nan, nan, nan, 11]),
    ("test_interp_limit_forward",           [nan, 1.0, 3.0, nan, nan, nan, 11.0, nan]),
    ("test_interp_limit_area",              [nan, nan, 3, nan, nan, nan, 7, nan, nan]),
    ("test_interp_limit_direction",         [1, 3, nan, nan, nan, 7, 9, nan, nan, 12, nan]),
    ("test_interp_limit_to_ends",           [nan, nan, 5, 7, 9, nan]),
    ("test_interp_limit_before_ends",       [nan, nan, 5, 7, nan, nan]),
    ("test_interp_limit_direction_limit_exceeds_length", [nan, 1, 1, 1, 1, nan]),
    ("test_interp_limit_direction_limit_exceeds_length s2", [1, nan, nan, 4]),
    ("test_interpolate_invalid_nonpositive_limit",       [1, 3, nan, 12, nan, 25]),
    ("test_interp_all_good-style, line 676",             [1, 2, nan, 4, 5, nan, 7]),
    ("audit 2026-11-03 (cubic with an interior gap run)", [1, nan, 3, nan, 5, nan, 7, 8, 9]),
    ("audit 2026-11-03 (leading NaN run)",               [nan, nan, 2, 4, nan, 8, 16, 32, nan]),
]
LOCAL = ["linear", "slinear", "nearest", "zero"]
HOLD = ["pad", "bfill"]
GLOBAL = [("quadratic", None), ("cubic", None), ("cubicspline", None), ("pchip", None),
          ("akima", None), ("barycentric", None), ("krogh", None), ("polynomial", 2)]

def run(vals, method, order, limit, d, area):
    s = pd.Series(vals, dtype=float)
    if method in ("pad", "bfill"):
        # pandas 3 dropped these from interpolate(); ffill()/bfill() are the same fill
        f = s.ffill if method == "pad" else s.bfill
        return f(limit=limit, limit_area=area).tolist()
    kw = dict(method=method)
    if order is not None: kw["order"] = order
    if limit is not None: kw["limit"] = limit
    if d is not None: kw["limit_direction"] = d
    if area is not None: kw["limit_area"] = area
    return s.interpolate(**kw).tolist()

def lit(v):
    return "undef" if v != v else repr(float(v))

def emit(method, order, limit, d, area, vals, out):
    print("\t[ %r, %s, %s, %s, %s, [ %s ], [ %s ] ]," % (
        method,
        "undef" if order is None else order,
        "undef" if limit is None else limit,
        "undef" if d is None else repr(d),
        "undef" if area is None else repr(area),
        ", ".join(lit(v) for v in vals), ", ".join(lit(v) for v in out)))

for name, vals in SERIES:
    print("\t# %s" % name)
    for m in LOCAL:
        for limit, d, area in itertools.product([None, 1, 2], ["forward", "backward", "both"],
                                                [None, "inside", "outside"]):
            emit(m, None, limit, d, area, vals, run(vals, m, None, limit, d, area))
    for m in HOLD:
        for limit, area in itertools.product([None, 1, 2], [None, "inside", "outside"]):
            emit(m, None, limit, None, area, vals, run(vals, m, None, limit, None, area))
    anchors = sum(1 for v in vals if v == v)
    for m, order in GLOBAL:
        if anchors < 4: continue
        for d, area in itertools.product([None, "both"], [None, "inside"]):
            try:
                out = run(vals, m, order, None, d, area)
            except Exception:
                continue
            emit(m, order, None, d, area, vals, out)
