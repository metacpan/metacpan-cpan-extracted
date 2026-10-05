#!/usr/bin/env python3
#
# Regenerates the frozen pandas side of t/merge.R.pandas.t.  Re-run it with
#
#     python3 t/merge.R.pandas.py > /tmp/merge.pandas.pl
#
# and paste the output over the "BEGIN GENERATED (pandas)" .. "END GENERATED
# (pandas)" block of t/merge.R.pandas.t.  The test itself never runs python:
# everything this prints is a Perl literal.
#
# Written against pandas 2.2.3.  Every case below comes from pandas' own merge
# suite, pandas/tests/reshape/merge/{test_merge.py,test_merge_cross.py,
# test_multi.py}; the test function it came from is named in the case's `name`
# field, which the .t prints as the test description.  Where a case's data came
# from a random generator, the random column is replaced by fixed integers --
# the bug each of those tests was written for is in the matching, not in the
# payload -- and the substitution is noted at the case.
#
# Every cited test function is also present unchanged in pandas 3.0.4, and this
# script run under 3.0.4 prints a table byte-identical to the 2.2.3 one, so the
# frozen answers are not specific to either release.
#
# Four things are normalised so that a pandas answer can be compared with a
# Stats::LikeR one at all:
#
#   * suffixes.  pandas suffixes colliding non-key columns _x/_y, R and
#     Stats::LikeR .x/.y, so every generated case passes
#     suffixes => ['_x','_y'] and the frozen names are pandas' own.
#   * NaN keys.  pandas matches NaN to NaN; Stats::LikeR's rule is that a key
#     cell that is undef matches nothing (R's incomparables = NA).  na_unmatched
#     below substitutes a row-unique sentinel for each NaN key cell before
#     merging and restores NaN afterwards, so the frozen answer follows
#     Stats::LikeR's rule.  The divergence itself is recorded in the .t.
#   * key columns under left_on/right_on.  pandas keeps both key columns; R and
#     Stats::LikeR keep one, under the left name, filled from whichever side
#     has it.  coalesce_keys() below does that to pandas' answer.
#   * integral floats.  Introducing a NaN upcasts an int64 column to float64,
#     so pandas' 4 comes back as 4.0 while perl still prints 4.  pv() emits an
#     integral float as an integer, and refuses a non-integral one: a
#     non-integer double does not stringify the same on a double, long-double
#     and __float128 perl (0.2 is "0.2" at 15 significant digits and
#     "0.200000000000000011" at 18), and this file compares cells as strings.
#     The .t covers double-valued keys separately, with dyadic literals.

import numpy as np
import pandas as pd

# --------------------------------------------------------------- Perl emitters
def pv(x):
    """One cell as a Perl literal."""
    if x is None or (isinstance(x, float) and np.isnan(x)) or x is pd.NA:
        return 'undef'
    if isinstance(x, (bool, np.bool_)):
        return '1' if x else '0'
    if isinstance(x, (int, np.integer)):
        return str(int(x))
    if isinstance(x, (float, np.floating)):
        if not float(x).is_integer():
            raise ValueError('non-integer double %r in the corpus; see header' % x)
        return str(int(x))
    return "'" + str(x).replace('\\', '\\\\').replace("'", "\\'") + "'"

def pname(names):
    return '[' + ', '.join("'%s'" % n for n in names) + ']'

def prow(cells):
    return '[' + ', '.join(pv(c) for c in cells) + ']'

def pframe(df, ind, pfx=''):
    """A DataFrame as `<pfx>cols => [...], <pfx>rows => [[...], ...]`."""
    cols = list(df.columns)
    rows = [prow(df.iloc[i][c] for c in cols) for i in range(len(df))]
    pad  = ' ' * (len(pfx) + len('rows => [ '))
    out  = ['%s%scols => %s,' % (ind, pfx, pname(cols))]
    if not rows:
        out.append('%s%srows => [],' % (ind, pfx))
    else:
        out.append('%s%srows => [ %s,' % (ind, pfx, rows[0]))
        out += ['%s%s%s,' % (ind, pad, r) for r in rows[1:]]
        out.append('%s%s],' % (ind, pad[:-2]))
    return out

FRAMES, DFS, CASES = [], {}, []

def frame(nm, df):
    if nm not in DFS:
        DFS[nm] = df
        FRAMES.extend(["\t'%s' => {" % nm] + pframe(df, '\t\t') + ['\t},'])
    return nm

def emit(name, lname, rname, args, want, shapes=None):
    CASES.append("\t{ name  => '%s'," % name.replace("'", "\\'"))
    CASES.append("\t  left  => '%s', right => '%s'," % (lname, rname))
    CASES.append('\t  args  => [ %s ],' % args)
    if shapes:
        CASES.append("\t  shapes => '%s'," % shapes)
    CASES.extend(pframe(want, '\t  ', 'want_'))
    CASES.append('\t},')

