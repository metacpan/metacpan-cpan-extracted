use strict; use warnings;

package Net::OAuth2Server::Request::Token::RefreshToken;
use parent 'Net::OAuth2Server::Request';

sub grant_type { 'refresh_token' }
sub allowed_methods { 'POST' }
sub required_parameters { qw( refresh_token client_id client_secret ) }

sub get_grant {
	my ( $self, $grant_maker ) = ( shift, shift );
	return if $self->error;
	$grant_maker->from_refresh_token( $self, $self->params( $self->required_parameters ), @_ );
}

our $VERSION = '0.002';
