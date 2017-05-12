#!/home/y/bin/perl
use strict;
use lib qw (/homes/yunfang/work/yahoo/jupiter/Metric);
use Statistics::PointEstimation;
use Statistics::RVGenerator;
use POSIX;

my $stat = new Statistics::PointEstimation::Sufficient;
$stat->set_significance(99);
$stat->load_data(30,3.996,1.235);
$stat->output_confidence_interval();
$stat->set_significance(95);
$stat->output_confidence_interval();