# ------------------------------------------------------------ join normalisers
SENT = 'NA:'                    # not a value any corpus row carries

def na_unmatched(left, right, **kw):
    """pandas' merge under Stats::LikeR's key rule: a NaN key matches nothing.

    Each NaN key cell becomes a sentinel unique to (side, row, column), so it
    can never equal a cell on the other side and never collides with real data;
    the sentinels become NaN again in the result."""
    lkeys = kw.get('left_on') or kw.get('on') or []
    rkeys = kw.get('right_on') or kw.get('on') or []
    if isinstance(lkeys, str): lkeys = [lkeys]
    if isinstance(rkeys, str): rkeys = [rkeys]
    if not lkeys and kw.get('how') != 'cross':   # natural join: shared columns
        lkeys = rkeys = [c for c in left.columns if c in set(right.columns)]

    def stamp(df, keys, side):
        df = df.copy()
        for k in keys:
            col = df[k].astype(object)
            na  = col.isna()
            col[na] = ['%s%s:%d:%s' % (SENT, side, i, k) for i in range(int(na.sum()))]
            df[k] = col
        return df

    m = pd.merge(stamp(left, lkeys, 'x'), stamp(right, rkeys, 'y'), **kw)
    for c in m.columns:
        if m[c].dtype != object:
            continue
        m[c] = m[c].map(lambda v: np.nan
                        if isinstance(v, str) and v.startswith(SENT) else v)
    return m

def coalesce_keys(m, left_on, right_on):
    """R's and Stats::LikeR's single output key column: keep the left name,
    filled from the right where the left row is the missing one."""
    if isinstance(left_on, str):  left_on  = [left_on]
    if isinstance(right_on, str): right_on = [right_on]
    m = m.copy()
    for lk, rk in zip(left_on, right_on):
        m[lk] = m[lk].where(m[lk].notna(), m[rk])
    return m.drop(columns=[rk for rk in right_on if rk not in left_on])

HOWS = ('inner', 'left', 'right', 'outer')

def four(name, ln, rn, on, shapes=None):
    """One case per `how`, keys named the same on both sides."""
    for how in HOWS:
        want = na_unmatched(DFS[ln], DFS[rn], on=on, how=how, suffixes=('_x', '_y'))
        pon  = ("'%s'" % on) if isinstance(on, str) else pname(on)
        emit('%s [%s]' % (name, how), ln, rn,
             "'how' => '%s', 'on' => %s, 'suffixes' => ['_x','_y']" % (how, pon),
             want, shapes)

def four_xy(name, ln, rn, left_on, right_on, shapes=None):
    """The same, with the keys named differently on each side."""
    for how in HOWS:
        want = na_unmatched(DFS[ln], DFS[rn], left_on=left_on, right_on=right_on,
                            how=how, suffixes=('_x', '_y'))
        want = coalesce_keys(want, left_on, right_on)
        pl = ("'%s'" % left_on)  if isinstance(left_on, str)  else pname(left_on)
        pr = ("'%s'" % right_on) if isinstance(right_on, str) else pname(right_on)
        emit('%s [%s]' % (name, how), ln, rn,
             "'how' => '%s', 'left_on' => %s, 'right_on' => %s, "
             "'suffixes' => ['_x','_y']" % (how, pl, pr), want, shapes)

# --------------------------------------------------------------------- corpus

# test_merge_cross.py::test_merge_cross -- the two parametrisations, one where
# the right column collides with the left and one where it does not.
frame('cross_a',  pd.DataFrame({'a': [1, 3]}))
frame('cross_b',  pd.DataFrame({'b': [3, 4]}))
frame('cross_a2', pd.DataFrame({'a': [3, 4]}))
for rn in ('cross_b', 'cross_a2'):
    emit('test_merge_cross: %s' % rn, 'cross_a', rn,
         "'how' => 'cross', 'suffixes' => ['_x','_y']",
         pd.merge(DFS['cross_a'], DFS[rn], how='cross', suffixes=('_x', '_y')))

# test_merge_cross.py::test_merge_cross_mixed_dtypes
frame('cross_A', pd.DataFrame(['a', 'b', 'c'], columns=['A']))
frame('cross_B', pd.DataFrame(range(2), columns=['B']))
emit('test_merge_cross_mixed_dtypes', 'cross_A', 'cross_B',
     "'how' => 'cross'", pd.merge(DFS['cross_A'], DFS['cross_B'], how='cross'))

# test_merge_cross.py::test_merge_cross_more_than_one_column
frame('cross_AB', pd.DataFrame({'A': list('ab'), 'B': [2, 1]}))
frame('cross_CD', pd.DataFrame({'C': range(2), 'D': range(4, 6)}))
emit('test_merge_cross_more_than_one_column', 'cross_AB', 'cross_CD',
     "'how' => 'cross'", pd.merge(DFS['cross_AB'], DFS['cross_CD'], how='cross'))

