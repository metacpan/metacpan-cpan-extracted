#!perl

use strict;
use warnings;

use Mojolicious::Lite;
use Test::More;
use FindBin qw/ $Bin /;
use lib $Bin;
use AllTests;

my $verify_client_sub = sub {
  my ( %args ) = @_;

  my ( $c,$client_id,$scopes_ref,$redirect_uri,$response_type )
    = @args{ qw/ mojo_controller client_id scopes redirect_uri response_type / };

  ok( $c,'have a mojo_controller' );

  # in reality we would check a config file / the database to confirm the
  # client_id and client_secret match and that the scopes are valid
  return ( 0,'invalid_scope' ) if grep { $_ eq 'cry' } @{ $scopes_ref // [] };
  return ( 0,'access_denied' ) if grep { $_ eq 'drink' } @{ $scopes_ref // [] };
  return ( 0,'unauthorized_client' ) if $client_id ne '1';
  return ( 0,'unauthorized_client' ) if $response_type ne 'code';

  # all good
  return ( 1,undef );
};

my $store_auth_code_sub = sub {
  my ( %args ) = @_;

  my ( $c,$auth_code,$client_id,$expires_in,$url,$scopes_ref )
    = @args{qw/ mojo_controller auth_code client_id expires_in redirect_uri scopes / };

  ok( $c,'have a mojo_controller' );

  # in reality would store stuff in the database here (or perhaps a
  # correctly scoped hash, but the database is where it should be so
  # we have persistence across restarts and such)
  return;
};

my %VERIFIED_AUTH_CODES;
my $ACCESS_REVOKED = 0;

my $verify_auth_code_sub = sub {
  my ( %args ) = @_;

  my ( $c,$client_id,$client_secret,$auth_code,$url )
    = @args{qw/ mojo_controller client_id client_secret auth_code redirect_uri / };

  ok( $c,'have a mojo_controller' );

  return ( 0,'invalid_grant' ) if $client_id ne '1';
  return ( 0,'invalid_grant' ) if $client_secret ne 'boo';

  my $error     = undef;
  my $scope     = {
    eat   => 1,
    sleep => 0,
  };

  if ( $VERIFIED_AUTH_CODES{$auth_code} ) {
    # the auth code has been used before - we must revoke the auth code
    # and access tokens - this would be done in the database, but for
    # testing here i'm just setting a simple flag
    $ACCESS_REVOKED++;
    return ( 0,'invalid_grant' );
  }

  $VERIFIED_AUTH_CODES{$auth_code} = 1;

  # and here we would check the database, check the auth code hasn't
  # expired, and so on
  return ( $client_id,$error,$scope );
};

my $VALID_ACCESS_TOKEN;
my $VALID_REFRESH_TOKEN;

my $store_access_token_sub = sub {
  my ( %args ) = @_;

  my (
    $c,$client_id,$auth_code,$access_token,$refresh_token,
    $expires_in,$scope,$old_refresh_token
  ) = @args{qw/
    mojo_controller client_id auth_code access_token
    refresh_token expires_in scopes old_refresh_token
  / };

  ok( $c,'have a mojo_controller' );

  $VALID_ACCESS_TOKEN  = $access_token;
  $VALID_REFRESH_TOKEN = $refresh_token;

  # again, store stuff in the database
  return;
};

my $verify_access_token_sub = sub {
  my ( %args ) = @_;

  my ( $c,$access_token,$scopes_ref,$is_refresh_token )
  	= @args{qw/ mojo_controller access_token scopes is_refresh_token /};

  ok( $c,'have a mojo_controller' );

  # and here we should check the access code is valid, not expired, and the
  # passed scopes are allowed for the access token
  return 1 if $is_refresh_token and $access_token eq $VALID_REFRESH_TOKEN;
  return 0 if $ACCESS_REVOKED;
  return 0 if grep { $_ eq 'sleep' } @{ $scopes_ref // [] };

  # this will only ever allow one access token - for the purposes of testing
  # that when a refresh token is used the previous access token is revoked
  return 0 if $access_token ne $VALID_ACCESS_TOKEN;

  my $client_id = 1;

  return { client_id => $client_id };
};

MOJO_APP: {
  # plugin configuration
  plugin 'OAuth2::Server' => {
    authorize_route     => '/o/auth',
    access_token_route  => '/o/token',
    verify_client       => $verify_client_sub,
    store_auth_code     => $store_auth_code_sub,
    verify_auth_code    => $verify_auth_code_sub,
    store_access_token  => $store_access_token_sub,
    verify_access_token => $verify_access_token_sub,
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

AllTests::run({
  authorize_route    => '/o/auth',  
  access_token_route => '/o/token',
});

done_testing();

# vim: ts=2:sw=2:et
