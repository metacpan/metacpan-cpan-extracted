#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Xero' );
}

diag( "Testing Net::Xero $Net::Xero::VERSION, Perl $], $^X" );
