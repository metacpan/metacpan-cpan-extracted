# Generator for t/group_by.R.pandas.t (pandas half).  Run with
#     python3 -I t/group_by.R.pandas.py
# pandas 3.0.4 / NumPy 2.4.6.  Prints, for each case, the groups
# df.groupby(key, dropna=True)[value] gives as {key: [values]}:
#   pandas/tests/groupby/test_groupby_dropna.py
#     ::test_groupby_dropna_normal_index_dataframe (GH 3729): frame a, b, c, d;
#       the groups of b, c and d by a, from which the test's sums follow
#     ::test_groupby_dropna_series_by: values [390, 350, 30, 20] by
#       ["a", "b", "a", NaN], whose means are the test's [210, 350]
#     ::test_groupby_nan_included (GH 35646): "group" with NaN keys, B 0..4;
#       the test uses dropna=False, whose NaN group has no counterpart here,
#       so the dropna=True groups g1 [0, 2] and g2 [3] are used
# pandas keeps a NaN *value* in its group (apply(list)); group_by() leaves it
# out (README), so NaN values are dropped from the expectation here.
import numpy as np, pandas as pd
print("# pandas", pd.__version__, "numpy", np.__version__)
def fmt(v):
    return "undef" if isinstance(v, float) and v != v else (
        "'%s'" % v if isinstance(v, str) else repr(float(v)) if isinstance(v, float) else str(v))
def groups(df, key, val):
    out = {}
    for k, g in df.groupby(key, dropna=True, sort=True):
        out[k] = [x for x in g[val].tolist() if x == x]
    return out
def emit(name, rows_cols, key, vals):
    df = pd.DataFrame(rows_cols)
    print("\t%s => {" % name)
    for v in vals:
        print("\t\t%s => {" % v)
        for k, l in groups(df, key, v).items():
            print("\t\t\t'%s' => [%s]," % (k, ", ".join(fmt(x) for x in l)))
        print("\t\t},")
    print("\t},")
print("my %PD = (")
emit("gh3729", {"a": ["B", None, "A", "B"], "b": [12, 12.3, 123.23, 1],
                "c": [12, 233.0, 123, 1], "d": [12, 12, 1, 1.0]}, "a", ["b", "c", "d"])
emit("series_by", {"k": ["a", "b", "a", np.nan], "v": [390.0, 350.0, 30.0, 20.0]}, "k", ["v"])
emit("nan_included", {"group": ["g1", np.nan, "g1", "g2", np.nan], "B": [0, 1, 2, 3, 4]}, "group", ["B"])
print(");")
print("my %PDDATA = (")
print("\tgh3729 => { a => ['B', undef, 'A', 'B'], b => [12, 12.3, 123.23, 1], c => [12, 233, 123, 1], d => [12, 12, 1, 1] },")
print("\tseries_by => { k => ['a', 'b', 'a', undef], v => [390, 350, 30, 20] },")
print("\tnan_included => { group => ['g1', undef, 'g1', 'g2', undef], B => [0, 1, 2, 3, 4] },")
print(");")
