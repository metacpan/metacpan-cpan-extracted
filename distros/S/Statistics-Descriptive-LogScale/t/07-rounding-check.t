#!/usr/bin/perl -w

use strict;
use Test::More;
use Data::Dumper;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new();
note Dumper($stat);

my @data = map { $_/100 } 1..200;

plan tests => scalar @data;
foreach (@data) {
	my ($l, $x, $m, $r) =
		($stat->_lower($_), $_, $stat->_round($_), $stat->_upper($_));
	ok ( $l <= $x && $x <= $r && $l < $m && $m < $r,
		"$l <= $x <= $r, $l < $m < $r" );
};

