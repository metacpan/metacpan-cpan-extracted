use strict; use warnings;

package Net::OAuth2Server::Request::Token::ClientCredentials;
use parent 'Net::OAuth2Server::Request';

sub grant_type { 'client_credentials' }
sub allowed_methods { 'POST' }
sub required_parameters { qw( client_id client_secret ) }

sub get_grant {
	my ( $self, $grant_maker ) = ( shift, shift );
	return if $self->error;
	$grant_maker->from_client_credentials( $self, $self->params( $self->required_parameters ), @_ );
}

our $VERSION = '0.002';
