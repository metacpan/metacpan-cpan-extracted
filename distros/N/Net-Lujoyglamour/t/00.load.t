use Test::More tests => 3; #-*-cperl-*-

use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

BEGIN {
use_ok( 'Net::Lujoyglamour' );
use_ok( 'Net::Lujoyglamour::WebApp' );
use_ok( 'Net::Lujoyglamour::Result::Url' );
}

diag( "Testing Net::Lujoyglamour $Net::Lujoyglamour::VERSION" );
