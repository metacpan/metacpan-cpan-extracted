#!/usr/bin/perl

# Load test the Perl::Metrics module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;

ok( $] >= 5.006, 'Your perl is new enough' );

# Load Perl::Metrics. Can it be found in the plugin list?
require_ok( 'Perl::Metrics' );
my @plugins = Perl::Metrics->plugins;
ok( scalar(@plugins), 'Found at least one plugin' );
ok( scalar(grep { $_ eq 'Perl::Metrics::Plugin::MinimumVersion' } @plugins),
	'Found Perl::Metrics::Plugin::MinimumVersion' );

# Load the plugin itself
use_ok( 'Perl::Metrics::Plugin::MinimumVersion' );
