# Python half of the generator for t/uniq.R.numpy.t (the R half is
# t/uniq.R.numpy.R).  Re-run with
#     /home/con/.pyenv/versions/3.14.2/bin/python3 -I t/uniq.R.numpy.py
# (NumPy 2.4.6, pandas 3.0.4 printed the values committed in the test on
# 2026-11-26.)  The NumPy results are sorted, the pandas ones are in
# first-seen order, which is what uniq() promises.
import struct
import numpy as np
import pandas as pd
a = [5, 7, 1, 2, 1, 5, 7] * 10   # numpy/lib/tests/test_arraysetops.py test_unique_1d
print("numpy test_unique_1d sorted:", np.unique(a).tolist(), "pandas order:", pd.unique(np.array(a)).tolist())
print("numpy ticket 4785 flat:", np.unique([(1, 2), (1, 2), (2, 3)]).tolist())
print("pandas test_signed_zero:", pd.unique(np.array([-0.0, 0.0])).tolist())
N1 = struct.unpack("d", struct.pack("=Q", 0x7FF8000000000000))[0]
N2 = struct.unpack("d", struct.pack("=Q", 0x7FF8000000000001))[0]
print("pandas test_different_nans count:", len(pd.unique(np.array([N1, N2]))))
print("pandas test_nan_in_object_array:", pd.unique(np.array(["a", np.nan, "c", "c"], dtype=object)).tolist())
s = pd.Series([1.2345] * 100); s[::2] = np.nan
print("pandas test_unique count:", len(s.unique()))
print("pandas test_unique_uint64:", pd.Series([1, 2, 2**63, 2**63], dtype=np.uint64).unique().tolist())
print("pandas test_unique_none:", pd.Series([1, 2, 3, None, None, None], dtype=object).unique().tolist())
