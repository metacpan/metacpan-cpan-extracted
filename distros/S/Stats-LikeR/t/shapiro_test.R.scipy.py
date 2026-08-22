# Regenerates the one SciPy sample in t/shapiro_test.R.scipy.t that is not a
# literal in SciPy's own source:
#
#   scipy/stats/tests/test_morestats.py, TestShapiro::test_basic
#     x3 = stats.norm.rvs(loc=5, scale=3, size=100, random_state=12345678)
#
# whose expected W and p there (0.97728027037175, 0.08143656270016) SciPy
# annotates as "reference values generated using R shapiro.test".
#
#   python3 t/shapiro_test.R.scipy.py
#
# prints the sample as a Perl list.  The test never runs this script and
# never calls Python.
from scipy import stats

x3 = stats.norm.rvs(loc=5, scale=3, size=100, random_state=12345678)
print("my $scipy_x3 = [")
for i in range(0, len(x3), 4):
    print("\t" + ", ".join(repr(float(v)) for v in x3[i:i + 4]) + ",")
print("];")
