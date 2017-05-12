#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Radio::oFono' ) || print "Bail out!\n";
}

diag( "Testing Net::Radio::oFono $Net::Radio::oFono::VERSION, Perl $], $^X" );
