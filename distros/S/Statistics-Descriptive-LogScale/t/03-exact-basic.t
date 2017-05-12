#!/usr/bin/perl -w

use strict;
use Test::More;

use Statistics::Descriptive::LogScale;

my $inf = 9 ** 9 ** 9;

my $stat = Statistics::Descriptive::LogScale->new( floor => 1, base => 2);

$stat->add_data(-2, 0, 0, 4, 8);

is ($stat->count, 5, "count");
is ($stat->mean, 2, "mean");
is ($stat->median, 0, "median");
is ($stat->sumsq, 84, "sumsq");
is ($stat->min, -2, "min");
is ($stat->max, 8, "max");

is ($stat->_count(-4), 0,   "count < left");
is ($stat->_count(-2), 0.5, "count(-2)");
is ($stat->_count(0),  2,   "count(0)");
is ($stat->_count(2),  3,   "count(2)");
is ($stat->_count(4),  3.5, "count(4)");
is ($stat->_count(8),  4.5, "count(8)");
is ($stat->_count(16), 5,   "count > right");

is ($stat->_count($stat->_lower(-2)), 0, "Count(lower(min)) = 0");
is ($stat->_count($stat->_upper(8)), 5, "Count(upper(max)) = count");
is ($stat->_count(0,2), 1, "count( 2 args )");

is ($stat->cdf(-$inf), 0, "CDF(-inf) = 0");
is ($stat->cdf(+$inf), 1, "CDF(+inf) = 1");
is ($stat->cdf(0), 0.4, "CDF(0) = 0.4");
is ($stat->cdf(0, 16), 0.6, "CDF(0, inf) = 1-CDF(0)");
note "The rest of CDF is tested by _count";

my $hash = $stat->get_data_hash;
is_deeply( $hash, { -2 => 1, 0 => 2, 4=>1, 8=>1 }, "as_hash" );

my $stat2 = Statistics::Descriptive::LogScale->new( floor => 1, base => 2);
$stat2->add_data_hash($hash);

foreach my $method (qw(count mean median sumsq min max)) {
	is ($stat2->$method, $stat->$method, "data round trip: $method");
};
is_deeply($stat2->get_data_hash, $hash, "data round trip: hash");

note explain $stat->{cache};
$stat->add_data(1, 1);
ok (!exists $stat->{cache}, "Cache deleted on add");

done_testing;
