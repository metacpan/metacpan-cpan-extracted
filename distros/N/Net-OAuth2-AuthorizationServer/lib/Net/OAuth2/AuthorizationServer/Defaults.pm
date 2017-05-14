package Net::OAuth2::AuthorizationServer::Defaults;

use strict;
use warnings;

use Moo::Role;

use Types::Standard qw/ :all /;
use Carp qw/ croak /;
use Mojo::JWT;
use Crypt::PRNG qw/ random_string /;
use Try::Tiny;
use Time::HiRes qw/ gettimeofday /;
use MIME::Base64 qw/ encode_base64 /;

has 'jwt_secret' => (
    is       => 'ro',
    isa      => Str,
    required => 0,
);

has 'access_token_ttl' => (
    is       => 'ro',
    isa      => Int,
    required => 0,
    default  => sub { 3600 },
);

has [
    qw/
        clients
        access_tokens
        refresh_tokens
    /
] => (
    is       => 'ro',
    isa      => Maybe [HashRef],
    required => 0,
    default  => sub { {} },
);

has [
    qw/
        verify_client_cb
        store_access_token_cb
        verify_access_token_cb
        login_resource_owner_cb
        confirm_by_resource_owner_cb
    /
] => (
    is       => 'ro',
    isa      => Maybe [CodeRef],
    required => 0,
);

