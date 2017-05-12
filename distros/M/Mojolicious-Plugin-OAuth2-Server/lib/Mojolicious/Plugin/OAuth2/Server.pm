package Mojolicious::Plugin::OAuth2::Server;

=head1 NAME

Mojolicious::Plugin::OAuth2::Server - Easier implementation of an OAuth2
Authorization Server / Resource Server with Mojolicious

=for html
<a href='https://travis-ci.org/Humanstate/mojolicious-plugin-oauth2-server?branch=master'><img src='https://travis-ci.org/Humanstate/mojolicious-plugin-oauth2-server.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/Humanstate/mojolicious-plugin-oauth2-server?branch=master'><img src='https://coveralls.io/repos/Humanstate/mojolicious-plugin-oauth2-server/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

0.36

=head1 SYNOPSIS

  use Mojolicious::Lite;

  plugin 'OAuth2::Server' => {
      ... # see SYNOPSIS in Net::OAuth2::AuthorizationServer::Manual
  };

  group {
    # /api - must be authorized
    under '/api' => sub {
      my ( $c ) = @_;

      return 1 if $c->oauth; # must be authorized via oauth

      $c->render( status => 401, text => 'Unauthorized' );
      return undef;
    };

    any '/annoy_friends' => sub { shift->render( text => "Annoyed Friends" ); };
    any '/post_image'    => sub { shift->render( text => "Posted Image" ); };
  };

  any '/track_location' => sub {
    my ( $c ) = @_;

    my $oauth_details = $c->oauth( 'track_location' )
        || return $c->render( status => 401, text => 'You cannot track location' );

    $c->render( text => "Target acquired: @{[$oauth_details->{user_id}]}" );
  };

  app->start;

Or full fat app:

  use Mojo::Base 'Mojolicious';

  ...

  sub startup {
    my $self = shift;

    ...

    $self->plugin( 'OAuth2::Server' => $oauth2_auth_code_grant_config );
  }

Then in your controller:

  sub my_route_name {
    my ( $c ) = @_;
 
    if ( my $oauth_details = $c->oauth( qw/required scopes/ ) ) {
      ... # do something, user_id, client_id, etc, available in $oauth_details
    } else {
      return $c->render( status => 401, text => 'Unauthorized' );
    }

    ...
  }

=head1 DESCRIPTION

This plugin implements the various OAuth2 grant types flow as described at
L<http://tools.ietf.org/html/rfc6749>. It is a complete implementation of
RFC6749, with the exception of the "Extension Grants" as the description of
that grant type is rather hand-wavy.

The bulk of the functionality is implemented in the L<Net::OAuth2::AuthorizationServer>
distribution, you should see that for more comprehensive documentation and
examples of usage.

The examples here use the "Authorization Code Grant" flow as that is considered
the most secure and most complete form of OAuth2.

=cut

use strict;
use warnings;
use base qw/ Mojolicious::Plugin /;

use Mojo::URL;
use Mojo::Parameters;
use Mojo::Util qw/ b64_decode /;
use Net::OAuth2::AuthorizationServer;
use Carp qw/ croak /;

our $VERSION = '0.36';

my ( $AuthCodeGrant,$PasswordGrant,$ImplicitGrant,$ClientCredentialsGrant,$Grant );

=head1 METHODS

=head2 register

Registers the plugin with your app - note that you must pass callbacks for
certain functions that the plugin expects to call if you are not using the
plugin in its simplest form.

  $self->register($app, \%config);

Registering the plugin will call the L<Net::OAuth2::AuthorizationServer>
and create a C<auth_code_grant> that can be accessed using the defined
C<authorize_route> and C<access_token_route>. The arguments passed to the
plugin are passed straight through to the C<auth_code_grant> method in
the L<Net::OAuth2::AuthorizationServer> module.

=head2 oauth

Checks if there is a valid Authorization: Bearer header with a valid access
token and if the access token has the requisite scopes. The scopes are optional:

  unless ( my $oauth_details = $c->oauth( @scopes ) ) {
    return $c->render( status => 401, text => 'Unauthorized' );
  }

This calls the L<Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant>
module (C<verify_token_and_scope> method) to validate the access/refresh token.

=cut

my $warned_dep = 0;

