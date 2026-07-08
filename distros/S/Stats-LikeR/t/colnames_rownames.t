#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# colnames / rownames: the column and row names of the four frame shapes.
#   AoA        columns = 0 .. widest_row-1 ; rows = 0 .. $#$data
#   AoH        columns = sorted union of row keys ; rows = 0 .. $#$data
#   HoA        columns = sorted keys ; rows = 0 .. longest_column-1
#   HoH        columns = sorted union of inner keys ; rows = sorted outer keys
# ref-based (via _df_shape, the agg() family), list in list context and the
# count in scalar context: scalar colnames == ncol, scalar rownames == nrow.

#--------
# colnames -- AoA: 0-based column indices, spanning the widest row
#--------
is_deeply( [ colnames([ [1,2,3], [4,5,6] ]) ],      [0,1,2],   'AoA colnames: 0-based indices' );
is_deeply( [ colnames([ [1,2], [3,4,5,6] ]) ],      [0,1,2,3], 'AoA colnames: ragged spans widest row' );
is_deeply( [ colnames([ [] ]) ],                    [],        'AoA colnames: one empty row -> no columns' );

#--------
# colnames -- AoH: sorted union of keys across every row (ragged tolerated)
#--------
is_deeply( [ colnames([ {b=>2,a=>1}, {a=>3,c=>9} ]) ], [qw(a b c)], 'AoH colnames: sorted key union' );
is_deeply( [ colnames([ {only=>1} ]) ],                ['only'],    'AoH colnames: single row' );
is_deeply( [ colnames([ undef, {q=>1}, undef ]) ],     ['q'],       'AoH colnames: undef rows skipped' );

#--------
# colnames -- HoA: the keys are the columns, sorted
#--------
is_deeply( [ colnames({ z=>[1,2], a=>[3,4], m=>[5,6] }) ], [qw(a m z)], 'HoA colnames: sorted keys' );
is_deeply( [ colnames({ a=>[1,2,3] }) ],                   ['a'],       'HoA colnames: single column' );

#--------
# colnames -- HoH: sorted union of inner keys (ragged inner rows tolerated)
#--------
is_deeply( [ colnames({ r2=>{x=>1,y=>2}, r1=>{y=>3,z=>4} }) ], [qw(x y z)], 'HoH colnames: sorted inner-key union' );

#--------
# rownames -- AoA / AoH: 0-based row indices (one per top-level element)
#--------
is_deeply( [ rownames([ [1,2,3], [4,5,6] ]) ],            [0,1],   'AoA rownames: 0-based indices' );
is_deeply( [ rownames([ {a=>1}, {a=>2}, {a=>3} ]) ],      [0,1,2], 'AoH rownames: 0-based indices' );
is_deeply( [ rownames([ undef, {a=>1} ]) ],               [0,1],   'AoH rownames: undef rows still counted' );

#--------
# rownames -- HoA: 0-based indices over the longest column (ragged tolerated)
#--------
is_deeply( [ rownames({ a=>[1,2], b=>[3,4] }) ],          [0,1],   'HoA rownames: 0-based indices' );
is_deeply( [ rownames({ a=>[1,2,3], b=>[4,5] }) ],        [0,1,2], 'HoA rownames: ragged spans longest column' );
is_deeply( [ rownames({ a=>[1,2,3], b=>undef }) ],        [0,1,2], 'HoA rownames: undef column skipped for length' );

#--------
# rownames -- HoH: the outer keys are the rows, sorted
#--------
is_deeply( [ rownames({ r2=>{x=>1}, r1=>{x=>2}, r3=>{x=>3} }) ], [qw(r1 r2 r3)], 'HoH rownames: sorted outer keys' );
is_deeply( [ rownames({ only=>{x=>1} }) ],                       ['only'],       'HoH rownames: single row' );

#--------
# empty frames -- empty list, form-agnostic defaults
#--------
is_deeply( [ colnames([]) ], [], 'colnames empty array ref: no columns' );
is_deeply( [ rownames([]) ], [], 'rownames empty array ref: no rows' );
is_deeply( [ colnames({}) ], [], 'colnames empty hash ref: no columns' );
is_deeply( [ rownames({}) ], [], 'rownames empty hash ref: no rows' );

#--------
# scalar context -- the count, agreeing with ncol / nrow
#--------
is( scalar colnames([ {b=>2,a=>1}, {a=>3,c=>9} ]), 3, 'scalar colnames == ncol (union)' );
is( scalar rownames({ r1=>{x=>1}, r2=>{x=>2} }),   2, 'scalar rownames == nrow (HoH keys)' );
is( scalar colnames([ [1,2,3,4] ]),                4, 'scalar colnames == ncol (AoA width)' );
is( scalar rownames([ [1],[2],[3] ]),              3, 'scalar rownames == nrow (AoA rows)' );

#--------
# list context -- every name is returned, not just the last
#--------
{
	my @c = colnames({ z=>[1], a=>[2], 'm'=>[3] });
	is( scalar(@c), 3, 'HoA colnames: list context yields all three names' );
}

#--------
# error paths -- clean dies with the caller-labelled message
#--------
throws_ok { colnames(undef) }
	qr/colnames: undefined data in first position/,
	'colnames(undef) dies';
throws_ok { rownames(undef) }
	qr/rownames: undefined data in first position/,
	'rownames(undef) dies';
throws_ok { colnames(42) }
	qr/colnames: data frame must be an ARRAY .*or HASH/,
	'colnames(non-ref) dies';
throws_ok { rownames('frame') }
	qr/rownames: data frame must be an ARRAY .*or HASH/,
	'rownames(non-ref) dies';
throws_ok { colnames([ 'scalar', 'row' ]) }
	qr/array elements must be ARRAY .*or HASH/,
	'colnames(array of plain scalars) dies';
throws_ok { rownames({ a=>[1,2], b=>{x=>1} }) }
	qr/mixes array and hash values/,
	'rownames(mixed hash values) dies';

#--------
# non-container refs -- die at the deref, message-agnostic (mirrors nrow.t)
#--------
dies_ok { colnames(\my $s) }    'colnames(scalar ref) dies';
dies_ok { rownames(sub { 1 }) } 'rownames(code ref) dies';

#--------
# no memory leaks on the pure-Perl enumeration paths (guarded under
# Devel::Cover).  Die paths are omitted: Carp/warn caching reports false
# positives, exactly as noted in nrow.t.
#--------
unless ($INC{'Devel/Cover.pm'}) {
	no_leaks_ok { colnames([ [1,2,3], [4,5,6] ]) }             'colnames(): AoA, no leaks';
	no_leaks_ok { colnames([ {b=>2,a=>1}, {a=>3,c=>9} ]) }     'colnames(): AoH, no leaks';
	no_leaks_ok { colnames({ z=>[1,2], a=>[3,4] }) }           'colnames(): HoA, no leaks';
	no_leaks_ok { colnames({ r1=>{x=>1}, r2=>{y=>2} }) }       'colnames(): HoH, no leaks';
	no_leaks_ok { rownames([ [1,2], [3,4], [5,6] ]) }          'rownames(): AoA, no leaks';
	no_leaks_ok { rownames([ {a=>1}, {a=>2} ]) }               'rownames(): AoH, no leaks';
	no_leaks_ok { rownames({ a=>[1,2,3], b=>[4,5,6] }) }       'rownames(): HoA, no leaks';
	no_leaks_ok { rownames({ r1=>{x=>1}, r2=>{x=>2} }) }       'rownames(): HoH, no leaks';
}

done_testing();
