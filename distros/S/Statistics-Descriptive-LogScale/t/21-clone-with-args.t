#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new(
	base => 1.01, linear_width => 0.125 );

$stat->add_data(1..10);

my $stat2 = $stat->clone( min => 5.5 );

is ($stat2->count, 5, "Half data expected" );
is ($stat2->log_base, $stat->log_base, "Base copied");

my $stat3 = $stat->clone( data => undef );
$stat3->add_data( 6..10 );
is_deeply( $stat2, $stat3, "Multiple clones get the same (data => undef)" );

my $stat4 = $stat->clone( data => { 6=>1, 7=>1, 8=>1, 9=>1, 10=>1 } );
is_deeply( $stat2, $stat4, "Multiple clones get the same (data => {})" );

my $stat_noize = Statistics::Descriptive::LogScale->new;
$stat_noize->add_data( -1, 0, 0, 0, 1 );
my $stat_wo_noize = $stat_noize->clone( noize_thresh => 2 );
is ($stat_wo_noize->count, 3, "3 elements after noize trim" );
is_deeply ($stat_wo_noize->get_data_hash, { 0 => 3 }, "all zero");

done_testing;
