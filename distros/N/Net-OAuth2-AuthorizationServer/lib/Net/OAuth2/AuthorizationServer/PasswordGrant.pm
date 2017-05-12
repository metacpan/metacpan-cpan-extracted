package Net::OAuth2::AuthorizationServer::PasswordGrant;

=head1 NAME

Net::OAuth2::AuthorizationServer::PasswordGrant - OAuth2 Resource Owner Password Credentials Grant

=head1 SYNOPSIS

  my $Grant = Net::OAuth2::AuthorizationServer::PasswordGrant->new(
    clients => {
      TrendyNewService => {
        client_secret => 'TopSecretClientSecret',
        scopes        => {
          post_images   => 1,
          annoy_friends => 1,
        },
      },
    },
    users => {
      bob => 'j$s03R#!\fs',
      tom => 'dE0@@s^tWg1',
    },
  );

  # verify a client against known clients
  my ( $is_valid,$error,$scopes ) = $Grant->verify_user_password(
    client_id     => $client_id,
    client_secret => $client_secret,
    username      => $username,
    password      => $password,
    scopes        => [ qw/ list of scopes / ],
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
    type            => 'access', # one of: access, refresh
    redirect_uri    => $redirect_uri,
    user_id         => $user_id,      # optional
  );

  # store access token
  $Grant->store_access_token(
    client_id         => $client,
    access_token      => $access_token,
    refresh_token     => $refresh_token,
    scopes            => $scopes_ref,
    old_refresh_token => $old_refresh_token,
  );

  # verify an access token
  my ( $is_valid,$error ) = $Grant->verify_access_token(
    access_token     => $access_token,
    scopes           => $scopes_ref,
    is_refresh_token => 0,
  );

  # or:
  my ( $client,$error,$scope,$user_id ) = $Grant->verify_token_and_scope(
    refresh_token    => $refresh_token,
    auth_header      => $http_authorization_header,
  );

=head1 DESCRIPTION

This module implements the OAuth2 "Resource Owner Password Credentials Grant" flow as described
at L<http://tools.ietf.org/html/rfc6749#section-4.3>.

=head1 CONSTRUCTOR ARGUMENTS

Along with those detailed at L<Net::OAuth2::AuthorizationServer::Manual/"CONSTRUCTOR ARGUMENTS">
the following are supported by this grant type:

=head2 users

A hashref of client details keyed like so:

  $username => $password

=head1 CALLBACK FUNCTIONS

The following callbacks are supported by this grant type:

  login_resource_owner_cb
  confirm_by_resource_owner_cb
  verify_client_cb
  verify_user_password_cb
  store_access_token_cb
  verify_access_token_cb

Please see L<Net::OAuth2::AuthorizationServer::Manual/"CALLBACK FUNCTIONS"> for
documentation on each callback function.

=cut

use strict;
use warnings;

use Moo;
with 'Net::OAuth2::AuthorizationServer::Defaults';

use Carp qw/ croak /;
use Types::Standard qw/ :all /;

has 'verify_user_password_cb' => (
    is       => 'ro',
    isa      => Maybe [CodeRef],
    required => 0,
);

has 'users' => (
    is       => 'ro',
    isa      => Maybe [HashRef],
    required => 0,
    default  => sub { {} },
);


sub _uses_auth_codes     { 0 };
sub _uses_user_passwords { 1 };

sub _has_users { return keys %{ shift->users // {} } ? 1 : 0 }

sub BUILD {
    my ( $self, $args ) = @_;

    if (
        # if we don't have a list of clients
        !$self->_has_clients

        # and we don't have a list of users
		and !$self->_has_users

        # we must know how to verify clients and tokens
        and (   !$args->{ verify_client_cb }
            and !$args->{ verify_user_password_cb }
            and !$args->{ store_access_token_cb }
            and !$args->{ verify_access_token_cb } )
        )
    {
        croak __PACKAGE__ . " requires either clients or overrides";
    }
}

sub verify_user_password {
    _delegate_to_cb_or_private( 'verify_user_password', @_ );
}

sub _verify_user_password {
    my ( $self, %args ) = @_;

    my ( $client_id, $client_secret, $username, $password, $scopes ) =
        @args{ qw/ client_id client_secret username password scopes / };

    my $client = $self->clients->{ $client_id }
        || return ( 0, 'unauthorized_client' );

    if (   !exists( $self->clients->{ $client_id } )
        or !exists( $self->users->{ $username } )
        or ( $client_secret ne $self->clients->{ $client_id }{ client_secret } )
        or ( $password ne $self->users->{ $username } )
    ) {
        return ( 0, 'invalid_grant' );
    }
    else {
        return ( $client_id, undef, $scopes, $username );
    }

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
