#!/usr/bin/perl
# 02-vnr.t - check Statistics::LSNoHistory against data in VNR
#
# $Id: 02-vnr.t,v 1.2 2003/02/23 05:11:31 pliam Exp $
#

# Check the regression calculation against that from the book 
# "VNR Concise Encyclopedia of Mathematics", 1975.
# It turns out that these data are slightly inaccurate,
# but serve as a sanity check.

use strict;
use Test::More 'no_plan';
BEGIN { use_ok('Statistics::LSNoHistory'); }

my @xy = (
	135, 29.30,
	145, 35.20,
	139, 34.50,
	142, 32.10,
	137, 33.60,
	137, 32.30,
	134, 27.20,
	144, 36.70,
	135, 26.90,
	146, 38.20
);
my $r = Statistics::LSNoHistory->new(points => \@xy); 
my $class = 'Statistics::LSNoHistory';
isa_ok($r, $class, 'correct object type');
is($r->average_x, 139.4, 'x average');
is($r->average_y, 32.6, 'y average'); # 32.61 in book is clearly wrong
is(sprintf("%.4f", $r->variance_x), '20.2667', 'x variance');
is(sprintf("%.4f", $r->variance_y), '14.7133', 'y variance'); # 14.8 implicit
is(sprintf("%.3f", $r->slope), '0.742', 'slope'); # 0.746 in book
is(sprintf("%.2f", $r->intercept), '-70.88', 'intercept'); # -71.38 in book 
is(sprintf("%.3f", $r->slope_y), '1.023', 'y slope'); # 1.019 in book
is(sprintf("%.1f", $r->intercept_y), '106.1', 'y intercept'); # 106.2 in book
is(sprintf("%.2f", $r->pearson_r), '0.87', 'r');
is($r->minimum_x, 134.0, 'x min');
is($r->maximum_x, 146.0, 'x max');
is($r->minimum_y, 26.9, 'y min');
is($r->maximum_y, 38.2, 'y max');
