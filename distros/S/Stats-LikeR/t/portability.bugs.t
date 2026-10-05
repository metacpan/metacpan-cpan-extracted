#!/usr/bin/env perl
# Regressions for the portability and undefined-behaviour fixes in 0.31.
#
# None of these needs a reference implementation: each asserts a shape the C
# either produces or does not.  What they have in common is that all of them
# passed on the machine they were written on and would have failed elsewhere,
# which is why they are pinned from Perl rather than left to a code reading.
#
# 1. %zu.  Nine plain snprintf() calls used the C99 %zu length modifier.  It
#    is not implemented by MSVC's older CRT, which prints the literal text
#    instead, and two of the nine build hash KEYS rather than messages -- so
#    on such a build every column of a csort() conversion would have been
#    stored under the same key "zu" and all but one would have been lost.  The
#    rest are a group label that is returned to the caller and several croak
#    texts.  All nine now use my_snprintf() with UVuf, the modifier Configure
#    picked for this build's UV.
#
#    A Linux CRT implements %zu, so these tests could not have failed here
#    before the change.  They are here because they will fail on a CRT that
#    does not, which is exactly the platform no local run covers.
#
# 2. Zero-length calls on NULL pointers.  qsort() and memcmp() are both
#    declared with non-null pointer arguments whatever the count, so passing
#    NULL is undefined even for zero elements -- UBSan reports it, and a
#    compiler may infer non-nullness and delete a later check.  p_adjust()
#    reached qsort(NULL, 0) whenever no row hash had any keys, and
#    drop_duplicates() reached memcmp(NULL, NULL, 0) when every key so far
#    had been zero-length.  Both are reachable from one line of Perl.
#
# 3. ssize_t.  Seven declarations used the POSIX spelling, which perl does not
#    define and MSVC does not ship: the file only compiled because glibc
#    supplies it.  They are SSize_t (or size_t where the value is a length)
#    now.  That is a compile-time property with nothing to assert from Perl;
#    it is noted here so the reason is recorded with the rest.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 23;
use lib 'blib/lib', 'blib/arch';
use Stats::LikeR qw(csort oneway_test prop_test p_adjust drop_duplicates);

# --- 1. %zu: hash keys built from a column index -------------------------
# csort() converting an AoA names the columns "0" .. "ncols-1".  With a
# broken format every column collides on one key and the frame loses columns.
{
	my $aoh = csort([[3, 'c'], [1, 'a'], [2, 'b']], 0, 'aoh');
	is(scalar @$aoh, 3, 'csort AoA->AoH: row count');
	is_deeply([sort keys %{ $aoh->[0] }], ['0', '1'],
	          'csort AoA->AoH: column keys are "0" and "1", not "zu"');
	is($aoh->[0]{0}, 1, 'csort AoA->AoH: sorted first row, column 0');
	is($aoh->[0]{1}, 'a', 'csort AoA->AoH: sorted first row, column 1');

	my $hoa = csort([[3, 'c'], [1, 'a'], [2, 'b']], 0, 'hoa');
	is_deeply([sort keys %$hoa], ['0', '1'],
	          'csort AoA->HoA: column keys are "0" and "1", not "zu"');
	is_deeply($hoa->{0}, [1, 2, 3],   'csort AoA->HoA: column 0 permuted');
	is_deeply($hoa->{1}, ['a','b','c'], 'csort AoA->HoA: column 1 permuted');
}

# A wider frame, so a collision cannot hide behind a two-column example.
{
	my @rows = map { [ $_, $_ + 1, $_ + 2, $_ + 3, $_ + 4 ] } (3, 1, 2);
	my $hoa = csort(\@rows, 0, 'hoa');
	is_deeply([sort { $a <=> $b } keys %$hoa], [0, 1, 2, 3, 4],
	          'csort AoA->HoA: five distinct column keys');
}

# --- 1b. %zu: a group label returned to the caller -----------------------
{
	my $o = oneway_test([[1,2,3], [4,5,7], [8,9,11]]);
	is_deeply([sort keys %{ $o->{'group_stats'}{size} }],
	          ['Index 0', 'Index 1', 'Index 2'],
	          'oneway_test: group labels number themselves');
	is($o->{'group_stats'}{size}{'Index 0'}, 3, 'oneway_test: group 0 size');
}

# --- 1c. %zu: counts inside croak text -----------------------------------
{
	my $e = '';
	eval { oneway_test({ v => [1,2,3,4], g => ['a','a','a','a'] },
	                   formula => 'v ~ g') } or $e = $@;
	like($e, qr/need at least 2 distinct groups, found 1\b/,
	     'oneway_test: distinct-group count reaches the message');

	$e = '';
	eval { oneway_test({ v => [1,2,3], g => ['a','a','b'] },
	                   formula => 'v ~ g') } or $e = $@;
	like($e, qr/group 'b' has only 1 observation\(s\)/,
	     'oneway_test: per-group count reaches the message');
}

# --- 1d. %zu: the sample count in prop_test's method string --------------
{
	for my $k (1, 2, 3, 5) {
		my @counts = map { $_ * 3 + 5 } 1 .. $k;
		my @ns     = map { 100 } 1 .. $k;
		my $p = prop_test(\@counts, \@ns);
		if ($k == 1) {
			like($p->{method}, qr/^1-sample proportions test\b/,
			     "prop_test: k=$k method names the sample count");
		} else {
			like($p->{method}, qr/^$k-sample test for /,
			     "prop_test: k=$k method names the sample count");
		}
	}
}

# --- 2. zero-length calls on NULL pointers -------------------------------
# Each of these reached a qsort()/memcmp() with a null pointer and a count of
# zero.  On glibc that happens to work, so the assertion is only that they
# still do the right thing -- a UBSan build is what makes the fix visible,
# and the suite is run under one.
{
	my $r = p_adjust([{}, {}]);
	ok(defined $r, 'p_adjust on rows with no columns returns');
	is(ref $r, 'ARRAY', 'p_adjust on rows with no columns returns a frame');
	is(scalar @$r, 2, 'p_adjust on rows with no columns keeps both rows');
	is_deeply($r->[0], {}, 'p_adjust leaves an empty row empty');

	my $d = drop_duplicates([{}, {}]);
	is(scalar @$d, 1, 'drop_duplicates collapses two empty rows to one');

	my $d2 = drop_duplicates([{}, {}, {}, {}]);
	is(scalar @$d2, 1, 'drop_duplicates collapses four empty rows to one');

	# a zero-length key alongside a real one: the same memcmp, n == 0, but
	# with T->buf allocated, so it exercises the guard rather than the NULL
	my $d3 = drop_duplicates([{ '' => 1 }, { '' => 1 }, { '' => 2 }]);
	is(scalar @$d3, 2, 'drop_duplicates distinguishes rows under a "" key');
}
