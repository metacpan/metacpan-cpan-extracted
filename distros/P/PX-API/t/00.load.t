use Test::More tests => 5;

BEGIN {
use_ok( 'PX::API' );
use_ok( 'PX::API::Request' );
use_ok( 'PX::API::Response' );
use_ok( 'PX::API::Response::Rest' );
use_ok( 'PX::API::Response::JSON' );
}

diag( "Testing PX::API $PX::API::VERSION" );
