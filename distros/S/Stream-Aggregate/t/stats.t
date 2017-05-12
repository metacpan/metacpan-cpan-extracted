#!/usr/bin/perl -Ilib -I../lib -I../../uri-hostportion/lib

use strict;
use Stream::Aggregate::Stats;
use Test::More qw(no_plan);

my $finished = 0;
END { ok $finished, "finished" }

my %data = (
	foo => [ qw( 3 7 7 19) ],
	bar => [ qw( 16 17 18 19 20 ) ], 
	baz => [ qw( 16 17 18 19 20 21 ) ], 
	house_rem => [ qw( 10 20 30 40 50 ) ],
	'/' => [ qw( 1 2 10 20 30 40 10001 ) ],
	house => [ qw( 10003 10004 11010 11500 30 11300 11400 20 11100 11200 10005 10 10006 10007 50 40 10084 ) ],
	docrank => [ 0.3e-37, 0.4e-34, 1.2e-20, 1.9e-25, 9.3e-22, 9.4e-30, 8.2e-25 ],
	url_depth => [ 3, 2, 2, 2, 4, 5, 5, 5, 5 ],
	dist => [ 423, 473, 597, 507 ],
);


local($Stream::Aggregate::Stats::ps) = { keep => \%data };

is(mean('foo'), 9, 'mean foo');
is(standard_deviation('foo'), 6, 'standard deviation foo');
is(percentile(baz => 80), 20, 'simple percentile');
is(percentile(baz => 82), 20.1, 'interpolated percentile');
is(percentile(baz => 100), 21, '100th percentile');
is(percentile(baz => 0), 16, '0th percentile');
is(median('foo'), 7, 'median foo');
is(median('bar'), 18, 'median bar');
is(smallest('foo'), 3, 'smallest foo');
is(largest('foo'), 19, 'smallest foo');
is(dominant('foo'), 7, 'dominant foo');

# the following are just using this test module as a calculator
# for generating numbers for aggregation tests

is(dominantcount('foo'), 2, 'dominantcount foo');
is(sprintf("%.8f", standard_deviation('house_rem')), 14.14213562, 'standard deviation - house_rem');
is(sprintf("%.8f", standard_deviation('/')), 3493.63919378, 'standard deviation - /');
is(sprintf("%.8f", mean('house')), 7515.82352941, 'mean house');
is(sprintf("%.9g", mean('docrank')), 1.84728714e-21, 'mean docrank');
is(sprintf("%.9g", standard_deviation('docrank')), 4.15722456e-21, 'stddev docrank');
is(sprintf("%.8f", mean('url_depth')), 3.66666667, 'url_depth');
is(median('url_depth'), 4, 'url_depth');
is(sprintf("%.8f", standard_deviation('dist')), 63.47440429, 'std_dist');

$finished = 1;