# test_merge_cross.py::test_merge_cross_null_values -- a cross join ignores the
# keys entirely, so a missing cell just rides along.  pandas' c column is
# [1.0, 2.0]; integral, so it survives pv().
frame('cross_null_l', pd.DataFrame({'a': [1, np.nan]}))
frame('cross_null_r', pd.DataFrame({'b': ['a', 'b'], 'c': [1.0, 2.0]}))
emit('test_merge_cross_null_values', 'cross_null_l', 'cross_null_r',
     "'how' => 'cross'",
     pd.merge(DFS['cross_null_l'], DFS['cross_null_r'], how='cross'))

# test_merge.py::TestMerge::test_intelligently_handle_join_key (GH#733) -- a
# many-to-many key with unmatched rows on both sides.
frame('ihjk_l', pd.DataFrame({'key': [1, 1, 2, 2, 3], 'value': list(range(5))},
                             columns=['value', 'key']))
frame('ihjk_r', pd.DataFrame({'key': [1, 1, 2, 3, 4, 5], 'rvalue': list(range(6))}))
four('test_intelligently_handle_join_key', 'ihjk_l', 'ihjk_r', 'key')

# test_merge.py::TestMerge::test_merge_overlap -- a self-join on a key with
# ties, so the row count is sum(count^2) and every non-key column collides.
# v1 was standard_normal(7); fixed integers here.
frame('overlap', pd.DataFrame({'key': ['a', 'b', 'c', 'd', 'e', 'e', 'a'],
                               'v1': [10, 20, 30, 40, 50, 60, 70]}))
four('test_merge_overlap: self-join, every non-key column collides',
     'overlap', 'overlap', 'key')

# test_merge.py::TestMerge::test_merge_different_column_key_names -- left_on /
# right_on with a colliding non-key column.  pandas keeps both lkey and rkey;
# the frozen answer keeps one coalesced key column, which is R's convention and
# Stats::LikeR's.
frame('dckn_l', pd.DataFrame({'lkey': ['foo', 'bar', 'baz', 'foo'],
                              'value': [1, 2, 3, 4]}))
frame('dckn_r', pd.DataFrame({'rkey': ['foo', 'bar', 'qux', 'foo'],
                              'value': [5, 6, 7, 8]}))
four_xy('test_merge_different_column_key_names', 'dckn_l', 'dckn_r',
        'lkey', 'rkey')

# test_merge.py::TestMerge::test_merge_same_order_left_right (GH#35382) -- a
# self-join whose key repeats, five rows out of three.
frame('order_a', pd.DataFrame({'a': [1, 0, 1]}))
four('test_merge_same_order_left_right', 'order_a', 'order_a', 'a')

# test_merge.py::TestMerge::test_left_merge_empty_dataframe -- an empty right
# frame, both ways round.  An empty AoH carries no column names at all, so
# these run as HoA only; the .t pins what the AoH form does instead.
frame('lmed_l',  pd.DataFrame({'key': [1], 'value': [2]}))
frame('lmed_r',  pd.DataFrame({'key': pd.Series([], dtype='int64')}))
four('test_left_merge_empty_dataframe', 'lmed_l', 'lmed_r', 'key', shapes='hoa')
four('test_left_merge_empty_dataframe, reversed', 'lmed_r', 'lmed_l', 'key',
     shapes='hoa')

# test_merge.py::TestMerge::test_merge_empty (GH#52777) -- the ten
# (left_empty, how) parametrisations, over a natural join on A.
me_left  = pd.DataFrame({'A': [2, 1], 'B': [3, 4]})
me_right = pd.DataFrame({'A': [1], 'C': [5]}, dtype='int64')
frame('me_left',   me_left)
frame('me_right',  me_right)
frame('me_left0',  me_left.head(0))
frame('me_right0', me_right.head(0))
for left_empty in (False, True):
    ln = 'me_left0' if left_empty else 'me_left'
    rn = 'me_right' if left_empty else 'me_right0'
    for how in HOWS + ('cross',):
        kw = dict(how=how) if how == 'cross' else dict(how=how, on='A')
        want = na_unmatched(DFS[ln], DFS[rn], suffixes=('_x', '_y'), **kw)
        args = ("'how' => 'cross', 'suffixes' => ['_x','_y']" if how == 'cross'
                else "'how' => '%s', 'on' => 'A', 'suffixes' => ['_x','_y']" % how)
        emit('test_merge_empty: %s empty [%s]' %
             ('left' if left_empty else 'right', how), ln, rn, args, want,
             shapes='hoa')

