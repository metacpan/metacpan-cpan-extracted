# Generator for the pandas half of the frozen expectations in
# t/frame.cleaning.R.pandas.t (fillna, ffill, bfill, dropna, drop_duplicates,
# value_counts).
#
# Re-run with
#
#     python3 -I t/frame.cleaning.R.pandas.py
#
# and compare its output with the %FR, @DD, @FILL, @DROP and @VC tables in the
# .t file.  The test never runs this, or Python.
#
# pandas 3.0.4, pandas/tests/:
#   frame/methods/test_drop_duplicates.py  test_drop_duplicates,
#       test_drop_duplicates_for_take_all, test_drop_duplicates_NA,
#       test_drop_duplicates_NA_for_take_all, test_drop_duplicates_empty,
#       and the GH 11376 and GH 11864 frames inside test_drop_duplicates
#   frame/methods/test_dropna.py  test_dropEmptyRows, test_dropIncompleteRows,
#       test_dropna, test_dropna_multiple_axes, test_dropna_tz_aware_datetime,
#       test_set_single_column_subset, test_subset_is_nparray,
#       test_no_nans_in_frame
#   frame/methods/test_drop.py  test_drop (the labels path, for rows =>)
#   frame/methods/test_fillna.py  test_fillna_different_dtype,
#       test_fillna_mixed_type, test_frame_fillna_limit,
#       test_frame_pad_backfill_limit, test_ffill_bfill_limit_area (run with
#       limit alone), test_inplace_dict_update_view,
#       test_fillna_dictlike_value_duplicate_colnames
#   series/methods/test_fillna.py  test_series_fillna_limit
#   series/methods/test_value_counts.py and base/test_value_counts.py
#   frame/methods/test_value_counts.py  test_data_frame_value_counts_subset
# Each case below names the test its input comes from.  Inputs written as
# np.random.default_rng(2).standard_normal(...) upstream are replaced by
# dyadic literals (k / 4), since only the NA pattern matters to a fill.
import json
import sys

import numpy as np
import pandas as pd

nan = np.nan

def pl(v):
    if v is None or (isinstance(v, float) and v != v) or v is pd.NA:
        return "undef"
    if isinstance(v, (bool, np.bool_)):
        return "1" if v else "0"
    if isinstance(v, (int, np.integer)):
        return str(int(v))
    if isinstance(v, (float, np.floating)):
        return repr(float(v))
    if isinstance(v, str):
        return "'" + v.replace("\\", "\\\\").replace("'", "\\'") + "'"
    if isinstance(v, (list, tuple, np.ndarray)):
        return "[" + ", ".join(pl(x) for x in v) + "]"
    if isinstance(v, dict):
        return "{ " + ", ".join("%s => %s" % (pl(str(k)), pl(x)) for k, x in v.items()) + " }"
    raise TypeError(repr(v))

def cols_of(df):
    return {str(c): list(df[c].astype(object).where(df[c].notna(), None)) for c in df.columns}

FR = {}   # frame name -> (column order, columns)
def frame(name, df):
    FR[name] = ([str(c) for c in df.columns], cols_of(df))
    return df

def kept(df, res):
    return [int(i) for i in res.index]

print("# ---- frames (HoA; column order, then columns)")
print("my %FR = (")
# --- drop_duplicates frames
dfA = frame("dd_main", pd.DataFrame({
    "AAA": ["foo", "bar", "foo", "bar", "foo", "bar", "bar", "foo"],
    "B": ["one", "one", "two", "two", "two", "two", "one", "two"],
    "C": [1, 1, 2, 2, 2, 2, 1, 2], "D": list(range(8))}))
dfT = frame("dd_take_all", pd.DataFrame({
    "AAA": ["foo", "bar", "baz", "bar", "foo", "bar", "qux", "foo"],
    "B": ["one", "one", "two", "two", "two", "two", "one", "two"],
    "C": [1, 1, 2, 2, 2, 2, 1, 2], "D": list(range(8))}))
