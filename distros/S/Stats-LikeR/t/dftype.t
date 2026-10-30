#!/usr/bin/env perl
#
# dftype(): the shape names it gives every kind of argument. Neither R nor
# Python has a function that classifies a structure into these names, so the
# cases here are written against the table in README.md's "dftype" section
# rather than taken from a reference suite.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	} ? 1 : 0;
}

# the four frame shapes
is(dftype([ [1, 2], [3, 4] ]),                    'AoA', 'AoA');
is(dftype([ { a => 1 }, { a => 2 } ]),            'AoH', 'AoH');
is(dftype({ a => [1, 2], b => [3, 4] }),          'HoA', 'HoA');
is(dftype({ r1 => { a => 1 }, r2 => { a => 2 } }), 'HoH', 'HoH');
is(dftype([ [] ]),                                'AoA', 'an empty row is still a row');
is(dftype({ a => {} }),                           'HoH', 'an empty inner hash is still a row');
is(dftype([ [ [1] ] ]),                           'AoA', 'only two levels are looked at');

# undef elements are passed over, wherever they are
is(dftype([ undef, { a => 1 } ]),                 'AoH', 'a leading undef row');
is(dftype([ [1], undef, [2] ]),                   'AoA', 'an undef row in the middle');
is(dftype({ a => undef, b => [1] }),              'HoA', 'an undef column');
{
	my @sparse;
	$sparse[3] = { a => 1 };
	is(dftype(\@sparse), 'AoH', 'holes in a sparse array');
}

# nothing defined, or anything mixed, is a plain container
is(dftype([]),                                    'array', 'empty array');
is(dftype({}),                                    'hash',  'empty hash');
is(dftype([ undef, undef ]),                      'array', 'all-undef array');
is(dftype({ a => undef }),                        'hash',  'all-undef hash');
is(dftype([ 1, 2, 3 ]),                           'array', 'flat array');
is(dftype({ a => 1, b => 2 }),                    'hash',  'flat hash');
is(dftype([ [1], { a => 1 } ]),                   'array', 'array and hash rows');
is(dftype([ { a => 1 }, [1] ]),                   'array', 'hash and array rows');
is(dftype([ [1], 2 ]),                            'array', 'an array row, then a scalar');
is(dftype([ [1], [2], \3 ]),                      'array', 'a non-container ref after the rows');
is(dftype({ a => [1], b => { c => 1 } }),         'hash',  'array and hash values');
is(dftype({ a => [1], b => 2 }),                  'hash',  'an array value and a scalar');
is(dftype({ a => sub { 1 } }),                    'hash',  'a code ref value');

# values that are not references
is(dftype(undef), 'undef',  'undef');
is(dftype(42),    'scalar', 'a number');
is(dftype('AoH'), 'scalar', 'a string');
is(dftype(''),    'scalar', 'the empty string');
is(dftype(0),     'scalar', 'zero');

# other references, by the type ref() gives an unblessed one
is(dftype(\1),             'SCALAR', 'scalar ref');
is(dftype(\\1),            'REF',    'ref to a ref');
is(dftype(\[ [1] ]),       'REF',    'ref to an AoA ref');
is(dftype(sub { 1 }),      'CODE',   'code ref');
is(dftype(\*STDOUT),       'GLOB',   'glob ref');
is(dftype(qr/x/),          'REGEXP', 'qr// on this perl');

# blessing is ignored
is(dftype(bless [ [1] ], 'Frame'),              'AoA', 'blessed AoA');
is(dftype(bless { a => [1] }, 'Frame'),         'HoA', 'blessed HoA');
is(dftype([ bless({ a => 1 }, 'Row') ]),        'AoH', 'blessed rows');
is(dftype(bless [ 1, 2 ], 'Frame'),             'array', 'blessed flat array');
is(dftype(bless \(my $s = 1), 'Thing'),         'SCALAR', 'blessed scalar ref');

# a variable, not a literal
{
	my $aoh = [ { a => 1 } ];
	my $ref = $aoh;
	is(dftype($ref), 'AoH', 'through a variable');
	is(dftype($aoh->[0]), 'hash', 'one row of it');
	is(dftype($aoh->[0]{a}), 'scalar', 'one cell of it');
}

