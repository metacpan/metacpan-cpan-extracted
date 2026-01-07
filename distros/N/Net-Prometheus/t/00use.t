#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;

require Net::Prometheus;

require Net::Prometheus::Types;

require Net::Prometheus::Gauge;
require Net::Prometheus::Counter;
require Net::Prometheus::Summary;
require Net::Prometheus::Histogram;

require Net::Prometheus::PerlCollector;
require Net::Prometheus::ProcessCollector;

# Each process collector should at least *compile* when not on its own host OS
require Net::Prometheus::ProcessCollector::linux;

pass( 'Modules loaded' );
done_testing;