dfN = frame("dd_NA_str", pd.DataFrame({
    "A": [None, None, "foo", "bar", "foo", "bar", "bar", "foo"],
    "B": ["one", "one", "two", "two", "two", "two", "one", "two"],
    "C": [1.0, nan, nan, nan, 1.0, 1.0, 1, 1.0], "D": list(range(8))}))
dfM = frame("dd_NA_num", pd.DataFrame({
    "A": ["foo", "bar", "foo", "bar", "foo", "bar", "bar", "foo"],
    "B": ["one", "one", "two", "two", "two", "two", "one", "two"],
    "C": [1.0, nan, nan, nan, 1.0, 1.0, 1, 1.0], "D": list(range(8))}))
dfNT = frame("dd_NA_take_all", pd.DataFrame({
    "A": [None, None, "foo", "bar", "foo", "baz", "bar", "qux"],
    "C": [1.0, nan, nan, nan, 1.0, 2.0, 3, 1.0]}))
dfG = frame("dd_gh11376", pd.DataFrame({"x": [7, 6, 3, 3, 4, 8, 0], "y": [0, 6, 5, 5, 9, 1, 2]}))
dfL = frame("dd_gh11864", pd.concat([pd.DataFrame([i] * 9 for i in range(16)),
    pd.DataFrame([[1] + [0] * 8])], ignore_index=True))
dfL.columns = ["c%d" % i for i in range(9)]
FR["dd_gh11864"] = ([str(c) for c in dfL.columns], cols_of(dfL))
dfInt = frame("dd_int", pd.DataFrame([[1, 0], [0, 2]], columns=["p", "q"]))
dfNeg = frame("dd_neg", pd.DataFrame([[-2, 0], [0, -4]], columns=["p", "q"]))
dd_cases = []
def dd(name, fr, df, subset, keep):
    sub = subset if subset is not None else None
    res = df.drop_duplicates(subset, keep=keep) if subset is not None else df.drop_duplicates(keep=keep)
    dd_cases.append((name, fr, subset, "none" if keep is False else keep, kept(df, res)))
for keep in ["first", "last", False]:
    for sub in ["AAA", ["AAA", "B"], "C", "B"]:
        dd("test_drop_duplicates", "dd_main", dfA, sub, keep)
    for sub in ["AAA", ["AAA", "B"]]:
        dd("test_drop_duplicates_for_take_all", "dd_take_all", dfT, sub, keep)
    for sub in ["A", ["A", "B"]]:
        dd("test_drop_duplicates_NA (None)", "dd_NA_str", dfN, sub, keep)
    for sub in ["C", ["C", "B"]]:
        dd("test_drop_duplicates_NA (nan)", "dd_NA_num", dfM, sub, keep)
    dd("test_drop_duplicates_NA_for_take_all A", "dd_NA_take_all", dfNT, "A", keep)
    dd("test_drop_duplicates_NA_for_take_all C", "dd_NA_take_all", dfNT, "C", keep)
    dd("GH 11376", "dd_gh11376", dfG, None, keep)
    dd("GH 11864", "dd_gh11864", dfL, None, keep)
    dd("test_drop_duplicates [[1,0],[0,2]]", "dd_int", dfInt, None, keep)
    dd("test_drop_duplicates [[-2,0],[0,-4]]", "dd_neg", dfNeg, None, keep)
# whole-row ("consider everything") on the three-column frame
three = frame("dd_main3", dfA[["AAA", "B", "C"]])
for keep in ["first", "last", False]:
    dd("test_drop_duplicates (consider everything)", "dd_main3", three, None, keep)
print(",\n".join("\t%s => { cols => %s, data => %s }" % (pl(k), pl(v[0]), pl(v[1])) for k, v in FR.items()))
print(");")
print("# ---- drop_duplicates cases: [pandas test, frame, subset, keep, kept row indices]")
print("my @DD = (")
for c in dd_cases:
    print("\t[ %s, %s, %s, %s, %s ]," % (pl(c[0]), pl(c[1]), pl(c[2]) if c[2] is not None else "undef", pl(c[3]), pl(c[4])))
