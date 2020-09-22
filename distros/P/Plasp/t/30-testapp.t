#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 15;

use FindBin;
use lib "$FindBin::Bin/lib";
use HTTP::Cookies;
use HTTP::Request::Common;
use Plack::Test;
use TestApp;
use URI::Escape;

my $app  = TestApp->new;
my $test = Plack::Test->create( $app );

my $cookie_jar = HTTP::Cookies->new;
my ( $res, $cookies );

sub get_cookies {
    my ( $res, $key ) = @_;
    my $cj = HTTP::Cookies->new;
    $cj->extract_cookies( $res );
    uri_unescape( $cj->get_cookies( 'localhost.local', $key ) );
}

$res = $test->request( GET '/hello_world.asp' );
like( $res->content, qr/<h1>Hello World!<\/h1>/, 'Simple Hello World page processed!' );
unlike( $res->content, qr/extra content should not be seen/, '$Response->End properly' );
like( $res->header( 'Content-Type' ), qr/^TeXt\/HTml/, 'Content type successfully set' );
is( $res->headers->content_type_charset, 'ISO-LATIN-1', 'Content type charset successfully set' );
is( get_cookies( $res, 'gotcha' ), 'yup!', 'Cookie successfully set' );
is( get_cookies( $res, 'another' ), 'gotcha=yup!', 'Another cookie successfully set' );

$res = $test->request( GET '/welcome.asp' );
like(
    $res->content,
    qr/<title>Welcome Page!<\/title>.*<p>This is the welcome page for TestApp::ASP<\/p>/s,
    'Welcome page fully processed with XMLSubs and $Response->Include!'
);

$res = $test->request( GET '/welcome_again.asp' );
like(
    $res->content,
    qr/<h1>Welcome again to TestApp::ASP!<\/h1>/s,
    'Welcome again page fully processed, tested $Response->TrapInclude!'
);

$res = $test->request( GET '/die.asp' );
is( $res->code, 500, 'Properly errored' );

$res = $test->request( GET '/notfound.asp' );
is( $res->code, 404, 'Properly not found for non-existent file' );

$res = $test->request( GET '/templates/some_template.tmpl' );
is( $res->code, 404, 'Properly not found for templates, though in root' );

$res = $test->request( GET '/redirect.asp' );
is( $res->code, 302, 'Properly redirected (status)' );
is( $res->header( 'Location' ), '/welcome.asp', 'Properly redirected (location header)' );

$res = $test->request( GET '/redirect_permanent.asp' );
is( $res->code, 301, 'Properly redirected manually (status)' );
is( $res->header( 'Location' ), '/welcome.asp', 'Properly redirected manually (location header)' );
