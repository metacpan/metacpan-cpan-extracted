#!/usr/bin/perl
# Copyright (c) 2011 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use warnings;
use strict;
use Test::More;
use Regexp::Common qw/Chess/;

my $re = $RE{Chess}{SAN};

sub gen_variants {
	my $base = shift;
	my $msg = shift;
	my $opts = shift;

	my %ret;

	$ret{$base} = $msg unless $opts->{onlycapture};

	if(! $opts->{nocapture}) {
		my $capture = $base;
		$capture =~ s/(?=[a-h][1-8]$|[a-h][1-8]=[NBQR]$)/x/;
		$ret{"$capture"} = "$msg (capture)";
		$ret{"$capture+"} = "$msg (capture+check)";
		$ret{"$capture#"} = "$msg (capture+checkmate)";
	}

	if(! $opts->{onlycapture}) {
		$ret{"$base+"} = "$msg (check)";
		$ret{"$base#"} = "$msg (checkmate)";
	}

	return %ret;
}

# N.b. Test::More escapes hashes (#) as they are otherwise
#      part of the TAP syntax (directive delimiter).

my %good = (
	gen_variants('Ka1', 'King moves'),
	gen_variants('Qh8', 'Queen moves'),
	gen_variants('a6', 'Pawn moves'),
	map({ gen_variants("a8=$_->[0]", "White pawn promotion to $_->[1]") }
		([qw/Q queen/], [qw/N knight/], [qw/B bishop/], [qw/R rook/])),
	map({ gen_variants("a1=$_->[0]", "Black pawn promotion to $_->[1]") }
		([qw/Q queen/], [qw/N knight/], [qw/B bishop/], [qw/R rook/])),
	gen_variants('O-O', 'Castling king side', {nocapture=>1}),
	gen_variants('O-O-O', 'Castling queen side', {nocapture=>1}),
	gen_variants('Bb2a3', 'Coordinate disambiguation, bishop'),
	gen_variants('Nbb3', 'File disambiguation, knight'),
	gen_variants('R5c3', 'File disambiguation, rook'),
	gen_variants('ba3', 'File disambiguation, pawn', {onlycapture=>1}),
	gen_variants('Rf8', 'Rook to f8 (no promotion)'),
	gen_variants('Qd1', 'Queen to d1 (no promotion)'),
);

my %bad = (
	gen_variants('i1', 'invalid file (pawn)'),
	gen_variants('h9', 'invalid rank (pawn)'),
	gen_variants('i0', 'invalid file and rank (pawn)'),
	gen_variants('a8=K', 'pawn promotion to king'),
	gen_variants('a8', 'pawn moves to rank 8 w/o promotion'),
	'' => 'empty string',
	'Qxxa3' => 'multiple capture characters',
	'Qxa3##' => 'multiple checkmate characters',
	'Qxa3++' => 'multiple check characters',
	'b1b2a3' => "three coordinates",
	'O-o' => "mixing capital and lower letters (castling)",
	'B2a' => "coordinates with wrong order",
);

plan tests => keys(%good) + keys(%bad) + 1;

my $undef;
ok(  /^$re$/, "Should match '$_' ($good{$_})")    for(keys %good);
ok(! /^$re$/, "Should not match '$_' ($bad{$_})") for(keys %bad );

{
	no warnings qw/uninitialized/;
	ok($undef !~ /^$re$/, "Should not match undef");
}

