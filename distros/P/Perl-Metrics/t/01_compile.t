#!/usr/bin/perl

# Load test the Perl::Metrics module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

# Does everything load?
use Test::More tests => 9;

ok( $] >= 5.005, 'Your perl is new enough' );

require_ok( 'Perl::Metrics' );
ok( $Perl::Metrics::CDBI::VERSION,   '::Metrics loaded ::CDBI'   );
ok( $Perl::Metrics::File::VERSION,   '::Metrics loaded ::File'   );
ok( $Perl::Metrics::Metric::VERSION, '::Metrics loaded ::Metric' );
ok( $Perl::Metrics::Plugin::VERSION, '::Metrics loaded ::Plugin' );

# Search for plugins
my @plugins = Perl::Metrics->plugins;
ok( scalar(@plugins), 'Found at least one plugin' );
ok( scalar(grep { $_ eq 'Perl::Metrics::Plugin::Core' } @plugins),
	"Found Perl::Metrics::Plugin::Core" );

# Load the sample/core plugin
use_ok( 'Perl::Metrics::Plugin::Core' );
