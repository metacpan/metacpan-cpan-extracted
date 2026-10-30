package Stats::LikeR::Usage;
# The help screens that Stats::LikeR prints above an error in how a function was
# called, laid out as Python's argparse lays out its own (Lib/argparse.py,
# HelpFormatter): the usage line, a one-line description, the positional
# arguments, the options with their defaults, and an example. The error itself
# follows on the last line, as "fn: error: ...", where argparse's
# ArgumentParser.error() puts its own.
#
# This file is required only when such an error is raised, by
# Stats::LikeR::_usage_text(), so a correct call never compiles it. Every
# exported function has a screen here; t/usage.t checks that, and checks the
# layout every screen must keep:
#
#  - the first line is "usage: fn(", and a usage too long for one line wraps
#    onto lines indented to start under its first argument, after "usage:
#    fn(", as argparse indents under its first after "usage: prog ";
#  - the sections are "positional arguments:", "options:" and "example:", in
#    that order, the first two left out when a function has nothing to put in
#    them;
#  - an entry's name and its help are two columns, and a name too wide for its
#    column puts its help on the next line, as argparse does. argparse starts
#    the help at most at column 25 (max_help_position=24, counted from 0) and
#    sooner when every name is short; here it is column 26 in every screen, so
#    that all of them line up with one another, and with df2h's, the first;
#  - no line is wider than 80 columns, there are no tabs, and the screen ends
#    with one blank line, above the error.
#
# A name that is a second name for another function (aoh2h, rbind) is in
# %ALIAS, and shows the screen of the function it is; that function's messages
# already name it.
use strict;
use warnings;

our %ALIAS = (
	aoh2h => 'df2h',
	rbind => 'concat',
);

our %SCREEN;

$SCREEN{df2h} = <<'END';
usage: df2h(DF [, var_name => KEY] [, value_name => VALUE]
            [, duplicates => {die,first,last}])

Fold the two columns of a data frame into a flat hash: { KEY => VALUE, ... }.

positional arguments:
  DF                     the data frame: an AoH, AoA, HoA or HoH

options:
  var_name => KEY        column whose cells become the hash keys
                         (default: 'variable'; for an AoA, position 0)
  value_name => VALUE    column whose cells become the hash values
                         (default: 'value'; for an AoA, position 1)
  duplicates => MODE     what a repeated key does: die, first or last
                         (default: die; a HoH accepts only die)

example:
  df2h([ { variable => 'a', value => 1 }, { variable => 'b', value => 2 } ])
      # returns { a => 1, b => 2 }

END

# Screens, part 1.

$SCREEN{add_data} = <<'END';
usage: add_data(TARGET, NEW)

Add NEW's rows or columns to TARGET, in place, coercing NEW to TARGET's shape.

positional arguments:
  TARGET                 the hash or array ref added to; it is changed in place
  NEW                    the hash or array ref whose data is added (copied)

example:
  my $d = { x => [1, 2] };
  add_data($d, { x => [3] });
      # $d is now { x => [1, 2, 3] }

END

$SCREEN{agg} = <<'END';
usage: agg(DF, agg => { COL => FUNC, ... } [, by => COL] [, skipna => {1,0}]
           [, sort => {1,0}] [, output_type => {aoa,aoh,hoa,hoh}])

Aggregate the columns of a data frame, whole or by group.

positional arguments:
  DF                     the data frame: an AoA, AoH, HoA or HoH

options:
  agg => SPEC            required: { COL => FUNC }, FUNC an aggregator name
                         (mean median sum sd var min max count n nunique
                         first last mode), a list of them, or a coderef
  by => COL              a grouping column, or an arrayref of them
                         (default: none, one row for the whole frame)
  skipna => BOOL         ignore undef cells in numeric aggregators
                         (default: 1)
  sort => BOOL           sort the groups by key; 0 keeps first-seen order
                         (default: 1)
  output_type => TYPE    the shape returned (default: the shape of DF)

example:
  agg([ { g => 'a', x => 1 }, { g => 'a', x => 3 }, { g => 'b', x => 5 } ],
      by => 'g', agg => { x => 'mean' })
      # returns [ { g => 'a', x => 2 }, { g => 'b', x => 5 } ]

END

$SCREEN{aoh2hoa} = <<'END';
usage: aoh2hoa(AOH)

Transpose an array of hashes (rows) into a hash of arrays (columns).

positional arguments:
  AOH                    an arrayref of hashrefs, one per row

example:
  aoh2hoa([ { a => 1, b => 2 }, { a => 3 } ])
      # returns { a => [1, 3], b => [2, undef] }

END

$SCREEN{aoh2hoh} = <<'END';
usage: aoh2hoh(AOH, KEY)

Index an array of hashes by one column, into a hash of hashes.

positional arguments:
  AOH                    an arrayref of hashrefs, one per row
  KEY                    the column whose (unique) value names each row

example:
  aoh2hoh([ { id => 'p1', kd => 12.4 }, { id => 'p2', kd => 3.1 } ], 'id')
      # returns { p1 => { id => 'p1', kd => 12.4 },
      #           p2 => { id => 'p2', kd => 3.1 } }

END

$SCREEN{assign} = <<'END';
usage: assign(DF, NAME => VALUE [, NAME => VALUE ...])

Add or overwrite columns of a data frame, in place, and return it.

positional arguments:
  DF                     the data frame: an AoH, HoA or HoH

options:
  NAME => VALUE          the column NAME, set from VALUE: a coderef called
                         once per row with the row in $_, an arrayref holding
                         the whole column, or a map_cell { ... } block that
                         edits the column NAME cell by cell

example:
  assign([ { w => 70, h => 1.75 } ], bmi => sub { $_->{w} / $_->{h}**2 })
      # returns [ { w => 70, h => 1.75, bmi => 22.8571428571429 } ]

END

$SCREEN{avals} = <<'END';
usage: avals(DF, COLUMN)

Return one column of a data frame as a list (vals() returns it as an arrayref).

positional arguments:
  DF                     the data frame: an AoH, HoA or HoH
  COLUMN                 the name of the column

example:
  avals([ { age => 30 }, { age => 41 } ], 'age')
      # returns (30, 41)

END

$SCREEN{bfill} = <<'END';
usage: bfill(DF [, cols => [COL, ...]] [, limit => N])

Fill each undef cell with the next defined value below it in its column.

positional arguments:
  DF                     the data frame: an AoA, AoH, HoA or HoH

options:
  cols => [COL, ...]     the columns to fill (default: every column)
  limit => N             fill at most N undef cells in a row in each gap
                         (default: no limit)

example:
  bfill({ x => [undef, 2, undef, 4] })
      # returns { x => [2, 2, 4, 4] }

END

$SCREEN{ffill} = <<'END';
usage: ffill(DF [, cols => [COL, ...]] [, limit => N])

Fill each undef cell with the last defined value above it in its column.

positional arguments:
  DF                     the data frame: an AoA, AoH, HoA or HoH

options:
  cols => [COL, ...]     the columns to fill (default: every column)
  limit => N             fill at most N undef cells in a row in each gap
                         (default: no limit)

example:
  ffill({ x => [1, undef, 3, undef] })
      # returns { x => [1, 1, 3, 3] }

END

$SCREEN{fillna} = <<'END';
usage: fillna(DF, value => VALUE [, cols => [COL, ...]])

Replace undef cells with a constant, in a new data frame.

positional arguments:
  DF                     the data frame: an AoA, AoH, HoA or HoH

options:
  value => VALUE         required: the fill for every column, or a hashref
                         { COL => VALUE, ... } of a fill per column
  cols => [COL, ...]     the columns a single VALUE fills; not with a hashref
                         (default: every column)

example:
  fillna({ x => [1, undef], y => [undef, 'b'] }, value => 0)
      # returns { x => [1, 0], y => [0, 'b'] }

END

$SCREEN{chunk} = <<'END';
usage: chunk(ARRAY, size => N | parts => K)

Split an array into contiguous groups, in order.

positional arguments:
  ARRAY                  the arrayref to split; its contents are not examined

options:
  size => N              N elements in each group, the last group holding
                         what is left
  parts => K             K groups of as equal a size as possible; give
                         exactly one of size and parts

example:
  chunk([1 .. 5], size => 2)
      # returns ([1, 2], [3, 4], [5])

END

$SCREEN{col} = <<'END';
usage: col(NAME)

Name a column in a filter() predicate: col('x') > 0, combined with & | !.

positional arguments:
  NAME                   the name of the column

example:
  filter([ { age => 15 }, { age => 30 } ], col('age') >= 18)
      # returns [ { age => 30 } ]

END

$SCREEN{col2col} = <<'END';
usage: col2col(DATA, COMMAND [, COLS [, na => {pairwise,omit,keep}]
               [, skip_errors => {1,0}] [, rm_undef => {1,0}]])

Apply a two-column function to every pair of columns, into a hash of hashes.

positional arguments:
  DATA                   the table: an AoH, HoA or HoH
  COMMAND                a coderef called as COMMAND->(\@a, \@b), or the
                         name of a function, such as 'cor'
  COLS                   the "from" columns: one name, an arrayref of names,
                         or undef for every column (default: every column);
                         or, in its place, a hashref of the options below

options:
  na => MODE             undef cells: pairwise drops a row from both
                         columns, omit drops it from its own column, keep
                         passes it through (default: pairwise)
  skip_errors => BOOL    store a failing pair's error as its cell, rather
                         than dying (default: 1)
  rm_undef => BOOL       the older na: 1 is pairwise and 0 is keep; also
                         spelt rm_na, and not given with na

example:
  col2col({ x => [1, 2, 3], y => [2, 4, 7] }, 'cor')
      # returns { x => { y => 0.993399267798783 },
      #           y => { x => 0.993399267798783 } }

END

$SCREEN{colnames} = <<'END';
usage: colnames(DF)

Return the column names of a data frame, or their count in scalar context.

positional arguments:
  DF                     the data frame: an AoA, AoH, HoA or HoH

example:
  colnames([ { b => 1, a => 2 }, { c => 3 } ])
      # returns ('a', 'b', 'c')

END

$SCREEN{concat} = <<'END';
usage: concat(DF [, DF ...])

Stack data frames of one shape, row-wise, as R's rbind() does.

positional arguments:
  DF                     a data frame: an AoA, AoH, HoA or HoH; every
                         non-empty one must have the same shape

example:
  concat({ x => [1, 2] }, { x => [3], y => ['a'] })
      # returns { x => [1, 2, 3], y => [undef, undef, 'a'] }

END

$SCREEN{csort} = <<'END';
usage: csort(DF, BY [, OUTPUT_TYPE] [, ROW_NAME_COL])

Return a copy of a data frame sorted by a column or a comparator.

positional arguments:
  DF                     the data frame: an AoA, AoH, HoA or HoH
  BY                     a column name (AoH, HoA, HoH), a column index (AoA),
                         or a comparator coderef using $a and $b
  OUTPUT_TYPE            the shape returned: {aoh,hoa,aoa}
                         (default: the shape of DF, a HoH giving an AoH)
  ROW_NAME_COL           for a HoH, the column that holds the row names
                         (default: 'row_name')

example:
  csort([ { n => 3 }, { n => 1 }, { n => 2 } ], 'n')
      # returns [ { n => 1 }, { n => 2 }, { n => 3 } ]

END

# Screens, part 2.

$SCREEN{cfilter} = <<'END';
usage: cfilter(DATA, (keep => SELECTOR | remove => SELECTOR)
               [, na => {keep,omit}] [, against => COLUMN])

Select the columns of a table by name, pattern or test, in the same shape.

positional arguments:
  DATA                   the table: an AoH, HoA or HoH

options:
  keep => SELECTOR       the columns to keep: an arrayref of names, a qr//
                         matched against the names, or a code ref or function
                         name that a column's cells must pass
  remove => SELECTOR     the columns to remove, chosen as for keep; give one
                         of keep and remove
  na => NA               for a code ref or function: keep hands it undef
                         cells, omit leaves them out (default: keep)
  against => COLUMN      for a two-column test such as cor: the column each
                         column is paired with, over the rows defined in both

example:
  cfilter({ x => [1, 2], y => [3, 4], z => [0, 0] }, keep => ['x', 'y'])
      # returns { x => [1, 2], y => [3, 4] }

END

$SCREEN{dftype} = <<'END';
usage: dftype(DATA)

Name the shape of DATA: AoA, AoH, HoA, HoH, array, hash, scalar or undef.

positional arguments:
  DATA                   any scalar, or a reference to anything

example:
  dftype([ { a => 1 }, { a => 2 } ])
      # returns 'AoH'

END

$SCREEN{drop_cols} = <<'END';
usage: drop_cols(DF, COLUMN [, COLUMN ...])

Return a new data frame without the named columns.

positional arguments:
  DF                     the data frame: an AoH, AoA, HoA or HoH
  COLUMN                 a column to drop: a name, or for an AoA a 0-based
                         position; several may also come as one arrayref

