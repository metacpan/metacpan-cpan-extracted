# Generator for t/epi_2x2.R.statsmodels.t (statsmodels half).  Run with
#     python3 -I t/epi_2x2.R.statsmodels.py
# For each table [[a, b], [c, d]] (rows exposure, columns outcome) it prints
# statsmodels' Table2x2 odds ratio, risk ratio (both Wald on the log scale),
# and statsmodels.stats.proportion.confint_proportions_2indep(method="wald",
# compare="diff") for the risk difference, at conf_level 0.95, 0.90 and 0.99.
# correct => 1 (and a zero cell) means +0.5 on every cell first; the corrected
# table is handed to statsmodels, which has no such option of its own.
import numpy as np, statsmodels
from statsmodels.stats.contingency_tables import Table2x2
from statsmodels.stats.proportion import confint_proportions_2indep
print("# statsmodels", statsmodels.__version__, "numpy", np.__version__)
T = {
 # statsmodels/stats/tests/test_contingency_tables.py::Test2x2_1
 "sm_test2x2_1": [[2, 2], [2, 2]],
 # R fisher.test.Rd Convictions: matrix(c(2, 10, 15, 3), nrow = 2)
 "convictions": [[2, 15], [10, 3]],
 # R mcnemar.test.Rd Performance, matrix(c(794, 86, 150, 570), nrow = 2)
 "performance": [[794, 150], [86, 570]],
 # R fisher.test.Rd TeaTasting, matrix(c(3, 1, 1, 3), nrow = 2)
 "tea": [[3, 1], [1, 3]],
 # R prop.test.Rd smokers: groups 1 and 2 as exposed (events, non-events)
 "smokers12": [[83, 3], [90, 3]],
 "smokers34": [[129, 7], [70, 12]],
 "readme": [[30, 70], [20, 80]],
 "rare": [[3, 997], [1, 999]],
 "protective": [[10, 90], [40, 60]],
 "zero_a": [[0, 10], [5, 10]],
 "zero_d": [[10, 5], [20, 0]],
 "zero_b": [[7, 0], [3, 12]],
}
def row(name, t, correct, cl):
    t_in = "[[%d, %d], [%d, %d]]" % tuple(int(v) for r in t for v in r)
    t = np.array(t, dtype=float)
    if correct or (t == 0).any():
        t = t + 0.5
    tb = Table2x2(t)
    a = 1 - cl
    o = tb.oddsratio_confint(a); r = tb.riskratio_confint(a)
    p1 = t[0, 0] / t[0].sum(); p0 = t[1, 0] / t[1].sum(); n1 = t[0].sum(); n0 = t[1].sum()
    d = confint_proportions_2indep(t[0, 0], n1, t[1, 0], n0, method="wald",
                                   compare="diff", alpha=a)
    f = lambda x: repr(float(x))
    print("\t[ '%s', %s, %d, %s, %s ]," % (name, t_in, int(correct), cl,
          ", ".join(f(x) for x in (tb.oddsratio, o[0], o[1], tb.riskratio, r[0], r[1],
                                   p1 - p0, d[0], d[1]))))
for name, t in T.items():
    for cl in (0.95, 0.90, 0.99):
        row(name, t, 0, cl)
    row(name, t, 1, 0.95)
