#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new;
$stat->add_data( 1..100 );

my $stat2 = Statistics::Descriptive::LogScale->new;
$stat2->add_data( 1..100 ) for 1..64;
$stat2->scale_sample(1/64); # 1/64 is whole number from CPU's POW

is_deeply ($stat2->get_data_hash, $stat->get_data_hash, "Same data ret");
cmp_ok ( $stat2->count, "==", 100, "Count as expected");
