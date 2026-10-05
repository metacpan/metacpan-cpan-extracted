#!/usr/bin/env python3
#
# Regenerates the frozen pandas side of t/agg.R.pandas.t.  Re-run it with
#
#     /home/con/.pyenv/versions/3.14.2/bin/python t/agg.R.pandas.py > /tmp/agg.pandas.pl
#
# and paste the output over the "BEGIN GENERATED (pandas)" .. "END GENERATED
# (pandas)" block of t/agg.R.pandas.t.  The test itself never runs python:
# everything this prints is a Perl literal.
#
# Written against pandas 3.0.4 (numpy 2.4.6).  Every case comes from pandas'
# own groupby suite, pandas/tests/groupby/; the test function is named in the
# case's `name` field, which the .t prints as the test description:
#
#   aggregate/test_aggregate.py
#     test_groupby_aggregation_mixed_dtype      GH#6212
#     test_groupby_agg_dict_with_getitem        GH#25471
#     test_groupby_agg_dict_dup_columns         GH#55006
#     test_order_aggregate_multiple_funcs       GH#25692 ('ohlc' left out: agg()
#                                               has no such reducer)
#     test_agg_with_missing_values              GH#58810
#     test_groupby_aggregate_empty_key          GH#32580, first parametrisation
#     test_with_na_groups                       (float64 parametrisation)
#   test_reductions.py
#     test_basic_aggregations                   (float64 parametrisation)
#     test_mean_skipna, test_sum_skipna,        GH#15675, the float64 rows of
#     test_multifunc_skipna                     each, read from the test
#                                               module's own parametrize marks
#     test_cython_median
#     test_nunique
#   methods/test_nth.py
#     test_first_last_with_None_expanded        GH#32800, GH#38286
#
# Normalisations, each so that a pandas answer is comparable with agg()'s:
#
#   * NaN keys.  groupby() drops a group whose key is NaN unless dropna=False;
#     agg() always keeps it, as an undef key.  Every case here is computed with
#     dropna=False, so the frozen answer has those groups; the .t pins the
#     default (dropna=True) answer as a divergence.
#   * Names.  pandas' std is agg()'s sd, and size/len is n.  A frozen output
#     name is agg()'s: a column with one reducer keeps its name, with several
#     it is <col>_<func>.
#   * Floats.  A value is printed with repr(), the shortest string that reads
#     back as the same double; an integral float prints as an integer, since
#     perl prints 4.0 as 4.
#   * Order.  pandas sorts groups by key.  Where every key column holds one
#     type (all numbers, or all strings, NaN last) that is agg()'s rule too and
#     the case is marked ordered => 1, so the .t checks the order as well; a
#     column mixing numbers and strings (GH#6212) is compared by group only,
#     since pandas sorts the numbers before the strings and agg() compares
#     such a column as strings throughout.
#   * Random data.  test_basic_aggregations and test_cython_median draw from
#     np.random.default_rng(2) exactly as the tests do; the draw is frozen.

import ast
import math
import os
import numpy as np
import pandas as pd

assert pd.__version__ == "3.0.4", pd.__version__


def pv(v):
    if v is None or (isinstance(v, float) and math.isnan(v)) or v is pd.NA:
        return "undef"
    if isinstance(v, (bool, np.bool_)):
        raise ValueError("bool")
    if isinstance(v, str):
        return "'" + v.replace("\\", "\\\\").replace("'", "\\'") + "'"
    if isinstance(v, (int, np.integer)):
        return str(int(v))
    v = float(v)
    if math.isinf(v):
        raise ValueError("inf")
    if v == int(v) and abs(v) < 2**53:
        return str(int(v))
    return repr(v)


def qk(s):
    return pv(str(s))


def emit(name, data, by, agg, groups, skipna=1, ordered=0, aoa=None):
    """data: dict col -> list (or None with aoa); groups: [(keys, {out: val})]"""
    print("\t{")
    print(f"\t\tname    => {qk(name)},")
    if aoa is not None:
        print("\t\taoa     => [")
        for row in aoa:
            print("\t\t\t[ " + ", ".join(pv(v) for v in row) + " ],")
        print("\t\t],")
    else:
        print("\t\tcols    => [ " + ", ".join(qk(c) for c in data) + " ],")
        print("\t\tdata    => {")
        for c, vals in data.items():
            print(f"\t\t\t{qk(c)} => [ " + ", ".join(pv(v) for v in vals) + " ],")
        print("\t\t},")
    print("\t\tby      => [ " + ", ".join(qk(b) for b in by) + " ],")
    parts = []
    for c, f in agg.items():
        f = f if isinstance(f, list) else [f]
        parts.append(f"{qk(c)} => " + (qk(f[0]) if len(f) == 1
                     else "[ " + ", ".join(qk(x) for x in f) + " ]"))
    print("\t\tagg     => { " + ", ".join(parts) + " },")
    print(f"\t\tskipna  => {skipna},")
    print(f"\t\tordered => {ordered},")
    print("\t\tgroups  => [")
    for keys, vals in groups:
        print("\t\t\t[ [ " + ", ".join(pv(k) for k in keys) + " ], { "
              + ", ".join(f"{qk(o)} => {pv(v)}" for o, v in vals.items()) + " } ],")
    print("\t\t],")
    print("\t},")


