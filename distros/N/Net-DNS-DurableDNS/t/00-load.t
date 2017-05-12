#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::DNS::DurableDNS' );
}

diag( "Testing Net::DNS::DurableDNS $Net::DNS::DurableDNS::VERSION, Perl $], $^X" );
