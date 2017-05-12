#! /usr/bin/env perl

use strict;
use Test;

BEGIN { plan tests => 8 };

use Statistics::OnLine;
ok(1); # If we made it this far, we're loaded.

my $s = Statistics::OnLine->new;
ok( $s );

my @data = (1, 2, 3, 4, 5);
$s->add_data( @data );
ok( $s->mean() == 3 );

$s->add_data( 6, 7 )->add_data( 8 );
$s->add_data( ); # does nothing!
$s->add_data( 9, 10 );
$s->add_data( 1, 10, 10, 10 );
ok( $s->skewness < 0 );

$s->clean;
ok( $s->count == 0 );

$s->clean->add_data( 1, 1, 1, 10 );
ok( $s->skewness > 0 );

$s->clean->add_data( 1, 3, 3, 3, 5 );
my $k1 = $s->kurtosis;

$s->clean->add_data( 1, 1, 3, 5, 5 );
my $k2 = $s->kurtosis;

ok( $k2 < $k1 );

$s->clean->add_data( 0, 0, 0, 0, 0 );
$s->clean->add_data( );
ok( $s->count == 0 );

# -*- mode: perl -*-
