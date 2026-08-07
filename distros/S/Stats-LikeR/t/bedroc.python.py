#!/usr/bin/env python3
"""Reference BEDROC values for t/bedroc.python.t.

The two functions below are copied VERBATIM from the pep-priml project, which
is the production Python code Stats::LikeR's bedroc() has to agree with:

  bedroc_score()  <- ~/ui/pep-priml/train-anomaly/pipeline/_compute.py
                     (binary labels, higher score = better, normalised as
                      (RIE - RIE_min) / (RIE_max - RIE_min))
  _bedroc()       <- ~/ui/pep-priml/train-regress/train.py
                     (regression variant: actives = lowest `active_frac` of
                      y_true, ranked by lowest y_pred first, normalised as
                      RIE * factor1 + factor2 -- Truchon & Bayly eq. 36)
  ef_at_frac()    <- ~/ui/pep-priml/train-anomaly/pipeline/_compute.py
                     (enrichment factor, checked against bedroc's top => ...)

Emits JSON on stdout: a list of cases, each with the data, the Perl-side
options, and the expected numbers.  Every case uses DISTINCT scores and
DISTINCT y_true values so that tie handling (midranks in the XS, input-order /
seeded-permutation tie-breaks in Python) cannot make the two disagree for
reasons that are not bugs; ties are covered separately by t/bedroc.t.
"""

import json
import sys

import numpy as np
from scipy.stats import rankdata  # noqa: F401  (import parity with _compute.py)

# ── verbatim: train-anomaly/pipeline/_compute.py ──────────────────────────────
BEDROC_ALPHA = 32.2      # from train-anomaly/config.py
BEDROC_ALPHA_10 = 16.1   # from train-anomaly/config.py


def bedroc_score(y_true, scores, alpha=BEDROC_ALPHA):
    """BEDROC (Truchon & Bayly, JCIM 2007). Rewards early recovery of actives."""
    n = len(y_true); ra = y_true.sum() / n
    order = np.argsort(scores)[::-1]
    ranks = np.where(y_true[order] == 1)[0] + 1
    exp_sum = np.exp(-alpha * ranks / n).sum()
    rie_denom = ra * (1 - np.exp(-alpha)) / (np.exp(alpha / n) - 1)
    rie = exp_sum / rie_denom
    rie_max = (1 - np.exp(-alpha * ra)) / (ra * (1 - np.exp(-alpha)))
    rie_min = (1 - np.exp( alpha * ra)) / (ra * (1 - np.exp( alpha)))
    return (rie - rie_min) / (rie_max - rie_min)


def prec_at_k(scores, labels, k):
    return labels[np.argsort(scores)[::-1][:k]].sum() / k


def ef_at_frac(scores, labels, frac):
    """Enrichment Factor at a given fraction of the dataset."""
    n = len(labels); k = int(np.ceil(frac * n))
    base = labels.sum() / n
    return prec_at_k(scores, labels, k) / base if base > 0 else 0.0


# ── verbatim: train-regress/train.py ─────────────────────────────────────────
def _bedroc(y_true: np.ndarray, y_pred: np.ndarray,
            alpha: float = 16.1, active_frac: float = 0.10) -> float:
    """Boltzmann-Enhanced Discrimination of ROC (Truchon & Bayly 2007)."""
    n = len(y_true)
    if n < 5:
        return float("nan")
    n_a = max(1, int(np.ceil(active_frac * n)))
    r_a = n_a / n
    active_idx = set(np.argsort(y_true)[:n_a].tolist())
    y_pred = np.asarray(y_pred, dtype=float)
    tiebreak = np.random.default_rng(0).permutation(len(y_pred))
    pred_order = np.lexsort((tiebreak, y_pred))
    ranks = np.array([i + 1 for i, idx in enumerate(pred_order) if int(idx) in active_idx],
                     dtype=float)
    s = float(np.sum(np.exp(-alpha * ranks / n)))
    ri_denom = r_a * (1.0 - np.exp(-alpha)) / (np.exp(alpha / n) - 1.0)
    rie = s / ri_denom
    factor = r_a * np.sinh(alpha / 2.0) / (
        np.cosh(alpha / 2.0) - np.cosh(alpha / 2.0 - alpha * r_a))
    offset = 1.0 / (1.0 - np.exp(alpha * (1.0 - r_a)))
    return float(rie * factor + offset)


# ── raw RIE pieces, so the XS's rie / rie_min / rie_max are checked too ───────
def rie_parts(y_true, scores, alpha):
    """(rie, rie_min, rie_max) for binary y_true, higher score first."""
    n = len(y_true); ra = y_true.sum() / n
    order = np.argsort(scores)[::-1]
    ranks = np.where(y_true[order] == 1)[0] + 1
    exp_sum = np.exp(-alpha * ranks / n).sum()
    rie = exp_sum / (ra * (1 - np.exp(-alpha)) / (np.exp(alpha / n) - 1))
    rie_max = (1 - np.exp(-alpha * ra)) / (ra * (1 - np.exp(-alpha)))
    rie_min = (1 - np.exp( alpha * ra)) / (ra * (1 - np.exp( alpha)))
    return float(rie), float(rie_min), float(rie_max)