print(");")
# misspelled column (GH 19730) is an error in pandas, checked in the .t

# ---------------------------------------------------------- fill cases
print("# ---- fill cases: [pandas test, op, args, input frame, expected frame]")
print("my @FILL = (")
def ent(name, op, args, df, exp):
    print("\t[ %s, %s, %s,\n\t\t{ cols => %s, data => %s },\n\t\t{ cols => %s, data => %s } ]," % (
        pl(name), pl(op), pl(args) if args else "{}",
        pl([str(c) for c in df.columns]), pl(cols_of(df)),
        pl([str(c) for c in exp.columns]), pl(cols_of(exp))))

df = pd.DataFrame([["a", "a", nan, "a"], ["b", "b", nan, "b"], ["c", "c", nan, "c"]])
df.columns = ["0", "1", "2", "3"]
ent("test_fillna_different_dtype", "fillna", {"value": {"2": "foo"}}, df, df.fillna({"2": "foo"}))
ent("test_fillna_different_dtype (scalar)", "fillna", {"value": "foo"}, df, df.fillna("foo"))
ent("test_fillna_different_dtype (ffill)", "ffill", {}, df, df.ffill())
ent("test_fillna_different_dtype (bfill)", "bfill", {}, df, df.bfill())

df = pd.DataFrame({"x": [nan, 2], "y": [nan, 2]})
ent("test_inplace_dict_update_view (scalar)", "fillna", {"value": -1}, df, df.fillna(-1))
ent("test_inplace_dict_update_view (dict)", "fillna", {"value": {"x": -1, "y": -1}}, df, df.fillna({"x": -1, "y": -1}))
ent("fillna dict names one column only", "fillna", {"value": {"x": -1}}, df, df.fillna({"x": -1}))
ent("fillna dict with an unknown column (ignored)", "fillna", {"value": {"x": -1, "zz": 5}}, df, df.fillna({"x": -1, "zz": 5}))

# test_fillna_mixed_type: ffill of a string column and a float column
mf = pd.DataFrame({"A": [1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5],
                   "foo": ["bar", "bar", nan, nan, nan, "bar", nan, "bar"]})
mf.loc[mf.index[-3:], "A"] = nan
ent("test_fillna_mixed_type (ffill)", "ffill", {}, mf, mf.ffill())
ent("test_fillna_mixed_type (bfill)", "bfill", {}, mf, mf.bfill())
ent("test_fillna_mixed_type (fillna 0)", "fillna", {"value": 0}, mf, mf.fillna(value=0))
ent("test_fillna_mixed_type (cols)", "fillna", {"value": 0, "cols": ["A"]}, mf,
    mf.assign(A=mf["A"].fillna(0)))

# test_frame_fillna_limit / test_frame_pad_backfill_limit
index = np.arange(10)
base = pd.DataFrame(np.arange(40).reshape(10, 4) / 4.0, index=index, columns=list("abcd"))
for lim in [None, 1, 2, 5]:
    top = base[:2].reindex(index)
    bot = base[-2:].reindex(index)
    kw = {} if lim is None else {"limit": lim}
    ent("test_frame_fillna_limit ffill %s" % lim, "ffill", kw, top, top.ffill(**kw))
    ent("test_frame_fillna_limit bfill %s" % lim, "bfill", kw, bot, bot.bfill(**kw))

# test_ffill_bfill_limit_area, data and limit only
d9 = [nan, nan, 3, nan, nan, nan, 7, nan, nan]
for lim in [None, 1, 2, 3]:
    kw = {} if lim is None else {"limit": lim}
    d = pd.DataFrame({"v": d9})
    ent("test_ffill_bfill_limit_area data, ffill %s" % lim, "ffill", kw, d, d.ffill(**kw))
    ent("test_ffill_bfill_limit_area data, bfill %s" % lim, "bfill", kw, d, d.bfill(**kw))
