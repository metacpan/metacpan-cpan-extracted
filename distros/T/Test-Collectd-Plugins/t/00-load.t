#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Collectd::Plugins' ) || print "Bail out!\n";
}

diag( "Testing Test::Collectd::Plugins $Test::Collectd::Plugins::VERSION, Perl $], $^X" );
