#!perl

use strict;
use warnings;

use Mojolicious::Lite;
use Test::More;
use FindBin qw/ $Bin /;
use lib $Bin;
use AllTests;

my $VALID_ACCESS_TOKEN;

my $verify_client_sub = sub {
  my ( %args ) = @_;

  my ( $c,$client_id,$scopes_ref,$redirect_uri,$response_type )
    = @args{ qw/ mojo_controller client_id scopes redirect_uri response_type / };

  # in reality we would check a config file / the database to confirm the
  # client_id and client_secret match and that the scopes are valid
  return ( 0,'invalid_scope' ) if grep { $_ eq 'cry' } @{ $scopes_ref // [] };
  return ( 0,'access_denied' ) if grep { $_ eq 'drink' } @{ $scopes_ref // [] };
  return ( 0,'unauthorized_client' ) if $client_id ne '1';

  # all good
  return ( 1,undef );
};


my $store_access_token_sub = sub {
  my ( %args ) = @_;
  $VALID_ACCESS_TOKEN  = $args{access_token};

  # again, store stuff in the database
  return;
};

my $verify_access_token_sub = sub {
  my ( %args ) = @_;

  my ( $c,$access_token,$scopes_ref,$is_refresh_token )
  	= @args{qw/ mojo_controller access_token scopes is_refresh_token /};

  # and here we should check the access code is valid, not expired, and the
  # passed scopes are allowed for the access token
  if ( @{ $scopes_ref // [] } ) {
    return 0 if grep { $_ eq 'sleep' } @{ $scopes_ref // [] };
  }

  # this will only ever allow one access token - for the purposes of testing
  # that when a refresh token is used the previous access token is revoked
  return 0 if $access_token ne $VALID_ACCESS_TOKEN;

  my $client_id = 1;

  return $client_id;
};

MOJO_APP: {
  # plugin configuration
  plugin 'OAuth2::Server' => {
    args_as_hash        => 0,
    access_token_route  => '/o/token',
    verify_client       => $verify_client_sub,
    store_access_token  => $store_access_token_sub,
    verify_access_token => $verify_access_token_sub,
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

AllTests::run({
  access_token_route => '/o/token',  
  grant_type         => 'client_credentials',
  skip_revoke_tests  => 1, # there is no auth code
});

done_testing();

# vim: ts=2:sw=2:et
