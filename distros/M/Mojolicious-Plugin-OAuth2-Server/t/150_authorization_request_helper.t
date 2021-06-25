#!perl

use strict;
use warnings;

use Mojolicious::Lite;
use Mojo::Util qw/ b64_encode url_unescape /;
use Test::More;
use Test::Mojo;
use Mojo::URL;
use Mojo::JWT;

MOJO_APP: {
  # plugin configuration
  plugin 'OAuth2::Server' => {
    args_as_hash        => 0,
    authorize_route     => '/o/auth',
    verify_client       => sub { return ( 1,undef ) },
    jwt_secret          => 'WEEEE_SECRET',
  };

  get '/foo' => sub {
    my ( $c ) = @_;

    my $redirect_uri = $c->oauth2_auth_request({
      client_id     => 'Foo',
	  redirect_uri  => 'foo://wee',
	  response_type => 'token',
    user_id       => 'LEEJO',
	});

    $c->render( text => $redirect_uri );
  };

  group {
    # /api - must be authorized
    under '/api' => sub {
      my ( $c ) = @_;
      return 1 if $c->oauth && $c->oauth->{client_id};
      $c->render( status => 401, text => 'Unauthorized' );
      return undef;
    };

    get '/eat' => sub { shift->render( text => "food"); };
  };

  # /sleep - must be authorized and have sleep scope
  get '/api/sleep' => sub {
    my ( $c ) = @_;
    $c->oauth( 'sleep' )
      || $c->render( status => 401, text => 'You cannot sleep' );

    $c->render( text => "bed" );
  };
};

my $t = Test::Mojo->new;
$t->get_ok( '/foo' )
  ->status_is( 200 )
  ->content_like( qr!^foo://wee#access_token=([^&]*)&token_type=bearer&expires_in=3600$! )
;

my $url = Mojo::URL->new( $t->tx->res->content->get_body_chunk );

my $fragment = $url->fragment;
ok( my ( $access_token ) = ( $fragment =~ qr/access_token=([^&]*)/ ),'includes token' );
$access_token = url_unescape( $access_token );

my $json = Mojo::JWT->new( secret => 'WEEEE_SECRET' )
  ->decode( $access_token );

is( $json->{user_id},'LEEJO','user_id passed through to access token' );

note( "don't use access token to access route" );
$t->get_ok('/api/eat')->status_is( 401 );
$t->get_ok('/api/sleep')->status_is( 401 );

note( "use access token to access route" );

$t->ua->on(start => sub {
  my ( $ua,$tx ) = @_;
  $tx->req->headers->header( 'Authorization' => "Bearer $access_token" );
});

$t->get_ok('/api/eat')->status_is( 200 );
$t->get_ok('/api/sleep')->status_is( 401 );

done_testing();

# vim: ts=2:sw=2:et
