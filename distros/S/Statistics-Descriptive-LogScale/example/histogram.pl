#!/usr/bin/perl -w

# This is a simple script that reads numbers from STDIN
# and prints out a summary at EOF.

use strict;
my $can_size = eval { require Devel::Size; 1; };

# always prefer local version of module
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Statistics::Descriptive::LogScale;

my $base;
my $floor;
my $trim;

# Don't require module just in case
if ( eval { require Getopt::Long; 1; } ) {
	Getopt::Long->import;
	GetOptions (
		'base=s' => \$base,
		'floor=s' => \$floor,
		'trim=s' => \$trim,
		'help' => sub {
			print "Usage: $0 [--base <1+small o> --floor <nnn>] [<n>]\n";
			print "Read numbers from STDIN, output histogram\n";
			print "Number of sections = n (default 20)";
			exit 2;
		},
	);
} else {
	@ARGV and die "Options given, but no Getopt::Long support";
};
my $count = shift || 20;

my $stat = Statistics::Descriptive::LogScale->new(
	base => $base, zero_thresh => $floor);

# use proper regex pfor numbers
my $re_num = qr/(?:[-+]?(?:\d+\.?\d*|\.\d+)(?:[Ee][-+]?\d+)?)/;
while (<STDIN>) {
	$stat->add_data(/($re_num)/g);
};

print_result();

if ($can_size) {
	print "Memory usage: ".Devel::Size::total_size($stat)."\n";
};

sub print_result {
	printf "Count: %u\nAverage: %f +- %f\nRange: %f .. %f\n",
		$stat->count, $stat->mean, $stat->standard_deviation,
		$stat->min, $stat->max;

	my $hist = $stat->frequency_distribution_ref($count);
	my $max = 0;
	$_ > $max and $max = $_ for values %$hist;
	foreach (sort { $a <=> $b } keys %$hist) {
		printf "%10.3f: %8u | %s\n", $_, $hist->{$_},
			"#" x int (50 * $hist->{$_} / $max);
	};
};

