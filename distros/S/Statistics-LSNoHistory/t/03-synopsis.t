#!/usr/bin/perl
# 03-synopsis.t - check Statistics::LSNoHistory pod synopsis
#
# $Id: 03-synopsis.t,v 1.1 2003/02/23 05:19:39 pliam Exp $
#

use strict;
use Test::More 'no_plan';
BEGIN { use_ok('Statistics::LSNoHistory'); }

## declare class and a few regression objects
my $class = 'Statistics::LSNoHistory';
my ($r1, $r2, $r3, $r4, $r5, $branch);

## declare stats and accessors
my @stats = qw(num sumx sumy sumxx sumyy sumxy);
push(@stats, qw(minx maxx miny maxy)); # min/max
my %empty; @empty{@stats} = (0) x scalar(@stats);
my @methods = qw(average_x average_y variance_x variance_y slope intercept);
push(@methods, qw(slope_y intercept_y pearson_r chi_squared));
push(@methods, qw(minimum_x maximum_x minimum_y maximum_y));

# construct from points
$r1 = Statistics::LSNoHistory->new(points => [
	1.0 => 1.0,
	2.1 => 1.9,
	2.8 => 3.2,
	4.0 => 4.1,
	5.2 => 4.9
]);

## dump the stats
my $dump = $r1->dump_stats;
for (@stats) {
	diag(sprintf("%s => %f", $_, $dump->{$_}));
}

# other equivalent constructions
$r2 = Statistics::LSNoHistory->new(
	xvalues => [1.0, 2.1, 2.8, 4.0, 5.2],
	yvalues => [1.0, 1.9, 3.2, 4.1, 4.9]
);
# or
$r3 = Statistics::LSNoHistory->new;
$r3->append_arrays(
	[1.0, 2.1, 2.8, 4.0, 5.2],
	[1.0, 1.9, 3.2, 4.1, 4.9]
);
# or
$r4 = Statistics::LSNoHistory->new;
$r4->append_points(
	1.0 => 1.0, 2.1 => 1.9, 2.8 => 3.2, 4.0 => 4.1, 5.2 => 4.9
);

# You may also construct from the preliminary statistics of a 
# previous regression:
$r5 = Statistics::LSNoHistory->new(
	num => 5,
	sumx => 15.1,
	sumy => 15.1,
	sumxx => 56.29,
	sumyy => 55.67,
	sumxy => 55.83,
	minx => 1.0,
	maxx => 5.2,
	miny => 1.0,
	maxy => 4.9
);

## check that these really are equivalent
for my $m (@methods) {
	diag(sprintf("%s = %f\n", $m, $r1->$m));
	is(sprintf("%.10f", $r1->$m), sprintf("%.10f", $r2->$m), 
		"$m: r1 = r2");
	is(sprintf("%.10f", $r1->$m), sprintf("%.10f", $r3->$m), 
		"$m: r1 = r3");
	is(sprintf("%.10f", $r1->$m), sprintf("%.10f", $r4->$m), 
		"$m: r1 = r4");
	is(sprintf("%.10f", $r1->$m), sprintf("%.10f", $r5->$m), 
		"$m: r1 = r5");
}

# thus a branch may be instantiated as follows
$branch = Statistics::LSNoHistory->new(%{$r5->dump_stats});
for my $m (@methods) {
	diag(sprintf("%s = %f\n", $m, $r5->$m));
	is(sprintf("%.10f", $r5->$m), sprintf("%.10f", $branch->$m), 
		"$m: r5 = branch");
}
$r5->append_point(6.1, 5.9);
$branch->append_point(5.8, 6.0);
ok(!eq_hash($r5->dump_stats, $branch->dump_stats), 
	'branch is different after separate appends');

# calculate regression values, print some
is(sprintf("%.6f", $r1->slope), '0.956961', 'slope');
is(sprintf("%.6f", $r1->intercept), '0.129978', 'intercept');
is(sprintf("%.6f", $r1->pearson_r), '0.985986', 'pearson r');
