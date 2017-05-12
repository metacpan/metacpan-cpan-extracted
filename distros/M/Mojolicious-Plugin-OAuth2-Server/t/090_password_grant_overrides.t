#!perl

use strict;
use warnings;

use Mojolicious::Lite;
use Test::More;
use FindBin qw/ $Bin /;
use lib $Bin;
use AllTests;

my $verify_user_password_sub = sub {
  my ( %args ) = @_;

  my ( $client_id,$client_secret,$username,$password,$scopes )
    = @args{qw/ client_id client_secret username password scopes /};

  return ( 0,'unauthorized_client' )
    if ( $client_id ne '1' || $client_secret ne 'boo' );

  return ( $client_id,undef,$username,$scopes );
};

my $VALID_ACCESS_TOKEN;
my $VALID_REFRESH_TOKEN;

my $store_access_token_sub = sub {
  my ( %args ) = @_;

  $VALID_ACCESS_TOKEN  = $args{access_token};
  $VALID_REFRESH_TOKEN = $args{refresh_token};

  # again, store stuff in the database
  return;
};

my $verify_access_token_sub = sub {
  my ( %args ) = @_;

  # and here we should check the access code is valid, not expired, and the
  # passed scopes are allowed for the access token
  return 1 if $args{is_refresh_token} and $args{access_token} eq $VALID_REFRESH_TOKEN;
  return 0 if grep { $_ eq 'sleep' } @{ $args{scopes} // [] };

  # this will only ever allow one access token - for the purposes of testing
  # that when a refresh token is used the previous access token is revoked
  return 0 if $args{access_token} ne $VALID_ACCESS_TOKEN;

  my $client_id = 1;

  return $client_id;
};

MOJO_APP: {
  # plugin configuration
  plugin 'OAuth2::Server' => {
    args_as_hash         => 1,
    authorize_route      => '/o/auth',
    access_token_route   => '/o/token',
    verify_user_password => $verify_user_password_sub,
    verify_client        => sub {}, # no-op as using password grant
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
  authorize_route    => '/o/auth',  
  access_token_route => '/o/token',
  grant_type         => 'password',
  skip_revoke_tests  => 1, # there is no auth code
});

done_testing();

# vim: ts=2:sw=2:et