# tied containers are classified by what they fetch
{
	package TieArr;
	sub TIEARRAY  { my ($c, @v) = @_; bless [@v], $c }
	sub FETCH     { $_[0][$_[1]] }
	sub FETCHSIZE { scalar @{ $_[0] } }
	package TieHash;
	sub TIEHASH  { my ($c, %v) = @_; bless { %v }, $c }
	sub FETCH    { $_[0]{$_[1]} }
	sub FIRSTKEY { my $h = $_[0]; my $n = keys %$h; each %$h }
	sub NEXTKEY  { each %{ $_[0] } }
	package main;
	tie my @ta, 'TieArr', [1], [2];
	is(dftype(\@ta), 'AoA', 'tied AoA');
	tie my @tb, 'TieArr', [1], { a => 1 };
	is(dftype(\@tb), 'array', 'tied mixed array');
	tie my %th, 'TieHash', a => { x => 1 }, b => { x => 2 };
	is(dftype(\%th), 'HoH', 'tied HoH');
	tie my %tf, 'TieHash', a => 1;
	is(dftype(\%tf), 'hash', 'tied flat hash');
}

# a tied scalar argument has its get magic run once
{
	package TieSc;
	our $fetches = 0;
	sub TIESCALAR { my ($c, $v) = @_; bless \$v, $c }
	sub FETCH     { $fetches++; ${ $_[0] } }
	package main;
	tie my $ts, 'TieSc', { a => [1] };
	is(dftype($ts), 'HoA', 'tied scalar holding a HoA');
	is($TieSc::fetches, 1, 'its FETCH ran once');
}

# the hash's each iterator is left where it was, whether or not the walk
# stopped early
{
	my %h = map { $_ => [ $_ ] } 1 .. 20;
	$h{11} = 'flat';
	my @order = keys %h;
	my ($first) = each %h;
	is(dftype(\%h), 'hash', 'a mixed hash, walked part way');
	my ($next) = each %h;
	is($next, $order[1], 'each carries on from where it was');
	keys %h;
	delete $h{11};
	@order = keys %h;
	($first) = each %h;
	is(dftype(\%h), 'HoA', 'a HoA, walked to the end');
	($next) = each %h;
	is($next, $order[1], 'and after a whole walk too');
}

# a tied hash walk that stops early fetches nothing after the stop
{
	package TieCount;
	our %fetched;
	sub TIEHASH  { my ($c, %v) = @_; bless { %v }, $c }
	sub FETCH    { $fetched{ $_[1] }++; $_[0]{ $_[1] } }
	sub FIRSTKEY { my $h = $_[0]; my $n = keys %$h; each %$h }
	sub NEXTKEY  { each %{ $_[0] } }
	package main;
	tie my %t, 'TieCount', (map { $_ => [ $_ ] } 1 .. 10), 5 => 'flat';
	%TieCount::fetched = ();
	is(dftype(\%t), 'hash', 'tied mixed hash');
	my @twice = grep { $TieCount::fetched{$_} > 1 } keys %TieCount::fetched;
	is_deeply(\@twice, [], 'no value fetched twice');
}

# the argument count
for my $args ([], [ [], [] ], [ undef, undef ]) {
	my $n = @$args;
	is(eval { dftype(@$args); 1 }, undef, "dftype with $n arguments dies");
	like($@, qr/^usage: dftype\(DATA\)/, '  with its help screen');
	like($@, qr/^dftype: error: expected 1 argument, got $n\n\z/m, '  and the count on the last line');
}

SKIP: {
	skip 'Test::LeakTrace not installed', 5 unless $HAVE_LEAKTRACE;
	no_leaks_ok { dftype([ { a => 1 }, { b => 2 } ]) } 'no leaks: AoH';
	no_leaks_ok { dftype({ a => [1], b => { c => 1 } }) } 'no leaks: mixed hash, early stop';
	no_leaks_ok { dftype(sub { 1 }) } 'no leaks: code ref';
	tie my %lt, 'TieCount', a => [1], b => { c => 1 }, d => [2];
	no_leaks_ok { dftype(\%lt) } 'no leaks: tied mixed hash, early stop';
	no_leaks_ok { eval { dftype() } } 'no leaks: usage error';
}

done_testing();
