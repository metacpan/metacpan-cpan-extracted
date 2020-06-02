use strict; use warnings;

package Net::OAuth2Server::Request::Resource;
use parent 'Net::OAuth2Server::Request';

sub allowed_methods       { qw( GET HEAD POST ) }
sub accepted_auth         { 'Bearer' }
sub required_parameters   { 'access_token' }
sub required_confidential { 'access_token' }

sub get_grant {
	my ( $self, $grant_maker ) = ( shift, shift );
	return if $self->error;
	$grant_maker->from_bearer_token( $self, $self->param( 'access_token' ), @_ )
		or ( $self->error || $self->with_error_invalid_token, return );
}

our $VERSION = '0.001';
