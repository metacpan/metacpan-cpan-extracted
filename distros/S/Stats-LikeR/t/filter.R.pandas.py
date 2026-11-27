# Generator for t/filter.R.pandas.t (pandas half).  Run with
#     python3 -I t/filter.R.pandas.py
# Prints Perl literals: the frames and, per predicate, the 0-based row
# indices pandas keeps.  pandas 3.0.4, NumPy 2.4.6.
#   - frame F1 and the "a == b", "a != b", "a in b", "a in b and c < d" cases
#     are pandas/tests/frame/test_query_eval.py::test_object_array_eq_ne and
#     ::test_query_with_string_columns, with c and d drawn exactly as the
#     tests do (default_rng(2).integers(5 / 9, size=12)); the expected rows
#     are the tests' own `df[...]` boolean-indexing expressions.
#   - the "inf" frame follows ::test_inf (a == inf, a != inf), using a column
#     that really holds inf, which the test's `df.loc[::2, 0]` does not.
#   - the NaN frame is a missing-value check in the spirit of
#     ::test_date_query_with_NaT: pandas keeps a NaN row for `!=` where R's
#     subset() and filter() do not (see the .t header).
import numpy as np, pandas as pd
print("# pandas", pd.__version__, "numpy", np.__version__)
def lst(v): return "[" + ", ".join("undef" if (isinstance(x, float) and x != x) else
    ("'%s'" % x if isinstance(x, str) else repr(float(x)) if isinstance(x, float) else str(x)) for x in v) + "]"
def idx(mask): return "[" + ", ".join(str(i) for i in np.flatnonzero(np.asarray(mask))) + "]"
df = pd.DataFrame({"a": list("aaaabbbbcccc"), "b": list("aabbccddeeff"),
    "c": np.random.default_rng(2).integers(5, size=12),
    "d": np.random.default_rng(2).integers(9, size=12)})
print("my %%F1 = (a => %s, b => %s, c => %s, d => %s);" % tuple(lst(df[k]) for k in "abcd"))
print("my %PD1 = (")
def case(name, mask): print("\tq{%s} => %s," % (name, idx(mask)))
case("a == b", df.a == df.b)
case("a != b", df.a != df.b)
case("a in b", df.a.isin(df.b))
case("a in b and c < d", df.a.isin(df.b) & (df.c < df.d))
case("c > 2", df.c > 2)
case("c >= 2", df.c >= 2)
case("c == 2", df.c == 2)
case("c != 2", df.c != 2)
case("c < 2", df.c < 2)
case("c <= 2", df.c <= 2)
case("c > 2 & d < 5", (df.c > 2) & (df.d < 5))
case("c > 2 | d < 5", (df.c > 2) | (df.d < 5))
case("~(c > 2)", ~(df.c > 2))
case("a == 'b' & c > 1", (df.a == 'b') & (df.c > 1))
case("a != 'a' | d == 0", (df.a != 'a') | (df.d == 0))
case("a > 'a'", df.a > 'a')
case("a <= 'b'", df.a <= 'b')
print(");")
inf = np.inf
g = pd.DataFrame({"a": [inf, 0.5, -inf, 2.0, inf, 0.25], "k": [0, 1, 2, 3, 4, 5]})
print("my %%INF = (a => [9**9**9, 0.5, -9**9**9, 2, 9**9**9, 0.25], k => %s);" % lst(g.k))
print("my %PDINF = (")
case("a == inf", g.a == inf); case("a != inf", g.a != inf)
case("a > 1", g.a > 1); case("a < 1", g.a < 1)
print(");")
n = pd.DataFrame({"x": [1.0, np.nan, 3.0, 0.0, np.nan, 2.0]})
print("my %%NAN = (x => %s);" % lst(n.x))
print("my %PDNAN = (")
case("x > 1", n.x > 1); case("x >= 1", n.x >= 1); case("x < 2", n.x < 2); case("x == 1", n.x == 1)
case("x != 1 (pandas keeps NaN)", n.x != 1)
print(");")
