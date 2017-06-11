package AllTests;

use strict;
use warnings;

use Mojo::URL;
use Mojo::Util qw/ b64_encode url_unescape /;
use Test::More;
use Test::Deep;
use Test::Mojo;

sub run {
  my ( $args ) = @_;

  my $grant_type  = $args->{grant_type}         // 'authorization_code';
  my $auth_route  = $args->{authorize_route}    // '/oauth/authorize';
  my $token_route = $args->{access_token_route} // '/oauth/access_token';

  my %valid_auth_params = (
    client_id     => 1,
    client_secret => 'boo',
    response_type => $grant_type eq 'token' ? 'token' : 'code',
    redirect_uri  => 'https://client/cb',
    scope         => 'eat',
    state         => 'queasy',
  );

  # now the testing begins
  my $t = Test::Mojo->new;
  my $auth_code;

  if ( $grant_type =~ /(authorization_code|token)/ ) {

    my $response_type = $grant_type eq 'token' ? 'token' : 'code';

    note( "authorization request" );

    note( " ... not authorized (missing params)" );
    foreach my $form_params (
      { response_type => $response_type, },
      { client_id     => 1 },
    ) {
      $t->get_ok( $auth_route => form => $form_params )
        ->status_is( 400 )
        ->json_is( {
          error => 'invalid_request',
          error_description => 'the request was missing one of: client_id, '
            . 'response_type;'
            . 'or response_type did not equal "code" or "token"',
          error_uri         => '',
        } )
      ;
    }

    note( " ... not authorized (errors)" );

    foreach my $invalid_params (
      { client_id     => 2,       error => 'unauthorized_client', },
      { scope         => 'cry',   error => 'invalid_scope', },
    ) {
      my $expected_error = delete( $invalid_params->{error} );
      $t->get_ok( $auth_route => form => {
          %valid_auth_params, %{ $invalid_params }
        } )
        ->status_is( 302 )
      ;

      my $location = Mojo::URL->new( $t->tx->res->headers->location );
      is( $location->path,'/cb','redirect to right place' );
      ok( ! $location->query->param( 'code' ),'no code' );
      is( $location->query->param( 'error' ),$expected_error,'expected error' );
    }

    if ( $grant_type eq 'authorization_code' ) {
      # check this is enforced, i.e. we can't use implicit grant by
      # sending "token" rather than "code"
      my %force_implicit_grant = %valid_auth_params;
      delete( $force_implicit_grant{client_secret} );
      $force_implicit_grant{response_type} = 'token';

      $t->get_ok( $auth_route => form => \%force_implicit_grant )
        ->status_is( 302 )
      ;

      my $location = Mojo::URL->new( $t->tx->res->headers->location );
      is( $location->path,'/cb','redirect to right place' );
      ok( ! $location->query->param( 'code' ),'no code' );
      ok( ! $location->query->param( 'access_token' ),'no code' );
      is( $location->query->param( 'error' ),'unauthorized_client','expected error' );
    }

    $t->get_ok( $auth_route => form => \%valid_auth_params )
      ->status_is( 302 )
    ;

    note( " ... authorized" );
    my $location = Mojo::URL->new( $t->tx->res->headers->location );
    is( $location->path,'/cb','redirect to right place' );

    if ( $response_type eq 'token' ) {
      like( $location->fragment,qr/access_token/,'includes access_token' );
      like( $location->fragment,qr/bearer/,'includes token_type' );
      like( $location->fragment,qr/queasy/,'includes state' );
    } else {
      ok( $auth_code = $location->query->param( 'code' ),'includes code' );
      is( $location->query->param( 'state' ),'queasy','includes state' );
    }
  }

  if ( $grant_type eq 'token' ) {

    my $location = Mojo::URL->new( $t->tx->res->headers->location );
    note $location->fragment;
    ok( my ( $access_token ) = ( $location->fragment =~ qr/access_token=([^&]*)/ ),'includes token' );

    $access_token = url_unescape( $access_token );

    note( "don't use access token to access route" );
    $t->get_ok('/api/eat')->status_is( 401 );
    $t->get_ok('/api/sleep')->status_is( 401 );

    note( "use access token to access route" );

    $t->ua->on(start => sub {
      my ( $ua,$tx ) = @_;
      $tx->req->headers->header( 'Authorization' => "Bearer $access_token" );
    });

    $t->get_ok('/api/eat')->status_is( $args->{no_200_responses} ? 401 : 200 );
    $t->get_ok('/api/sleep')->status_is( 401 );

    return;
  }

  note( "access token" );

  my %valid_token_params = (
    client_id     => 1,
    client_secret => 'boo',
    grant_type    => $grant_type,
    ( $grant_type eq 'authorization_code' ? (
      code          => $auth_code,
      redirect_uri  => $valid_auth_params{redirect_uri},
    ) : (
      username      => 'bob',
      password      => 'hey_ho!',
      scope         => [ qw/ eat / ],
    ) ),
  );

  note( " ... no token (missing params)" );
  foreach my $form_params (
    { response_type => 'code', },
    { client_id     => 1 },
  ) {
    $t->post_ok( $token_route => form => $form_params )
      ->status_is( 400 )
      ->json_is( {
        error => 'invalid_request',
        error_description => 'the request was missing one of: grant_type, '
          . 'client_id, client_secret, code, redirect_uri;'
          . 'or grant_type did not equal "authorization_code" '
          . 'or "refresh_token"',
        error_uri         => '',
      } )
    ;
  }

  note( " ... no token (errors)" );

  foreach my $invalid_params (
    { client_id     => 2,       error => 'unauthorized_client', },
    { client_secret => 'wee',   error => 'unauthorized_client', },
  ) {
    my $expected_error = delete( $invalid_params->{error} );
    $t->post_ok( $token_route => form => {
        %valid_token_params, %{ $invalid_params }
      } )
      ->status_is( 400 )
    ;
  }

  my @post_args;

  if ( $grant_type eq 'client_credentials' ) {

    my %valid_token_params = (
      grant_type    => $grant_type,
      scope         => [ qw/ eat / ],
    );

    my $encoded_client_details = b64_encode( join( ':',1,'boo' ) );
    chomp( $encoded_client_details );

    @post_args = (
      $token_route =>
      { 'Authorization' => "Basic $encoded_client_details" } =>
      form => \%valid_token_params
    );

  } else {
    @post_args = ( $token_route => form => \%valid_token_params );
  }

  $t->post_ok( @post_args )
    ->status_is( $args->{no_200_responses} ? 400 : 200 )
    ->header_is( 'Cache-Control' => 'no-store' )
    ->header_is( 'Pragma'        => 'no-cache' )
  ;

  if ( $args->{no_200_responses} ) {

    cmp_deeply(
      $t->tx->res->json,
      {
        'error' => 'unauthorized_client',
      },
      'json_is_deeply'
    );

  } else {
    cmp_deeply(
      $t->tx->res->json,
      {
        access_token  => re( '^.+$' ),
        token_type    => 'Bearer',
        expires_in    => '3600',
        ( $grant_type eq 'client_credentials'
          ? ()
          : ( refresh_token => re( '^.+$' ) )
        ),
      },
      'json_is_deeply'
    );
  }

  my $access_token  = $t->tx->res->json->{access_token} // '';
  my $refresh_token = $t->tx->res->json->{refresh_token} // '';

  note( "don't use access token to access route" );
  $t->get_ok('/api/eat')->status_is( 401 );
  $t->get_ok('/api/sleep')->status_is( 401 );

  note( "use access token to access route" );

  $t->ua->on(start => sub {
    my ( $ua,$tx ) = @_;
    $tx->req->headers->header( 'Authorization' => "Bearer $access_token" );
  });

  $t->get_ok('/api/eat')->status_is( $args->{no_200_responses} ? 401 : 200 );
  $t->get_ok('/api/sleep')->status_is( 401 );

  if ( $grant_type ne 'client_credentials' ) {
    note( "refresh token cannot access routes" );

    $t->ua->on(start => sub {
      my ( $ua,$tx ) = @_;
      $tx->req->headers->header( 'Authorization' => "Bearer $refresh_token" );
    });

    $t->get_ok('/api/eat')->status_is( 401 );
    $t->get_ok('/api/sleep')->status_is( 401 );

    note( "get a new access token using refresh token" );

    my %valid_refresh_token_params = (
      grant_type    => 'refresh_token',
      refresh_token => $refresh_token,
      scope         => 'eat',
    );

    $t->post_ok( $token_route => form => \%valid_refresh_token_params )
      ->status_is( 200 )
      ->header_is( 'Cache-Control' => 'no-store' )
      ->header_is( 'Pragma'        => 'no-cache' )
    ;

    cmp_deeply(
      $t->tx->res->json,
      {
        access_token  => re( '^.+$' ),
        token_type    => 'Bearer',
        expires_in    => '3600',
        refresh_token => re( '^.+$' ),
      },
      'json_is_deeply'
    );

    isnt( $t->tx->res->json->{access_token},$access_token,'new access_token' );
    isnt( $t->tx->res->json->{refresh_token},$refresh_token,'new refresh_token' );
  }

  return $t if $args->{skip_revoke_tests};

  my $new_access_token  = $t->tx->res->json->{access_token};
  my $new_refresh_token = $t->tx->res->json->{refresh_token};

  note( "previous access token revoked" );

  $t->get_ok('/api/eat')->status_is( 401 );
  $t->get_ok('/api/sleep')->status_is( 401 );

  note( "new access token valid" );

  $t->ua->on(start => sub {
    my ( $ua,$tx ) = @_;
    $tx->req->headers->header( 'Authorization' => "Bearer $new_access_token" );
  });

  $t->get_ok('/api/eat')->status_is( 200 );
  $t->get_ok('/api/sleep')->status_is( 401 );

  note( "access token (2nd time with same auth code fails)" );

  $t->post_ok( $token_route => form => \%valid_token_params )
    ->status_is( 400 )
  ;

  note( " ... access revoked" );
  $t->get_ok('/api/eat')->status_is( 401 );
  $t->get_ok('/api/sleep')->status_is( 401 );

  return $t;
}

1;

# vim: ts=2:sw=2:et