example:
  drop_cols({ a => [1, 4], b => [2, 5], c => [3, 6] }, 'b')
      # returns { a => [1, 4], c => [3, 6] }

END

$SCREEN{drop_duplicates} = <<'END';
usage: drop_duplicates(DF [, subset => COLUMNS]
                       [, keep => {first,last,0}])

Remove duplicate rows, keeping one occurrence of each.

positional arguments:
  DF                     the data frame: an AoH, AoA or HoA (not a HoH)

options:
  subset => COLUMNS      the column, or arrayref of columns, whose cells make
                         two rows equal (default: every column)
  keep => KEEP           which occurrence survives: first, last, or 0 (also
                         'none') to drop every duplicated row (default: first)

example:
  drop_duplicates({ id => [1, 1, 2], v => [10, 20, 30] }, subset => 'id')
      # returns { id => [1, 2], v => [10, 30] }

END

$SCREEN{dropna} = <<'END';
usage: dropna(DF, (cols => COLUMNS | rows => ROWS) [, how => {any,all}])

Drop the rows of a data frame that hold undef in given columns, or given rows.

positional arguments:
  DF                     the data frame: an AoH, HoA or HoH

options:
  cols => COLUMNS        arrayref of columns: drop the rows undef in them
  rows => ROWS           arrayref of rows to delete outright: indices for an
                         AoH or HoA, row names for a HoH; give one of cols
                         and rows
  how => HOW             with cols, drop a row when any or when all of them
                         are undef (default: any)

example:
  dropna({ A => [1, 2, undef], B => [1, 2, 3] }, cols => ['A'])
      # returns { A => [1, 2], B => [1, 2] }

END

$SCREEN{filter} = <<'END';
usage: filter(DF, PREDICATE [, output_type => {aoh,hoa}])

Keep the rows of a data frame for which a predicate is true.

positional arguments:
  DF                     the data frame: an AoH, HoA or HoH
  PREDICATE              a code ref called with each row as $_, or a col()
                         expression such as col('x') > 0

options:
  output_type => TYPE    the shape of the result, aoh or hoa
                         (default: the shape of DF)

example:
  filter([ { x => 1 }, { x => 5 } ], sub { $_->{x} > 2 })
      # returns [ { x => 5 } ]

END

$SCREEN{get_union} = <<'END';
usage: get_union(ARRAY [, ARRAY ...])

Return every distinct value in any of the arrays, in first-seen order.

positional arguments:
  ARRAY                  an array ref, read as a set; at least one

example:
  get_union([1, 2, 3, 3], [3, 4])
      # returns (1, 2, 3, 4), or 4 in scalar context

END

$SCREEN{group_by} = <<'END';
usage: group_by(DATA, VALUE_COLUMN, GROUP_COLUMN [, FILTER ...])

Split the values of one column by the levels of another, as R's split() does.

positional arguments:
  DATA                   the data frame: an AoH, HoA or HoH
  VALUE_COLUMN           the column whose values are collected
  GROUP_COLUMN           the column whose levels key the result
  FILTER                 a hashref { column => sub { ... } }; a row is kept
                         only when each sub is true of that cell, in $_

example:
  group_by([ { g => 'a', v => 1 }, { g => 'b', v => 2 }, { g => 'a', v => 3 } ],
           'v', 'g')
      # returns { a => [1, 3], b => [2] }

END

$SCREEN{h2aoh} = <<'END';
usage: h2aoh(HASH [, var_name => KEY] [, value_name => VALUE]
             [, sort => {key,value,none}])

Unfold a flat hash into a two-column AoH, one row per pair.

positional arguments:
  HASH                   a hash ref whose values are plain scalars

options:
  var_name => KEY        name of the column that receives the keys
                         (default: 'variable')
  value_name => VALUE    name of the column that receives the values
                         (default: 'value')
  sort => ORDER          the row order: key, value (largest first), or none
                         (default: key)

example:
  h2aoh({ a => 1, b => 2 })
      # returns [ { variable => 'a', value => 1 },
      #           { variable => 'b', value => 2 } ]

END

$SCREEN{hoa2aoh} = <<'END';
usage: hoa2aoh(HOA)

Turn a hash of arrays into an array of hashes, one hash per row.

positional arguments:
  HOA                    a hash ref whose values are array refs, one per
                         column

example:
  hoa2aoh({ id => [1, 2], name => ['a', 'b'] })
      # returns [ { id => 1, name => 'a' }, { id => 2, name => 'b' } ]

END

$SCREEN{hoa2hoh} = <<'END';
usage: hoa2hoh(HOA, KEY)

Turn a hash of arrays into a hash of hashes keyed by one of its columns.

positional arguments:
  HOA                    a hash ref whose values are array refs, one per
                         column
  KEY                    the column whose values name the rows; it stays in
                         each row

example:
  hoa2hoh({ id => ['a', 'b'], x => [1, 2] }, 'id')
      # returns { a => { id => 'a', x => 1 }, b => { id => 'b', x => 2 } }

END

$SCREEN{hoh2hoa} = <<'END';
usage: hoh2hoa(HOH [, undef_val => FILL] [, row_names => COLUMN])

Turn a hash of hashes into a hash of arrays, its rows in sorted order.

positional arguments:
  HOH                    a hash ref whose values are hash refs, one per row

options:
  undef_val => FILL      the value for a missing or undef cell
                         (default: undef)
  row_names => COLUMN    add a column of this name holding the row names
                         (default: none)

example:
  hoh2hoa({ r1 => { a => 1, b => 2 }, r2 => { a => 3 } })
      # returns { a => [1, 3], b => [2, undef] }

END

$SCREEN{interpolate} = <<'END';
usage: interpolate(DF [, method => METHOD] [, cols => COLUMNS] [, order => N]
                   [, x => X] [, limit => N]
                   [, limit_direction => {forward,backward,both}]
                   [, limit_area => {inside,outside}])

Fill undef cells along the rows by interpolation, as pandas' interpolate does.

positional arguments:
  DF                     the data frame: an AoH, AoA, HoA or HoH

options:
  method => METHOD       linear, index, values, time, slinear, nearest, zero,
                         pad, ffill, bfill, backfill, quadratic, cubic,
                         cubicspline, pchip, akima, barycentric, krogh,
                         polynomial or spline (default: linear)
  cols => COLUMNS        arrayref of the columns to fill (default: all)
  order => N             the degree, which polynomial and spline require
  x => X                 the abscissae: a column, or an arrayref
                         (default: the row positions)
  limit => N             the most cells filled in one run of undefs
                         (default: no limit)
  limit_direction => DIRECTION
                         which way limit counts: forward, backward or both
                         (default: forward)
  limit_area => AREA     fill only inside or only outside the known values
                         (default: both)

example:
  interpolate({ v => [1, undef, 3] })
      # returns { v => [1, 2, 3] }

END

$SCREEN{intersection} = <<'END';
usage: intersection(ARRAY [, ARRAY ...])

Return the distinct values found in every one of the arrays.

positional arguments:
  ARRAY                  an array ref, read as a set; at least one

example:
  intersection([1, 2, 3], [2, 3, 4])
      # returns (2, 3), or 2 in scalar context

END

$SCREEN{is_equivalent} = <<'END';
usage: is_equivalent(ARRAY, ARRAY [, ARRAY ...])

Return 1 if every array holds the same set of distinct values, and 0 if not.

positional arguments:
  ARRAY                  an array ref, read as a set; at least two

example:
  is_equivalent([1, 2, 3], [3, 2, 1])
      # returns 1

END

$SCREEN{ljoin} = <<'END';
usage: ljoin(H, I)

Add I's columns to the rows of H that I also has, modifying H in place.

positional arguments:
  H                      a hash of hashes, { row => { column => value } }
  I                      a hash whose rows are hash refs, or array refs of
                         column => value pairs

example:
  my %h = (jack => { age => 30 });
  ljoin(\%h, { jack => { dept => 'IT' }, jane => { age => 25 } })
      # %h is now (jack => { age => 30, dept => 'IT' })

END

$SCREEN{Lonly} = <<'END';
usage: Lonly(ARRAY [, ARRAY ...])

Return the distinct values of the first array that are in no other array.

positional arguments:
  ARRAY                  an array ref, read as a set; at least one

example:
  Lonly([1, 2, 3], [3, 4, 5])
      # returns (1, 2), or 2 in scalar context

END

$SCREEN{map_cell} = <<'END';
usage: map_cell(BLOCK)

Wrap a block for assign(), which runs it on each cell of a column as $_.

positional arguments:
  BLOCK                  a block, map_cell { ... }, run once per row with $_
                         a copy of the cell; $_ is then stored back

