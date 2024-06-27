use 5.036;
use Test::More;
plan tests => 1;

BEGIN {
use_ok( 'Switch::Back' );
}

diag( "Testing Switch::Back $Switch::Back::VERSION" );
