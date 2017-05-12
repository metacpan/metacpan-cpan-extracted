#!/usr/bin/perl -w

# This script tests find_boundaries() method

use strict;
use Test::More;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new();

$stat->add_data( 1..10 );

my @bound;

@bound = $stat->find_boundaries;
is (scalar @bound, 2, "2 values");
cmp_ok( $bound[0], "<=", 1, "bound < sample" );
cmp_ok( $bound[1], ">=", 10, "bound > sample" );

@bound = $stat->find_boundaries( ltrim => 11, utrim => 11 );
is (scalar @bound, 2, "2 values");

# note explain $stat->_debug_bins;
cmp_ok( $bound[0], ">", 1, "bound > outliers" );
cmp_ok( $bound[1], "<", 10, "bound < outliers" );
cmp_ok( $bound[0], "==", $stat->percentile(11), "percentile(11)" );
cmp_ok( $bound[1], "==", $stat->percentile(89), "percentile(89)" );

done_testing;