example:
  assign([ { x => 'A:1' } ], x => map_cell { s/^[A-Z]:// })
      # returns [ { x => '1' } ]

END

$SCREEN{Ronly} = <<'END';
usage: Ronly(ARRAY [, ARRAY ...])

Return the distinct values of the last array that are in no other array.

positional arguments:
  ARRAY                  an array ref, read as a set; at least one

example:
  Ronly([1, 2, 3], [3, 4, 5])
      # returns (4, 5), or 2 in scalar context

END

# Screens, part 3.

$SCREEN{matrix} = <<'END';
usage: matrix(DATA [, NROW] [, NCOL] [, BYROW])

Shape a flat list of numbers into a matrix, as an array of rows, like R's.

positional arguments:
  DATA                   array ref of the cells, filled column by column; also
                         data => DATA
  NROW                   number of rows; also nrow => NROW (default: from NCOL,
                         else every cell in one column)
  NCOL                   number of columns; also ncol => NCOL (default: from
                         NROW, else 1)
  BYROW                  fill row by row instead; also byrow => 1 (default: 0)

example:
  matrix([1..6], 2)      # same as matrix(data => [1..6], nrow => 2)
      # returns [ [1, 3, 5], [2, 4, 6] ]

END

$SCREEN{melt} = <<'END';
usage: melt(DF [, id_vars => COLS] [, value_vars => COLS] [, var_name => NAME]
            [, value_name => NAME] [, output_type => {aoa,aoh,hoa,hoh}])

Unpivot a wide data frame into long form, like pandas' DataFrame.melt.

positional arguments:
  DF                     the data frame: an AoH, AoA, HoA or HoH

options:
  id_vars => COLS        a column or array ref of columns kept and repeated down
                         the output (default: none)
  value_vars => COLS     a column or array ref of columns to unpivot (default:
                         every column not in id_vars)
  var_name => NAME       name of the column-name column (default: 'variable')
  value_name => NAME     name of the value column (default: 'value')
  output_type => TYPE    aoa, aoh, hoa or hoh (default: the shape of DF)

example:
  melt([ { A => 'a', B => 1, C => 2 } ], id_vars => 'A')
      # returns [ { A => 'a', variable => 'B', value => 1 },
      #           { A => 'a', variable => 'C', value => 2 } ]

END

$SCREEN{merge} = <<'END';
usage: merge(LEFT, RIGHT [, how => {inner,left,right,outer,cross}]
             [, on => COLS] [, left_on => COLS, right_on => COLS]
             [, suffixes => [X, Y]] [, output_type => {aoh,hoa}])

Join two data frames on key columns, like R's merge and pandas' DataFrame.merge.

positional arguments:
  LEFT                   the left data frame: an AoH, HoA or HoH
  RIGHT                  the right data frame: an AoH, HoA or HoH

options:
  how => HOW             inner, left, right, outer (or full) or cross (default:
                         inner)
  on => COLS             a column or array ref of columns in both frames; also
                         by (default: every column the two share)
  left_on => COLS        the left key columns, given with right_on; also by_x
  right_on => COLS       the right key columns, given with left_on; also by_y
  suffixes => [X, Y]     appended to a non-key column found in both (default:
                         ['.x', '.y'])
  output_type => TYPE    aoh or hoa; also out (default: hoa for a HoA left
                         frame, else aoh)

example:
  merge([ { id => 1, x => 'a' }, { id => 2, x => 'b' } ],
        [ { id => 1, y => 'c' } ], on => 'id')
      # returns [ { id => 1, x => 'a', y => 'c' } ]

END

$SCREEN{ncol} = <<'END';
usage: ncol(DF)

Count the columns of a data frame; a flat array is one column.

positional arguments:
  DF                     the data frame: an AoH, AoA, HoA, HoH or a plain array
                         ref

example:
  ncol([ { a => 1, b => 2 } ])     # returns 2

END

$SCREEN{nrow} = <<'END';
usage: nrow(DF)

Count the rows of a data frame; a flat array has one row per element.

positional arguments:
  DF                     the data frame: an AoH, AoA, HoA, HoH or a plain array
                         ref

example:
  nrow([ { a => 1 }, { a => 2 } ])     # returns 2

END

$SCREEN{pivot_table} = <<'END';
usage: pivot_table(DF, columns => COLS [, index => COLS] [, values => COLS]
                   [, aggfunc => FUNC] [, fill_value => X] [, skipna => {0,1}]
                   [, sort => {0,1}] [, sep => STR]
                   [, output_type => {aoa,aoh,hoa,hoh}])

Spread a long data frame into a wide one, like pandas' pivot_table.

positional arguments:
  DF                     the data frame: an AoH, AoA, HoA or HoH

options:
  columns => COLS        a column or array ref of columns whose values name the
                         output columns (required)
  index => COLS          a column or array ref of columns that key the output
                         rows (default: none, one row)
  values => COLS         the columns to aggregate (default: every column not in
                         index or columns)
  aggfunc => FUNC        mean, median, sum, sd, var, min, max, count, n,
                         nunique, first, last or mode, a code ref, or an array
                         ref of these (default: mean)
  fill_value => X        put in place of an undef result cell (default: leave it
                         undef)
  skipna => {0,1}        drop undef cells before a numeric reduction (default:
                         1)
  sort => {0,1}          sort the output rows and columns; 0 keeps first-seen
                         order (default: 1)
  sep => STR             joins the pieces of a generated column name (default:
                         '.')
  output_type => TYPE    aoa, aoh, hoa or hoh (default: the shape of DF)

example:
  pivot_table([ { k => 'a', y => 1, v => 2 }, { k => 'a', y => 1, v => 4 } ],
              index => 'k', columns => 'y', values => 'v')
      # returns [ { k => 'a', 1 => 3 } ]

END

$SCREEN{qcut} = <<'END';
usage: qcut(DATA, Q [, edges => {0,1}] [, codes => {0,1}] [, labels => LABELS]
            [, duplicates => {raise,drop}])

Cut numbers into equal-frequency bins, like pandas' qcut.

positional arguments:
  DATA                   array ref of numbers; undef is missing
  Q                      the number of bins, or an array ref of probabilities in
                         [0, 1]

options:
  edges => {0,1}         return the bin edges (default: 1, or 0 when codes are
                         asked for)
  codes => {0,1}         return each value's 0-based bin code (default: 0)
  labels => LABELS       an array ref of one label per bin, or 'interval';
                         implies codes => 1
  duplicates => MODE     raise dies on a repeated edge, drop merges it (default:
                         raise)

example:
  my @edges = qcut([1..8], 4)     # returns (1, 2.75, 4.5, 6.25, 8)
  my $codes = qcut([1..8], 2, codes => 1)
      # returns [0, 0, 0, 0, 1, 1, 1, 1]

END

$SCREEN{read_table} = <<'END';
usage: read_table(FILE [, sep => SEP] [, header => {0,1}] [, col_names => NAMES]
                  [, output_type => {aoa,aoh,hoa,hoh}] [, row_names => COL]
                  [, auto_row_names => NAME] [, comment => STR] [, quote => Q]
                  [, filter => FILTER] [, na_strings => STRS]
                  [, colClasses => CLASSES] [, sheet => SHEET]
                  [, explode => {0,1}])

Read a delimited text, VCF or .xlsx file into a data frame, like R's read.table.

positional arguments:
  FILE                   the file; .gz and .bz2 are read through, .xlsx is read
                         as Excel

options:
  sep => SEP             a literal separator or a qr// regex; also delim
                         (default: tab for .tsv and .vcf, else ',')
  header => {0,1}        the first line names the columns (default: 1)
  col_names => NAMES     array ref of column names, used in place of the header
                         (default: the header, or V1, V2, ...)
  output_type => TYPE    aoa, aoh, hoa or hoh (default: aoh; hoh for an exploded
                         VCF)
  row_names => COL       hoh only: the column that keys the rows (default: the
                         first)
  auto_row_names => NAME
                         read R's write.table output, whose header lacks the
                         row-name field; 1 names the column row_name (default:
                         off)
  comment => STR         lines starting with it are skipped (default: '#', '##'
                         for a VCF)
  quote => Q             '"' quotes fields, '' turns quoting off (default: '"')
  filter => FILTER       a hash ref of code refs by column name or 1-based field
                         (0 is the whole row), or one code ref for the row; a
                         row is kept when every one returns true
  na_strings => STRS     a string or array ref of field texts read as undef;
                         also na_values or undef_val (default: none)
  colClasses => CLASSES  numeric, integer or character: one for all columns, an
                         array ref by position or a hash ref by name
  sheet => SHEET         .xlsx only: a sheet name or 1-based index (default: the
                         first sheet)
  explode => {0,1}       VCF only: split each sample column by its FORMAT keys
                         (default: 1)

example:
  my $aoh = read_table('cohort.csv', sep => ',', output_type => 'aoh')
      # returns [ { id => 1, age => 41, ... }, ... ], one hash per row

END

$SCREEN{rename_cols} = <<'END';
usage: rename_cols(DF, OLD => NEW, ...)

Rename columns of a data frame; in void context the frame itself is renamed.

positional arguments:
  DF                     the data frame: an AoH, HoA or HoH (an AoA has no
                         names)
  OLD => NEW             one or more pairs, or one hash ref { OLD => NEW, ... }

example:
  rename_cols([ { a => 1 } ], a => 'b')     # returns [ { b => 1 } ]

END

$SCREEN{rownames} = <<'END';
usage: rownames(DF)

List the row names of a data frame: a HoH's keys, else 0 .. n-1.

positional arguments:
  DF                     the data frame: an AoH, AoA, HoA or HoH

example:
  rownames({ r1 => { a => 1 }, r2 => { a => 2 } })     # returns ('r1', 'r2')

END

$SCREEN{select_cols} = <<'END';
usage: select_cols(DF, COL, ...)

Keep only the named columns of a data frame, in the order given.

positional arguments:
  DF                     the data frame: an AoH, AoA, HoA or HoH
  COL                    one or more column names (positions for an AoA), or one
                         array ref of them

example:
  select_cols([ { a => 1, b => 2 } ], 'a')     # returns [ { a => 1 } ]

END

$SCREEN{table_one} = <<'END';
usage: table_one(DF [, by => COL] [, vars => COLS] [, types => TYPES]
                 [, nonparametric => {0,1}] [, digits => N] [, pct_digits => N])

Build the descriptive "Table 1" of a clinical paper, one row per variable.

positional arguments:
  DF                     the data frame: an AoH, AoA, HoA or HoH

options:
  by => COL              the column whose groups are compared (default: none)
  vars => COLS           array ref of the columns to summarise (default: every
                         column but by)
  types => TYPES         hash ref of column => 'continuous' or 'categorical'
                         (default: continuous when every value is a number)
  nonparametric => {0,1}
                         Wilcoxon or Kruskal-Wallis in place of t-test or ANOVA
                         (default: 0)
  digits => N            decimal places of a mean and sd (default: 2)
  pct_digits => N        decimal places of a percentage (default: 1)

example:
  table_one([ { arm => 'A', age => 30 }, { arm => 'A', age => 40 },
              { arm => 'B', age => 50 }, { arm => 'B', age => 60 } ],
            by => 'arm')
      # returns [ { variable => 'age', A => '35.00 (7.07)',
      #             B => '55.00 (7.07)', Overall => '45.00 (12.91)',
      #             test => 't-test', ... } ]

END

$SCREEN{transpose} = <<'END';
usage: transpose(DATA)

Swap the rows and columns of an array of arrays or a hash of hashes.

positional arguments:
  DATA                   an AoA, whose rows must be one length, or a HoH

example:
  transpose([ [1, 2, 3], [4, 5, 6] ])     # returns [ [1, 4], [2, 5], [3, 6] ]

END

$SCREEN{uniq} = <<'END';
usage: uniq(VALUE, ...)

List the distinct values of its arguments, in first-seen order.

positional arguments:
  VALUE                  scalars or array refs, which are expanded one level

example:
  uniq(1, 2, 2, 3, 1)     # returns (1, 2, 3); in scalar context, 3

END

$SCREEN{vals} = <<'END';
usage: vals(DF, COL)

Pull one column of a data frame out as an array ref, like pandas' to_list.

positional arguments:
  DF                     the data frame: an AoH, HoA or HoH (a HoH in sorted key
                         order)
  COL                    the column name

example:
  vals([ { age => 30 }, { age => 41 } ], 'age')     # returns [30, 41]

END

$SCREEN{value_counts} = <<'END';
usage: value_counts(DATA [, KEY])

Count how many times each value occurs.

positional arguments:
  DATA                   a list of values, an array ref, or an AoH, AoA, HoA or
                         HoH
  KEY                    the column to count: a name, or a position for an AoA

example:
  value_counts('a', 'b', 'b')     # returns { a => 1, b => 2 }
  value_counts([ { d => 'x' }, { d => 'y' }, { d => 'x' } ], 'd')
      # returns { x => 2, y => 1 }

END

$SCREEN{view} = <<'END';
usage: view(DF [, n => N] [, cols => COLS] [, row_names => COL] [, na => STR]
            [, max_width => N] [, ellipsis => STR] [, gap => N] [, width => N]
            [, color => {auto,0,1}] [, colors => COLORS] [, to => FH]
            [, return_only => {0,1}])

Print the first rows of a data frame as an aligned table, like R's head.

positional arguments:
  DF                     the data frame: an AoH, AoA, HoA or HoH

options:
  n => N                 rows to show; also rows (default: 6)
  cols => COLS           array ref fixing which columns show, in order; also
                         columns
  row_names => COL       the column used as the row label
  na => STR              shown for an undef cell (default: 'undef')
  max_width => N         cut a cell wider than this (default: 80)
  ellipsis => STR        marks a cut cell (default: '...')
  gap => N               spaces between columns (default: 2)
  width => N             terminal width that wide tables are split at (default:
                         $ENV{COLUMNS}, else 80)
  color => MODE          auto colours only when printing to a terminal (default:
                         auto)
  colors => COLORS       hash ref of colour overrides
  to => FH               filehandle to print to (default: STDOUT)
  return_only => {0,1}   return the text and print nothing (default: 0)

example:
  my $text = view([ { a => 1, b => 'x' } ], return_only => 1)
      # returns the table as a string; view() always returns it

END

$SCREEN{write_table} = <<'END';
usage: write_table(DATA, FILE [, sep => SEP] [, col_names => NAMES]
                   [, row_names => ROWS] [, undef_val => STR] [, quiet => {0,1}]
                   [, tex => {0,1}] [, tex_* => ...] [, xlsx => {0,1}]
                   [, xlsx_* => ...])

Write a data frame to a delimited text, LaTeX or .xlsx file.

positional arguments:
  DATA                   the data frame: an AoH, AoA, HoA, HoH or flat hash;
                         also data => DATA
  FILE                   the file; .gz and .bz2 compress, .tex and .xlsx pick
                         the format; also file => FILE

options:
  sep => SEP             field separator; also delim (default: tab for .tsv,
                         else ',')
  col_names => NAMES     array ref of the columns to write, in order; for an
                         AoA, its header
  row_names => ROWS      1 writes a row-name column, 0 none, a name uses that
                         column (default: 1 for a HoH, else 0)
  undef_val => STR       written for an undef cell (default: '')
  quiet => {0,1}         do not print the "wrote FILE" line (default: 0)
  tex => {0,1}           write a LaTeX tabular (default: 1 for a .tex FILE)
  tex_col_align => A     c, l or r for every column (default: c)
  tex_size => CMD        a size command such as \small
  tex_comment => TEXT    a string or array ref of % comment lines
  tex_bold_1st_col => {0,1}
                         bold the first column (default: 1)
  tex_format => {0,1}    print numbers as %.4g (default: 0)
  tex_longtable => {0,1}
                         write a longtable body (default: 0)
  tex_longtable_head => H
                         longtable header rows, with H as the continued caption
  xlsx => {0,1}          write an Excel workbook (default: 1 for an .xlsx FILE)
  xlsx_sheet => NAME     the sheet name (default: 'Sheet1')
  xlsx_comment => TEXT   a string or array ref of lines for the provenance
                         comment
  xlsx_freeze_rows => N  leading rows to freeze (default: 0)
  xlsx_freeze_cols => N  leading columns to freeze (default: 0)

example:
  write_table([ { id => 1, age => 41 } ], 'cohort.tsv')
      # writes cohort.tsv, tab-separated, and returns nothing

END

# Screens, part 4.

$SCREEN{min} = <<'END';
usage: min(X [, X ...])

The smallest of the values, as R's min(); a NaN anywhere makes it NaN.

positional arguments:
  X                      a number, or an array ref of numbers; every argument is
                         pooled into one sample

example:
  min(1, [4, 2], 3)
      # returns 1

END

$SCREEN{max} = <<'END';
usage: max(X [, X ...])

The largest of the values, as R's max(); a NaN anywhere makes it NaN.

positional arguments:
  X                      a number, or an array ref of numbers; every argument is
                         pooled into one sample

example:
  max(1, [4, 2], 3)
      # returns 4

END

$SCREEN{mean} = <<'END';
usage: mean(X [, X ...])

The arithmetic mean of the values, as R's mean().

positional arguments:
  X                      a number, or an array ref of numbers; every argument is
                         pooled into one sample

example:
  mean([1, 2], [3, 4])
      # returns 2.5

END

$SCREEN{median} = <<'END';
usage: median(X [, X ...])

The median of the values, as R's median().

positional arguments:
  X                      a number, or an array ref of numbers; every argument is
                         pooled into one sample

example:
  median(3, 1, 2, 10)
      # returns 2.5

END

$SCREEN{sum} = <<'END';
usage: sum(X [, X ...])

The sum of the values, compensated as R's sum() is.

positional arguments:
  X                      a number, or an array ref of numbers; every argument is
                         pooled into one sample

example:
  sum(1, 2, 3, 4)
      # returns 10

END

$SCREEN{sd} = <<'END';
usage: sd(X [, X ...])

The sample standard deviation (n - 1 denominator), as R's sd().

positional arguments:
  X                      a number, or an array ref of numbers; every argument is
                         pooled into one sample; at least two values

example:
  sd(2, 4, 4, 4, 5, 5, 7, 9)
      # returns 2.1380899352994

END

$SCREEN{var} = <<'END';
usage: var(X [, X ...])

The sample variance (n - 1 denominator), as R's var().

positional arguments:
  X                      a number, or an array ref of numbers; every argument is
                         pooled into one sample; at least two values

example:
  var(2, 4, 4, 4, 5, 5, 7, 9)
      # returns 4.57142857142857

END

$SCREEN{mode} = <<'END';
usage: mode(X [, X ...])

The most common value or values, in the order each was first seen.

positional arguments:
  X                      a value (number or string), or an array ref of values;
                         every argument is pooled

example:
  mode('a', 'a', 'c', 'c', 'z')
      # returns ('a', 'c')

END

$SCREEN{skew} = <<'END';
usage: skew(X [, X ...] [, x => ARRAYREF] [, type => {1,2,3}])

Sample skewness of the values.

positional arguments:
  X                      a number, or an array ref of numbers; every argument is
                         pooled into one sample

options:
  x => ARRAYREF          the data by name, pooled with any X
  type => {1,2,3}        the estimator: 1 = the plain moment ratio, 2 = the
                         adjusted one SAS, SPSS and Excel use, 3 = e1071's
                         default (default: 2; type 2 needs at least 3 values)

example:
  skew(2, 4, 4, 4, 5, 5, 7, 9)
      # returns 0.8184875533568

END

$SCREEN{kurtosis} = <<'END';
usage: kurtosis(X [, X ...] [, x => ARRAYREF] [, type => {1,2,3}])

Sample excess kurtosis of the values (a normal sample gives about 0).

positional arguments:
  X                      a number, or an array ref of numbers; every argument is
                         pooled into one sample

options:
  x => ARRAYREF          the data by name, pooled with any X
  type => {1,2,3}        the estimator: 1 = the plain moment ratio, 2 = the
                         adjusted one SAS, SPSS and Excel use, 3 = e1071's
                         default (default: 2; type 2 needs at least 4 values)

example:
  kurtosis(2, 4, 4, 4, 5, 5, 7, 9)
      # returns 0.940625

END

$SCREEN{quantile} = <<'END';
usage: quantile(X [, probs => ARRAYREF])

Sample quantiles by R's type 7 interpolation, keyed '25%' and so on.

positional arguments:
  X                      the data, an array ref; undef values are dropped

options:
  x => ARRAYREF          the data by name, in place of X
  probs => ARRAYREF      probabilities in [0, 1], or one number (default: [0,
                         0.25, 0.5, 0.75, 1]); an undef or NaN prob gives
                         undef or NaN under the key ''

example:
  quantile([1 .. 9], probs => [0.25, 0.5])
      # returns { '25%' => 3, '50%' => 5 }

END

$SCREEN{rank} = <<'END';
usage: rank(X [, X ...] [, ties_method => METHOD] [, na_last => WHERE])

The ranks of the values in input order, as R's rank(); undef and NaN are NA.

positional arguments:
  X                      a number, or an array ref of numbers; every argument is
                         pooled into one sample

options:
  ties_method => METHOD  how tied values share ranks: average, first, last,
                         random, max or min (default: average)
  na_last => WHERE       where NAs go: true (ranked last), false (ranked first),
                         keep (left undef), or na or undef (dropped) (default:
                         true)

example:
  rank([3, 1, 4, 1, 5], ties_method => 'min')
      # returns (3, 1, 4, 1, 5)

END

$SCREEN{scale} = <<'END';
usage: scale(X [, X ...] [, center => C] [, scale => S])

Centre and scale the values, as R's scale(); an AoA is scaled by column.

positional arguments:
  X                      a number, or an array ref of numbers; every argument is
                         pooled into one sample, or one array of arrays, a
                         matrix of rows

options:
  center => C            mean, true or 1 subtracts the mean; none, false, 0 or
                         '' subtracts nothing; any other number is subtracted,
                         and an array ref gives one number per column
                         (default: mean)
  scale => S             sd, true or 1 divides by sqrt(sum(x^2)/(n-1)) of the
                         centred column, the sd when centred on the mean; none,
                         false, 0 or '' divides by nothing; any other number,
                         or an array ref of one per column, is divided by
                         (default: sd)
  { center => C, scale => S }
                         the same options as a trailing hash ref

example:
  scale(1, 2, 3)
      # returns (-1, 0, 1)

END

$SCREEN{seq} = <<'END';
usage: seq(FROM, TO [, BY])

A sequence from FROM to TO, as R's seq() (base::seq.default).

positional arguments:
  FROM                   the first value, a finite number
  TO                     the last value, a finite number, reached exactly or not
                         passed
  BY                     the step (default: none, which counts by 1 or -1 to TO,
                         as R's from:to)

example:
  seq(1, 2, 0.25)
      # returns (1, 1.25, 1.5, 1.75, 2)

END

$SCREEN{cov} = <<'END';
usage: cov(X, Y [, METHOD])

The covariance of two samples, as R's cov().

positional arguments:
  X                      the first sample, an array ref
  Y                      the second sample, an array ref of the same length
  METHOD                 pearson, spearman or kendall (default: pearson)

example:
  cov([1, 2, 3, 4], [2, 4, 6, 9])
      # returns 3.83333333333333

END

$SCREEN{cor} = <<'END';
usage: cor(X [, Y [, METHOD]])

The correlation of two samples, or the correlation matrix of one, as R's cor().

positional arguments:
  X                      a sample (an array ref), or a matrix (an array of
                         arrays of rows)
  Y                      a second sample, a matrix with as many rows as X, or
                         undef to leave it out (default: undef)
  METHOD                 pearson, spearman or kendall (default: pearson)

example:
  cor([1, 2, 3, 4], [2, 4, 6, 8], 'spearman')
      # returns 1

END

$SCREEN{hist} = <<'END';
usage: hist(X [, breaks => N])

Histogram counts over R's pretty() breakpoints, as R's hist().

positional arguments:
  X                      the data, an array ref of numbers; non-finite values
                         are dropped

options:
  breaks => N            the suggested number of bins, also accepted as a bare
                         second argument (default: Sturges' rule,
                         ceiling(log2(n) + 1))

example:
  hist([1, 2, 2, 3, 3, 3, 4, 4, 5], breaks => 4)
      # returns { breaks => [1, 2, 3, 4, 5], counts => [3, 3, 2, 1],
      #           mids => [...], density => [...] }

END

$SCREEN{density} = <<'END';
usage: density(X [, bw => BW] [, adjust => A] [, kernel => K] [, n => N]
               [, weights => ARRAYREF] [, from => F] [, to => T] [, cut => C]
               [, OPTION => VALUE ...])

Kernel density estimate of a sample, as R's density().

positional arguments:
  X                      the data, an array ref of numbers

options:
  x => ARRAYREF          the data by name, in place of X
  bw => BW               the bandwidth: a number, or a rule: nrd0, nrd, ucv,
                         bcv, SJ, SJ-ste or SJ-dpi (default: nrd0)
  adjust => A            a multiplier on the bandwidth (default: 1)
  kernel => K            the kernel: gaussian, epanechnikov, rectangular,
                         triangular, biweight, cosine or optcosine (default:
                         gaussian)
  n => N                 the number of points the estimate is given at (default:
                         512)
  weights => ARRAYREF    a non-negative weight for each value (default: equal
                         weights)
  from => F, to => T     the ends of the grid (default: cut bandwidths beyond
                         the smallest and largest value)
  cut => C               how many bandwidths the grid runs past the data
                         (default: 3)
  na_rm => BOOL          drop undef and NaN values rather than die (default: 0)
  width => W             the kernel's support, used when bw is not given
                         (default: none)
  window => K            the kernel, as R's window (default: none)
  ext => E, nb => NB     as R's density(): grid extension (default: 4) and bins
                         for the bandwidth rules (default: 1000)
  give_rkern => BOOL     return R(K), the kernel's roughness, and no estimate
                         (default: 0)
  subdensity => BOOL     allow weights that sum to less than 1 (default: 0)
  warn_wbw => BOOL       warn when weights are given with a bw rule (default:
                         true when the weights vary)
  old_coords => BOOL     R's coordinates before R 4.4.0 (default: 0)

example:
  density([1, 2, 3, 4, 5], n => 4)
      # returns { x => [-1.92075386855191, 1.3597487104827, ...],
      #           y => [...], bw => 0.973584622850636, ... }

END

$SCREEN{bw_nrd0} = <<'END';
usage: bw_nrd0(X)

Silverman's rule-of-thumb bandwidth, as R's bw.nrd0().

positional arguments:
  X                      the data, an array ref of at least two finite numbers

options:
  x => ARRAYREF          the data by name, in place of X

example:
  bw_nrd0([1, 2, 3, 4, 5])
      # returns 0.973584622850636

END

$SCREEN{bw_nrd} = <<'END';
usage: bw_nrd(X)

Scott's variant of the rule-of-thumb bandwidth, as R's bw.nrd().

positional arguments:
  X                      the data, an array ref of at least two finite numbers

options:
  x => ARRAYREF          the data by name, in place of X

example:
  bw_nrd([1, 2, 3, 4, 5])
      # returns 1.14666633357964

END

$SCREEN{bw_ucv} = <<'END';
usage: bw_ucv(X [, nb => NB] [, lower => L] [, upper => U] [, tol => TOL])

Bandwidth by unbiased cross-validation, as R's bw.ucv().

positional arguments:
  X                      the data, an array ref of at least two finite numbers

options:
  x => ARRAYREF          the data by name, in place of X
  nb => NB               the number of bins (default: 1000)
  lower => L             the low end of the search (default: 0.1 * hmax)
  upper => U             the high end of the search (default: hmax, from the
                         data)
  tol => TOL             the search's tolerance (default: 0.1 * lower)

example:
  bw_ucv([1, 2, 3, 4, 5, 10, 11, 12, 13, 14])
      # returns 2.29000986442776

END

$SCREEN{bw_bcv} = <<'END';
usage: bw_bcv(X [, nb => NB] [, lower => L] [, upper => U] [, tol => TOL])

Bandwidth by biased cross-validation, as R's bw.bcv().

positional arguments:
  X                      the data, an array ref of at least two finite numbers

options:
  x => ARRAYREF          the data by name, in place of X
  nb => NB               the number of bins (default: 1000)
  lower => L             the low end of the search (default: 0.1 * hmax)
  upper => U             the high end of the search (default: hmax, from the
                         data)
  tol => TOL             the search's tolerance (default: 0.1 * lower)

example:
  bw_bcv([2, 10, 10, (11) x 4, 12, 12, 13, (14) x 4, (15) x 5, (16) x 3,
          (17) x 4, 18, 19, 20, 27])
      # returns 2.29124659635325

END

$SCREEN{bw_sj} = <<'END';
usage: bw_sj(X [, method => {ste,dpi}] [, nb => NB] [, lower => L]
             [, upper => U] [, tol => TOL])

The Sheather & Jones bandwidth, as R's bw.SJ().

positional arguments:
  X                      the data, an array ref of at least two finite numbers

options:
  x => ARRAYREF          the data by name, in place of X
  method => {ste,dpi}    solve-the-equation or direct plug-in (default: ste)
  nb => NB               the number of bins (default: 1000)
  lower => L             the low end of the search (default: 0.1 * hmax, widened
                         until it brackets the answer)
  upper => U             the high end of the search (default: hmax, from the
                         data, widened the same way)
  tol => TOL             the search's tolerance (default: 0.1 * lower)

example:
  bw_sj([1, 2, 3, 4, 5, 10, 11, 12, 13, 14], method => 'dpi')
      # returns 2.30587442647329

END

$SCREEN{summary} = <<'END';
usage: summary(DATA [, nrows => N] [, return_only => BOOL]
               [, VIEW_OPTION => VALUE ...])

Count, quartiles, median and mean of each numeric variable, as R's summary().

positional arguments:
  DATA                   a list of numbers, or a ref to a vector, an AoA, AoH,
                         HoA or HoH

options:
  nrows => N             the most rows to show; also nrow, n or rows (default:
                         10)
  return_only => BOOL    return the table without printing it (default: 0)
  color => BOOL          colour the table (default: on when printing to a
                         terminal)
  VIEW_OPTION            na, colors, max_width, ellipsis, gap, width or to, as
                         view() takes them

example:
  summary([1, 2, 3, 4, 5], return_only => 1)
      # returns the table as a string: 5 values, Min. 1, Median 3, Max. 5

END

# Screens, part 5.

$SCREEN{dnorm} = <<'END';
usage: dnorm(X [, mean => MEAN] [, sd => SD] [, log => BOOL])

The normal density at X, as R's dnorm().

positional arguments:
  X                      a number, or an array reference of them, which gives
                         one back (an undef in it is NaN)

options:
  mean => MEAN           mean of the distribution (default: 0)
  sd => SD               standard deviation (default: 1)
  log => BOOL            return the log of the density (default: 0)

example:
  dnorm(0)
      # returns 0.398942280401433

END

$SCREEN{pnorm} = <<'END';
usage: pnorm(Q [, mean => MEAN] [, sd => SD] [, lower => BOOL] [, log => BOOL])

The normal distribution function at Q, as R's pnorm().

positional arguments:
  Q                      a number, or an array reference of them, which gives
                         one back (an undef in it is NaN)

options:
  mean => MEAN           mean of the distribution (default: 0)
  sd => SD               standard deviation (default: 1)
  lower => BOOL          1 for the lower tail, 0 for the upper (default: 1);
                         also spelled lower_tail
  log => BOOL            return the log of the probability (default: 0); also
                         spelled log_p

example:
  pnorm(1.96)
      # returns 0.97500210485178

END

$SCREEN{qnorm} = <<'END';
usage: qnorm(P [, MEAN [, SD]] [, lower => BOOL] [, log => BOOL])

The normal quantile function at P, as R's qnorm(): the inverse of pnorm().

positional arguments:
  P                      a probability, or an array reference of them, which
                         gives one back (an undef in it is NaN)
  MEAN                   mean of the distribution (default: 0); or mean => MEAN
  SD                     standard deviation (default: 1); or sd => SD

options:
  lower => BOOL          1 for the lower tail, 0 for the upper (default: 1);
                         also spelled lower_tail
  log => BOOL            P is given as a log (default: 0); also spelled log_p

example:
  qnorm(0.975)
      # returns 1.95996398454005

END

$SCREEN{pt} = <<'END';
usage: pt(Q, DF [, lower => BOOL] [, log => BOOL])

The Student t distribution function at Q, as R's pt().

positional arguments:
  Q                      a number, or an array reference of them, which gives
                         one back (an undef in it is NaN)
  DF                     degrees of freedom (required); or df => DF

options:
  lower => BOOL          1 for the lower tail, 0 for the upper (default: 1);
                         also spelled lower_tail
  log => BOOL            return the log of the probability (default: 0); also
                         spelled log_p

example:
  pt(2.5, 10)
      # returns 0.984276577881696

END

$SCREEN{qt} = <<'END';
usage: qt(P, DF [, lower => BOOL] [, log => BOOL])

The Student t quantile function at P, as R's qt().

positional arguments:
  P                      a probability, or an array reference of them, which
                         gives one back (an undef in it is NaN)
  DF                     degrees of freedom (required); or df => DF

options:
  lower => BOOL          1 for the lower tail, 0 for the upper (default: 1);
                         also spelled lower_tail
  log => BOOL            P is given as a log (default: 0); also spelled log_p

example:
  qt(0.975, 10)
      # returns 2.22813885198627

END

$SCREEN{pchisq} = <<'END';
usage: pchisq(Q, DF [, lower => BOOL] [, log => BOOL])

The chi-square distribution function at Q, as R's pchisq().

positional arguments:
  Q                      a number, or an array reference of them, which gives
                         one back (an undef in it is NaN)
  DF                     degrees of freedom (required); or df => DF

options:
  lower => BOOL          1 for the lower tail, 0 for the upper (default: 1);
                         also spelled lower_tail
  log => BOOL            return the log of the probability (default: 0); also
                         spelled log_p

example:
  pchisq(3.84, 1)
      # returns 0.949956478751295

END

$SCREEN{qchisq} = <<'END';
usage: qchisq(P, DF [, lower => BOOL] [, log => BOOL])

The chi-square quantile function at P, as R's qchisq().

positional arguments:
  P                      a probability, or an array reference of them, which
                         gives one back (an undef in it is NaN)
  DF                     degrees of freedom (required); or df => DF

options:
  lower => BOOL          1 for the lower tail, 0 for the upper (default: 1);
                         also spelled lower_tail
  log => BOOL            P is given as a log (default: 0); also spelled log_p

example:
  qchisq(0.95, 1)
      # returns 3.84145882069412

END

$SCREEN{pf} = <<'END';
usage: pf(Q, DF1, DF2 [, lower => BOOL] [, log => BOOL])

The F distribution function at Q, as R's pf().

positional arguments:
  Q                      a number, or an array reference of them, which gives
                         one back (an undef in it is NaN)
  DF1                    numerator degrees of freedom (required); or df1 => DF1
  DF2                    denominator degrees of freedom (required); or df2 =>
                         DF2

options:
  lower => BOOL          1 for the lower tail, 0 for the upper (default: 1);
                         also spelled lower_tail
  log => BOOL            return the log of the probability (default: 0); also
                         spelled log_p

example:
  pf(3, 2, 10)
      # returns 0.904632568359375

END

$SCREEN{qf} = <<'END';
usage: qf(P, DF1, DF2 [, lower => BOOL] [, log => BOOL])

The F quantile function at P, as R's qf().

positional arguments:
  P                      a probability, or an array reference of them, which
                         gives one back (an undef in it is NaN)
  DF1                    numerator degrees of freedom (required); or df1 => DF1
  DF2                    denominator degrees of freedom (required); or df2 =>
                         DF2

options:
  lower => BOOL          1 for the lower tail, 0 for the upper (default: 1);
                         also spelled lower_tail
  log => BOOL            P is given as a log (default: 0); also spelled log_p

example:
  qf(0.95, 2, 10)
      # returns 4.1028210151304

END

$SCREEN{pbinom} = <<'END';
usage: pbinom(Q, SIZE, PROB [, lower => BOOL] [, log => BOOL])

The binomial distribution function at Q, as R's pbinom().

positional arguments:
  Q                      a number, or an array reference of them, which gives
                         one back (an undef in it is NaN)
  SIZE                   number of trials (required); or size => SIZE
  PROB                   probability of success on each trial (required); or
                         prob => PROB

options:
  lower => BOOL          1 for the lower tail, 0 for the upper (default: 1);
                         also spelled lower_tail
  log => BOOL            return the log of the probability (default: 0); also
                         spelled log_p

example:
  pbinom(3, 10, 0.25)
      # returns 0.775875091552734

END

$SCREEN{ptukey} = <<'END';
usage: ptukey(Q, NMEANS, DF [, nranges => N] [, lower_tail => BOOL]
              [, log_p => BOOL])

The studentized range distribution function at Q, as R's ptukey().

positional arguments:
  Q                      the studentized range, a number
  NMEANS                 number of groups
  DF                     degrees of freedom

options:
  nranges => N           number of groups whose range is taken (default: 1)
  lower_tail => BOOL     1 for the lower tail, 0 for the upper (default: 1)
  log_p => BOOL          return the log of the probability (default: 0)

example:
  ptukey(3.5, 3, 12)
      # returns 0.930004514724551

END

$SCREEN{qtukey} = <<'END';
usage: qtukey(P, NMEANS, DF [, nranges => N] [, lower_tail => BOOL]
              [, log_p => BOOL])

The studentized range quantile function at P, as R's qtukey().

positional arguments:
  P                      a probability, a number
  NMEANS                 number of groups
  DF                     degrees of freedom

options:
  nranges => N           number of groups whose range is taken (default: 1)
  lower_tail => BOOL     1 for the lower tail, 0 for the upper (default: 1)
  log_p => BOOL          P is given as a log (default: 0)

example:
  qtukey(0.95, 3, 12)
      # returns 3.77292895940834

END

$SCREEN{rbinom} = <<'END';
usage: rbinom(n => N, size => SIZE, prob => PROB)

Draw N binomial variates, as R's rbinom(); all three are required.

options:
  n => N                 number of draws
  size => SIZE           number of trials in each draw
  prob => PROB           probability of success, in [0, 1]

example:
  rbinom(n => 3, size => 10, prob => 0.5)
      # returns an array reference of 3 whole numbers in 0 .. 10

END

$SCREEN{rnorm} = <<'END';
usage: rnorm(N [, MEAN [, SD]])

Draw N normal variates, as R's rnorm(); each may also be given by name.

positional arguments:
  N                      number of draws (required); or n => N
  MEAN                   mean (default: 0); or mean => MEAN
  SD                     standard deviation, >= 0 (default: 1); or sd => SD

example:
  rnorm(3, 10, 2)
      # returns an array reference of 3 numbers drawn from N(10, 2^2)

END

$SCREEN{runif} = <<'END';
usage: runif(N [, MIN [, MAX]])

Draw N uniform variates, as R's runif(); each may also be given by name.

positional arguments:
  N                      number of draws (required); or n => N
  MIN                    lower bound (default: 0); or min => MIN
  MAX                    upper bound (default: 1); or max => MAX

example:
  runif(3, 0, 10)
      # returns an array reference of 3 numbers in [0, 10)

END

$SCREEN{sample} = <<'END';
usage: sample(DATA [, N])

Draw N elements of an array, or N keys of a hash, without replacement.

positional arguments:
  DATA                   an array reference, or a hash reference
  N                      how many to draw, at most the number there are
                         (default: 1)

example:
  sample([10, 20, 30], 2)
      # returns an array reference of 2 of the values, such as [30, 10]
  sample({ a => 1, b => 2, c => 3 }, 2)
      # returns a hash reference of 2 of the pairs, such as { c => 3, a => 1 }

END

$SCREEN{power_t_test} = <<'END';
usage: power_t_test([n => N] [, delta => DELTA] [, sd => SD]
                    [, sig_level => ALPHA] [, power => POWER]
                    [, type => {two.sample,one.sample,paired}]
                    [, alternative => {two.sided,one.sided,greater,less}]
                    [, strict => BOOL] [, tol => TOL])

As R's power.t.test(): whichever one of the first five is undef is solved for.

options:
  n => N                 observations per group, at least 2
  delta => DELTA         true difference in means
  sd => SD               standard deviation (default: 1)
  sig_level => ALPHA     significance level, in [0, 1] (default: 0.05)
  power => POWER         power of the test, in [0, 1]; left out, it is solved
                         for
  type => TYPE           two.sample, one.sample or paired (default: two.sample)
  alternative => ALT     two.sided, one.sided, greater or less (default:
                         two.sided)
  strict => BOOL         count both tails in a two-sided power (default: 0)
  tol => TOL             relative tolerance on a solved-for root (default:
                         1e-12)

example:
  power_t_test(n => 20, delta => 1)
      # returns { power => 0.868952801692123, n => 20, delta => 1, ... }

END

$SCREEN{p_adjust} = <<'END';
usage: p_adjust(P [, METHOD] [, columns => COLS])

Adjust p-values for multiple testing, as R's p.adjust().

positional arguments:
  P                      an array reference of p-values, or an AoA, AoH, HoA or
                         HoH data frame
  METHOD                 holm, hochberg, hommel, bonferroni, BH, BY, fdr or
                         none, in any case (default: holm); or method => METHOD

options:
  columns => COLS        the column, or an array reference of the columns,
                         holding p-values in a frame (default: all of them);
                         also spelled column, cols or col

example:
  p_adjust([0.01, 0.04, 0.03, 0.2], 'BH')
      # returns (0.04, 0.0533333333333333, 0.0533333333333333, 0.2)

END

# Screens, part 6.

$SCREEN{binom_test} = <<'END';
usage: binom_test(X, N [, p => P] [, alternative => {two.sided,less,greater}]
                  [, conf_level => LEVEL])

Exact binomial test of X successes in N trials against a success rate P.

positional arguments:
  X                      the number of successes, or [SUCCESSES, FAILURES]
  N                      the number of trials; left out when X is an array ref

options:
  p => P                 the success rate under the null (default: 0.5)
  alternative => ALT     two.sided, less or greater (default: two.sided)
  conf_level => LEVEL    confidence level of conf_int (default: 0.95)

example:
  binom_test(6, 10, p => 0.5)
      # returns { p_value => 0.7539, estimate => 0.6, conf_int => [...], ... }

END

$SCREEN{chisq_test} = <<'END';
usage: chisq_test(DATA [, correct => BOOL] [, p => PROBS]
                  [, rescale_p => BOOL])

Pearson's chi-squared test: goodness of fit for a 1D table, independence for 2D.

positional arguments:
  DATA                   counts: an array ref or hash ref (goodness of fit),
                         or an AoA or HoH (a contingency table)

options:
  correct => BOOL        Yates' continuity correction, 2x2 tables only
                         (default: 1)
  p => PROBS             null probabilities for goodness of fit, an array ref
                         in DATA's order or a hash ref keyed as DATA
                         (default: uniform)
  rescale_p => BOOL      divide p by its sum first (default: 0)

example:
  chisq_test([89, 37, 30, 28, 2], p => [0.40, 0.20, 0.20, 0.19, 0.01])
      # returns { statistic => { 'X-squared' => 5.7947 },
      #           parameter => { df => 4 }, p_value => 0.2150, ... }

END

$SCREEN{cmh_test} = <<'END';
usage: cmh_test(STRATA [, correct => BOOL] [, conf_level => LEVEL])

Cochran-Mantel-Haenszel test of association across stratified 2x2 tables.

positional arguments:
  STRATA                 an array ref of 2x2 tables, each [a, b, c, d] as in
                         epi_2x2

options:
  correct => BOOL        continuity correction (default: 1)
  conf_level => LEVEL    confidence level of the common odds ratio's conf_int
                         (default: 0.95)

example:
  cmh_test([ [10, 3, 5, 12], [8, 4, 6, 9] ])
      # returns { statistic => 6.2823, p_value => 0.0122, estimate => 4.8,
      #           conf_int => [...], k => 2, ... }

END

$SCREEN{cor_test} = <<'END';
usage: cor_test(X, Y [, method => {pearson,kendall,spearman}]
                [, alternative => {two.sided,less,greater}] [, exact => BOOL]
                [, conf_level => LEVEL] [, continuity => BOOL])

Test for correlation between paired samples, over their complete pairs.

positional arguments:
  X, Y                   two array refs of the same length; may also be given
                         as x => X, y => Y

options:
  method => METHOD       pearson, kendall or spearman (default: pearson)
  alternative => ALT     two.sided, less or greater (default: two.sided)
  exact => BOOL          exact p-value for kendall and spearman (default: as
                         R decides, from n and ties)
  conf_level => LEVEL    confidence level of pearson's conf_int
                         (default: 0.95)
  continuity => BOOL     continuity correction for kendall and spearman's
                         normal approximation (default: 0)

example:
  cor_test([1, 2, 3, 4, 5], [2, 1, 4, 3, 6])
      # returns { estimate => 0.8220, statistic => 2.5, parameter => 3,
      #           p_value => 0.0877, conf_int => [...], ... }

END

$SCREEN{fisher_test} = <<'END';
usage: fisher_test(TABLE [, alternative => {two.sided,less,greater}]
                   [, conf_level => LEVEL])

Fisher's exact test of independence in an R x C table of counts.

positional arguments:
  TABLE                  counts, at least 2x2: an AoA, or a HoH of rows

options:
  alternative => ALT     two.sided, less or greater; 2x2 tables only
                         (default: two.sided)
  conf_level => LEVEL    confidence level of the odds ratio's conf_int, 2x2
                         tables only (default: 0.95)

example:
  fisher_test([ [10, 2], [3, 15] ])
      # returns { p_value => 0.000537, estimate => { 'odds ratio' => 21.3053 },
      #           conf_int => [2.7534, 300.6828], ... }

END

$SCREEN{kruskal_test} = <<'END';
usage: kruskal_test(X, G | GROUPS)

Kruskal-Wallis rank-sum test that every group has the same distribution.

positional arguments:
  X                      an array ref of observations; also x => X
  G                      an array ref of group labels, as long as X; also
                         g => G
  GROUPS                 instead of X and G, a hash ref of array refs, one
                         per group; also h => GROUPS

example:
  kruskal_test({ normal     => [2.9, 3.0, 2.5, 2.6, 3.2],
                 airway     => [3.8, 2.7, 4.0, 2.4],
                 asbestosis => [2.8, 3.4, 3.7, 2.2, 2.0] })
      # returns { statistic => 0.7714, parameter => 2, p_value => 0.6800,
      #           group_stats => { size => {...}, mean => {...} }, ... }

END

$SCREEN{ks_test} = <<'END';
usage: ks_test(X, Y | CDF [, alternative => {two.sided,less,greater}]
               [, exact => BOOL])

Kolmogorov-Smirnov test: two samples, or one sample against a reference CDF.

positional arguments:
  X                      an array ref of observations; also x => X
  Y                      a second array ref, for the two-sample test; also
                         y => Y
  CDF                    instead of Y, the name of a reference CDF for the
                         one-sample test; only 'pnorm' (standard normal)

options:
  alternative => ALT     two.sided, less or greater (default: two.sided)
  exact => BOOL          exact p-value, 1, or asymptotic, 0 (default: exact
                         when nx*ny < 10000, or n < 100 for one sample)

example:
  ks_test([0.61, 0.29, 0.06, 0.59, -1.73], [-0.4, 1.9, 2.3, 1.1, 3.0])
      # returns { statistic => 0.8, p_value => 0.0794, method => ...,
      #           alternative => 'two.sided' }

END

$SCREEN{oneway_test} = <<'END';
usage: oneway_test(DATA [, var_equal => BOOL] [, formula => FORMULA])

One-way test for equal group means; Welch's, unequal variances, by default.

positional arguments:
  DATA                   the groups: a hash of arrays, one key per group, or
                         an array of arrays; with formula, a hash of columns

options:
  var_equal => BOOL      assume equal variances, the classic F test
                         (default: 0, Welch's test)
  formula => FORMULA     'response ~ factor', splitting DATA's response
                         column by its factor column; hash DATA only

example:
  oneway_test({ a => [5.5, 5.4, 5.8], b => [4.5, 4.8, 4.2],
                c => [6.1, 6.6, 5.9] })
      # returns { Group => { 'F value' => 18.5772, 'Pr(>F)' => 0.0110, ... },
      #           Residuals => { Df => 3.7886, ... }, group_stats => {...} }

END

$SCREEN{prop_test} = <<'END';
usage: prop_test(X, N [, p => P] [, alternative => {two.sided,less,greater}]
                 [, conf_level => LEVEL] [, correct => BOOL])

Test of one proportion against P, or of two or more proportions for equality.

positional arguments:
  X                      successes: a number, or an array ref with one per
                         group
  N                      trials: a number, or an array ref as long as X

options:
  p => P                 null probability, one number or one per group
                         (default: 0.5 for one group, else the pooled rate)
  alternative => ALT     two.sided, less or greater (default: two.sided)
  conf_level => LEVEL    confidence level of conf_int (default: 0.95)
  correct => BOOL        Yates' continuity correction, one or two groups only
                         (default: 1)

example:
  prop_test([83, 90], [100, 100])
      # returns { statistic => 1.5414, parameter => 1, p_value => 0.2144,
      #           estimate => [0.83, 0.9], conf_int => [...], ... }

END

$SCREEN{mcnemar_test} = <<'END';
usage: mcnemar_test(TABLE | X, Y [, correct => BOOL] [, exact => BOOL])

McNemar's test of symmetry for paired categorical data.

positional arguments:
  TABLE                  a square k x k matrix of counts, as an AoA
  X, Y                   two array refs of paired observations, the same
                         length, cross-tabulated over their levels

options:
  correct => BOOL        Yates' continuity correction, 2x2 only (default: 1)
  exact => BOOL          exact binomial test instead, 2x2 only (default: 0)

example:
  mcnemar_test([ [794, 86], [150, 570] ])
      # returns { statistic => 16.8178, parameter => 1, p_value => 4.1e-05,
      #           method => ... }

END

$SCREEN{friedman_test} = <<'END';
usage: friedman_test(MATRIX)

Friedman rank-sum test for an unreplicated complete block design.

positional arguments:
  MATRIX                 an array ref of rows, one block (subject) per row and
                         one treatment (condition) per column

example:
  friedman_test([ [7, 9, 8], [6, 6, 7], [9, 10, 9], [8, 8, 6] ])
      # returns { statistic => 2, parameter => 2, p_value => 0.3679,
      #           n => 4, ... }

END

$SCREEN{dunn_test} = <<'END';
usage: dunn_test(VALUES, GROUPS
                 [, method => {none,bonferroni,sidak,holm,hs,bh,by}])

Dunn's post-hoc test: every pairwise comparison after a Kruskal-Wallis test.

positional arguments:
  VALUES                 an array ref of numeric observations
  GROUPS                 an array ref of group labels, as long as VALUES

options:
  method => METHOD       p-value adjustment: none, bonferroni, sidak, holm,
                         hs (Holm-Sidak), bh (also fdr) or by (default: holm)

example:
  dunn_test([2.1, 3.4, 1.9, 6.1, 7.3, 5.9], ['A', 'A', 'A', 'B', 'B', 'B'])
      # returns [ { comparison => 'A - B', Z => -1.9640, p_value => 0.0495,
      #             p_adjust => 0.0495, ... } ], one hash per pair

END

$SCREEN{shapiro_test} = <<'END';
usage: shapiro_test(X)

Shapiro-Wilk test of whether a sample is normally distributed.

positional arguments:
  X                      an array ref of 3 to 5000 numbers, once undef and
                         NaN are dropped

example:
  shapiro_test([1, 2, 3, 4, 5])
      # returns { W => 0.9868, statistic => 0.9868, p_value => 0.9672 }

END

$SCREEN{t_test} = <<'END';
usage: t_test(X [, Y] [, mu => MU] [, paired => BOOL] [, var_equal => BOOL]
              [, alternative => {two.sided,less,greater}]
              [, conf_level => LEVEL])

Student's or Welch's t-test: one sample, two samples, or paired.

positional arguments:
  X                      an array ref of the first sample; also x => X
  Y                      an array ref of the second sample, for a two-sample
                         or paired test; also y => Y

options:
  mu => MU               the mean, or difference of means, under the null
                         (default: 0)
  paired => BOOL         paired test; X and Y the same length (default: 0)
  var_equal => BOOL      pooled variance instead of Welch's (default: 0)
  alternative => ALT     two.sided, less or greater (default: two.sided)
  conf_level => LEVEL    confidence level of conf_int, 0 to 1
                         (default: 0.95)

example:
  t_test([5.1, 4.9, 5.6, 5.8, 6.0], mu => 5)
      # returns { statistic => 2.3041, df => 4, p_value => 0.0826,
      #           estimate => 5.48, conf_int => [4.9016, 6.0584], ... }

END

$SCREEN{var_test} = <<'END';
usage: var_test(X, Y [, ratio => RATIO]
                [, alternative => {two.sided,less,greater}]
                [, conf_level => LEVEL])

F test that two samples from normal populations have the same variance.

positional arguments:
  X                      an array ref of the first sample; also x => X
  Y                      an array ref of the second sample; also y => Y

options:
  ratio => RATIO         the ratio of the variances under the null, positive
                         and finite (default: 1)
  alternative => ALT     two.sided, less or greater (default: two.sided)
  conf_level => LEVEL    confidence level of conf_int, strictly between 0 and
                         1 (default: 0.95)

example:
  var_test([2.9, 3.0, 2.5, 2.6, 3.2], [3.8, 2.7, 4.0, 2.4])
      # returns { statistic => 0.1319, parameter => [4, 3], p_value => 0.0796,
      #           estimate => 0.1319, conf_int => [...], ... }

END

$SCREEN{wilcox_test} = <<'END';
usage: wilcox_test(X [, Y] [, paired => BOOL] [, mu => MU]
                   [, alternative => {two.sided,less,greater}]
                   [, exact => BOOL] [, correct => BOOL]
                   [, edgeworth => {0,1,2,3}] [, conf_int => BOOL]
                   [, conf_level => LEVEL] [, digits_rank => DIGITS]
                   [, tol_root => TOL])

Wilcoxon rank-sum (Mann-Whitney) or signed-rank test.

positional arguments:
  X                      an array ref of the first sample; also x => X
  Y                      an array ref of the second sample; also y => Y.
                         Left out, or undef, for the one-sample test

options:
  paired => BOOL         signed-rank test on X - Y; Y the same length
                         (default: 0)
  mu => MU               location shift under the null, finite (default: 0)
  alternative => ALT     two.sided, less or greater (default: two.sided)
  exact => BOOL          exact p-value, 1, or the normal approximation, 0
                         (default: undef, exact when the samples are < 50)
  correct => BOOL        continuity correction on the normal approximation
                         (default: 1)
  edgeworth => TERMS     Edgeworth terms refining the normal approximation
                         (default: 0)
  conf_int => BOOL       also the Hodges-Lehmann estimate and conf_int
                         (default: 0)
  conf_level => LEVEL    requested level of conf_int, between 0 and 1
                         (default: 0.95)
  digits_rank => DIGITS
                         significant digits to round to before ranking
                         (default: undef, no rounding)
  tol_root => TOL        tolerance of the asymptotic interval's root search,
                         positive (default: 1e-4)

example:
  wilcox_test([1.83, 0.50, 1.62, 2.48, 1.68], [0.88, 0.65, 0.60, 2.05, 1.06],
              paired => 1)
      # returns { statistic => 14, statistic_name => 'V', p_value => 0.125,
      #           method => ..., alternative => 'two.sided', ... }

END

$SCREEN{TukeyHSD} = <<'END';
usage: TukeyHSD(FIT, data => DATA [, response => NAME | formula => FORMULA]
                [, which => FACTORS] [, conf_level => LEVEL]
                [, ordered => BOOL])

Tukey's honest significant differences between the levels of each factor.

positional arguments:
  FIT                    a fit from aov, lm or glm

options:
  data => DATA           the data frame the model was fitted to (required);
                         a hash of groups for aov's no-formula form
  response => NAME       the response column (or give formula)
  formula => FORMULA     'response ~ ...', read for its response
  which => FACTORS       a factor name or an array ref of them (default: every
                         factor in FIT); names the result in the wide form
  conf_level => LEVEL    family-wise confidence level, between 0 and 1
                         (default: 0.95)
  ordered => BOOL        order each factor's levels by increasing mean
                         (default: 0)

example:
  my %pw = (ctrl => [4.17, 5.58, 5.18], trt => [4.81, 4.17, 4.41]);
  TukeyHSD(aov(\%pw), data => \%pw)
      # returns { group => [ { comparison => 'trt-ctrl', diff => -0.5133,
      #           lwr => -1.7883, upr => 0.7616, 'p adj' => 0.3262 } ],
      #           conf_level => 0.95, ordered => 0 }

END

$SCREEN{anova} = <<'END';
usage: anova(DATA, FORMULA [, FORMULA ...] | FIT, FIT [, FIT ...]
             [, test => {F,Chisq,LRT}] [, dispersion => DISPERSION])

Sequential (Type-I) ANOVA table of a linear model, or a comparison of models.

positional arguments:
  DATA                   the data frame: a hash of columns, or an AoH
  FORMULA                'response ~ terms'; two or more compare the nested
                         models in turn
  FIT                    instead of DATA and FORMULA, two or more lm or glm
                         fits to compare

options:
  test => TEST           F, Chisq or LRT; with FITs only (default: F for lm
                         and gaussian glm, else Chisq)
  dispersion => DISPERSION
                         the dispersion the test scales by; with FITs only
                         (default: the largest model's)

example:
  anova({ yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
          ctrl  => [1, 1, 1, 0, 0, 0] }, 'yield ~ ctrl')
      # returns { ctrl => { Df => 1, 'F value' => 25.6, 'Pr(>F)' => 0.0072,
      #           ... }, Residuals => { Df => 4, ... } }

END

$SCREEN{aov} = <<'END';
usage: aov(DATA [, FORMULA])

Analysis of variance: the sequential (Type-I) table of a linear model.

positional arguments:
  DATA                   the data frame: a hash of columns, or an AoH; with
                         no FORMULA, a hash of groups, each an array ref
  FORMULA                'response ~ terms' (default: none, the groups are
                         stacked and fitted as Value ~ Group)

example:
  aov({ ctrl => [4.17, 5.58, 5.18], trt => [4.81, 4.17, 4.41] })
      # returns { Group => { 'F value' => 1.2497, 'Pr(>F)' => 0.3262, ... },
      #           Residuals => {...}, coefficients => {...}, ... }

END

# Screens, part 7.

$SCREEN{lm} = <<'END';
usage: lm(formula => FORMULA, data => DF)

Fit a linear model by least squares, as R's lm().

options:
  formula => FORMULA     'y ~ x1 + x2'; takes +, :, *, ^, ., - and -1 as R's
                         formulas do (required)
  data => DF             the data: a HoA, AoH or HoH; rows are named from a
                         row_names column if there is one (required)

example:
  lm(formula => 'y ~ x', data => { x => [1, 2, 3, 4], y => [3, 5, 7, 10] })
      # returns { coefficients => { Intercept => 0.5, x => 2.3 }, summary,
      #           r_squared, f_pvalue, fitted_values, residuals, ... }

END

$SCREEN{glm} = <<'END';
usage: glm(formula => FORMULA, data => DF [, family => FAMILY]
           [, theta => THETA] [, conf_level => LEVEL] [, offset => OFFSET]
           [, weights => W] [, vcov => TYPE] [, cluster => CLUSTER]
           [, absorb => FACTORS] [, maxit => N] [, epsilon => TOL])

Fit a generalized linear model by IRLS, as R's glm() and MASS::glm.nb().

options:
  formula => FORMULA     as lm()'s, plus offset() terms and factors to absorb
                         after a '|' (required)
  data => DF             the data: a HoA, AoH or HoH (required)
  family => FAMILY       {gaussian,binomial,poisson,negbin} (default: gaussian)
  theta => THETA         negbin dispersion, held fixed (default: estimated)
  conf_level => LEVEL    level of the confidence intervals (default: 0.95)
  offset => OFFSET       a column, an expression such as 'log(t)', or an array
                         ref of one value per row (default: none)
  weights => W           prior weights: a column or an array ref (default: none)
  vcov => TYPE           {model,HC0,HC1,HC2,HC3}; also accepted as vcov_type
                         (default: model, or HC0 with a cluster)
  cluster => CLUSTER     a column, 'a + b' for multiway clustering, or an array
                         ref of labels (default: none)
  absorb => FACTORS      a column name or an array ref of them, absorbed as
                         fixed effects (default: none)
  maxit => N             IRLS iteration limit, 1 to 1e6 (default: 25)
  epsilon => TOL         IRLS convergence tolerance, between 0 and 1 (default:
                         1e-8)

example:
  glm(formula => 'y ~ x', family => 'poisson',
      data => { x => [1, 2, 3, 4, 5], y => [1, 3, 2, 6, 8] })
      # returns { coefficients => { Intercept => -0.2087, x => 0.4632 },
      #           summary, exp, conf_int, deviance, aic, converged, ... }

END

$SCREEN{predict} = <<'END';
usage: predict(MODEL [, NEWDATA] [, type => TYPE])

Predict from a fitted lm() or glm() model, as R's predict().

positional arguments:
  MODEL                  a model returned by lm() or glm()
  NEWDATA                a HoA, AoH, HoH or flat hash of new rows; leave it out,
                         or give undef, for the model's own fitted_values

options:
  type => TYPE           {response,link}: the response scale, with the inverse
                         link applied, or the linear predictor (default:
                         response)

example:
  my $fit = lm(formula => 'y ~ x',
               data => { x => [1, 2, 3, 4], y => [3, 5, 7, 10] });
  predict($fit, { x => [5, 6] })
      # returns { 1 => 12, 2 => 14.3 }

END

$SCREEN{prcomp} = <<'END';
usage: prcomp(X [, center => BOOL] [, scale => BOOL] [, retx => BOOL]
              [, tol => TOL] [, rank => N])

Principal component analysis, as R's prcomp().

positional arguments:
  X                      the data: an AoA, AoH, HoA or HoH; x => X also works

options:
  center => BOOL         shift each column to mean zero first (default: 1)
  scale => BOOL          scale each column to unit variance first (default: 0)
  retx => BOOL           return the rotated data as x (default: 1)
  tol => TOL             leave out of rotation and x the components whose sdev
                         is at most tol times the first's (default: undef, keep
                         all); sdev always has all of them, as in R
  rank => N              return at most N components in rotation and x
                         (default: undef, all)

example:
  prcomp([ [2, 4], [4, 2], [6, 6] ])
      # returns { sdev => [2.4495, 1.4142], rotation, x, center, scale }

END

$SCREEN{vif} = <<'END';
usage: vif(DF, FORMULA)

Variance inflation factors of a model's terms, as car::vif().

positional arguments:
  DF                     the data: a HoA, AoH or HoH
  FORMULA                a formula read as lm() reads it, such as 'y ~ a + b +
                         c', or an array ref of column names, which is '~ a + b
                         + c'

example:
  vif({ a => [1, 2, 3, 4, 5, 6], b => [2, 1, 4, 3, 6, 5],
        c => [1, 3, 2, 5, 4, 7] }, [qw(a b c)])
      # returns { a => 134.9, b => 36.9, c => 56.0 }, or a { GVIF, Df,
      # 'GVIF^(1/(2*Df))' } hash per term when a term has more than one column

END

$SCREEN{hosmer_lemeshow} = <<'END';
usage: hosmer_lemeshow(OBSERVED, PREDICTED [, g => G])

Hosmer-Lemeshow goodness-of-fit test of a logistic model, as hoslem.test().

positional arguments:
  OBSERVED               array ref of the observed 0/1 outcomes
  PREDICTED              array ref of the model's predicted probabilities, one
                         per outcome

options:
  g => G                 number of risk groups, an integer of at least 3
                         (default: 10)

example:
  hosmer_lemeshow(\@obs, \@prob, g => 10)
      # returns { statistic, parameter, p_value, groups, table }

END

$SCREEN{survfit} = <<'END';
usage: survfit(TIME, STATUS [, group => GROUP] [, conf_level => LEVEL])

Kaplan-Meier survival curves, as survival::survfit().

positional arguments:
  TIME                   array ref of survival or censoring times
  STATUS                 array ref of event flags: 1 = event, 0 = censored; or
                         2 = event, 1 = censored, when the largest is 2

options:
  group => GROUP         array ref of group labels, for one curve per group
                         (default: one curve)
  conf_level => LEVEL    level of the confidence intervals (default: 0.95)

example:
  survfit([1, 2, 3, 4, 5], [1, 0, 1, 1, 0])
      # returns { strata => { '' => { time, n_risk, n_event, surv => [0.8, 0.8,
      #           0.5333, 0.2667, 0.2667], lower, upper, median => 4, ... } } }

END

$SCREEN{logrank_test} = <<'END';
usage: logrank_test(TIME, STATUS, GROUP [, rho => RHO])

Log-rank (Mantel-Cox) test that survival curves differ, as survival::survdiff().

positional arguments:
  TIME                   array ref of survival or censoring times
  STATUS                 array ref of event flags: 1 = event, 0 = censored; or
                         2 = event, 1 = censored, when the largest is 2
  GROUP                  array ref of group labels, two or more groups

options:
  rho => RHO             weight each event time by S(t-)^RHO, the pooled
                         Kaplan-Meier curve; 1 is Peto & Peto's test (default:
                         0, the log-rank test)

example:
  logrank_test([1, 2, 3, 4, 5, 6], [1, 1, 0, 1, 1, 1], [qw(a a a b b b)])
      # returns { statistic => 2.4694, parameter => 1, p_value => 0.1161,
      #           observed => [2, 3], expected => [0.9, 4.1],
      #           groups => ['a', 'b'], rho => 0, method }

END

$SCREEN{coxph} = <<'END';
usage: coxph(TIME, STATUS, COVARIATES [, OPTION => VALUE ...])

Cox proportional-hazards regression, as survival::coxph().

positional arguments:
  TIME                   array ref of stop times; or leave out all three and
                         give formula => and data =>
  STATUS                 array ref of event flags: 1 = event, 0 = censored; or
                         2 = event, 1 = censored, when the largest is 2
  COVARIATES             an array ref of one covariate, or [\@x1, \@x2, ...]

options:
  formula => FORMULA     'Surv(time, status) ~ x' or 'Surv(start, stop, status)
                         ~ x', with strata() and cluster() terms, in place of
                         the three arrays
  data => DF             the data the formula names: a HoA, AoH or HoH
  names => NAMES         array ref of covariate names (default: x1, x2, ...)
  ties => TIES           {efron,breslow} (default: efron)
  conf_level => LEVEL    level of the confidence intervals (default: 0.95)
  maxit => N             Newton iteration limit, 0 to 1e6; also iter_max
                         (default: 20)
  eps => TOL             convergence tolerance, between 0 and 1 (default: 1e-9)
  start => START         array ref of interval start times, for (start, stop]
                         data (default: none)
  strata => STRATA       array ref of stratum labels (default: none)
  cluster => CLUSTER     array ref of cluster labels, or with a formula a column
                         name (default: none)
  weights => W           case weights (default: none)
  offset => OFFSET       one offset per row (default: none)
  robust => BOOL         report the robust variance (default: 0, or 1 with a
                         cluster)

example:
  coxph(\@time, \@status, [\@age, \@sex], names => ['age', 'sex'])
      # returns { coef, exp_coef, se, z, p_value, conf_int, names, loglik,
      #           lr_stat, lr_p_value, n, nevent, converged, ... }

END

$SCREEN{zerotrunc} = <<'END';
usage: zerotrunc(formula => FORMULA, data => DF [, dist => DIST]
                 [, theta => THETA] [, offset => OFFSET] [, weights => W]
                 [, conf_level => LEVEL])

Zero-truncated count regression, as countreg::zerotrunc().

options:
  formula => FORMULA     as glm()'s, with offset() terms allowed; the response
                         is a count of at least 1 (required)
  data => DF             the data: a HoA, AoH or HoH (required)
  dist => DIST           {poisson,negbin,geometric} (default: poisson)
  theta => THETA         a fixed negbin dispersion, greater than 0 (default:
                         estimated)
  offset => OFFSET       a column, an expression or an array ref (default: none)
  weights => W           case weights (default: none)
  conf_level => LEVEL    level of the confidence intervals (default: 0.95)

example:
  zerotrunc(formula => 'days ~ hours + age', data => \%admitted,
            dist => 'negbin')
      # returns { coefficients, summary, vcov, theta, SE_logtheta, loglik, aic,
      #           nobs, converged, fitted_values, residuals, ... }

END

$SCREEN{hurdle} = <<'END';
usage: hurdle(formula => FORMULA, data => DF [, dist => DIST]
              [, zero_dist => DIST] [, link => LINK] [, offset => OFFSET]
              [, weights => W] [, conf_level => LEVEL])

Hurdle model for counts with excess zeros, as pscl::hurdle().

options:
  formula => FORMULA     'y ~ count terms' or 'y ~ count terms | zero terms'
                         (required)
  data => DF             the data: a HoA, AoH or HoH (required)
  dist => DIST           the count part: {poisson,negbin,geometric} (default:
                         poisson)
  zero_dist => DIST      the zero part: {binomial,poisson,negbin,geometric}
                         (default: binomial)
  link => LINK           the binomial zero part's link; only logit is
                         implemented (default: logit)
  offset => OFFSET       a column, an expression or an array ref, for the count
                         part (default: none)
  weights => W           case weights (default: none)
  conf_level => LEVEL    level of the confidence intervals (default: 0.95)

example:
  hurdle(formula => 'days ~ hours + age | hours', data => \%d, dist => 'negbin')
      # returns { coefficients => { count => {...}, zero => {...} }, summary,
      #           vcov, loglik, aic, nobs, converged, fitted_values, ... }

END

$SCREEN{svyglm} = <<'END';
usage: svyglm(formula => FORMULA, data => DF [, family => FAMILY]
              [, weights => W] [, strata => STRATA] [, cluster => PSU]
              [, fpc => FPC] [, nest => BOOL] [, offset => OFFSET]
              [, conf_level => LEVEL])

Design-based regression for complex survey data, as survey::svyglm().

options:
  formula => FORMULA     as glm()'s, with offset() terms allowed (required)
  data => DF             the data: a HoA, AoH or HoH (required)
  family => FAMILY       {gaussian,binomial,quasibinomial,poisson,quasipoisson}
                         (default: gaussian)
  weights => W           sampling weights: a column name or an array ref
                         (default: 1)
  strata => STRATA       stratum of each row: a column name or an array ref
                         (default: none)
  cluster => PSU         the PSU of each row; also ids, id or psu (default: one
                         PSU per row)
  fpc => FPC             finite population correction: stratum size or sampling
                         fraction (default: none)
  nest => BOOL           PSU labels are unique only within strata (default: 0)
  offset => OFFSET       a column, an expression or an array ref (default: none)
  conf_level => LEVEL    level of the confidence intervals (default: 0.95)

example:
  svyglm(formula => 'y ~ x', data => \%d, weights => 'pw', strata => 'st',
         cluster => 'psu')
      # returns { coefficients, summary, vcov, conf_int, degf, n_psu, n_strata,
      #           nobs, converged, fitted_values, ... }

END

$SCREEN{ivreg} = <<'END';
usage: ivreg(formula => FORMULA, data => DF [, weights => W] [, vcov => TYPE]
             [, cluster => CLUSTER] [, conf_level => LEVEL])

Instrumental-variables regression by two-stage least squares, as ivreg::ivreg().

options:
  formula => FORMULA     'y ~ regressors | instruments' or 'y ~ exogenous |
                         endogenous | instruments' (required)
  data => DF             the data: a HoA, AoH or HoH (required)
  weights => W           weights: a column name or an array ref (default: none)
  vcov => TYPE           {model,HC0,HC1}; also vcov_type (default: model, or HC0
                         with a cluster)
  cluster => CLUSTER     a column name or an array ref of labels (default: none)
  conf_level => LEVEL    level of the confidence intervals (default: 0.95)

example:
  ivreg(formula => 'y ~ x + w | z + w', data => \%d)
      # returns { coefficients, summary, vcov, conf_int, diagnostics => { weak,
      #           wu_hausman, sargan }, r_squared, sigma, nobs, ... }

END

$SCREEN{lmer} = <<'END';
usage: lmer(formula => FORMULA, data => DF [, REML => BOOL]
            [, conf_level => LEVEL])

Linear mixed-effects regression, as lme4::lmer() with lmerTest's t tests.

options:
  formula => FORMULA     fixed effects plus one or more (terms | group)
                         random-effects terms (required)
  data => DF             the data: a HoA, AoH or HoH (required)
  REML => BOOL           1 for REML, 0 for maximum likelihood; also reml
                         (default: 1)
  conf_level => LEVEL    level of the confidence intervals (default: 0.95)

example:
  lmer(formula => 'Reaction ~ Days + (Days | Subject)', data => \%sleepstudy)
      # returns { coefficients, summary, vcov, conf_int, varcor, sigma, theta,
      #           loglik, AIC, BIC, nobs, converged, singular, ... }

END

# Screens, part 8.

$SCREEN{age_standardize} = <<'END';
usage: age_standardize(COUNT, POP, STDPOP [, per => SCALE]
                       [, conf_level => LEVEL])

Directly standardized rate, with the Fay-Feuer gamma confidence interval.

positional arguments:
  COUNT                  events per stratum (or named: count => COUNT, or
                         rate => RATE to give stratum rates instead)
  POP                    population or person-time per stratum (or named:
                         pop => POP)
  STDPOP                 standard-population weight per stratum (or named:
                         stdpop => STDPOP)

options:
  per => SCALE           multiplier for every reported rate (default: 1)
  conf_level => LEVEL    confidence level, between 0 and 1 (default: 0.95)

example:
  age_standardize([5, 20, 55, 60], [1000, 3000, 4000, 2000],
                  [2000, 3000, 3000, 2000], per => 100_000)
      # returns { adj_rate => 1312.5, conf_int => [1097.8, 1569.6], ... }

END

$SCREEN{auc} = <<'END';
usage: auc(SCORES, LABELS [, positive => LABEL] [, direction => {>,<}])

Area under the ROC curve: the chance a positive outscores a negative.

positional arguments:
  SCORES                 array ref of scores
  LABELS                 array ref of class labels, one per score

options:
  positive => LABEL      the label of the positive class, compared as a
                         string (default: 1)
  direction => {>,<}     '>' if a higher score is more positive, '<' if a
                         lower one is (default: '>')

example:
  auc([0.9, 0.4, 0.8, 0.3], [1, 1, 0, 0])
      # returns 0.75

END

$SCREEN{auroc} = <<'END';
usage: auroc(LABELS, SCORES [, positive => LABEL] [, direction => {>,<}]
             [, cutoff => X | active_frac => FRAC]
             [, active_side => {high,low}])

Area under the ROC curve, with sklearn's roc_auc_score() argument order.

positional arguments:
  LABELS                 array ref of class labels, or of a numeric truth
                         column with cutoff or active_frac
  SCORES                 array ref of scores, one per label

options:
  positive => LABEL      the label of the positive class, compared as a
                         string (default: 1)
  direction => {>,<}     '>' if a higher score is more positive, '<' if a
                         lower one is (default: '>')
  cutoff => X            call a truth value >= X positive
  active_frac => FRAC    call this fraction of the truth values positive,
                         strictly between 0 and 1, from one tail
  active_side => SIDE    the tail active_frac takes: high or low
                         (default: high)

example:
  auroc([1, 1, 0, 0], [0.9, 0.4, 0.8, 0.3])
      # returns 0.75

END

$SCREEN{bedroc} = <<'END';
usage: bedroc(SCORES, LABELS [, alpha => ALPHA] [, positive => LABEL]
              [, cutoff => X | active_frac => FRAC]
              [, active_side => {high,low}] [, direction => {>,<}]
              [, top => FRAC])

Boltzmann-Enhanced Discrimination of ROC, an early-recognition metric.

positional arguments:
  SCORES                 array ref of ranking scores
  LABELS                 array ref of class labels, or of a numeric truth
                         column with cutoff or active_frac

options:
  alpha => ALPHA         early-recognition weight, > 0 and finite
                         (default: 20)
  positive => LABEL      the label of an active, compared as a string
                         (default: 1)
  cutoff => X            call a truth value >= X active
  active_frac => FRAC    call this fraction of the truth values active,
                         strictly between 0 and 1, from one tail
  active_side => SIDE    the tail active_frac takes: high or low
                         (default: high)
  direction => {>,<}     '>' if a higher score ranks first, '<' if a lower
                         one does (default: '>')
  top => FRAC            also report enrichment in the top fraction, in
                         (0, 1]

example:
  bedroc([0.9, 0.8, 0.4, 0.3, 0.2, 0.1], [1, 1, 0, 0, 0, 0], alpha => 20)
      # returns { bedroc => 1, ... }; bedroc('h') prints a longer help

END

$SCREEN{roc} = <<'END';
usage: roc(SCORES, LABELS [, positive => LABEL] [, conf_level => LEVEL]
           [, direction => {>,<}])

ROC curve: DeLong AUC and interval, every threshold, and Youden's best cut.

positional arguments:
  SCORES                 array ref of scores
  LABELS                 array ref of class labels, one per score

options:
  positive => LABEL      the label of the positive class, compared as a
                         string (default: 1)
  conf_level => LEVEL    confidence level of auc_ci, between 0 and 1
                         (default: 0.95)
  direction => {>,<}     '>' if a higher score is more positive, '<' if a
                         lower one is (default: '>')

example:
  roc([0.9, 0.4, 0.8, 0.3], [1, 1, 0, 0])
      # returns { auc => 0.75, auc_ci => [...], youden => {...}, ... }

END

$SCREEN{cohen_d} = <<'END';
usage: cohen_d(X, Y [, conf_level => LEVEL] [, ci_method => {nct,normal}])

Cohen's d for two independent groups, with Hedges' g and a confidence interval.

positional arguments:
  X                      array ref of the first group's values
  Y                      array ref of the second group's values

options:
  conf_level => LEVEL    confidence level, between 0 and 1 (default: 0.95)
  ci_method => METHOD    nct for the noncentral-t interval, normal for
                         d +- z * se (default: nct)

example:
  cohen_d([1, 2, 3, 4], [3, 4, 5, 6])
      # returns { estimate => -1.549, conf_int => [-3.134, 0.125], ... }

END

$SCREEN{smd} = <<'END';
usage: smd(X, Y)

Standardized mean difference, over the unweighted mean of the two variances.

positional arguments:
  X                      array ref of the first group's values
  Y                      array ref of the second group's values

example:
  smd([1, 2, 3, 4], [3, 4, 5, 6])
      # returns -1.549

END

$SCREEN{cramers_v} = <<'END';
usage: cramers_v(TABLE | X, Y)

Cramer's V for a contingency table, with Bergsma's bias-corrected V.

positional arguments:
  TABLE                  array ref of rows of counts, at least 2 x 2
  X, Y                   or two parallel array refs of categories, which are
                         cross-tabulated

example:
  cramers_v([[10, 20, 30], [15, 25, 10]])
      # returns { estimate => 0.312, bias_corrected => 0.283, ... }

END

$SCREEN{eta_squared} = <<'END';
usage: eta_squared(AOV | VALUES, GROUPS)

Eta-squared, partial eta-squared and omega-squared for a one-way design.

positional arguments:
  AOV                    a one-way aov() result
  VALUES, GROUPS         or two parallel array refs: the values and their
                         group labels

example:
  eta_squared([1, 2, 3, 4, 5, 6], [qw(a a b b c c)])
      # returns { eta_sq => 0.914, omega_sq => 0.833, ... }

END

$SCREEN{epi_2x2} = <<'END';
usage: epi_2x2(A, B, C, D | TABLE [, conf_level => LEVEL]
               [, correct => BOOL])

Odds ratio, risk ratio and risk difference, with intervals, for a 2x2 table.

positional arguments:
  A, B, C, D             the cell counts: exposed with and without the
                         outcome, then unexposed with and without it
  TABLE                  or one array ref, [a, b, c, d] or [[a, b], [c, d]]

options:
  conf_level => LEVEL    confidence level, between 0 and 1 (default: 0.95)
  correct => BOOL        add 0.5 to every cell, as a zero cell does anyway
                         (default: 0)

example:
  epi_2x2(30, 70, 20, 80)
      # returns { odds_ratio => 1.714, odds_ratio_ci => [0.895, 3.285], ... }

END

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stats::LikeR::Usage

=head1 VERSION

version 0.3413

=head1 AUTHOR

David E. Condon <dec986@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026-present by David E. Condon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
