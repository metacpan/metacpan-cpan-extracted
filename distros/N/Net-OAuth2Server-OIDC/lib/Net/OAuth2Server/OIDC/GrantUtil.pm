use strict; use warnings;

package Net::OAuth2Server::OIDC::GrantUtil;
our $VERSION = '0.006';

sub provides_refresh_token { shift->scope->contains( 'offline_access' ) }

sub userinfo_claims {
	my $scope = shift->scope;
	return unless $scope->contains( 'openid' );
	( qw( sub ), (
		$scope->contains( 'profile' ) ? qw(
			name family_name given_name middle_name nickname preferred_username
			profile picture website
			gender
			birthdate
			zoneinfo locale
			updated_at
		) : (),
		$scope->contains( 'email' )   ? qw( email email_verified ) : (),
		$scope->contains( 'address' ) ? qw( address ) : (),
		$scope->contains( 'phone' )   ? qw( phone_number phone_number_verified ) : (),
	) );
}

1;
