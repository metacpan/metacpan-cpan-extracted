package Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant;

=head1 NAME

Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant - OAuth2 Authorization Code Grant

=head1 SYNOPSIS

  my $Grant = Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant->new(
    clients => {
      TrendyNewService => {
        client_secret => 'TopSecretClientSecret',
        scopes        => {
          post_images   => 1,
          annoy_friends => 1,
        },
      },
    }
  );

  # verify a client against known clients
  my ( $is_valid,$error ) = $Grant->verify_client(
    client_id => $client_id,
    scopes    => [ qw/ list of scopes / ],
  );

  if ( ! $Grant->login_resource_owner ) {
    # resource owner needs to login
    ...
  }

  # have resource owner confirm (and perhaps modify) scopes
  my ( $confirmed,$error,$scopes_ref ) = $Grant->confirm_by_resource_owner(
    client_id       => $client_id,
    scopes          => [ qw/ list of scopes / ],
  );

  # generate a token
  my $token = $Grant->token(
    client_id       => $client_id,
    scopes          => $scopes_ref,
    type            => 'auth', # one of: auth, access, refresh
    redirect_uri    => $redirect_uri,
    user_id         => $user_id,      # optional
  );

  # store the auth code
  $Grant->store_auth_code(
    auth_code       => $auth_code,
    client_id       => $client_id,
    redirect_uri    => $uri,
    scopes          => $scopes_ref,
  );

  # verify an auth code
  my ( $client,$error,$scope,$user_id ) = $Grant->verify_auth_code(
    client_id       => $client_id,
    client_secret   => $client_secret,
    auth_code       => $auth_code,
    redirect_uri    => $uri,
  );

  # store access token
  $Grant->store_access_token(
    client_id         => $client,
    auth_code         => $auth_code,
    access_token      => $access_token,
    refresh_token     => $refresh_token,
    scopes            => $scopes_ref,
    old_refresh_token => $old_refresh_token,
  );

  # verify an access token
  my ( $is_valid,$error ) = $Grant->verify_access_token(
    access_token     => $access_token,
    scopes           => [ qw/ list of scopes / ],
    is_refresh_token => 0,
  );

  # or:
  my ( $client,$error,$scope,$user_id ) = $Grant->verify_token_and_scope(
    refresh_token    => $refresh_token,
    auth_header      => $http_authorization_header,
  );

=head1 DESCRIPTION

This module implements the OAuth2 "Authorization Code Grant" flow as described
at L<http://tools.ietf.org/html/rfc6749#section-4.1>.

=head1 CONSTRUCTOR ARGUMENTS

Along with those detailed at L<Net::OAuth2::AuthorizationServer::Manual/"CONSTRUCTOR ARGUMENTS">
the following are supported by this grant type:

=head2 auth_code_ttl

The validity period of the generated authorization code in seconds. Defaults to
600 seconds (10 minutes)

=head1 CALLBACK FUNCTIONS

The following callbacks are supported by this grant type:

  verify_client_cb
  login_resource_owner_cb
  confirm_by_resource_owner_cb
  store_auth_code_cb
  verify_auth_code_cb
  store_access_token_cb
  verify_access_token_cb

Please see L<Net::OAuth2::AuthorizationServer::Manual/"CALLBACK FUNCTIONS"> for
documentation on each callback function.

=cut

use strict;
use warnings;

use Moo;
with 'Net::OAuth2::AuthorizationServer::Defaults';

use Types::Standard qw/ :all /;
use Carp qw/ croak /;
use MIME::Base64 qw/ decode_base64 /;
use Mojo::JWT;
use Try::Tiny;

has 'auth_code_ttl' => (
    is       => 'ro',
    isa      => Int,
    required => 0,
    default  => sub { 600 },
);

has 'auth_codes' => (
    is       => 'ro',
    isa      => Maybe [HashRef],
    required => 0,
    default  => sub { {} },
);

