use strict; use warnings;

package Net::OAuth2Server::Request::Token::Password;
use parent 'Net::OAuth2Server::Request';

sub grant_type { 'password' }
sub allowed_methods { 'POST' }
sub grant_parameters { qw( username password client_id client_secret ) }
*required_parameters = \&grant_parameters;

sub get_grant {
	my ( $self, $grant_maker ) = ( shift, shift );
	return if $self->error;
	$grant_maker->from_password( $self, $self->params( $self->grant_parameters ), @_ );
}

our $VERSION = '0.003';
