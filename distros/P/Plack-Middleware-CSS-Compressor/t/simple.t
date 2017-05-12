use strict;
use warnings;

use HTTP::Request::Common;
use Plack::App::File;
use Plack::Middleware::CSS::Compressor;
use Plack::Test;
use Test::More
    tests => 7
;

my $app = Plack::Middleware::CSS::Compressor->wrap(
    Plack::App::File->new( 'root' => 't' )
);

test_psgi( $app => sub {
	my $cb = shift;
	my $res = $cb->( GET( '/' ) );

	is( $res->code, 404 );

	$res = $cb->( GET( '/foo.css' ) );
	is( $res->code, 200 );
	is( $res->content_type, 'text/css' );
	is( $res->content, <<EOF );
body
{
	margin: 0 0 0 0;
}
EOF

	$res = $cb->( GET( '/foo-min.css' ) );
	is( $res->code, 200 );
	is( $res->content_type, 'text/css' );
	is( $res->content, 'body{margin:0}' );
} );

