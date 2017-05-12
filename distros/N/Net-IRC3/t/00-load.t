#!perl -T

use Test::More tests => 4;

BEGIN {
   use_ok( 'Net::IRC3' );
   use_ok( 'Net::IRC3::Util' );
   use_ok( 'Net::IRC3::Connection' );
   use_ok( 'Net::IRC3::Client::Connection' );
}

diag( "Testing Net::IRC3 $Net::IRC3::VERSION, Perl $], $^X" );
