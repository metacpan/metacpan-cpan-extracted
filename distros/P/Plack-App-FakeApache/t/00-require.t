use Test::More tests => 5;

require_ok( 'Plack::App::FakeApache' );
require_ok( 'Plack::App::FakeApache::Request' );
require_ok( 'Plack::App::FakeApache::Connection' );
require_ok( 'Plack::App::FakeApache::Log' );
require_ok( 'Plack::App::WrapApacheReq' );

