#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Domain::ES::ccTLD' );
}

diag( "Testing Net::Domain::ES::ccTLD $Net::Domain::ES::ccTLD::VERSION, Perl $], $^X" );