def rows(res, by, outmap):
    """a grouped result with a (Multi)Index -> [(keys, {out: val})]"""
    out = []
    for idx, row in res.iterrows():
        keys = idx if isinstance(idx, tuple) else (idx,)
        out.append((list(keys), {o: row[c] for o, c in outmap.items()}))
    return out


# ---- GH#6212 ----------------------------------------------------------------
df = pd.DataFrame({
    "v1": [1, 3, 5, 7, 8, 3, 5, np.nan, 4, 5, 7, 9],
    "v2": [11, 33, 55, 77, 88, 33, 55, np.nan, 44, 55, 77, 99],
    "by1": ["red", "blue", 1, 2, np.nan, "big", 1, 2, "red", 1, np.nan, 12],
    "by2": ["wet", "dry", 99, 95, np.nan, "damp", 95, 99, "red", 99, np.nan, np.nan],
})
res = df.groupby(["by1", "by2"], dropna=False)[["v1", "v2"]].mean()
emit("test_aggregate.py test_groupby_aggregation_mixed_dtype GH#6212 (dropna=False)",
     {c: list(df[c]) for c in ["by1", "by2", "v1", "v2"]}, ["by1", "by2"],
     {"v1": "mean", "v2": "mean"}, rows(res, 2, {"v1": "v1", "v2": "v2"}))

# ---- GH#25471 ---------------------------------------------------------------
dat = pd.DataFrame({"A": ["A", "A", "B", "B", "B"], "B": [1, 2, 1, 1, 2]})
res = dat.groupby("A")[["B"]].agg({"B": "sum"})
emit("test_aggregate.py test_groupby_agg_dict_with_getitem GH#25471",
     {c: list(dat[c]) for c in dat}, ["A"], {"B": "sum"},
     rows(res, 1, {"B": "B"}), ordered=1)

# ---- GH#55006: duplicate column labels, so positional (AoA) only -------------
df = pd.DataFrame([[1, 2, 3, 4], [1, 3, 4, 5], [2, 4, 5, 6]], columns=["a", "b", "c", "c"])
res = df.groupby("a").agg({"b": "sum"})
emit("test_aggregate.py test_groupby_agg_dict_dup_columns GH#55006 (AoA, positions)",
     None, [0], {1: "sum"}, rows(res, 1, {1: "b"}), ordered=1,
     aoa=df.values.tolist())

# ---- GH#25692: reducer order is kept ----------------------------------------
df = pd.DataFrame({"A": [1, 1, 2, 2], "B": [1, 2, 3, 4]})
funcs = ["sum", "max", "mean", "min"]
res = df.groupby("A").agg(funcs)
res.columns = ["B_" + f for f in res.columns.get_level_values(1)]
emit("test_aggregate.py test_order_aggregate_multiple_funcs GH#25692 (without ohlc)",
     {c: list(df[c]) for c in df}, ["A"], {"B": funcs},
     rows(res, 1, {o: o for o in res.columns}), ordered=1)

# ---- GH#58810: ungrouped, an all-NaN column ----------------------------------
missing = pd.DataFrame({"nan": [np.nan] * 4, "values": [1, 2, 3, 4]})
res = missing.agg({"nan": "min", "values": "sum"})
emit("test_aggregate.py test_agg_with_missing_values GH#58810 (ungrouped)",
     {c: list(missing[c]) for c in missing}, [], {"nan": "min", "values": "sum"},
     [([], {"nan": res["nan"], "values": res["values"]})])

# ---- GH#32580 ---------------------------------------------------------------
df = pd.DataFrame({"a": [1, 1, 2], "b": [1, 2, 3], "c": [1, 2, 4]})
res = df.groupby("a").agg({"c": ["min"]})
res.columns = ["c"]
emit("test_aggregate.py test_groupby_aggregate_empty_key GH#32580 ({c: [min]})",
     {c: list(df[c]) for c in df}, ["a"], {"c": ["min"]},
     rows(res, 1, {"c": "c"}), ordered=1)

# ---- test_with_na_groups ----------------------------------------------------
values = [1.0] * 10
labels = [np.nan, "foo", "bar", "bar", np.nan, np.nan, "bar", "bar", np.nan, "foo"]
s = pd.Series(values)
res = s.groupby(pd.Series(labels), dropna=False).agg(len)
emit("test_aggregate.py test_with_na_groups (dropna=False, len -> n)",
     {"label": labels, "v": values}, ["label"], {"v": "n"},
     [([k], {"v": v}) for k, v in res.items()], ordered=1)

