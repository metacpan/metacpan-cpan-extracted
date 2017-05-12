use Test::More;
use Test::Mojo;
use strict;
use warnings;
use Mojo::URL;
use Data::Dumper; $Data::Dumper::Indent=$Data::Dumper::Sortkeys=1;

my $t = Test::Mojo->new( 't::MojoTestServer' );
$t->get_ok('/')->status_is(200)->content_is( 'This is t::MojoTestServer' );


sub request_with_redirect {
    my ($t, @args) = @_;
    $t->get_ok( @args );
    my $response = $t->tx->res;
    if ($response->headers->header('location')) {
#	use URI;
	my $location = $response->headers->header('location');
	if (ref $location) {
	    $location = $location->[0];
	}
	my $uri = Mojo::URL->new( $location );
	$t->get_ok( "" . $uri->path );
	$response = $t->tx->res;
    }
    return $response;
}


{
    @TestApp::View::PHPTest::headers = ();
    $TestApp::View::PHPTest::capture_all_headers = 1;

    $t->get_ok( '/redirect.php?location=1' )
	->content_like( qr/./, 'got content for request with redirect')
	->status_is(302, 'got default redirect status');

}


{
    my $response = request_with_redirect $t, '/redirect.php?location=1';
    my $content = $response->body;

    ok( $response, 'response ok with redirect' );
    ok( $content =~ /reached redirect_destination.php/,
	'retrieved content from redirected location' );

    $response = request_with_redirect $t, '/redirect.php?location=2';
    $content = $response->body;

    ok( $response, 'response ok with redirect' );
    ok( $content =~ /reached redirect_destination2.php/,
	'retrieved content from redirected location' );
    ok( $response->code == 200, 'status after redirect is OK' );

}

{
    @TestApp::View::PHPTest::headers = ();
    $TestApp::View::PHPTest::capture_all_headers = 1;

    $t->get_ok( '/redirect.php?location=2&status=301' )
	->content_like( qr/./ , 'got content for req with redirect and status');
    $t->status_is(301, 'got correct status');

}

{
    @TestApp::View::PHPTest::headers = ();
    $TestApp::View::PHPTest::capture_all_headers = 1;

    $t->get_ok('/redirectx.php?location=2&status=303')
	->content_like( qr/./, 'got content for req with redirect,status')
	->status_is(301, 'got correct status');


}

done_testing();
