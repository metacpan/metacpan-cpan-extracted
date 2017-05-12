package Net::OAuth2::AuthorizationServer::ImplicitGrant;

=head1 NAME

Net::OAuth2::AuthorizationServer::ImplicitGrant - OAuth2 Resource Owner Implicit Grant

=head1 SYNOPSIS

  my $Grant = Net::OAuth2::AuthorizationServer::ImplicitGrant->new(
    clients => {
      TrendyNewService => {
        # optional
        redirect_uri  => 'https://...',
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
    redirect_uri  => $uri,                     # optional
    scopes        => [ qw/ list of scopes / ], # optional
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
    redirect_uri    => $redirect_uri,
    user_id         => $user_id,      # optional
  );

  # store access token
  $Grant->store_access_token(
    client_id         => $client,
    access_token      => $access_token,
    scopes            => $scopes_ref,
  );

  # verify an access token
  my ( $is_valid,$error ) = $Grant->verify_access_token(
    access_token     => $access_token,
    scopes           => $scopes_ref,
  );

=head1 DESCRIPTION

This module implements the OAuth2 "Resource Owner Implicit Grant" flow as described
at L<http://tools.ietf.org/html/rfc6749#section-4.2>.

=head1 CONSTRUCTOR ARGUMENTS

Along with those detailed at L<Net::OAuth2::AuthorizationServer::Manual/"CONSTRUCTOR ARGUMENTS">
the following are supported by this grant type:

=head1 CALLBACK FUNCTIONS

The following callbacks are supported by this grant type:

  verify_client_cb
  login_resource_owner_cb
  confirm_by_resource_owner_cb
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

sub _uses_auth_codes     { 0 };
sub _uses_user_passwords { 0 };

sub BUILD {
    my ( $self, $args ) = @_;

    if (
        # if we don't have a list of clients
        !$self->_has_clients

        # we must know how to verify clients and tokens
        and (   !$args->{ verify_client_cb }
            and !$args->{ store_access_token_cb }
            and !$args->{ verify_access_token_cb } )
        )
    {
        croak __PACKAGE__ . " requires either clients or overrides";
    }
}

sub _verify_client {
    my ( $self, %args ) = @_;

    my ( $client_id, $scopes_ref, $redirect_uri )
		= @args{ qw/ client_id scopes redirect_uri / };

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
		
		if (
			# redirect_uri is optional
			$self->clients->{ $client_id }{ redirect_uri }
			&& (
				! $redirect_uri
				|| $redirect_uri ne $self->clients->{ $client_id }{ redirect_uri }
			)
		) {
			return ( 0, 'invalid_request' );
		}

		if (
			# implies Authorization Code Grant, not Implicit Grant
			$self->clients->{ $client_id }{ client_secret }
		) {
			return ( 0, 'unauthorized_client' );
		}

        return ( 1, undef, $client_scopes );
    }

    return ( 0, 'unauthorized_client' );
}

sub _verify_access_token {
    my ( $self, %args ) = @_;

	delete( $args{is_refresh_token} ); # not supported by implicit grant

    return $self->_verify_access_token_jwt( %args ) if $self->jwt_secret;

    my ( $a_token, $scopes_ref ) =
        @args{ qw/ access_token scopes / };

    if ( exists( $self->access_tokens->{ $a_token } ) ) {

        if ( $self->access_tokens->{ $a_token }{ expires } <= time ) {
            $self->_revoke_access_token( $a_token );
            return ( 0, 'invalid_grant' );
        }
        elsif ( $scopes_ref ) {

            foreach my $scope ( @{ $scopes_ref // [] } ) {
                return ( 0, 'invalid_grant' )
                    if !$self->_has_scope( $scope, $self->access_tokens->{ $a_token }{ scope } );
            }

        }

        return ( $self->access_tokens->{ $a_token }{ client_id }, undef );
    }

    return ( 0, 'invalid_grant' );
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
