# Generator for t/cramers_v.R.scipy.t (the SciPy half).  Run with
#     python3 -I t/cramers_v.R.scipy.py
# Prints scipy.stats.contingency.association(method="cramer", correction=False)
# for the tables of t/cramers_v.R.scipy.R, to compare with R's V there.
# SciPy's own test is scipy/stats/tests/test_contingency.py::test_assoc
# (expected 0.09222412010290792 for obs1).
import numpy as np, scipy
from scipy.stats.contingency import association, chi2_contingency
print("scipy", scipy.__version__, "numpy", np.__version__)
T = {
 "agresti": [[762,327,468],[484,239,477]],
 "x2x2": [[12,7],[5,7]],
 "convictions": [[2,15],[10,3]],
 "job": [[1,3,10,6],[2,3,10,7],[1,6,14,12],[0,1,9,11]],
 "scipy_obs1": [[12,13,14,15,16],[17,16,18,19,11],[9,15,14,12,11]],
 "mtcars": [[1,8,2],[2,4,1],[12,0,2]],  # R: table(mtcars$cyl, mtcars$gear)
 "perfect": [[10,0],[0,10]],
 "small": [[3,1],[1,3]],
 "tall": [[10,20],[30,40],[25,5],[8,12]],
}
for k, t in T.items():
    a = np.array(t)
    print("%-12s %r chi2=%r" % (k, association(a, "cramer"),
          chi2_contingency(a, correction=False)[0]))
