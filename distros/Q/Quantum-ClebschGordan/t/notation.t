#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 55;
use Quantum::ClebschGordan;

foreach my $test (
	# [ notation, real ]
	[ '-1/2', -sqrt(1/2), -0.707106781186548 ],
	[ '-3/4', -sqrt(3/4), -0.866025403784439 ],
	[ '1/2', sqrt(1/2), 0.707106781186548 ],
	[ '3/4', sqrt(3/4), 0.866025403784439 ],
	[ undef, undef, undef ],
	[ '', '', '' ],
	[ 0, 0, 0 ],
	[ 1, 1, 1 ],
	[ -1, -1, -1 ],
	[ 4, 2, 2 ],
	[ -4, -2, -2 ],
    ){
  my ($n, $r, $r2) = @$test;
  my $nn = defined $n ? $n : 'undef';
  is( Quantum::ClebschGordan::notation2real($n), $r, "'$nn' notation->value" );
  is( Quantum::ClebschGordan::real2notation($r), $n, "'$nn' value->notation" );
  is( Quantum::ClebschGordan::notation2real($n), $r2, "'$nn' notation->value2" );
  is( Quantum::ClebschGordan::real2notation($r2), $n, "'$nn' value2->notation" );
  is( $r, $r2, "'$nn' reals match");
}

#eof#

