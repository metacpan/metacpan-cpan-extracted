#!perl

use strict;
use warnings;

use Mojolicious::Lite;
use Mojo::JWT;
use Test::More;
use Test::Deep;
use FindBin qw/ $Bin /;
use lib $Bin;
use AllTests;

my $jwt_secret = 'nova scotia scova notia';

MOJO_APP: {
  # plugin configuration
  plugin 'OAuth2::Server' => {
    jwt_secret           => $jwt_secret,
    clients              => {
      1 => {
        client_secret => 'boo',
        scopes        => {
          eat       => 1,
          drink     => 0,
          sleep     => 1,
        },
      },
    },
  };

  group {
    # /api - must be authorized
    under '/api' => sub {
      my ( $c ) = @_;
      return 1 if $c->oauth;
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

my %valid_auth_params = (
  client_id     => 1,
  client_secret => 'boo',
  response_type => 'code',
  redirect_uri  => 'https://client/cb',
  scope         => 'eat sleep',
  state         => 'queasy',
);

my $t = Test::Mojo->new;

$t->get_ok( '/oauth/authorize' => form => \%valid_auth_params )
  ->status_is( 302 )
;

my $location = Mojo::URL->new( $t->tx->res->headers->location );
is( $location->path,'/cb','redirect to right place' );
ok( my $auth_code = $location->query->param( 'code' ),'includes code' );

my $decoded_auth_code = Mojo::JWT->new( secret => $jwt_secret )->decode( $auth_code );

cmp_deeply(
	$decoded_auth_code,
	{
    'type' => 'auth',
    'aud' => 'https://client/cb',
    'client' => '1',
    'user_id' => undef,
    'exp' => re( '^\d{10}$' ),
    'iat' => re( '^\d{10}$' ),
    'jti' => re( '^.{32}$' ),
    'scopes' => [
      'eat',
      'sleep'
    ]
  },
	'decoded JWT (auth code)',
);

my %valid_token_params = (
  client_id     => 1,
  client_secret => 'boo',
  grant_type    => 'authorization_code',
  code          => $auth_code,
  redirect_uri  => $valid_auth_params{redirect_uri},
);

$t->post_ok( '/oauth/access_token'=> form => \%valid_token_params )
  ->status_is( 200 )
  ->header_is( 'Cache-Control' => 'no-store' )
  ->header_is( 'Pragma'        => 'no-cache' )
;

my $res = $t->tx->res->json;

cmp_deeply(
  $res,
  {
    access_token  => re( '^.+$' ),
    token_type    => 'Bearer',
    expires_in    => '3600',
    refresh_token => re( '^.+$' ),
  },
  'json_is_deeply'
);

my $decoded_access_token = Mojo::JWT->new( secret => $jwt_secret )
  ->decode( $res->{access_token} );
my $decoded_refresh_token = Mojo::JWT->new( secret => $jwt_secret )
  ->decode( $res->{refresh_token} );

cmp_deeply(
	$decoded_access_token,
	{
    'type' => 'access',
    'aud' => undef,
    'client' => '1',
    'user_id' => undef,
    'exp' => re( '^\d{10}$' ),
    'iat' => re( '^\d{10}$' ),
    'jti' => re( '^.{32}$' ),
    'scopes' => [
      'eat',
      'sleep',
    ]
  },
	'decoded JWT (access token)',
);

cmp_deeply(
	$decoded_refresh_token,
	{
    'type' => 'refresh',
    'aud' => undef,
    'client' => '1',
    'user_id' => undef,
    'iat' => re( '^\d{10}$' ),
    'jti' => re( '^.{32}$' ),
    'scopes' => [
      'eat',
      'sleep',
    ]
  },
	'decoded JWT (refresh token)',
);

done_testing();

# vim: ts=2:sw=2:et
