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

get '/' => sub {
    my $c = shift;
    $c->render( text => $c->recaptcha_get_html );
};

post '/test' => sub {
    my $c = shift;
    my ( $state, $err ) = $c->recaptcha_verify;
    $c->render(
        json => {
            verify => $state,
            errors => $err,
        }
    );
};

my $t = Test::Mojo->new;

$t->get_ok( '/' )->status_is( 200 )->content_is( <<'RECAPTCHA');
<script src="https://www.google.com/recaptcha/api.js?hl=" async defer></script>
<div class="g-recaptcha" data-sitekey="key"></div>
RECAPTCHA

$t->post_ok( '/test' => {} => form => { 'g-recaptcha-response' => 'foo' } )->status_is( 200 )
  ->json_like( '/verify' => qr/\A0\Z/ )->json_is( '/errors/0' => 'invalid-input-response' )
  ->json_is( '/errors/1' => 'invalid-input-secret' );

done_testing;
