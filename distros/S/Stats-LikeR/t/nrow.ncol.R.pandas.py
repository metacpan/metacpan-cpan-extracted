# Generator for the frozen pandas expectations in t/nrow.ncol.R.pandas.t.
#
# Re-run with
#
#     python3 -I t/nrow.ncol.R.pandas.py
#
# and compare its output with the %PANDAS table in the .t file.  The test never
# runs this, or Python.
#
# pandas 3.0.4, the DataFrame constructor cases in
# pandas/tests/frame/test_constructors.py and
# pandas/tests/frame/constructors/test_from_dict.py whose input has a
# Stats::LikeR frame shape: a list of dicts is an AoH, a list of lists an AoA,
# a dict of lists a HoA, and a dict of dicts read with orient="index" a HoH.
# Each line is the case name, then nrow, ncol and the sorted column names, or
# the exception pandas raises.
from collections import OrderedDict

import numpy as np
import pandas as pd

def shape(name, make):
    try:
        df = make()
    except ValueError as e:
        print("%-24s ValueError: %s" % (name, e))
        return
    cols = sorted(str(c) for c in df.columns)
    print("%-24s nrow=%d ncol=%d cols=%s" % (name, df.shape[0], df.shape[1], cols))

# test_constructor_list_of_dict_order (GH10056): records whose key sets differ
shape("list_of_dict_order", lambda: pd.DataFrame([
    {"First": 1, "Second": 4, "Third": 7, "Fourth": 10},
    {"Second": 5, "First": 2, "Fourth": 11, "Third": 8},
    {"Second": 6, "First": 3, "Fourth": 12, "Third": 9, "YYY": 14, "XXX": 13},
]))
# test_from_dict.py test_constructor_list_of_odicts: sparse records, one empty
shape("list_of_odicts", lambda: pd.DataFrame([
    OrderedDict([["a", 1.5], ["b", 3], ["c", 4], ["d", 6]]),
    OrderedDict([["a", 1.5], ["b", 3], ["d", 6]]),
    OrderedDict([["a", 1.5], ["d", 6]]),
    OrderedDict(),
    OrderedDict([["a", 1.5], ["b", 3], ["c", 4]]),
    OrderedDict([["b", 3], ["c", 4], ["d", 6]]),
]))
# test_constructor_list_of_dicts: one empty record
shape("list_of_dicts_empty", lambda: pd.DataFrame([{}]))
# test_from_dict.py test_constructor_single_row
shape("single_row", lambda: pd.DataFrame([
    OrderedDict([["a", 1.5], ["b", 3], ["c", 4], ["d", 6]]),
]))
# test_from_dict.py test_constructor_from_ordered_dict (GH8425), orient="index"
shape("from_ordered_dict_index", lambda: pd.DataFrame.from_dict(OrderedDict([
    ("one",   OrderedDict([("col_a", "foo1"), ("col_b", "bar1")])),
    ("two",   OrderedDict([("col_a", "foo2"), ("col_b", "bar2")])),
    ("three", OrderedDict([("col_a", "foo3"), ("col_b", "bar3")])),
]), orient="index"))
# test_from_dict.py test_constructor_orient, "dict of sequence", read as
# columns (a HoA); the test's orient="index" is its transpose
shape("dict_of_sequence", lambda: pd.DataFrame.from_dict(
    {"hi": [32, 3, 3], "there": [3, 5, 3]}))
# test_constructor_dict, "mix dict and array, wrong size"
shape("mix_dict_and_array", lambda: pd.DataFrame(
    {"A": {"a": "a", "b": "b"}, "B": ["a", "b", "c"]}))
# test_constructor_ragged: columns of 10 and 8
shape("ragged", lambda: pd.DataFrame({
    "A": np.random.default_rng(2).standard_normal(10),
    "B": np.random.default_rng(2).standard_normal(8),
}))
# test_constructor_list_of_lists (GH484)
shape("list_of_lists", lambda: pd.DataFrame(data=[[1, "a"], [2, "b"]]))
# test_constructor_list_of_lists (GH4851): ten 0-d arrays, a plain vector
shape("list_of_0d", lambda: pd.DataFrame([np.array(x) for x in range(10)]))
# test_constructor_dict, "Corner cases": len(DataFrame()) == 0
shape("empty", lambda: pd.DataFrame())
# test_constructor_empty_list (GH9939): no rows, columns A and B
shape("empty_list_columns", lambda: pd.DataFrame([], columns=["A", "B"]))
