#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# ncol: count columns across the Stats::LikeR frame forms.
#   AoH -> distinct keys per row (rows must agree on count)
#   AoA -> row length            (rows must agree on length)
#   HoA -> number of keys (keys ARE the columns)
#   HoH -> keys of a row hash    (rows must agree on count)
#   plain vector -> 1 column
# die-based (no Carp); reftype => blessed frames count too.

#--------
# AoH -- distinct keys per row
#--------
is( ncol([ {a=>1,b=>2,c=>3}, {a=>4,b=>5,c=>6} ]), 3, 'AoH: three columns' );
is( ncol([ {x=>1} ]),                             1, 'AoH: single row, one column' );
is( ncol([ {}, {} ]),                             0, 'AoH: empty rows, zero columns' );

#--------
# AoA -- row length
#--------
is( ncol([ [1,2,3,4], [5,6,7,8] ]),               4, 'AoA: four columns' );
is( ncol([ [1,2,3] ]),                            3, 'AoA: single row' );
is( ncol([ [], [] ]),                             0, 'AoA: empty rows, zero columns' );

#--------
# plain vector / empty array
#--------
is( ncol([ 10, 20, 30 ]),                         1, 'plain vector: one column' );
is( ncol([ undef ]),                              1, 'single undef element: one column' );
is( ncol([]),                                     0, 'empty array ref: zero columns' );

#--------
# HoA -- keys ARE the columns
#--------
is( ncol({ a=>[1,2,3], b=>[4,5,6] }),             2, 'HoA: two columns' );
is( ncol({ a=>[1,2,3] }),                         1, 'HoA: single column' );
is( ncol({ a=>[], b=>[], c=>[] }),                3, 'HoA: columns exist with zero rows' );

#--------
# HoH -- columns = keys of a row hash
#--------
is( ncol({ r1=>{a=>1,b=>2}, r2=>{a=>3,b=>4} }),   2, 'HoH: two columns' );
is( ncol({ only=>{a=>1,b=>2,c=>3} }),             3, 'HoH: single row' );

#--------
# empty hash
#--------
is( ncol({}),                                     0, 'empty hash ref: zero columns' );

#--------
# blessed frames -- reftype sees through the blessing
#--------
is( ncol(bless([ {x=>1,y=>2}, {x=>3,y=>4} ], 'My::Frame')),      2, 'blessed AoH' );
is( ncol(bless([ [1,2,3], [4,5,6] ], 'My::Frame')),              3, 'blessed AoA' );
is( ncol(bless({ a=>[1,2], b=>[3,4] }, 'My::Frame')),            2, 'blessed HoA' );
is( ncol(bless({ r1=>{a=>1,b=>2}, r2=>{a=>3,b=>4} }, 'My::F')),  2, 'blessed HoH' );

#--------
# scalar return -- one value in list context
#--------
{
	my @got = ncol([ [1,2,3] ]);
	is( scalar(@got), 1, 'list context yields exactly one value' );
	is( $got[0],      3, 'that value is the column count' );
}

#--------
# error paths -- clean dies
#--------
throws_ok { ncol(undef) }
	qr/expected an ARRAY or HASH ref \(got undef\)/,
	'undef arg dies';
throws_ok { ncol(42) }
	qr/expected an ARRAY or HASH ref \(got non-ref scalar\)/,
	'non-ref number dies';
throws_ok { ncol('frame') }
	qr/expected an ARRAY or HASH ref \(got non-ref scalar\)/,
	'non-ref string dies';
throws_ok { my $x = 5; ncol(\$x) }
	qr/expected an ARRAY or HASH ref \(got SCALAR\)/,
	'scalar ref dies (tightened guard)';
throws_ok { ncol(sub { 1 }) }
	qr/expected an ARRAY or HASH ref \(got CODE\)/,
	'code ref dies';
throws_ok { ncol(\*STDOUT) }
	qr/expected an ARRAY or HASH ref \(got GLOB\)/,
	'glob ref dies';

#--------
# error paths -- ragged / mixed frames
#--------
throws_ok { ncol([ {a=>1,b=>2}, {a=>1} ]) }
	qr/ragged AoH — row 1 has 1 columns, but row 0 has 2/,
	'ragged AoH dies';
throws_ok { ncol([ {a=>1}, [1,2] ]) }
	qr/AoH row 1 is not a hash ref/,
	'AoH with a non-hash row dies';
throws_ok { ncol([ [1,2,3], [1,2] ]) }
	qr/ragged AoA — row 1 has 2 columns, but row 0 has 3/,
	'ragged AoA dies';
throws_ok { ncol([ [1,2], {a=>1} ]) }
	qr/AoA row 1 is not an array ref/,
	'AoA with a non-array row dies';
throws_ok { ncol([ \1, \2 ]) }
	qr/array element 0 is a SCALAR ref/,
	'array of scalar refs dies';
throws_ok { ncol({ a=>[1,2], b=>undef }) }
	qr/HoA column 'b' is not an array ref/,
	'HoA with a non-array column dies (probe is the defined array)';
throws_ok { ncol({ r1=>{a=>1,b=>2}, r2=>{a=>1} }) }
	qr/ragged HoH/,
	'ragged HoH dies';
throws_ok { ncol({ r1=>{a=>1}, r2=>undef }) }
	qr/HoH row 'r2' is not a hash ref/,
	'HoH with a non-hash row dies (probe is the defined hash)';
throws_ok { ncol({ a=>1, b=>2 }) }
	qr/neither ARRAY refs \(HoA\) nor HASH refs \(HoH\)/,
	'hash of non-ref scalars dies';
throws_ok { ncol({ a=>undef, b=>undef }) }
	qr/neither ARRAY refs \(HoA\) nor HASH refs \(HoH\)/,
	'hash of all-undef values dies';

#--------
# no memory leaks on the pure-Perl counting paths (guarded under Devel::Cover).
# die paths are omitted: eval/$@ can register a false positive.
#--------
unless ($INC{'Devel/Cover.pm'}) {
	no_leaks_ok { ncol([ {a=>1,b=>2}, {a=>3,b=>4} ]) } 'ncol(): AoH count, no leaks';
	no_leaks_ok { ncol([ [1,2,3], [4,5,6] ]) }         'ncol(): AoA count, no leaks';
	no_leaks_ok { ncol([ 1, 2, 3 ]) }                  'ncol(): vector, no leaks';
	no_leaks_ok { ncol({ a=>[1,2], b=>[3,4] }) }       'ncol(): HoA count, no leaks';
	no_leaks_ok { ncol({ r1=>{a=>1}, r2=>{a=>2} }) }   'ncol(): HoH count, no leaks';
}

done_testing();
