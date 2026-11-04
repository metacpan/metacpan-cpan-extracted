# Generator for the frozen expected values in t/qcut.nan.pandas.t.
#
# Re-run with
#
#     python3 -I t/qcut.nan.pandas.py
#
# and paste its output over the blocks in the .t file.  The test never runs
# this, or Python.
#
# pandas 3.0.4 / NumPy 2.5.2, from pandas/tests/reshape/test_qcut.py:
#   test_qcut_nas: standard_normal(100) from default_rng(2), its first 20 set
#     to NaN; qcut(arr, 4) must leave those 20 missing.  The test there checks
#     only that; the bins and codes of the other 80 are frozen here as well.
#   test_qcut_nullable_integer: arange(100) with every other value NA, at
#     q = 2, 5 and 10, must bin as the same array with NaN in those places.
import numpy as np
import pandas as pd

def emit(name, arr, q):
    codes, bins = pd.qcut(arr, q, labels=False, retbins=True)
    print("\t%s => {" % name)
    print("\t\tq     => %d," % q)
    print("\t\tedges => [%s]," % ", ".join(repr(float(b)) for b in bins))
    print("\t\tcodes => [%s]," % ", ".join("undef" if np.isnan(c) else str(int(c)) for c in codes))
    print("\t},")

arr = np.random.default_rng(2).standard_normal(100)
arr[:20] = np.nan
print("my @NAS = (%s);" % ", ".join("'nan'" if np.isnan(v) else repr(float(v)) for v in arr))
print()
print("my %EXPECT = (")
emit("nas", arr, 4)
ints = np.arange(100, dtype=float)
ints[::2] = np.nan
for q in (2, 5, 10):
    emit("nullable_q%d" % q, ints, q)
print(");")
