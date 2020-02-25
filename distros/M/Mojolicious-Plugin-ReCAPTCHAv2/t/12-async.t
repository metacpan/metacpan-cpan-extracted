#!perl
# vim:syntax=perl:tabstop=4:number:noexpandtab:

use Mojo::Base -strict;
use Mojolicious::Lite;
use Mojo::JSON qw();
use Test::Mojo;
use Test::More;

plugin 'ReCAPTCHAv2' => {
    'sitekey' => 'key',
    'secret'  => 'secret',
};

post '/test' => sub {
    my $c = shift;

    $c->render_later;

    Mojo::IOLoop->delay(
        sub {
            my $delay = shift;
            $c->recaptcha_verify( $delay->begin( 0 ) );
        },
        sub {
            my ( $delay, $verified, $err ) = @_;
            if ( !$verified ) {
                return $c->render( json => { verify => $verified, errors => $err }, status => 403 );
            }
            else {
                return $c->render( json => { verify => $verified, errors => $err }, status => 403 );
            }
        },
    );
};

my $t = Test::Mojo->new;

$t->post_ok( '/test' => {} => form => { 'g-recaptcha-response' => 'foo' } )->status_is( 403 )
  ->json_like( '/verify' => qr/\A0\Z/ )->json_is( '/errors/0' => 'invalid-input-response' )
  ->json_is( '/errors/1' => 'invalid-input-secret' );

done_testing;
