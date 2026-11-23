#!/usr/bin/env python3
# Generator of the frozen literals in t/rank.R.scipy.t (SciPy 1.18.0
# rankdata).  Run: python3 t/rank.R.scipy.py ; paste the output into the test.
# The test never calls this.  It is SciPy's test_rankdata_object_string with
# the random choice replaced by a fixed draw (RandomState(20241122)).
import numpy as np
from scipy.stats import rankdata

def fmt(r):
    return '[' + ', '.join(repr(float(x)).rstrip('0').rstrip('.') if float(x) != int(x) else str(int(x)) for x in r) + ']'

val = ['foo', 'bar', 'qux', 'xyz', 'abc', 'efg', 'ace', 'qwe', 'qaz']
rng = np.random.RandomState(20241122)
a = list(rng.choice(val, 40))
print('my @str = qw(' + ' '.join(a) + ');')
for method, tm in (('average', 'average'), ('min', 'min'), ('max', 'max'), ('ordinal', 'first')):
    print("%s => %s," % (tm, fmt(rankdata(a, method=method))))
val = np.array([0, 1, 2, 2.718, 3, 3.141], dtype='object')
b = list(rng.choice(val, 40).astype('object'))
print('my @num = (' + ', '.join(repr(x) for x in b) + ');')
for method, tm in (('average', 'average'), ('min', 'min'), ('max', 'max'), ('ordinal', 'first')):
    print("%s => %s," % (tm, fmt(rankdata(b, method=method))))
