#!perl

use strict;
use warnings;

use Mojo::URL;
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Test::Deep;

# there's quite a bit that's invalid in this test as we
# are covering the edge cases and error checking (so do
# not take it as an example of real usage)

my $CONFIRMED_SCOPES;
my $LOGGED_IN = 0;

MOJO_APP: {
  # plugin configuration
  plugin 'OAuth2::Server' => {
    verify_client             => sub { return ( 1 ) },
    login_resource_owner      => sub {
      my ( %args ) = @_;

      my $c = $args{mojo_controller};
      if ( ! $LOGGED_IN++ ) {
        $c->redirect_to( '/oauth/login' );
        return;
      } else {
        return $LOGGED_IN;
      }
    },
    confirm_by_resource_owner => sub {
      my ( %args ) = @_;

      my ( $c,$client_id,$scopes_ref,$redirect_uri,$response_type )
        = @args{ qw/ mojo_controller client_id scopes redirect_uri response_type / };

      if ( ! defined $CONFIRMED_SCOPES ) {
        $c->redirect_to( '/oauth/confirm_scopes' );
        # access is not required to be set by resource owner
        $CONFIRMED_SCOPES = 0;
        return;
      } elsif ( ! $CONFIRMED_SCOPES++ ) {
        # resource owner denies access
        return 0;
      } else {
        # resource owner allows access
        return 1;
      }
    },
    clients               => {
      1 => {
        client_secret => 'boo',
      },
    },
  };

  get '/oauth/login'          => sub { return shift->render( text => "Login!" ) };
  get '/oauth/confirm_scopes' => sub { return shift->render( text => "Allow?" ) };
  get '/cb'             => sub {
    my ( $c ) = @_;
    if ( my $error = $c->param( 'error' ) ) {
      return $c->render( text => $error );
    } else {
      return $c->render( text => 'Callback' );
    }
  };
};

my $t = Test::Mojo->new;
$t->ua->max_redirects( 2 );

my $auth_route  = '/oauth/authorize';
my $token_route = '/oauth/access_token';

my %valid_auth_params = (
  client_id     => 1,
  client_secret => 'boo',
  response_type => 'code',
  redirect_uri  => '/cb',
);

note( "not logged in" );
$t->get_ok( $auth_route => form => \%valid_auth_params )
  ->status_is( 200 )
  ->content_is( "Login!" )
;

note( "logged in (confirm scopes)" );
$t->get_ok( $auth_route => form => \%valid_auth_params )
  ->status_is( 200 )
  ->content_is( "Allow?" )
;

$t->ua->max_redirects( 0 );

note( "logged in (deny scopes)" );
$t->get_ok( $auth_route => form => \%valid_auth_params )
  ->status_is( 302 )
;

my $expected_error = 'access_denied';
my $location = Mojo::URL->new( $t->tx->res->headers->location );
is( $location->path,'/cb','redirect to right place' );
ok( ! $location->query->param( 'code' ),'no code' );
is( $location->query->param( 'error' ),$expected_error,'expected error' );

$t->ua->max_redirects( 1 );

note( "logged in (already confirmed scopes)" );
$t->get_ok( $auth_route => form => \%valid_auth_params )
  ->status_is( 200 )
  ->content_is( 'Callback' )
;

note( "none existing auth code" );

my %valid_token_params = (
  client_id     => 1,
  client_secret => 'boo',
  grant_type    => 'authorization_code',
  code          => "invalid auth code",
  redirect_uri  => "/bad",
);

$t->post_ok( $token_route => form => \%valid_token_params )
  ->status_is( 400 )
  ->header_is( 'Cache-Control' => 'no-store' )
  ->header_is( 'Pragma'        => 'no-cache' )
;

cmp_deeply(
  $t->tx->res->json,
  {
    error => "invalid_grant",
  },
  'json_is_deeply'
);

done_testing();

# vim: ts=2:sw=2:et
