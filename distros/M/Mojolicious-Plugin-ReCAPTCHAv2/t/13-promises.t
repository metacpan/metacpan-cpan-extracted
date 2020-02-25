#!perl
# vim:syntax=perl:tabstop=4:number:noexpandtab:

use Mojo::Base -strict;
use Mojolicious::Lite;
use Mojo::JSON qw();
use Test::Mojo;
use Test::More;

use constant PROMISES => eval { require Mojo::Promise; 1 };
plan 'skip_all' => "Could not load Mojo::Promise" unless PROMISES;

plugin 'ReCAPTCHAv2' => {
    'sitekey' => 'key',
    'secret'  => 'secret',
};

post '/test' => sub {
    my $c = shift;

    $c->render_later;

    $c->recaptcha_verify_p->then( sub { $c->render( json => { verify => 1, errors => [] }, status => 200 ); } )
      ->catch( sub { $c->render( json => { verify => 0, errors => $_[0] }, status => 403 ); } )->wait;
};

my $t = Test::Mojo->new;

$t->post_ok( '/test' => {} => form => { 'g-recaptcha-response' => 'foo' } )->status_is( 403 )
  ->json_like( '/verify' => qr/\A0\Z/ )->json_is( '/errors/0' => 'invalid-input-response' )
  ->json_is( '/errors/1' => 'invalid-input-secret' );

done_testing;