has [
    qw/
        store_auth_code_cb
        verify_auth_code_cb
    /
] => (
    is       => 'ro',
    isa      => Maybe [CodeRef],
    required => 0,
);

sub _uses_auth_codes     { 1 };
sub _uses_user_passwords { 0 };

sub BUILD {
    my ( $self, $args ) = @_;

    if (
        # if we don't have a list of clients
        !$self->_has_clients

        # we must know how to verify clients and tokens
        and (   !$args->{ verify_client_cb }
            and !$args->{ store_auth_code_cb }
            and !$args->{ verify_auth_code_cb }
            and !$args->{ store_access_token_cb }
            and !$args->{ verify_access_token_cb } )
        )
    {
        croak __PACKAGE__ . " requires either clients or overrides";
    }
}

sub store_auth_code {
    _delegate_to_cb_or_private( 'store_auth_code', @_ );
}

sub verify_auth_code {
    _delegate_to_cb_or_private( 'verify_auth_code', @_ );
}

sub _store_auth_code {
    my ( $self, %args ) = @_;

    my ( $auth_code, $client_id, $expires_in, $uri, $scopes_ref ) =
        @args{ qw/ auth_code client_id expires_in redirect_uri scopes / };

    return 1 if $self->jwt_secret;

    $expires_in //= $self->auth_code_ttl;

    $self->auth_codes->{ $auth_code } = {
        client_id    => $client_id,
        expires      => time + $expires_in,
        redirect_uri => $uri,
        scope        => $scopes_ref,
    };

    return 1;
}

sub _verify_auth_code {
    my ( $self, %args ) = @_;

    my ( $client_id, $client_secret, $auth_code, $uri ) =
        @args{ qw/ client_id client_secret auth_code redirect_uri / };

    my $client = $self->clients->{ $client_id }
        || return ( 0, 'unauthorized_client' );

    return $self->_verify_auth_code_jwt( %args ) if $self->jwt_secret;

    my ( $sec, $usec, $rand ) = split( '-', decode_base64( $auth_code ) );

    if (   !exists( $self->auth_codes->{ $auth_code } )
        or !exists( $self->clients->{ $client_id } )
        or ( $client_secret ne $self->clients->{ $client_id }{ client_secret } )
        or $self->auth_codes->{ $auth_code }{ access_token }
        or ( $uri && $self->auth_codes->{ $auth_code }{ redirect_uri } ne $uri )
        or ( $self->auth_codes->{ $auth_code }{ expires } <= time ) )
    {

        if ( my $access_token = $self->auth_codes->{ $auth_code }{ access_token } ) {

            # this auth code has already been used to generate an access token
            # so we need to revoke the access token that was previously generated
            $self->_revoke_access_token( $access_token );
        }

        return ( 0, 'invalid_grant' );
    }
    else {
        return ( 1, undef, $self->auth_codes->{ $auth_code }{ scope } );
    }

}

sub _verify_auth_code_jwt {
    my ( $self, %args ) = @_;

    my ( $client_id, $client_secret, $auth_code, $uri ) =
        @args{ qw/ client_id client_secret auth_code redirect_uri / };

    my $client = $self->clients->{ $client_id }
        || return ( 0, 'unauthorized_client' );

    return ( 0, 'invalid_grant' )
        if ( $client_secret ne $client->{ client_secret } );

    my $auth_code_payload;

    try {
        $auth_code_payload = Mojo::JWT->new( secret => $self->jwt_secret )->decode( $auth_code );
    }
    catch {
        return ( 0, 'invalid_grant' );
    };

    if (  !$auth_code_payload
        or $auth_code_payload->{ type } ne 'auth'
        or $auth_code_payload->{ client } ne $client_id
        or ( $uri && $auth_code_payload->{ aud } ne $uri ) )
    {
        return ( 0, 'invalid_grant' );
    }

    my $scope = $auth_code_payload->{ scopes };

    return ( $client_id, undef, $scope );
}

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

    https://github.com/Humanstate/net-oauth2-authorizationserver

=cut

__PACKAGE__->meta->make_immutable;