# ---- test_basic_aggregations ------------------------------------------------
data = pd.Series(np.arange(9) // 3, index=np.arange(9), dtype="float64")
index = np.arange(9)
np.random.default_rng(2).shuffle(index)
data = data.reindex(index)
key = [i // 3 for i in data.index]
grouped = data.groupby(lambda x: x // 3, group_keys=False)
res = grouped.agg(["mean", "std"])
emit("test_reductions.py test_basic_aggregations (float64; mean, std -> sd)",
     {"k": key, "v": list(data.values)}, ["k"], {"v": ["mean", "sd"]},
     [([k], {"v_mean": r["mean"], "v_sd": r["std"]}) for k, r in res.iterrows()],
     ordered=1)


# ---- GH#15675: skipna, from the tests' own parametrize marks -----------------
# Read out of the test file's syntax tree rather than by importing it: the
# module imports pytest, which need not be installed for this to run.
TR = os.path.join(os.path.dirname(pd.__file__), "tests", "groupby", "test_reductions.py")
with open(TR) as fh:
    TREE = ast.parse(fh.read())


def params(fname):
    fn = next(n for n in TREE.body if isinstance(n, ast.FunctionDef) and n.name == fname)
    for d in fn.decorator_list:
        if isinstance(d, ast.Call) and getattr(d.func, "attr", "") == "parametrize":
            names = [n.strip() for n in d.args[0].value.split(",")]
            for p in eval(ast.unparse(d.args[1]), {"np": np, "pd": pd}):
                yield dict(zip(names, p))


ours = {"mean": "mean", "sum": "sum", "var": "var", "std": "sd", "min": "min",
        "max": "max", "median": "median"}
skip_cases = []
for i, p in enumerate(params("test_mean_skipna")):
    skip_cases.append(("test_mean_skipna", "mean", i, p))
for i, p in enumerate(params("test_sum_skipna")):
    skip_cases.append(("test_sum_skipna", "sum", i, p))
for i, p in enumerate(params("test_multifunc_skipna")):
    skip_cases.append(("test_multifunc_skipna", p["func"], i, p))
for test, func, i, p in skip_cases:
    if p["dtype"] != "float64" or func not in ours:
        continue
    vals = [float(v) for v in p["values"]]
    df = pd.DataFrame({"val": vals, "cat": ["A", "B"] * 5})
    for skipna in (True, False):
        res = getattr(df.groupby("cat")["val"], func)(skipna=skipna)
        emit(f"test_reductions.py {test} GH#15675 (parametrisation {i}: {func}, skipna={skipna})",
             {"cat": list(df["cat"]), "val": vals}, ["cat"], {"val": ours[func]},
             [([k], {"val": v}) for k, v in res.items()],
             skipna=int(skipna), ordered=1)

# ---- test_cython_median -----------------------------------------------------
arr = np.random.default_rng(2).standard_normal(1000)
arr[::2] = np.nan
labels = np.random.default_rng(2).integers(0, 50, size=1000).astype(float)
labels[::17] = np.nan
df = pd.DataFrame({"lab": labels, "x": arr})
res = df.groupby("lab", dropna=False)["x"].median()
emit("test_reductions.py test_cython_median (dropna=False)",
     {c: list(df[c]) for c in df}, ["lab"], {"x": "median"},
     [([k], {"x": v}) for k, v in res.items()], ordered=1)

# ---- test_nunique -----------------------------------------------------------
df = pd.DataFrame({"A": list("abbacc"), "B": list("abxacc"), "C": list("abbacx")})
res = df.groupby("A").nunique()
emit("test_reductions.py test_nunique", {c: list(df[c]) for c in df}, ["A"],
     {"B": "nunique", "C": "nunique"}, rows(res, 1, {"B": "B", "C": "C"}), ordered=1)
dfn = df.replace({"x": None})
res = dfn.groupby("A").nunique()           # dropna=True: what agg() counts
emit("test_reductions.py test_nunique (x replaced by None, dropna)",
     {c: list(dfn[c]) for c in dfn}, ["A"], {"B": "nunique", "C": "nunique"},
     rows(res, 1, {"B": "B", "C": "C"}), ordered=1)

# ---- GH#32800 / GH#38286 ----------------------------------------------------
for i, (vals, exp) in enumerate([([None, "foo", np.nan], "foo"), ([np.nan], None)]):
    df = pd.DataFrame({"id": "a", "value": vals}, dtype=object)
    for how in ("first", "last"):
        res = getattr(df.groupby("id"), how)()
        got = res["value"].iloc[0]
        assert (got is None and exp is None) or got == exp or (
            exp is None and isinstance(got, float) and math.isnan(got)), (got, exp)
        emit(f"test_nth.py test_first_last_with_None_expanded GH#32800/38286 ({how}, case {i})",
             {"id": list(df["id"]), "value": list(df["value"])}, ["id"],
             {"value": how}, [(["a"], {"value": got})], ordered=1)
