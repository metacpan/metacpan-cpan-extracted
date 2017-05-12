#!/usr/bin/perl -w

use strict;
use Test::More;
use Test::Number::Delta within => 1e-12;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new(
	zero_thresh => 0.125, base => 1.01
);

delta_ok ($stat->linear_threshold * 2, $stat->linear_width,
	"zero thresh given => linear thresh == linear width");
delta_ok ($stat->log_base, 1.01, "log_base()");

cmp_ok ($stat->linear_threshold, "<=", 0.125, "floor");
cmp_ok ($stat->linear_threshold, ">", 0, "floor");
delta_ok ($stat->bucket_width, 0.01, "Bucket width as expected");

$stat->add_data($stat->linear_threshold / 2);
$stat->add_data(-$stat->linear_threshold / 2);
my $raw = $stat->get_data_hash;
is_deeply ($raw, { 0 => 2 }, "2 subzero values => 0,0")
	or diag "Returned raw data = ".explain($raw);

my $stat2 = Statistics::Descriptive::LogScale->new(
	linear_threshold => 1, base => 1.1 );
delta_ok( $stat2->linear_threshold, $stat2->linear_width*11,
	 "linear_width deduced from linear_threshold correctly");

done_testing;
