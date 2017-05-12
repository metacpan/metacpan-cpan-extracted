#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Radio::Modem' ) || print "Bail out!\n";
}

diag( "Testing Net::Radio::Modem $Net::Radio::Modem::VERSION, Perl $], $^X" );
