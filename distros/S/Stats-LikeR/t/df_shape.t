#!/usr/bin/env perl
#
# _df_shape(), the shape classifier the frame functions written in Perl branch
# on. It was a Perl sub up to 0.331 and is XS from 0.34. The Perl is kept
# below as perl_df_shape(), verbatim from lib/Stats/LikeR.pm at 0.331 except
# for its name and its call to _usage_error(), and every case is run through
# both: the XS must give the same shape, or die with the same message. The
# location perl appends to its own "Not a HASH reference" is the one
# difference allowed, since the two die from different lines.
#
# What the XS does differently on purpose -- fetch a tied value once, and
# leave a hash's each iterator where it was -- is tested after that.

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

sub perl_df_shape {
	my ($df, $caller) = @_;
	unless (ref $df) {
		my $msg = 'data frame must be an ARRAY (AoA/AoH) or HASH (HoA/HoH) ref';
		Stats::LikeR::_usage_error($caller, $msg) if defined $caller;	# the caller's help screen
		die "data frame: $msg\n";
	}
	$caller = 'data frame' unless defined $caller;
	if (ref $df eq 'ARRAY') {
		for my $e (@$df) {
			next unless defined $e;
			return 'AoA' if ref $e eq 'ARRAY';
			return 'AoH' if ref $e eq 'HASH';
			die "$caller: array elements must be ARRAY (AoA) or HASH (AoH) refs\n";
		}
		return 'AoH';                         # empty -> harmless default
	}
	# HASH: HoA vs HoH, rejecting a mix
	my ($saw_arr, $saw_hash) = (0, 0);
	for my $v (values %$df) {
		next unless ref $v;
		$saw_arr++  if ref $v eq 'ARRAY';
		$saw_hash++ if ref $v eq 'HASH';
	}
	die "$caller: hashref mixes array and hash values (ambiguous HoA/HoH)\n"
		if $saw_arr and $saw_hash;
	return 'HoH' if $saw_hash;
	return 'HoA';                             # arrays, or empty -> default
}

# shape, or the error with perl's own " at FILE line N." taken off
sub outcome {
	my ($code, @args) = @_;
	my $r = eval { $code->(@args) };
	return "returned $r" unless $@;
	(my $e = $@) =~ s/ at \S+ line \d+\.\n\z/\n/;
	return "died: $e";
}

my @sparse;
$sparse[2] = [1];
my @cases = (
	# not a reference
	[ 'undef',                 undef ],
	[ 'a number',              42 ],
	[ 'a string',              'AoH' ],
	[ 'the empty string',      '' ],
	# arrays: the first defined element decides
	[ 'empty array',           [] ],
	[ 'all-undef array',       [ undef, undef ] ],
	[ 'AoA',                   [ [1], [2] ] ],
	[ 'AoH',                   [ { a => 1 } ] ],
	[ 'undef, then a row',     [ undef, [1] ] ],
	[ 'sparse array',          \@sparse ],
	[ 'array row first',       [ [1], { a => 1 } ] ],
	[ 'hash row first',        [ { a => 1 }, [1] ] ],
	[ 'array row, then junk',  [ [1], 2 ] ],
	[ 'a scalar first',        [ 1, [1] ] ],
	[ 'a scalar ref first',    [ \1 ] ],
	[ 'a code ref first',      [ sub { 1 } ] ],
	[ 'a blessed row first',   [ bless({ a => 1 }, 'Row') ] ],
	[ 'a row blessed ARRAY',   [ bless([1], 'ARRAY') ] ],
	[ 'a row blessed HASH',    [ bless([1], 'HASH') ] ],
	# hashes: every value counts
	[ 'empty hash',            {} ],
	[ 'flat hash',             { a => 1, b => 2 } ],
	[ 'HoA',                   { a => [1], b => [2] } ],
	[ 'HoH',                   { a => { x => 1 } } ],
	[ 'HoA with a scalar',     { a => [1], b => 2 } ],
	[ 'HoH with a scalar',     { a => { x => 1 }, b => 2 } ],
	[ 'HoA with undef',        { a => [1], b => undef } ],
	[ 'array and hash values', { a => [1], b => { x => 1 } } ],
	[ 'a code ref value',      { a => sub { 1 } } ],
	[ 'a blessed array value', { a => bless([1], 'Col') } ],
	[ 'a blessed hash value',  { a => bless({}, 'Row') } ],
	[ 'blessed and plain',     { a => bless({}, 'Row'), b => [1] } ],
	# the frame itself
	[ 'blessed HoA',           bless({ a => [1] }, 'Frame') ],
	[ 'blessed AoA',           bless([ [1] ], 'Frame') ],
	[ 'array blessed ARRAY',   bless([ [1] ], 'ARRAY') ],
	[ 'hash blessed ARRAY',    bless({ a => [1] }, 'ARRAY') ],
	[ 'hash blessed HASH',     bless({ a => [1] }, 'HASH') ],
	[ 'scalar ref',            \1 ],
	[ 'ref to a ref',          \[ [1] ] ],
	[ 'code ref',              sub { 1 } ],
);

for my $c (@cases) {
	my ($name, $df) = @$c;
	for my $caller ([], ['colnames'], [undef]) {
		my $how = @$caller ? defined $caller->[0] ? ', caller colnames' : ', caller undef' : '';
		is(outcome(\&Stats::LikeR::_df_shape, $df, @$caller),
		   outcome(\&perl_df_shape, $df, @$caller), "$name$how");
	}
}