ALPHAS = [0.5, 8.0, 16.1, 20.0, 32.2, 80.0]
cases = []


def distinct_scores(rng, n):
    """n distinct scores (no ties -> no tie-handling ambiguity)."""
    s = rng.permutation(n).astype(float) + rng.normal(0, 0.01, n)
    while len(np.unique(s)) != n:                    # astronomically unlikely
        s = rng.permutation(n).astype(float) + rng.normal(0, 0.01, n)
    return s


def add_binary(name, y, s, alpha, top=None):
    """Case for bedroc_score(): binary labels, higher score ranks first."""
    y = np.asarray(y, dtype=int)
    s = np.asarray(s, dtype=float)
    rie, rmin, rmax = rie_parts(y, s, alpha)
    c = {
        "name": name,
        "scores": [float(x) for x in s],
        "labels": [int(x) for x in y],
        "opts": {"alpha": alpha},
        "bedroc": float(bedroc_score(y, s, alpha=alpha)),
        "rie": rie, "rie_min": rmin, "rie_max": rmax,
        "n_active": int(y.sum()), "n": int(len(y)),
        "ra": float(y.sum() / len(y)),
        "python_fn": "bedroc_score",
    }
    if top is not None:
        c["opts"]["top"] = top
        c["ef"] = float(ef_at_frac(s, y, top))
    cases.append(c)


def add_regress(name, y_true, y_pred, alpha, active_frac):
    """Case for _bedroc(): actives = lowest active_frac of y_true, low pred first."""
    y_true = np.asarray(y_true, dtype=float)
    y_pred = np.asarray(y_pred, dtype=float)
    cases.append({
        "name": name,
        "scores": [float(x) for x in y_pred],        # ranked by lowest first
        "labels": [float(x) for x in y_true],        # binarised by active_frac
        "opts": {"alpha": alpha, "active_frac": active_frac,
                 "active_side": "low", "direction": "<"},
        "bedroc": float(_bedroc(y_true, y_pred, alpha=alpha, active_frac=active_frac)),
        "n": int(len(y_true)),
        "n_active": max(1, int(np.ceil(active_frac * len(y_true)))),
        "python_fn": "_bedroc",
    })


rng = np.random.default_rng(20260806)

# 1. binary labels, random scores, several n and alpha
for n in (5, 15, 40, 100, 501):
    for alpha in ALPHAS:
        s = distinct_scores(rng, n)
        n_a = max(1, n // 5)
        y = np.zeros(n, dtype=int)
        y[rng.choice(n, n_a, replace=False)] = 1
        add_binary(f"random binary n={n} alpha={alpha}", y, s, alpha, top=0.1)

# 2. correlated (realistic) ranking: actives really do score higher
for alpha in ALPHAS:
    n = 200
    y = np.zeros(n, dtype=int); y[rng.choice(n, 20, replace=False)] = 1
    s = y * 1.5 + rng.normal(0, 1, n)
    s = s + np.arange(n) * 1e-9                      # break any accidental tie
    add_binary(f"enriched ranking n=200 alpha={alpha}", y, s, alpha, top=0.05)

# 3. extreme class balance
for n_a, alpha in ((1, 32.2), (1, 0.5), (99, 20.0), (50, 16.1)):
    n = 100
    y = np.zeros(n, dtype=int); y[rng.choice(n, n_a, replace=False)] = 1
    add_binary(f"n_active={n_a} of 100 alpha={alpha}", y, distinct_scores(rng, n), alpha)

# 4. exact bounds: perfect and worst-case orderings
for alpha in ALPHAS:
    n = 50; y = np.array([1] * 10 + [0] * 40)
    add_binary(f"perfect ranking alpha={alpha}", y, np.arange(n, 0, -1, dtype=float), alpha)
    add_binary(f"worst ranking alpha={alpha}",   y, np.arange(n, dtype=float), alpha)

# 5. regression variant (the pep-priml winner-selection metric)
for n in (5, 11, 60, 200)  :
    for alpha in (8.0, 16.1, 32.2, 80.0):
        for frac in (0.05, 0.10, 0.25):
            y_true = rng.normal(-8, 2, n) + np.arange(n) * 1e-7   # distinct dG
            y_pred = y_true * 0.6 + rng.normal(0, 1.5, n) + np.arange(n) * 1e-7
            if len(np.unique(y_true)) != n or len(np.unique(y_pred)) != n:
                continue
            add_regress(f"regress n={n} alpha={alpha} frac={frac}",
                        y_true, y_pred, alpha, frac)

# 6. regression variant, exact bounds
for alpha in (16.1, 32.2):
    y_true = np.arange(40, dtype=float)              # actives = lowest values
    add_regress(f"regress perfect alpha={alpha}", y_true, y_true, alpha, 0.10)
    add_regress(f"regress worst alpha={alpha}",   y_true, -y_true, alpha, 0.10)

json.dump(cases, sys.stdout)
sys.stdout.write("\n")
