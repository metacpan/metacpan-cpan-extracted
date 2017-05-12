#!/usr/bin/perl -w

use strict;
use Test::More tests => 9 + 5*6;
use Data::Dumper;

my $inf = 9**9**9;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new(
	zero_thresh => 0.125, base => 2
);
note Dumper($stat);

is ($stat->_round(0.01), 0, "round(0)");
is ($stat->_round(-1), -1, "round(-1)");
is ($stat->_round(40), 32, "round(40)");

is ($stat->_lower($inf), $inf, "round inf");
is ($stat->_round($inf), $inf, "round inf");
is ($stat->_upper($inf), $inf, "round inf");

is ($stat->_lower(-$inf), -$inf, "round inf");
is ($stat->_round(-$inf), -$inf, "round inf");
is ($stat->_upper(-$inf), -$inf, "round inf");

foreach (0, 0.001, 1, -1, exp 3, -11, ) {
	note sprintf "%f =~ %f in [%f, %f]\n",
		$_, $stat->_round($_), $stat->_lower($_), $stat->_upper($_);
	cmp_ok ($stat->_lower($_), "<=", $_, "floor< $_");
	cmp_ok ($stat->_upper($_), ">=", $_, "ceil > $_");
	cmp_ok ($stat->_lower($_), "<", $stat->_round($_), "floor<round $_");
	cmp_ok ($stat->_upper($_), ">", $stat->_round($_), "ceil >round $_");

	if ($stat->_round($_) > 0) {
		is ($stat->_upper($_) / $stat->_lower($_),
			1+$stat->bucket_width, "ceil/floor($_)");
	} elsif ( $stat->_round($_) == 0) {
		is ($stat->_upper($_) / $stat->_lower($_),
			-1, "ceil/floor($_)");
	} else {
		is ($stat->_lower($_) / $stat->_upper($_),
			1+$stat->bucket_width, "ceil/floor($_)");
	};
};
