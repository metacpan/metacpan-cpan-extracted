#!perl

use strict;
use warnings;

use Mojo::URL;
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Test::Deep;

my $TTL = 3;

MOJO_APP: {
  # plugin configuration
  plugin 'OAuth2::Server' => {
    auth_code_ttl         => $TTL,
    access_token_ttl      => $TTL,
    clients               => {
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

my $t = Test::Mojo->new;
my $auth_route  = '/oauth/authorize';
my $token_route = '/oauth/access_token';

my %valid_auth_params = (
  client_id     => 1,
  client_secret => 'boo',
  response_type => 'code',
  redirect_uri  => 'https://client/cb',
  scope         => 'eat',
  state         => 'queasy',
);

$t->get_ok( $auth_route => form => \%valid_auth_params )
  ->status_is( 302 )
;

my $location = Mojo::URL->new( $t->tx->res->headers->location );
is( $location->path,'/cb','redirect to right place' );
ok( my $auth_code = $location->query->param( 'code' ),'includes code' );
is( $location->query->param( 'state' ),'queasy','includes state' );

my %valid_token_params = (
  client_id     => 1,
  client_secret => 'boo',
  grant_type    => 'authorization_code',
  code          => $auth_code,
  redirect_uri  => $valid_auth_params{redirect_uri},
);

$t->post_ok( $token_route => form => \%valid_token_params )
  ->status_is( 200 )
  ->header_is( 'Cache-Control' => 'no-store' )
  ->header_is( 'Pragma'        => 'no-cache' )
;

cmp_deeply(
  $t->tx->res->json,
  {
    access_token  => re( '^.+$' ),
    token_type    => 'Bearer',
    expires_in    => $TTL,
    refresh_token => re( '^.+$' ),
  },
  'json_is_deeply'
);

my $access_token  = $t->tx->res->json->{access_token};
my $refresh_token = $t->tx->res->json->{refresh_token};

$t->ua->on(start => sub {
  my ( $ua,$tx ) = @_;
  $tx->req->headers->header( 'Authorization' => "Bearer $access_token" );
});

$t->get_ok('/api/eat')->status_is( 200 );
$t->get_ok('/api/sleep')->status_is( 401 );

sleep( $TTL + 1 );

note( "access token expired" );
$t->get_ok('/api/eat')->status_is( 401 );
$t->get_ok('/api/sleep')->status_is( 401 );

note( "refresh token does not expire" );

$t->post_ok( $token_route => form => {
  %valid_token_params,
  grant_type    => 'refresh_token',
  refresh_token => $refresh_token,
} )
  ->status_is( 200 )
  ->header_is( 'Cache-Control' => 'no-store' )
  ->header_is( 'Pragma'        => 'no-cache' )
;

cmp_deeply(
  $t->tx->res->json,
  {
    access_token  => re( '^.+$' ),
    token_type    => 'Bearer',
    expires_in    => $TTL,
    refresh_token => re( '^.+$' ),
  },
  'json_is_deeply'
);

$access_token         = $t->tx->res->json->{access_token};
my $new_refresh_token = $t->tx->res->json->{refresh_token};

note( "previous refresh token revoked after using it" );

$t->post_ok( $token_route => form => {
  %valid_token_params,
  grant_type    => 'refresh_token',
  refresh_token => $refresh_token,
} )
  ->status_is( 400 )
  ->header_is( 'Cache-Control' => 'no-store' )
  ->header_is( 'Pragma'        => 'no-cache' )
;

note( "new auth code request" );
$t->get_ok( $auth_route => form => \%valid_auth_params )
  ->status_is( 302 )
;

$location = Mojo::URL->new( $t->tx->res->headers->location );
is( $location->path,'/cb','redirect to right place' );
ok( $auth_code = $location->query->param( 'code' ),'includes code' );
is( $location->query->param( 'state' ),'queasy','includes state' );

note( "auth code expires" );
sleep( $TTL + 1 );

$t->post_ok( $token_route => form => \%valid_token_params )
  ->status_is( 400 )
  ->header_is( 'Cache-Control' => 'no-store' )
  ->header_is( 'Pragma'        => 'no-cache' )
;

done_testing();

# vim: ts=2:sw=2:et
