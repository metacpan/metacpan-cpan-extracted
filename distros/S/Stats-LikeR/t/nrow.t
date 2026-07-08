#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# nrow: count rows across the Stats::LikeR frame forms.
#   AoH / AoA / plain vector -> physical top-level elements (scalar @$data)
#   HoH                      -> number of top-level keys
#   HoA                      -> common column length (croaks if ragged)
# reftype-based, so blessed frames count too.

#--------
# AoH / AoA / plain vector -- scalar @$data
#--------
is( nrow([ {a=>1,b=>2}, {a=>3,b=>4} ]),           2, 'AoH: two rows' );
is( nrow([ [1,2,3], [4,5,6], [7,8,9] ]),          3, 'AoA: three rows' );
is( nrow([ 10, 20, 30, 40 ]),                     4, 'plain vector: physical elements' );
is( nrow([ {a=>1} ]),                             1, 'AoH: single row' );
is( nrow([]),                                     0, 'empty array ref: zero rows' );

#--------
# HoH -- number of top-level keys
#--------
is( nrow({ r1=>{x=>1}, r2=>{x=>2}, r3=>{x=>3} }), 3, 'HoH: three rows' );
is( nrow({ only=>{x=>1} }),                       1, 'HoH: single row' );

#--------
# HoA -- common column length
#--------
is( nrow({ a=>[1,2,3,4,5], b=>[6,7,8,9,10] }),    5, 'HoA: two columns, five rows' );
is( nrow({ a=>[1,2,3] }),                         3, 'HoA: single column' );
is( nrow({ a=>[], b=>[] }),                       0, 'HoA: empty columns, zero rows' );

#--------
# empty hash -- zero, form-agnostic
#--------
is( nrow({}),                                     0, 'empty hash ref: zero rows' );

#--------
# blessed frames -- reftype sees through the blessing
#--------
is( nrow(bless([ {x=>1}, {x=>2} ], 'My::Frame')),         2, 'blessed AoH' );
is( nrow(bless({ r1=>{}, r2=>{}, r3=>{} }, 'My::Frame')), 3, 'blessed HoH' );
is( nrow(bless({ a=>[1,2], b=>[3,4] }, 'My::Frame')),     2, 'blessed HoA' );

#--------
# scalar return -- one value in list context
#--------
{
	my @got = nrow([1,2,3]);
	is( scalar(@got), 1, 'list context yields exactly one value' );
	is( $got[0],      3, 'that value is the row count' );
}

#--------
# error paths -- clean croaks
#--------
throws_ok { nrow(undef) }
	qr/expected an ARRAY or HASH ref \(got undef\)/,
	'undef arg croaks';
throws_ok { nrow(42) }
	qr/expected an ARRAY or HASH ref \(got non-ref scalar\)/,
	'non-ref number croaks';
throws_ok { nrow('frame') }
	qr/expected an ARRAY or HASH ref \(got non-ref scalar\)/,
	'non-ref string croaks';
throws_ok { nrow({ a=>[1,2,3], b=>[1,2] }) }
	qr/ragged HoA/,
	'ragged HoA croaks';
throws_ok { nrow({ a=>[1,2,3], b=>undef }) }
	qr/HoA column 'b' is not an array ref/,
	'undef column in HoA croaks (probe is the defined array, so column b is caught)';
throws_ok { nrow({ a=>1, b=>2 }) }
	qr/neither ARRAY refs \(HoA\) nor HASH refs \(HoH\)/,
	'hash of non-ref scalars croaks';
throws_ok { nrow({ a=>undef, b=>undef }) }
	qr/neither ARRAY refs \(HoA\) nor HASH refs \(HoH\)/,
	'hash of all-undef values croaks';

#--------
# non-container refs -- currently die at the hash deref (see note in reply).
# dies_ok is message-agnostic, so these survive tightening nrow's guard.
#--------
dies_ok { nrow(\my $s) }    'scalar ref dies';
dies_ok { nrow(sub { 1 }) } 'code ref dies';
dies_ok { nrow(\*STDOUT) }  'glob ref dies';

#--------
# no memory leaks on the pure-Perl counting paths (guarded under Devel::Cover).
# Croak paths are omitted: Carp caches SVs on first use, which Test::LeakTrace
# reports as a false positive.
#--------
unless ($INC{'Devel/Cover.pm'}) {
	no_leaks_ok { nrow([ {a=>1}, {a=>2} ]) }          'nrow(): AoH count, no leaks';
	no_leaks_ok { nrow([ [1,2], [3,4], [5,6] ]) }     'nrow(): AoA count, no leaks';
	no_leaks_ok { nrow({ r1=>{}, r2=>{} }) }          'nrow(): HoH count, no leaks';
	no_leaks_ok { nrow({ a=>[1,2,3], b=>[4,5,6] }) }  'nrow(): HoA count, no leaks';
}

done_testing();
