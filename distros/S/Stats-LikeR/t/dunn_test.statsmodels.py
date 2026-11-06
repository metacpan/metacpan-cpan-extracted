#!/usr/bin/env python3
"""Reference values for t/dunn_test.statsmodels.t.

Prints the Perl literal that t/dunn_test.statsmodels.t holds in cases(); the
test never runs this script.  Re-run it with

    python3 t/dunn_test.statsmodels.py > cases.pl

and paste its output over the body of cases() in the .t file.

Generated with Python 3.14.2, SciPy 1.18.0 and statsmodels 0.14.6.

The raw statistic is Dunn's (1964) z with the Kruskal-Wallis tie correction --
the formula of the R dunn.test package and of t/dunn_test.t's base-R values:

    z = (Rbar_i - Rbar_j) / sqrt((N(N+1)/12 - sum(t^3 - t)/(12(N-1)))
                                 * (1/n_i + 1/n_j))

with midranks from scipy.stats.rankdata() and the two-sided p-value
2 * scipy.stats.norm.sf(|z|), which keeps full relative accuracy in the tail.

The adjustments are statsmodels.stats.multitest.multipletests(), applied to
those raw p-values: 'bonferroni', 'sidak', 'holm', 'holm-sidak', 'fdr_bh' and
'fdr_by', which are dunn_test()'s bonferroni, sidak, holm, hs, bh and by.  Its
Sidak forms are -expm1(m * log1p(-p)), which is what pins dunn_test() to the
correct value below p = 1e-16, where 1 - (1 - p)^m is 0.
"""

from itertools import combinations

import numpy as np
from scipy.stats import norm, rankdata
from statsmodels.stats.multitest import multipletests

METHODS = [
    ('bonferroni', 'bonferroni'),
    ('sidak', 'sidak'),
    ('holm', 'holm'),
    ('hs', 'holm-sidak'),
    ('bh', 'fdr_bh'),
    ('by', 'fdr_by'),
]


def dunn(values, groups):
    values = np.asarray(values, dtype=float)
    groups = np.asarray(groups)
    n_tot = len(values)
    ranks = rankdata(values)
    _, counts = np.unique(values, return_counts=True)
    ties = float(np.sum(counts.astype(float) ** 3 - counts))
    s2 = n_tot * (n_tot + 1) / 12.0 - ties / (12.0 * (n_tot - 1))
    labels = sorted(set(groups.tolist()))
    rbar = {g: ranks[groups == g].mean() for g in labels}
    size = {g: int(np.sum(groups == g)) for g in labels}
    rows = []
    for a, b in combinations(labels, 2):
        z = (rbar[a] - rbar[b]) / np.sqrt(s2 * (1.0 / size[a] + 1.0 / size[b]))
        rows.append((f'{a} - {b}', z, 2.0 * norm.sf(abs(z))))
    return rows


def case(name, values, groups):
    rows = dunn(values, groups)
    raw = np.array([r[2] for r in rows])
    adj = {ours: multipletests(raw, method=theirs)[1] for ours, theirs in METHODS}
    out = [f"\t{{\n\t\tname   => '{name}',\n"]
    out.append('\t\tvalues => [' + ', '.join(repr(v) for v in values) + '],\n')
    out.append('\t\tgroups => [' + ', '.join(f"'{g}'" for g in groups) + '],\n')
    out.append('\t\tpairs  => {\n')
    for i, (comp, z, p) in enumerate(rows):
        cells = [f'Z => {float(z)!r}', f'p_value => {float(p)!r}']
        cells += [f'{ours} => {float(adj[ours][i])!r}' for ours, _ in METHODS]
        out.append(f"\t\t\t'{comp}' => {{ " + ', '.join(cells) + ' },\n')
    out.append('\t\t},\n\t},\n')
    return ''.join(out)


# t/dunn_test.t's data: three groups of five, one tie.
small_v = [2.1, 3.4, 1.9, 5.6, 4.2, 6.1, 7.3, 5.9, 8.2, 6.6,
           3.3, 4.4, 2.2, 3.3, 5.5]
small_g = ['A'] * 5 + ['B'] * 5 + ['C'] * 5

# Five groups of 25 integers: B overlaps A, C is tied pairs that B shares, D and E are
# clear of everything, so the ten raw p-values run from 0.42 down to 3.3e-22
# and every adjustment meets both a value near 1 and one far below 1e-16.
sep_v, sep_g = [], []
for g, vals in (('A', range(1, 26)), ('B', range(20, 45)),
                ('C', [30 + i // 2 for i in range(25)]),
                ('D', range(100, 125)), ('E', range(200, 225))):
    sep_v += list(vals)
    sep_g += [g] * 25

# Four disjoint groups of 200: raw p-values of 5e-18, 4e-67 and 1e-148.
far_v, far_g = [], []
for g, lo in (('a', 1), ('b', 301), ('c', 601), ('d', 901)):
    far_v += list(range(lo, lo + 200))
    far_g += [g] * 200

print(case('t/dunn_test.t data', small_v, small_g)
      + case('five groups, ties, p to 1e-21', sep_v, sep_g)
      + case('four disjoint groups of 200', far_v, far_g), end='')
