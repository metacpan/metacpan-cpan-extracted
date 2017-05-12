#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Radio::Modem::Adapter::oFono' ) || print "Bail out!\n";
}

diag( "Testing Net::Radio::Modem::Adapter::oFono $Net::Radio::Modem::Adapter::oFono::VERSION, Perl $], $^X" );
