#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new(
	linear_width => 1, only_linear => 1);

$stat->add_data(10001..10005);

is_deeply($stat->get_data_hash
	, { 10001=>1, 10002=>1, 10003=>1, 10004=>1, 10005 =>1 }
	, "Precise data preserved" );

is ($stat->mean, 10003, "stats work as expected");

$stat->add_data( ); # burn cache
	# TODO replace w/smth else if add_data checks for empty data
is_deeply( $stat->clone, $stat, "Clone works with new param" );

done_testing;
