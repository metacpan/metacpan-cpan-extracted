#!/usr/bin/env perl

# SUMMARY
#
# This is a script that demonstrates the very basic abilities
# of Statistics::Secriptive::LogScale.
#
# It reads numbers from STDIN or input files
# and adds them to statistical data pool
# then prints a summary with mean, median, percentiles etc.

use strict;
use warnings;

# We would to have some extra modules, but that's optional.
my $can_size   = eval { require Devel::Size; 1; };
my $can_getopt = eval { require Getopt::Long; 1; };

# Always prefer local version of our module
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Statistics::Descriptive::LogScale;

# These are our storage parameters
my $base;
my $linear;

# Parse options, if absolutely needed
my $want_options =  grep { qr/^-/ } @ARGV;

if ( $want_options ) {
	if (grep { $_ eq '--help' } @ARGV) {
		print "Usage: $0 [--base <1+small o> --precision <nnn>]\n";
		print "Read numbers from STDIN, output stat summary\n";
		print "NOTE that specifying options requires Getopt::Long";
		exit 1;
	};
	$can_getopt or die "Options given, but Getopt::Long not detected!";
	Getopt::Long->import;
	GetOptions (
		'base=s' => \$base,
		'precision=s' => \$linear,
	);
};

# HERE WE GO
# Initialize statistical storage
my $stat = Statistics::Descriptive::LogScale->new(
	base => $base, linear_width => $linear);

# Read input
# We want to catch scientific notation as well.
my $re_num = qr/(?:[-+]?(?:\d+\.?\d*|\.\d+)(?:[Ee][-+]?\d+)?)/;
while (<>) {
	$stat->add_data(/($re_num)/g);
};

# Print the most basic statistics. These can be done precisely in O(1) memory.
# See Statistics::Descriptive.
printf "Count: %u\nAverage/std. deviation: %f +- %f\nRange: %f .. %f\n",
	$stat->count, $stat->mean, $stat->standard_deviation,
	$stat->min, $stat->max;

# These two can be done in O(1) as well... But nobody does.
printf "Skewness: %f; kurtosis: %f\n",
	$stat->skewness, $stat->kurtosis;

# The following requires storing data in memory

# Trimmed mean is the average of data w/o outliers
# in this case, 25% lowest and 25% highest numbers were discarded
printf "Trimmed mean(0.25): %f\n",
	$stat->trimmed_mean(0.25);

# Print percentiles.
# Xth percentile is the point below which X% or data lies.
foreach (0.5, 1, 5, 10, 25, 50, 75, 90, 95, 99, 99.5) {
	my $x = $stat->percentile($_);
	$x = "-inf" unless defined $x;
	printf "%4.1f%%: %f\n", $_, $x;
};

# Print how much memory we used (if possible)
if ($can_size) {
	print "Memory usage: ".Devel::Size::total_size($stat)."\n";
};