d = pd.DataFrame({"v": [nan] * 7})
ent("test_ffill_bfill_limit_area all NaN", "ffill", {"limit": 1}, d, d.ffill(limit=1))
ent("test_ffill_bfill_limit_area all NaN", "bfill", {"limit": 1}, d, d.bfill(limit=1))
d = pd.DataFrame({"v": list(range(5))})
ent("test_ffill_bfill_limit_area no NaN", "ffill", {"limit": 1}, d, d.ffill(limit=1))

# two columns with different gaps, cols restriction
d = pd.DataFrame({"a": [1.0, nan, nan, 4.0, nan], "b": [nan, 2.0, nan, nan, 5.0]})
ent("two columns, ffill", "ffill", {}, d, d.ffill())
ent("two columns, bfill", "bfill", {}, d, d.bfill())
ent("two columns, ffill limit 1", "ffill", {"limit": 1}, d, d.ffill(limit=1))
ent("two columns, bfill limit 1", "bfill", {"limit": 1}, d, d.bfill(limit=1))
ent("two columns, ffill of a only", "ffill", {"cols": ["a"]}, d, d.assign(a=d["a"].ffill()))
ent("two columns, bfill of b only, limit 1", "bfill", {"cols": ["b"], "limit": 1}, d, d.assign(b=d["b"].bfill(limit=1)))
ent("two columns, fillna scalar", "fillna", {"value": 0.5}, d, d.fillna(0.5))
ent("two columns, fillna cols b", "fillna", {"value": 0.5, "cols": ["b"]}, d, d.assign(b=d["b"].fillna(0.5)))
ent("two columns, fillna dict", "fillna", {"value": {"a": -1.0, "b": -2.0}}, d, d.fillna({"a": -1.0, "b": -2.0}))
d = pd.DataFrame({"a": [1.0, 2.0], "b": [3.0, 4.0]})
ent("no NA at all", "fillna", {"value": 99}, d, d.fillna(99))
print(");")

# ----------------------------------------------------------- dropna cases
print("# ---- dropna cases: [pandas test, frame, cols, how, kept row indices]")
print("my @DROP = (")
def dn(name, df, cols, how="any"):
    fr = "dn_" + str(len(DN))
    DN[fr] = ([str(c) for c in df.columns], cols_of(df))
    res = df.dropna(subset=cols, how=how)
    print("\t[ %s, %s, %s, %s, %s ]," % (pl(name), pl(fr), pl(cols), pl(how), pl(kept(df, res))))
