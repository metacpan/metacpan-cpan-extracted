use strict; use warnings;

package Net::OAuth2Server::Request::Token::AuthorizationCode;
use parent 'Net::OAuth2Server::Request';

sub grant_type { 'authorization_code' }
sub allowed_methods { 'POST' }
sub required_parameters { qw( code redirect_uri client_id client_secret ) }

sub get_grant {
	my ( $self, $grant_maker ) = ( shift, shift );
	return if $self->error;
	$grant_maker->from_auth_code( $self, $self->params( $self->required_parameters ), @_ );
}

our $VERSION = '0.002';