# the help screen really is there, above the error
like(outcome(\&Stats::LikeR::_df_shape, 42, 'colnames'),
     qr/\Adied: usage: colnames\(.*^colnames: error: data frame must be an ARRAY/ms,
     'a non-reference dies with the caller\'s screen');
is(outcome(\&Stats::LikeR::_df_shape, 42),
   "died: data frame: data frame must be an ARRAY (AoA/AoH) or HASH (HoA/HoH) ref\n",
   'and with "data frame:" without one');
is(eval { Stats::LikeR::_df_shape(); 1 }, undef, 'no arguments dies');
like($@, qr/^Usage: Stats::LikeR::_df_shape\(df \[, caller\]\)/, '  with its usage');
is(eval { Stats::LikeR::_df_shape([], 'a', 'b'); 1 }, undef, 'three arguments die');

# a tied frame: each value fetched once (the Perl fetched one up to twice)
{
	package TieArr;
	our %fetched;
	sub TIEARRAY  { my ($c, @v) = @_; bless [@v], $c }
	sub FETCH     { $fetched{ $_[1] }++; $_[0][ $_[1] ] }
	sub FETCHSIZE { scalar @{ $_[0] } }
	package TieHash;
	our %fetched;
	sub TIEHASH  { my ($c, %v) = @_; bless { %v }, $c }
	sub FETCH    { $fetched{ $_[1] }++; $_[0]{ $_[1] } }
	sub FIRSTKEY { my $h = $_[0]; my $n = keys %$h; each %$h }
	sub NEXTKEY  { each %{ $_[0] } }
	package main;

	tie my @ta, 'TieArr', undef, [1], { a => 1 };
	%TieArr::fetched = ();
	is(Stats::LikeR::_df_shape(\@ta, 'x'), 'AoA', 'tied AoA');
	is_deeply(\%TieArr::fetched, { 0 => 1, 1 => 1 }, '  fetched up to the first defined row, once each');

	tie my %th, 'TieHash', a => { x => 1 }, b => { x => 2 }, c => 3;
	%TieHash::fetched = ();
	is(Stats::LikeR::_df_shape(\%th, 'x'), 'HoH', 'tied HoH');
	is_deeply(\%TieHash::fetched, { a => 1, b => 1, c => 1 }, '  every value fetched, once');

	tie my %tm, 'TieHash', a => [1], b => { x => 1 }, c => [2], d => [3];
	is(outcome(\&Stats::LikeR::_df_shape, \%tm, 'x'),
	   "died: x: hashref mixes array and hash values (ambiguous HoA/HoH)\n", 'tied mixed hash dies');
}

# a tied value in a plain hash or array: the container has no magic, the
# value does, and the hash's must still be fetched
{
	package TieScalar;
	our $fetched = 0;
	sub TIESCALAR { bless [ $_[1] ], $_[0] }
	sub FETCH     { $fetched++; $_[0][0] }
	sub STORE     { }
	package main;

	my %h = (a => [1], b => 1);
	tie $h{b}, 'TieScalar', { x => 1 };
	$TieScalar::fetched = 0;
	is(outcome(\&Stats::LikeR::_df_shape, \%h, 'x'),
	   outcome(\&perl_df_shape, \%h, 'x'), 'tied value in a plain hash makes it mixed');
	my %hh = (b => 1);
	tie $hh{b}, 'TieScalar', { x => 1 };
	$TieScalar::fetched = 0;
	is(Stats::LikeR::_df_shape(\%hh), 'HoH', 'tied value in a plain hash makes it a HoH');
	is($TieScalar::fetched, 1, '  fetched once');
	my @a = (undef);
	tie $a[0], 'TieScalar', [1];
	$TieScalar::fetched = 0;
	is(Stats::LikeR::_df_shape(\@a), 'AoA', 'tied element in a plain array');
	is($TieScalar::fetched, 1, '  fetched once');
}

# the caller's each iterator is left where it was, by a whole walk and by one
# cut short by the mix error
{
	my %h = map { $_ => [ $_ ] } 1 .. 20;
	my @order = keys %h;
	each %h;
	is(Stats::LikeR::_df_shape(\%h), 'HoA', 'HoA mid-each');
	my ($next) = each %h;
	is($next, $order[1], '  each carries on from where it was');
	keys %h;
	$h{21} = { x => 1 };
	@order = keys %h;
	each %h;
	is(eval { Stats::LikeR::_df_shape(\%h); 1 }, undef, 'mixed hash mid-each dies');
	($next) = each %h;
	is($next, $order[1], '  and each still carries on');
}

SKIP: {
	skip 'Test::LeakTrace not installed', 6 unless $HAVE_LEAKTRACE;
	no_leaks_ok { Stats::LikeR::_df_shape([ { a => 1 } ], 'x') } 'no leaks: AoH';
	no_leaks_ok { Stats::LikeR::_df_shape({ a => { x => 1 } }, 'x') } 'no leaks: HoH';
	no_leaks_ok { eval { Stats::LikeR::_df_shape([ 1 ], 'x') } } 'no leaks: bad row';
	no_leaks_ok { eval { Stats::LikeR::_df_shape({ a => [1], b => {} }, 'x') } } 'no leaks: mixed hash';
	no_leaks_ok { eval { Stats::LikeR::_df_shape(42, 'colnames') } } 'no leaks: help screen';
	tie my %tm, 'TieHash', a => [1], b => { x => 1 }, c => [2], d => [3];
	no_leaks_ok { eval { Stats::LikeR::_df_shape(\%tm, 'x') } } 'no leaks: tied mixed hash, cut short';
}

done_testing();