sub register {
  my ( $self,$app,$config ) = @_;

  my $auth_route   = $config->{authorize_route}    // '/oauth/authorize';
  my $atoken_route = $config->{access_token_route} // '/oauth/access_token';

  if ( $config->{users} && ! $config->{jwt_secret} ) {
    croak "You MUST provide a jwt_secret to use the password grant (users supplied)";
  }

  my $Server = Net::OAuth2::AuthorizationServer->new;

  # note that access_tokens and refresh_tokens will not be shared between
  # the various grant type objects, so if you need to support
  # both then you *must* either supply a jwt_secret or supply callbacks
  $AuthCodeGrant = $Server->auth_code_grant(
    ( map { +"${_}_cb" => ( $config->{$_} // undef ) } qw/
      verify_client store_auth_code verify_auth_code
      store_access_token verify_access_token
      login_resource_owner confirm_by_resource_owner
    / ),
    %{ $config },
  );

  $PasswordGrant = $Server->password_grant(
    ( map { +"${_}_cb" => ( $config->{$_} // undef ) } qw/
      verify_client verify_user_password
      store_access_token verify_access_token
      login_resource_owner confirm_by_resource_owner
    / ),
    %{ $config },
  );

  $ImplicitGrant = $Server->implicit_grant(
    ( map { +"${_}_cb" => ( $config->{$_} // undef ) } qw/
      verify_client store_access_token verify_access_token
      login_resource_owner confirm_by_resource_owner
    / ),
    %{ $config },
  );

  $ClientCredentialsGrant = $Server->client_credentials_grant(
    ( map { +"${_}_cb" => ( $config->{$_} // undef ) } qw/
      verify_client store_access_token verify_access_token
    / ),
    %{ $config },
  );

  $app->routes->get(
    $auth_route => sub { _authorization_request( @_ ) },
  );

  $app->routes->post(
    $atoken_route => sub { _access_token_request( @_ ) },
  );

  $app->helper(
    oauth => sub {
      my $c = shift;
      my @scopes = @_;
      $Grant = $AuthCodeGrant;
      my @res = $Grant->verify_token_and_scope(
        scopes           => [ @scopes ],
        auth_header      => $c->req->headers->header( 'Authorization' ),
        mojo_controller  => $c,
      );
      return $res[0];
    },
  );
}

sub _authorization_request {
  my ( $self ) = @_;

  my ( $client_id,$uri,$type,$scope,$state )
    = map { $self->param( $_ ) // undef }
    qw/ client_id redirect_uri response_type scope state /;

  my @scopes = $scope ? split( / /,$scope ) : ();

  if (
    ! defined( $client_id )
    or ! defined( $type )
    or $type !~ /^(code|token)$/
  ) {
    $self->render(
      status => 400,
      json   => {
        error             => 'invalid_request',
        error_description => 'the request was missing one of: client_id, '
          . 'response_type;'
          . 'or response_type did not equal "code" or "token"',
        error_uri         => '',
      }
    );
    return;
  }

  $Grant = $type eq 'token' ? $ImplicitGrant : $AuthCodeGrant;

  my $mojo_url = Mojo::URL->new( $uri );
  my ( $res,$error ) = $Grant->verify_client(
    client_id       => $client_id,
    redirect_uri    => $uri,
    scopes          => [ @scopes ],
    mojo_controller => $self,
    response_type   => $type,
  );

  if ( $res ) {

    if ( ! $Grant->login_resource_owner( mojo_controller => $self ) ) {
      $self->app->log->debug( "OAuth2::Server: Resource owner not logged in" );
      # call to $resource_owner_logged_in method should have called redirect_to
      return;
    } else {
      $self->app->log->debug( "OAuth2::Server: Resource owner is logged in" );
      $res = $Grant->confirm_by_resource_owner(
        client_id       => $client_id,
        scopes          => [ @scopes ],
        mojo_controller => $self,
      );
      if ( ! defined $res ) {
        $self->app->log->debug( "OAuth2::Server: Resource owner to confirm scopes" );
        # call to $resource_owner_confirms method should have called redirect_to
        return;
      }
      elsif ( $res == 0 ) {
        $self->app->log->debug( "OAuth2::Server: Resource owner denied scopes" );
        $error = 'access_denied';
      }
    }
  }

  if ( $res ) {

    return _maybe_generate_access_token( $self,$mojo_url,$client_id,[ @scopes ],$state )
      if $type eq 'token'; # implicit grant

    $self->app->log->debug( "OAuth2::Server: Generating auth code for $client_id" );
    my $auth_code = $Grant->token(
      client_id       => $client_id,
      scopes          => [ @scopes ],
      type            => 'auth',
      redirect_uri    => $uri,
    );

    $Grant->store_auth_code(
      auth_code       => $auth_code,
      client_id       => $client_id,
      expires_in      => $Grant->auth_code_ttl,
      redirect_uri    => $uri,
      scopes          => [ @scopes ],
      mojo_controller => $self,
    );

    $mojo_url->query->append( code  => $auth_code );

  } elsif ( $error ) {
    $mojo_url->query->append( error => $error );
  } else {
    # callback has not returned anything, assume server error
    $mojo_url->query->append(
      error             => 'server_error',
      error_description => 'call to verify_client returned unexpected value',
    );
  }

  $mojo_url->query->append( state => $state ) if defined( $state );

  $self->redirect_to( $mojo_url );
}

sub _maybe_generate_access_token {
  my ( $self,$mojo_url,$client,$scope,$state ) = @_;

  my $access_token  = $Grant->token(
    client_id  => $client,
    scopes     => $scope,
    type       => 'access',
  );

  $Grant->store_access_token(
    client_id         => $client,
    access_token      => $access_token,
    expires_in        => $Grant->access_token_ttl,
    scopes            => $scope,
    mojo_controller   => $self,
  );

  # http://example.com/cb#access_token=2YotnFZFEjr1zCsicMWpAA
  #     &state=xyz&token_type=example&expires_in=3600
  my $params = Mojo::Parameters->new(
     access_token => $access_token,
     token_type   => 'bearer',
     expires_in   => $Grant->access_token_ttl,
     ( $state
       ? ( state => $state )
       : (),
     )
  );

  $mojo_url->fragment( $params->to_string );
  $self->redirect_to( $mojo_url );
}

sub _access_token_request {
  my ( $self ) = @_;

  my (
    $client_id,$client_secret,$grant_type,$auth_code,$uri,
    $refresh_token,$username,$password
  ) = map { $self->param( $_ ) // undef } qw/
    client_id client_secret grant_type code redirect_uri
    refresh_token username password
  /;

  $grant_type //='';

  _access_token_request_check_params(
    $self,$grant_type,$username,$password,$auth_code,$uri
  ) || return;

  my $json_response = {};
  my $status        = 400;

  $Grant = $grant_type eq 'password'
    ? $PasswordGrant : $grant_type eq 'client_credentials'
    ? $ClientCredentialsGrant : $AuthCodeGrant;

  my ( $client,$error,$scope,$user_id,$old_refresh_token ) = _verify_credentials(
    $self,$Grant,$grant_type,$refresh_token,$client_id,$client_secret,
    $auth_code,$username,$password,$uri
  );

  if ( $client ) {

    $self->app->log->debug( "OAuth2::Server: Generating access token for @{[ ref $client ? $client->{client} : $client ]}" );

    my $expires_in    = $Grant->access_token_ttl;
    my $access_token  = $Grant->token(
      client_id => $client,
      scopes    => $scope,
      type      => 'access',
      user_id   => $user_id,
    );

    my $refresh_token  = $Grant->token(
      client_id => $client,
      scopes    => $scope,
      type      => 'refresh',
      user_id   => $user_id,
    );

    $Grant->store_access_token(
      client_id         => $client,
      ( $grant_type ne 'password' ? ( auth_code => $auth_code ) : () ),
      access_token      => $access_token,
      expires_in        => $expires_in,
      scopes            => $scope,
      ( $grant_type eq 'client_credentials'
        ? ()
        : (
          refresh_token     => $refresh_token,
          old_refresh_token => $old_refresh_token,
        )
      ),
      mojo_controller   => $self,
    );

    $status        = 200;
    $json_response = {
      access_token  => $access_token,
      token_type    => 'Bearer',
      expires_in    => $expires_in,
      ( $grant_type eq 'client_credentials'
        ? ()
        : ( refresh_token => $refresh_token ),
      )
    };

  } elsif ( $error ) {
      $json_response->{error} = $error;
  } else {
    # callback has not returned anything, assume server error
    my $method = $grant_type eq 'password'
      ? 'verify_user_password' : $grant_type eq 'client_credentials'
      ? 'verify_client' : 'verify_auth_code';

    $json_response = {
      error             => 'server_error',
      error_description => "call to $method returned unexpected value",
    };
  }

  $self->res->headers->header( 'Cache-Control' => 'no-store' );
  $self->res->headers->header( 'Pragma'        => 'no-cache' );

  $self->render(
    status => $status,
    json   => $json_response,
  );
}

sub _access_token_request_check_params {
  my ( $self,$grant_type,$username,$password,$auth_code,$uri ) = @_;

  if (
    $grant_type eq 'password'
  ) {
    if ( ! $username && ! $password ) {
      $self->render(
        status => 400,
        json   => {
          error             => 'invalid_request',
          error_description => 'the request was missing one of: '
            . 'client_id, client_secret, username, password',
          error_uri         => '',
        }
      );
      return 0;
    }
  } elsif (
    $grant_type eq 'client_credentials'
  ) {
    my ( $client_id,$client_secret ) = _client_credentials_from_header( $self );

    if ( ! $client_id || ! $client_secret ) {
      $self->render(
        status => 400,
        json   => {
          error             => 'invalid_request',
          error_description => 'the request was missing an Authorization: Basic'
            . ' header or it was missing the encoded client_id:client_secret data',
          error_uri         => '',
        }
      );
      return 0;
    }
  } elsif (
    ( $grant_type ne 'authorization_code' and $grant_type ne 'refresh_token' )
    or ( $grant_type eq 'authorization_code' and ! defined( $auth_code ) )
    or ( $grant_type eq 'authorization_code' and ! defined( $uri ) )
  ) {
    $self->render(
      status => 400,
      json   => {
        error             => 'invalid_request',
        error_description => 'the request was missing one of: grant_type, '
          . 'client_id, client_secret, code, redirect_uri;'
          . 'or grant_type did not equal "authorization_code" '
          . 'or "refresh_token"',
        error_uri         => '',
      }
    );
    return 0;
  }

  return 1;
}

sub _client_credentials_from_header {
  my ( $self ) = @_;

  if ( my $auth_header = $self->req->headers->header( 'Authorization' ) ) {
    if ( my ( $encoded_details ) = ( split( 'Basic ',$auth_header ) )[1] ) {
      my $decoded_details = b64_decode( $encoded_details );
      my ( $client_id,$client_secret ) = split( ':',$decoded_details );
      return ( $client_id,$client_secret );
    }
  }
}

sub _verify_credentials {
  my (
    $self,$Grant,$grant_type,$refresh_token,$client_id,$client_secret,
    $auth_code,$username,$password,$uri
  ) = @_;

  my ( $client,$error,$scope,$user_id,$old_refresh_token );

  if ( $grant_type eq 'refresh_token' ) {
    ( $client,$error,$scope,$user_id ) = $Grant->verify_token_and_scope(
      refresh_token    => $refresh_token,
      auth_header      => $self->req->headers->header( 'Authorization' ),
      mojo_controller  => $self,
    );
    $old_refresh_token = $refresh_token;

  } elsif ( $grant_type eq 'password' ) {
    $scope = $self->every_param( 'scope' );

    ( $client,$error,$scope,$user_id ) = $Grant->verify_user_password(
      client_id       => $client_id,
      client_secret   => $client_secret,
      username        => $username,
      password        => $password,
      mojo_controller => $self,
      scopes          => $scope,
    );
  } elsif ( $grant_type eq 'client_credentials' ) {

    my $client_secret;

    ( $client,$client_secret ) = _client_credentials_from_header( $self );

    $scope = $self->every_param( 'scope' );
    my $res;

    ( $res,$error ) = $Grant->verify_client(
      client_id       => $client,
      client_secret   => $client_secret,
      scopes          => $scope,
    );

    undef( $client_id ) if ! $res;

  } else {
    ( $client,$error,$scope,$user_id ) = $Grant->verify_auth_code(
      client_id       => $client_id,
      client_secret   => $client_secret,
      auth_code       => $auth_code,
      redirect_uri    => $uri,
      mojo_controller => $self,
    );
  }

  return ( $client,$error,$scope,$user_id,$old_refresh_token );
}

=head1 SEE ALSO

L<Net::OAuth2::AuthorizationServer> - The dist that handles the bulk of the
functionality used by this plugin

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

    https://github.com/Humanstate/mojolicious-plugin-oauth2-server

=cut

1;

# vim: ts=2:sw=2:et