# test_merge.py::TestMergeDtypes::test_merge_on_ints_floats -- an int64 key
# column joined against a float64 one holding the same values.  perl prints
# 1.0 as "1", so these match on the stringified key exactly as pandas' cast
# makes them match.
frame('intkey',   pd.DataFrame({'X': [1, 2, 3]}))
frame('floatkey', pd.DataFrame({'X': [1.0, 2.0, 3.0], 'Y': [1, 2, 3]}))
four('test_merge_on_ints_floats', 'intkey', 'floatkey', 'X')

# test_multi.py::TestMergeMulti::test_merge_na_keys -- a three-column natural
# join whose third key column holds NaN.  This is where pandas' rule (NaN
# matches NaN, checked upstream via fillna(-999)) and Stats::LikeR's part
# company; the frozen answer is Stats::LikeR's, and the .t records the
# divergence with pandas' own answer beside it.
frame('nak_frame', pd.DataFrame([[1950, 'A', 1], [1950, 'B', 1], [1955, 'B', 1],
                                 [1960, 'B', np.nan], [1970, 'B', 4],
                                 [1950, 'C', 4], [1960, 'C', np.nan],
                                 [1965, 'C', 3], [1970, 'C', 4]],
                                columns=['year', 'panel', 'data']))
frame('nak_other', pd.DataFrame([[1960, 'A', np.nan], [1970, 'A', np.nan],
                                 [1955, 'A', np.nan], [1965, 'A', np.nan],
                                 [1965, 'B', np.nan], [1955, 'C', np.nan]],
                                columns=['year', 'panel', 'data']))
four('test_merge_na_keys: three key columns, one of them NaN',
     'nak_frame', 'nak_other', ['year', 'panel', 'data'])

# test_multi.py::TestMergeMulti::test_merge_multiple_cols_with_mixed_cols_index
# (GH#29522) -- a two-column key, one string and one integer.
frame('mixed_df', pd.DataFrame({'lev1': list('AAABBB'), 'lev2': [1, 2, 3, 1, 2, 3],
                                'col': 0}))
frame('mixed_s', pd.DataFrame({'lev1': list('AAABBB'), 'lev2': [1, 2, 3, 1, 2, 3],
                               'Amount': range(6)}))
four('test_merge_multiple_cols_with_mixed_cols_index', 'mixed_df', 'mixed_s',
     ['lev1', 'lev2'])

# test_merge.py::TestMerge::test_merge_non_unique_index_many_to_many, rewritten
# from an index join to a column join: the key repeats on both sides and the
# two frames disagree about which keys they carry.
frame('m2m_l', pd.DataFrame({'k': ['2012-05-02', '2012-05-02', '2012-05-01',
                                   '2012-05-01'], 'x': ['a', 'b', 'c', 'd']}))
frame('m2m_r', pd.DataFrame({'k': ['2012-05-02', '2012-05-02', '2012-05-03',
                                   '2012-05-01', '2012-05-01'],
                             'y': ['e', 'f', 'g', ' h', 'i']}))
four('test_merge_non_unique_index_many_to_many', 'm2m_l', 'm2m_r', 'k')

# test_merge.py::test_merge_suffix -- the suffix parametrisations that a
# column-keyed join can express.  pandas' cases join on the index; here both
# frames carry a key column k as well, and the suffix rule under test is the
# same one.  A None suffix means "leave this side's name alone", which is
# Stats::LikeR's empty-string suffix.
sfx_l = pd.DataFrame({'k': [1, 2, 3], 'b': [1, 2, 3]})
sfx_r = pd.DataFrame({'k': [1, 2, 3], 'b': [4, 5, 6]})
frame('sfx_l', sfx_l)
frame('sfx_r', sfx_r)
for (ps, ls) in ((('', '_dup'), "['', '_dup']"),
                 (('_x', '_y'),  "['_x','_y']"),
                 ((None, '_y'),  "['', '_y']"),
                 (('_x', None),  "['_x','']"),
                 (('_a', None),  "['_a','']")):
    want = pd.merge(sfx_l, sfx_r, on='k', suffixes=ps)
    emit('test_merge_suffix: suffixes = %r' % (ps,), 'sfx_l', 'sfx_r',
         "'how' => 'inner', 'on' => 'k', 'suffixes' => %s" % ls, want)

# --------------------------------------------------------------------- output
print('# BEGIN GENERATED (pandas) -- python3 t/merge.R.pandas.py')
print('# %d frames and %d cases, from pandas %s'
      % (sum(1 for l in FRAMES if l.startswith("\t'")),
         sum(1 for l in CASES if l.startswith('\t{ name')), pd.__version__))
print('my %PD_FRAMES = (')
print('\n'.join(FRAMES))
print(');')
print()
print('my @PD_CASES = (')
print('\n'.join(CASES))
print(');')
print('# END GENERATED (pandas)')