DN = {}
mat = np.arange(10) / 4.0
mat[:5] = nan
f = pd.DataFrame({"foo": mat})
dn("test_dropEmptyRows how=all, foo", f, ["foo"], "all")
dn("test_dropEmptyRows how=any, foo", f, ["foo"], "any")
f["bar"] = 5
dn("test_dropIncompleteRows (all columns)", f, ["foo", "bar"])
dn("test_dropIncompleteRows subset=bar", f, ["bar"])
df6 = pd.DataFrame(np.arange(24).reshape(6, 4) / 4.0)
df6.iloc[:2, 2] = nan
df6.columns = ["0", "1", "2", "3"]
dn("test_dropna axis=0", df6, ["0", "1", "2", "3"])
dn("test_dropna subset=[0,1,3]", df6, ["0", "1", "3"])
dn("test_dropna subset=[2] how=all", df6, ["2"], "all")
df6b = df6.copy(); df6b["2"] = nan
dn("test_dropna df[2]=nan how=all, all cols", df6b, ["0", "1", "2", "3"], "all")
dn("test_dropna df[2]=nan how=any, all cols", df6b, ["0", "1", "2", "3"], "any")
dm = pd.DataFrame([[1, nan, 2, 3], [4, nan, 5, 6], [nan, nan, nan, nan], [7, nan, 8, 9]])
dm.columns = ["0", "1", "2", "3"]
dn("test_dropna_multiple_axes how=all", dm, ["0", "1", "2", "3"], "all")
dn("test_dropna_multiple_axes how=any", dm, ["0", "1", "2", "3"], "any")
dn("test_dropna_multiple_axes how=all, cols 0,2", dm, ["0", "2"], "all")
tz = pd.DataFrame({"Time": ["2015-01-01", None, nan, "2015-02-02"]})
dn("test_dropna_tz_aware_datetime Ex2", tz, ["Time"])
dn("test_set_single_column_subset", pd.DataFrame({"A": [1, 2, 3], "B": list("abc"), "C": [4, nan, 5]}), ["C"])
dn("test_subset_is_nparray", pd.DataFrame({"A": [1, 2, nan], "B": list("abc"), "C": [4, nan, 5]}), ["A", "C"])
dn("test_subset_is_nparray how=all", pd.DataFrame({"A": [1, 2, nan], "B": list("abc"), "C": [4, nan, 5]}), ["A", "C"], "all")
dn("test_no_nans_in_frame", pd.DataFrame([[1, 2], [3, 4]], columns=["0", "1"]), ["0", "1"])
dn("test_dropIncompleteRows, all NaN col", pd.DataFrame({"a": [nan, nan], "b": [1, 2]}), ["a", "b"])
dn("test_dropIncompleteRows, all NaN col", pd.DataFrame({"a": [nan, nan], "b": [1, 2]}), ["a", "b"], "all")
print(");")
print("my %DN = (")
print(",\n".join("\t%s => { cols => %s, data => %s }" % (pl(k), pl(v[0]), pl(v[1])) for k, v in DN.items()))
print(");")

# rows => : DataFrame.drop(index=...) from test_drop.py test_drop (labels path)
print("# ---- dropna rows => cases: [pandas test, frame, rows, kept row indices]")
print("my @ROWS = (")
df = pd.DataFrame({"A": [10, 20, 30, 40, 50], "B": list("abcde")})
for rows in [[1], [0, 4], [1, 1], [0, 1, 2, 3, 4], []]:
    res = df.drop(index=rows)
    print("\t[ 'DataFrame.drop(index=%s)', %s, %s, %s ]," % (rows, pl("rows5"), pl(rows), pl(kept(df, res))))
res = df.drop(index=[1, 99], errors="ignore")
print("\t[ 'DataFrame.drop(index=[1, 99], errors=ignore)', 'rows5', [1, 99], %s ]," % pl(kept(df, res)))
print(");")
print("my %%ROWF5 = ( cols => ['A', 'B'], data => %s );" % pl(cols_of(df)))

# ----------------------------------------------------------- value_counts
print("# ---- value_counts cases: [pandas test, values, expected counts]")
print("my @VC = (")
def vc(name, values):
    s = pd.Series(values, dtype=object)
    r = s.value_counts()  # dropna=True is the default
    exp = {str(k): int(v) for k, v in r.items()}
    print("\t[ %s, %s, %s ]," % (pl(name), pl(list(values)), pl(exp)))
vc("test_value_counts_categorical (object part)", ["a", "b", "c", "c", "c", "b"])
vc("test_value_counts_masked dropna=True", [1, 2, None, 2, None, 3])
vc("test_value_counts_categorical_with_nan dropna=True", ["a", "b", None, "a", None, None])
vc("test_data_frame_value_counts_single_col_default", [2, 4, 4, 6])
vc("test_data_frame_value_counts_subset (first_name)", ["John", "Anne", "John", "Beth"])
vc("test_data_frame_value_counts_subset (middle_name, dropna)", ["Smith", None, None, "Louise"])
vc("test_value_counts_bool_with_nan dropna=True", ["True", "False", "True", None])
vc("all identical", ["x"] * 5)
vc("one value", ["x"])
vc("empty-string key and whitespace", ["", " ", "", "a b"])
vc("numbers as keys", [1, 2, 2, 3, 3, 3])
vc("test_value_counts_complex_numbers values as text", ["1+1j", "1+1j", "1", "3j", "3j", "3j"])
print(");")