sub _has_clients { return keys %{ shift->clients // {} } ? 1 : 0 }
sub _uses_auth_codes { die "You must override _uses_auth_codes" };

sub verify_client {
    _delegate_to_cb_or_private( 'verify_client', @_ );
}

sub store_access_token {
    _delegate_to_cb_or_private( 'store_access_token', @_ );
}

sub verify_access_token {
    _delegate_to_cb_or_private( 'verify_access_token', @_ );
}

sub login_resource_owner {
    _delegate_to_cb_or_private( 'login_resource_owner', @_ );
}

sub confirm_by_resource_owner {
    _delegate_to_cb_or_private( 'confirm_by_resource_owner', @_ );
}

sub verify_token_and_scope {
    my ( $self, %args ) = @_;

    my ( $refresh_token, $scopes_ref, $auth_header, $is_legacy_caller ) =
        @args{ qw/ refresh_token scopes auth_header / };

    my $access_token;

    if ( !$refresh_token ) {
        if ( $auth_header ) {
            my ( $auth_type, $auth_access_token ) = split( / /, $auth_header );

            if ( $auth_type ne 'Bearer' ) {
                return ( 0, 'invalid_request' );
            }
            else {
                $access_token = $auth_access_token;
            }
        }
        else {
            return ( 0, 'invalid_request' );
        }
    }
    else {
        $access_token = $refresh_token;
    }

    return $self->verify_access_token(
        %args,
        access_token     => $access_token,
        scopes           => $scopes_ref,
        is_refresh_token => $refresh_token,
    );
}

sub _delegate_to_cb_or_private {

    my $method = shift;
    my $self   = shift;
    my %args   = @_;

    my $cb_method = "${method}_cb";
    my $p_method  = "_$method";

    if ( my $cb = $self->$cb_method ) {
        return $cb->( %args );
    }
    else {
        return $self->$p_method( %args );
    }
}

sub _login_resource_owner { 1 }

sub _confirm_by_resource_owner {
	my ( $self,%args ) = @_;

	# out of the box we just pass back "yes you can" and the list of scopes
	# note the wantarray is here for backwards compat as this method used
	# to just return 1 but now passing the scopes back requires an array
	return wantarray
		? ( 1,undef,$args{scopes} // [] )
		: 1;
}

sub _verify_client {
    my ( $self, %args ) = @_;

    my ( $client_id, $scopes_ref ) = @args{ qw/ client_id scopes / };

    if ( my $client = $self->clients->{ $client_id // '' } ) {
        my $client_scopes = [];

        foreach my $scope ( @{ $scopes_ref // [] } ) {
            if ( ! exists($self->clients->{ $client_id }{ scopes }{ $scope }) ) {
                return ( 0, 'invalid_scope' );
            }
            elsif ( $self->clients->{ $client_id }{ scopes }{ $scope } ) {
                push @{$client_scopes}, $scope;
            }
        }

        return ( 1, undef, $client_scopes );
    }

    return ( 0, 'unauthorized_client' );
}

sub _store_access_token {
    my ( $self, %args ) = @_;

    my ( $c_id, $auth_code, $access_token, $refresh_token, $expires_in, $scope, $old_refresh_token )
        = @args{
        qw/ client_id auth_code access_token refresh_token expires_in scopes old_refresh_token / };

    $expires_in //= $self->access_token_ttl;

    return 1 if $self->jwt_secret;

    if ( !defined( $auth_code ) && $old_refresh_token ) {

        # must have generated an access token via a refresh token so revoke the old
        # access token and refresh token and update the auth_codes hash to store the
        # new one (also copy across scopes if missing)
        $auth_code = $self->refresh_tokens->{ $old_refresh_token }{ auth_code };

        my $prev_access_token = $self->refresh_tokens->{ $old_refresh_token }{ access_token };

        # access tokens can be revoked, whilst refresh tokens can remain so we
        # need to get the data from the refresh token as the access token may
        # no longer exist at the point that the refresh token is used
        $scope //= $self->refresh_tokens->{ $old_refresh_token }{ scope };

        $self->_revoke_access_token( $prev_access_token );
    }

    delete( $self->refresh_tokens->{ $old_refresh_token } )
        if $old_refresh_token;

    $self->access_tokens->{ $access_token } = {
        scope         => $scope,
        expires       => time + $expires_in,
        refresh_token => $refresh_token // undef,
        client_id     => $c_id,
    };

	if ( $refresh_token ) {

		$self->refresh_tokens->{ $refresh_token } = {
			scope        => $scope,
			client_id    => $c_id,
			access_token => $access_token,
			( $self->_uses_auth_codes ? ( auth_code => $auth_code ) : () ),
		};
	}

	if ( $self->_uses_auth_codes ) {
    	$self->auth_codes->{ $auth_code }{ access_token } = $access_token;
	}

    return $c_id;
}

sub _verify_access_token {
    my ( $self, %args ) = @_;
    return $self->_verify_access_token_jwt( %args ) if $self->jwt_secret;

    my ( $a_token, $scopes_ref, $is_refresh_token ) =
        @args{ qw/ access_token scopes is_refresh_token / };

    if ( $is_refresh_token
        && exists( $self->refresh_tokens->{ $a_token } ) )
    {

        if ( $scopes_ref ) {
            foreach my $scope ( @{ $scopes_ref // [] } ) {
                return ( 0, 'invalid_grant' )
                    if !$self->_has_scope( $scope, $self->refresh_tokens->{ $a_token }{ scope } );
            }
        }

        return ( $self->refresh_tokens->{ $a_token }{ client_id }, undef );
    }
    elsif ( exists( $self->access_tokens->{ $a_token } ) ) {

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

sub _has_scope {
    my ( $self, $scope, $available_scopes ) = @_;
    return scalar grep { $_ eq $scope } @{ $available_scopes // [] };
}

sub _verify_access_token_jwt {
    my ( $self, %args ) = @_;

    my ( $access_token, $scopes_ref, $is_refresh_token ) =
        @args{ qw/ access_token scopes is_refresh_token / };

    my $access_token_payload;

    try {
        $access_token_payload =
            Mojo::JWT->new( secret => $self->jwt_secret )->decode( $access_token );
    }
    catch {
        return ( 0, 'invalid_grant' );
    };

    if (
        $access_token_payload
        && (   $access_token_payload->{ type } eq 'access'
            || $is_refresh_token && $access_token_payload->{ type } eq 'refresh' )
        )
    {

        if ( $scopes_ref ) {
            foreach my $scope ( @{ $scopes_ref // [] } ) {
                return ( 0, 'invalid_grant' )
                    if !$self->_has_scope( $scope, $access_token_payload->{ scopes } );
            }
        }

        return ( $access_token_payload, undef );
    }

    return ( 0, 'invalid_grant' );
}

sub _revoke_access_token {
    my ( $self, $access_token ) = @_;
    delete( $self->access_tokens->{ $access_token } );
}

sub token {
    my ( $self, %args ) = @_;

    my ( $client_id, $scopes, $type, $redirect_uri, $user_id, $claims ) =
        @args{ qw/ client_id scopes type redirect_uri user_id jwt_claims_cb / };

	if (
		! $self->_uses_auth_codes
		&& $type eq 'auth'
	) {
		croak "Invalid type for ->token ($type)";
	}

    my $ttl = $type eq 'auth' ? $self->auth_code_ttl : $self->access_token_ttl;
    undef( $ttl ) if $type eq 'refresh';
    my $code;

    if ( !$self->jwt_secret ) {
        my ( $sec, $usec ) = gettimeofday;
        $code = encode_base64( join( '-', $sec, $usec, rand(), random_string( 30 ) ), '' );
    }
    else {
		my $jti = random_string( 32 );

        $code = Mojo::JWT->new(
            ( $ttl ? ( expires => time + $ttl ) : () ),
            secret  => $self->jwt_secret,
            set_iat => 1,

            # https://tools.ietf.org/html/rfc7519#section-4
            claims => {

                # Registered Claim Names
                aud => $redirect_uri,         # the "audience"
                jti => $jti,

                # Private Claim Names
                user_id => $user_id,
                client  => $client_id,
                type    => $type,
                scopes  => $scopes,

				( $claims
					? ( $claims->({
							user_id      => $user_id,
							client_id    => $client_id,
							type         => $type,
							scopes       => $scopes,
							redirect_uri => $redirect_uri,
							jti          => $jti,
					}) )
					: ()
				),
            },
        )->encode;
    }

    return $code;
}

__PACKAGE__->meta->make_immutable;
