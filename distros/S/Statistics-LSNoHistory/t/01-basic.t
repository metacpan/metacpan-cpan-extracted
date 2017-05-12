#!/usr/bin/perl
# 01-basic.t - simple tests for Statistics::LSNoHistory
#
# $Id: 01-basic.t,v 1.3 2003/02/23 05:11:31 pliam Exp $
#

use strict;
use Test::More 'no_plan';
BEGIN { use_ok('Statistics::LSNoHistory'); }

## declare class and a few regression objects
my $class = 'Statistics::LSNoHistory';
my ($r1, $r2, $r3, $r4, $r5);
## declare stats and accessors
my @stats = qw(num sumx sumy sumxx sumyy sumxy);
push(@stats, qw(minx maxx miny maxy)); # min/max
my %empty; @empty{@stats} = (0) x scalar(@stats);
my @methods = qw(average_x average_y variance_x variance_y slope intercept);
push(@methods, qw(slope_y intercept_y pearson_r chi_squared));
push(@methods, qw(minimum_x maximum_x minimum_y maximum_y));

## default construction
ok(defined($r1 = Statistics::LSNoHistory->new), 'default constructor');
isa_ok($r1, $class, 'correct object type');
ok(eq_hash($r1->dump_stats, \%empty), 'zero values from default const.');

## append a single point, check the dump
$r1->append_point(1.1, 2.2);
my $dump = $r1->dump_stats;
ok(!eq_hash($dump, \%empty), 'nonzero values after point appended');
is($dump->{num}, 1, '1pt num check');
is($dump->{sumx}, 1.1, '1pt sumx check');
is($dump->{sumy}, 2.2, '1pt sumy check');
is($dump->{sumxx}, 1.21, '1pt sumxx check');
is($dump->{sumyy}, 4.84, '1pt sumyy check');
is($dump->{sumxy}, 2.42, '1pt sumxy check');
ok(eq_array([$dump->{minx}, $dump->{maxx}], [1.1, 1.1]), '1pt x min/max');
ok(eq_array([$dump->{miny}, $dump->{maxy}], [2.2, 2.2]), '1pt y min/max');
eval { $r1->average_x; };
like($@, qr/^Must have at least 2/, "won't regress 1 point");

## append another point and sanity check numbers
$r1->append_point(2.2, 4.4);
$dump = $r1->dump_stats; # dump again
ok(!eq_hash($dump, \%empty), 'nonzero values after 2-points');
is($dump->{num}, 2, '2pt num check');
is($dump->{sumx}, 3.3, '2pt sumx check');
is($dump->{sumy}, 6.6, '2pt sumy check');
is($dump->{sumxx}, 6.05, '2pt sumxx check');
is($dump->{sumyy}, 24.2, '2pt sumyy check');
is($dump->{sumxy}, 12.1, '2pt sumxy check');
is($dump->{minx}, 1.1, '2pt minx check');
is($dump->{maxx}, 2.2, '2pt maxx check');
is($dump->{miny}, 2.2, '2pt miny check');
is($dump->{maxy}, 4.4, '2pt maxy check');
is($r1->average_x, 1.65, '2py x average check');
is($r1->average_y, 3.3, '2pt y average check');
is($r1->variance_x, 0.605, '2pt x variance check');
is($r1->variance_y, 2.42, '2pt y variance check');
is($r1->slope, 2.0, '2pt slope check');
is($r1->intercept, 0.0, '2pt intercept check');
is($r1->slope_y, 0.5, '2pt y-slope check');
is($r1->intercept_y, 0.0, '2pt y-intercept check');
is($r1->pearson_r, 1.0, '2pt Pearson r check (perfect correlation)');
is($r1->chi_squared, 0.0, '2pt chi squared check');

## generate random line and construct in 2 ways
my @x = (0..9);
my @y = (0..9);
my @xy = ();
srand(314159^time);
# srand(314159);
map { $_ = int(rand(100))/10.0 } @x;
map { $_ = 2.2 + $x[$_]/2.2 + int(100*rand(0.1))/100.0 } @y;
for (0..9) { push(@xy, $x[$_], $y[$_]); } 
$r2 = Statistics::LSNoHistory->new(xvalues => \@x, yvalues => \@y); 
ok(defined($r2), 'x and y array value constructor');
isa_ok($r2, $class, 'correct object type');
ok(!eq_hash($r2->dump_stats, \%empty), 'nonzero values from constructor');
$r3 = Statistics::LSNoHistory->new(points => \@xy);
ok(defined($r3), '(x,y) point array constructor');
isa_ok($r3, $class, 'correct object type');
ok(!eq_hash($r3->dump_stats, \%empty), 'nonzero values from constructor');
my $d2 = $r2->dump_stats;
my $d3 = $r3->dump_stats;
unless (ok(eq_hash($d2, $d3), 'the 2 array constructors are equivalent')) {
	diag("Here is a dump of the stat values (which should be equal):");
	diag(sprintf("r2 => (%s)", join(',', @$d2{@stats})));
	diag(sprintf("r3 => (%s)", join(',', @$d3{@stats})));
}
unless (isnt($r2->pearson_r, 1.0, 'non-perfect correlation')) {
	diag(sprintf("Pearson's r = %f", $r2->pearson_r));
}
for my $m (@methods) {
	unless (is($r2->$m, $r3->$m, "regression method $m agree")) {
		diag(sprintf("\$r2->%s = %f\n", $m, $r2->$m));
		diag(sprintf("\$r3->%s = %f\n", $m, $r2->$m));
	}
}
for my $m (@methods) {
	diag(sprintf("\$r2->%s = %f\n", $m, $r2->$m));
}

## generate a random *perfect* line and check correlation
@x = (0..9);
@y = (0..9);
map { $_ = int(rand(100))/10.0 } @x;
map { $_ = 2.2 - $x[$_]/2.2 } @y;
$r4 = Statistics::LSNoHistory->new(xvalues => \@x, yvalues => \@y); 
isa_ok($r4, $class, 'correct object type');
my $pear = sprintf("%.6f", $r4->pearson_r);
unless (is($pear, '-1.000000', 'perfect correlation to 6 digits')) {
	diag(sprintf("correlation coef: \$r4->%s = %f\n", 'pearson_r', 
		$r4->pearson_r
	));
}	
for my $m (@methods) {
	diag(sprintf("\$r4->%s = %f\n", $m, $r4->$m));
}
