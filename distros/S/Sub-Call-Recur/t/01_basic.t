#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ok 'Sub::Call::Recur' => qw(:all);

sub sum {
    my ( $n, $sum ) = @_;

    if ( $n == 0 ) {
        return $sum;
    } else {
        recur ( $n - 1, $sum + 1 );
    }
}

sub sum_alt {
	return $_[1] if $_[0] == 0;
	recur( $_[0] - 1, $_[1] + 1 );
}

sub fact {
    my ( $n, $accum ) = @_;

    $accum ||= 1;

    if ( $n == 0 ) {
        return $accum;
    } else {
        recur( $n - 1, $n * $accum );
    }
}

foreach my $sum ( \&sum, \&sum_alt ) {
    is( $sum->(0, 0), 0, "0 + 0" );
    is( $sum->(0, 1), 1, "0 + 1" );
    is( $sum->(1, 0), 1, "1 + 0" );
    is( $sum->(1, 1), 2, "1 + 1" );
    is( $sum->(2, 2), 4, "2 + 2" );
    is( $sum->(10, 1), 11, "10 + 1" );
    is( $sum->(1000, 1), 1001, "1000 + 1" );
}

is( fact(0), 1, "fact(0)" );
is( fact(1), 1, "fact(1)" );
is( fact(2), 2, "fact(2)" );
is( fact(3), 6, "fact(3)" );
is( fact(4), 24, "fact(4)" );
is( fact(5), 120, "fact(5)" );
is( fact(6), 720, "fact(6)" );

done_testing;

# ex: set sw=4 et:

