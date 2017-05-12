#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( 'Net::Prometheus' );

use_ok( 'Net::Prometheus::Types' );

use_ok( 'Net::Prometheus::Gauge' );
use_ok( 'Net::Prometheus::Counter' );
use_ok( 'Net::Prometheus::Summary' );
use_ok( 'Net::Prometheus::Histogram' );

use_ok( 'Net::Prometheus::ProcessCollector' );

# Each process collector should at least *compile* when not on its own host OS
use_ok( 'Net::Prometheus::ProcessCollector::linux' );

done_testing;
