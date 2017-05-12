use Test::More tests => 2;

BEGIN {
use_ok( 'Plack::Middleware::ReverseProxyPath' );
}

my $version = $Plack::Middleware::ReverseProxyPath::VERSION;
ok( $version, "VERSION defined" );
diag( "Testing Plack::Middleware::ReverseProxyPath $version" );
