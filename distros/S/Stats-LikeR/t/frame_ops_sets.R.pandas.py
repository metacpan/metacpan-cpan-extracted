# Generator for the pandas expectations frozen in t/frame_ops_sets.R.pandas.t
# (drop_cols, select_cols, rename_cols, csort, ljoin).  Re-run with
#     python3 -I t/frame_ops_sets.R.pandas.py
# pandas 3.0.4 and NumPy 2.4.6 printed the values on 2026-11-26.  The .t never
# runs this.  Each block prints the row ids (0-based index of the input row)
# in the order pandas returns them, or the frame as records, as noted.
import numpy as np
import pandas as pd
import sys
print("pandas", pd.__version__, "numpy", np.__version__, file=sys.stderr)

nan = np.nan
def ids(df):
    return [int(i) for i in df.index]

# test_sort_values.py::test_sort_values
f = pd.DataFrame([[1, 1, 2], [3, 1, 0], [4, 5, 6]], index=[0, 1, 2], columns=list("ABC"))
print("sort_values A asc", ids(f.sort_values(by="A")))
print("sort_values A desc", ids(f.sort_values(by="A", ascending=False)))
print("sort_values B,C asc", ids(f.sort_values(by=["B", "C"])))
print("sort_values B,C desc", ids(f.sort_values(by=["B", "C"], ascending=False)))
print("sort_values B asc,A desc", ids(f.sort_values(by=["B", "A"], ascending=[True, False])))

# test_sort_values_nan (GH#3917)
d = pd.DataFrame({"A": [1, 2, nan, 1, 6, 8, 4], "B": [9, nan, 5, 2, 5, 4, 5]})
print("nan A last", ids(d.sort_values(["A"])))
print("nan A desc last", ids(d.sort_values(["A"], ascending=False)))
print("nan A first", ids(d.sort_values(["A"], na_position="first")))
print("nan A,B last", ids(d.sort_values(["A", "B"])))
print("nan A,B first", ids(d.sort_values(["A", "B"], na_position="first")))
print("nan A asc,B desc first", ids(d.sort_values(["A", "B"], ascending=[1, 0], na_position="first")))
print("nan A desc,B asc last", ids(d.sort_values(["A", "B"], ascending=[0, 1], na_position="last")))

# test_sort_values_stable_descending_sort (GH#6399)
g = pd.DataFrame([[2, "first"], [2, "second"], [1, "a"], [1, "b"]], columns=["sort_col", "order"])
print("stable desc", ids(g.sort_values(by="sort_col", kind="mergesort", ascending=False)))

# test_sort_values_stable_multicolumn_sort (GH#38426)
m = pd.DataFrame({
    "A": [1, 2, nan, 1, 1, 1, 6, 8, 4, 8, 8, nan, nan, 8, 8],
    "B": [9, nan, 5, 2, 2, 2, 5, 4, 5, 3, 4, nan, nan, 4, 4]})
for asc in ([True, True], [True, False], [False, True], [False, False]):
    for pos in ("first", "last"):
        print("multi", asc, pos, ids(m.sort_values(["A", "B"], ascending=asc, na_position=pos)))

# test_drop.py::test_drop_names / test_drop
df = pd.DataFrame([[1, 2, 3], [3, 4, 5], [5, 6, 7]], index=["a", "b", "c"], columns=["d", "e", "f"])
print("drop e", df.drop("e", axis=1).to_dict(orient="index"))
print("drop d,e,f ignore", df.drop(["d", "g"], axis=1, errors="ignore").to_dict(orient="index"))
print("drop []", df.drop([], axis=1).to_dict(orient="index"))
simple = pd.DataFrame({"A": [1, 2, 3, 4], "B": [0, 1, 2, 3]})
print("drop A", simple.drop("A", axis=1).to_dict(orient="list"))
print("drop A,B", simple.drop(["A", "B"], axis="columns").to_dict(orient="list"), len(simple.drop(["A", "B"], axis="columns")))

# test_rename.py::test_rename
fr = pd.DataFrame([[1, 2, 3, 4], [5, 6, 7, 8]], columns=list("ABCD"))
print("rename all", fr.rename(columns={"A": "a", "B": "b", "C": "c", "D": "d"}).to_dict(orient="list"))
print("rename partial", fr.rename(columns={"C": "foo", "D": "bar"}).to_dict(orient="list"))
sw = pd.DataFrame({"foo": [0], "bar": [1]})
print("rename swap", sw.rename(columns={"foo": "bar", "bar": "foo"}).to_dict(orient="list"))
# test_rename_bug (GH 5344): successive renames
b = pd.DataFrame({0: ["foo", "bar"], 1: ["bah", "bas"], 2: [1, 2]})
print("rename chain", b.rename(columns={0: "a"}).rename(columns={1: "b"}).to_dict(orient="list"))

# merge how="left" on the index (test_merge_arrow_string_index shape, keyed on index)
l = pd.DataFrame({"a": [1, 2]}, index=["a", "b"])
r = pd.DataFrame({"b": [10, 20]}, index=["a", "c"])
print("merge left", l.merge(r, how="left", left_index=True, right_index=True).to_dict(orient="index"))
l2 = pd.DataFrame({"v": [1, 2]}, index=["x", "y"]); r2 = pd.DataFrame({"v": [9, 8]}, index=["x", "z"])
print("merge left overlap", l2.merge(r2, how="left", left_index=True, right_index=True).to_dict(orient="index"))

# numpy/lib/tests/test_arraysetops.py, computed (not transcribed) for the sets
from numpy import intersect1d, union1d, setdiff1d
print("intersect1d", list(map(int, intersect1d([5, 5, 7, 1, 2], [2, 1, 4, 3, 3, 1, 5]))))
print("union1d", list(map(int, union1d([5, 4, 7, 1, 2], [2, 4, 3, 3, 2, 1, 5]))))
print("setdiff1d", list(map(int, setdiff1d([6, 5, 4, 7, 1, 2, 7, 4], [2, 4, 3, 3, 2, 1, 5]))))
