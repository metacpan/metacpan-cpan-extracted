#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# col()->match / ->nomatch : regex predicates for filter().  Perl cannot
# overload =~, so col('id') =~ /re/ can never be intercepted; these methods
# build the same deferred predicate object the comparison operators do, and
# filter() runs it once per row.  A pattern may be a qr// or a string; an undef
# cell never matches (mirroring the string comparisons).

my $aoh = [
	{ id => '5iz1', res => 1.8 },
	{ id => '5iz9', res => 3.0 },
	{ id => '1abc', res => 2.0 },
	{ id => '25iz', res => 1.0 },   # '5iz' present but not at the start
	{ res  => 1.0 },                # undef id
];
sub ids { join ',', map { defined $_->{id} ? $_->{id} : 'undef' } @{ $_[0] } }

is( ids(filter($aoh, col('id')->match(qr/^5iz/))), '5iz1,5iz9',
	'match(qr//) anchors at start' );
is( ids(filter($aoh, col('id')->match('^5iz'))), '5iz1,5iz9',
	'match accepts a string pattern' );
is( ids(filter($aoh, col('id')->match(qr/iz/))), '5iz1,5iz9,25iz',
	'match anywhere in the cell' );

# nomatch keeps the non-matching rows and drops undef (like `ne`)
is( ids(filter($aoh, col('id')->nomatch(qr/^5iz/))), '1abc,25iz',
	'nomatch keeps non-matches, drops undef' );
is( ids(filter($aoh, col('id')->nomatch('^5iz'))), '1abc,25iz',
	'nomatch accepts a string pattern' );

# ! match is the logical negation of the predicate, so (unlike nomatch) it
# KEEPS the undef row, since match() returns false there.
is( ids(filter($aoh, !(col('id')->match(qr/^5iz/)))), '1abc,25iz,undef',
	'!match negates the predicate (keeps undef)' );

# An empty pattern matches every defined cell, as it does in R 4.6.2, where
# grepl("", c("5iz1", "1abc", NA)) is TRUE TRUE FALSE, and in pandas 3.0.4,
# where pd.Series(["5iz1", "1abc", None]).str.contains("") is [True, True,
# None]. Before perl 5.18 the match operator does not match an empty qr// as
# written: it reuses the last pattern that matched successfully, and until
# 0.3422 ->match handed it the pattern as it came. Each filter here follows a
# successful match of /^25/, which only '25iz' passes, so an old perl without
# the fix keeps that one row for ->match and the other three for ->nomatch.
for my $c ([ 'qr//', qr// ], [ 'qr//i', qr//i ], [ "''", '' ]) {
	my ($what, $pat) = @$c;
	'25iz' =~ /^25/ or die 'the match that arms the old perls failed';
	is( ids(filter($aoh, col('id')->match($pat))), '5iz1,5iz9,1abc,25iz',
		"match($what) keeps every defined cell" );
	is( ids(filter($aoh, col('id')->nomatch($pat))), '',
		"nomatch($what) keeps nothing" );
	is( ids(filter($aoh, !(col('id')->match($pat)))), 'undef',
		"!match($what) keeps only the undef row" );
	is( ids(filter($aoh, col('id')->match($pat) & (col('res') < 2.5))), '5iz1,1abc,25iz',
		"match($what) & numeric comparison" );
}

# composition with & and |
is( ids(filter($aoh, col('id')->match(qr/^5iz/) & (col('res') < 2.5))), '5iz1',
	'match & numeric comparison' );
is( ids(filter($aoh, col('id')->match(qr/^1/) | col('id')->match(qr/^2/))), '1abc,25iz',
	'match | match' );

# other shapes
{
	my $hoa = { id => [ '5iz1', '1abc', '5iz2' ], v => [ 1, 2, 3 ] };
	my $r = filter($hoa, col('id')->match(qr/^5iz/));
	is_deeply( $r->{id}, [ '5iz1', '5iz2' ], 'HoA: match' );
	is_deeply( $r->{v},  [ 1, 3 ],           'HoA: match carries sibling column' );
}
{
	my $hoh = { r1 => { id => '5iz1' }, r2 => { id => '1abc' }, r3 => { id => '5iz2' } };
	my $r = filter($hoh, col('id')->nomatch(qr/^5iz/));
	is_deeply( [ sort keys %$r ], [ 'r2' ], 'HoH: nomatch on the outer-keyed rows' );
}

# error paths
throws_ok { my $p = (col('x') > 3); $p->match(qr/y/) }
	qr/bare column/, 'match on a built predicate dies';
throws_ok { col('x')->match() }
	qr/needs a pattern/, 'match without a pattern dies';
throws_ok { col('x')->nomatch(undef) }
	qr/needs a pattern/, 'nomatch with an undef pattern dies';

# input frame is never mutated
{
	my @orig = ( { id => '5iz1' }, { id => '1abc' } );
	my $snap = [ map { { %$_ } } @orig ];
	filter(\@orig, col('id')->match(qr/^5iz/));
	is_deeply( \@orig, $snap, 'filter with ->match does not mutate input' );
}

if ($INC{'Devel/Cover.pm'}) { done_testing(); exit 0 }
# The qr// is compiled outside the block on purpose: perl 5.10.0 leaks one SV
# per qr// evaluation. pp_qr() takes the package name from reg_qr_package(),
# which is a newSVpvs("Regexp"), and never releases it; the SvREFCNT_dec(pkg)
# that fixes it is in 5.10.1's pp_hot.c. A CPAN smoker on perl-5.10.0
# (x86_64-linux) failed 0.315 here with a leaked PV "Regexp", which is that SV
# and not anything filter() or ->match did.  ->match takes a precompiled qr//
# as-is, so the path under test is unchanged.
my $re_5iz = qr/^5iz/;
no_leaks_ok {
	my $r = filter($aoh, col('id')->match($re_5iz) & (col('res') < 2.5));
} 'col()->match: no memory leaks';
# an empty pattern is exchanged for a kept one, which compiles nothing
my $re_empty = qr//;
no_leaks_ok {
	my $r = filter($aoh, col('id')->match($re_empty));
} 'col()->match with an empty pattern: no memory leaks';
no_leaks_ok {
	eval { col('x')->match() };
} 'col()->match: no leaks on the die path';

done_testing;
