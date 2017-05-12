use Test::More tests => 3;

BEGIN {
use_ok( 'Net::Rexster::Client' );
use_ok( 'Net::Rexster::Response' );
use_ok( 'Net::Rexster::Request' );
}

diag( "Testing Net::Rexster::Client $Net::Rexster::Client::VERSION" );
