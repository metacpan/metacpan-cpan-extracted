#!perl -T

use strict;
use warnings;

use Net::Dogstatsd;

# Create an object to communicate with Dogstatsd, using default server/port settings.
my $dogstatsd = Net::Dogstatsd->new(
	host    => 'localhost',  #optional. Default = 127.0.0.1
	port    => '8125',       #optional. Default = 8125
	verbose => 0,            #optional. Default = 0
);

# Set, and print, the 'verbose' option value.
$dogstatsd->verbose(1);
print "In verbose mode." if $dogstatsd->verbose();

# Before we can start sending metrics, we have to get or create a socket to dogstatsd
my $socket = $dogstatsd->get_socket();

# Counter metrics can be incremented or decremented
# By default, they will be incremented or decremented by 1, unless the optional
# 'value' parameter is passed
$dogstatsd->increment(
	name  => 'test_metric.sample_counter',
	value => $increment_value, #optional; default = 1
	tags  => [ 'env:production', db ], #optional
);

$dogstatsd->decrement(
	name  => $metric_name,
	value => $decrement_value, #optional; default = 1
	tags  => [ 'env:devel', web ], #optional
);


# Gauge metrics can be used for capturing value of something over time
# Example: Gas gauge, inventory level, free memory
$dogstatsd->gauge(
	name  => 'test_metric.inventory_level',
	value => $gauge_value, #required - must be a number
	tags  => [ 'warehouse:us' ], #optional
);


# Histogram metrics measure the statistical distribution of a set of values.
# Provides min/max/avg as well as 75th, 85th, 95th and 99th percentiles.
# NOTE: do not use this for timers. Use timer() instead.
$dogstatsd->histogram(
	name  => $metric_name,
	value => $value,
	tags  => [ 'tag1', 'tag2:value', 'tag3' ], #optional
);


# Timers are a special type of histogram. 
$dogstatsd->timer(
	name  => $metric_name,
	value => $metric_value,
	unit  => $metric_unit, # 'ms' (milliseconds) or 's|sec' (seconds)
	tags  => [ 'tag1', 'tag2:value', 'tag3' ], #optional
);


# Set metrics are special counters that can track unique elements in a group.
# Example: the number of unique visitors currently on a website
$dogstatsd->sets(
	name  => 'unique.site_visitors',
	value => $account_id,
	tags  => [ 'referer:Google' ], #optional
);
	