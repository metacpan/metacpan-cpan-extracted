use Test::More tests => 3;

BEGIN {
use_ok( 'Net::DSML' );
use_ok( 'Net::DSML::Filter' );
use_ok( 'Net::DSML::Control' );
}

diag( "Testing Net::DSML $Net::DSML::VERSION" );
