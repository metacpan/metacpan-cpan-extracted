package Net::OAuth2::AuthorizationServer::ClientCredentialsGrant;

=head1 NAME

Net::OAuth2::AuthorizationServer::ClientCredentialsGrant - OAuth2 Client Credentials Grant

=head1 SYNOPSIS

  my $Grant = Net::OAuth2::AuthorizationServer::ClientCredentialsGrant->new(
    clients => {
      TrendyNewService => {
        client_secret  => 'TopSecretClientSecret',
        # optional
        scopes        => {
          post_images   => 1,
          annoy_friends => 1,
        },
      },
    }
  );

  # verify a client against known clients
  my ( $is_valid,$error,$scopes ) = $Grant->verify_client(
    client_id     => $client_id,
	client_secret => $client_secret,
    scopes        => [ qw/ list of scopes / ], # optional
  );

  # generate a token
  my $token = $Grant->token(
    client_id       => $client_id,
    scopes          => [ qw/ list of scopes / ],
    user_id         => $user_id,      # optional
  );

  # store access token
  $Grant->store_access_token(
    client_id         => $client,
    access_token      => $access_token,
    scopes            => [ qw/ list of scopes / ],
  );

  # verify an access token
  my ( $is_valid,$error ) = $Grant->verify_access_token(
    access_token     => $access_token,
    scopes           => [ qw/ list of scopes / ],
  );

=head1 DESCRIPTION

This module implements the OAuth2 "Client Credentials Grant" flow as described
at L<http://tools.ietf.org/html/rfc6749#section-4.4>.

=head1 CONSTRUCTOR ARGUMENTS

Along with those detailed at L<Net::OAuth2::AuthorizationServer::Manual/"CONSTRUCTOR ARGUMENTS">
the following are supported by this grant type:

=head1 CALLBACK FUNCTIONS

The following callbacks are supported by this grant type:

  verify_client_cb
  store_access_token_cb
  verify_access_token_cb

Please see L<Net::OAuth2::AuthorizationServer::Manual/"CALLBACK FUNCTIONS"> for
documentation on each callback function.

=cut

use strict;
use warnings;

use Moo;

# prety much the same as implicit grant but even simpler
extends 'Net::OAuth2::AuthorizationServer::ImplicitGrant';

use Carp qw/ croak /;
use Types::Standard qw/ :all /;

sub _uses_auth_codes     { 0 };
sub _uses_user_passwords { 0 };

sub _verify_client {
    my ( $self, %args ) = @_;

    my ( $client_id, $scopes_ref, $client_secret )
        = @args{ qw/ client_id scopes client_secret / };

    if ( my $client = $self->clients->{ $client_id } ) {
        my $client_scopes = [];

        foreach my $scope ( @{ $scopes_ref // [] } ) {
            if ( ! exists($self->clients->{ $client_id }{ scopes }{ $scope }) ) {
                return ( 0, 'invalid_scope' );
            }
            elsif ( $self->clients->{ $client_id }{ scopes }{ $scope } ) {
                push @{$client_scopes}, $scope;
            }
        }

        return ( 0, 'invalid_grant' )
            if ! defined $client_secret;

        if ( $client_secret ne $self->clients->{ $client_id }{ client_secret } ) {
            return ( 0, 'invalid_grant' );
        }

        return ( 1, undef, $client_scopes );
    }

    return ( 0, 'unauthorized_client' );
}

sub _verify_access_token {
    my ( $self, %args ) = @_;
	return $self->SUPER::_verify_access_token( %args );
}

sub _store_access_token {
    my ( $self, %args ) = @_;
	return $self->SUPER::_store_access_token( %args );
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
