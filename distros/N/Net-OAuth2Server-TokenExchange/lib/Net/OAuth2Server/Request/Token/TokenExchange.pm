use strict; use warnings;

package Net::OAuth2Server::Request::Token::TokenExchange;
use parent 'Net::OAuth2Server::Request';

our $VERSION = '0.003';

sub grant_type { 'urn:ietf:params:oauth:grant-type:token-exchange' }
sub allowed_methods { 'POST' }
sub grant_parameters { qw( subject_token_type subject_token ) }
*required_parameters = \&grant_parameters;

sub get_grant {
	my ( $self, $grant_maker ) = ( shift, shift );
	return if $self->error;

	if ( $self->has_param( 'actor_token' ) ) {
		$self->ensure_required( 'actor_token_type' ) or return;
	}
	elsif ( $self->has_param( 'actor_token_type' ) ) {
		$self->set_error_invalid_request( 'extraneous parameter: actor_token_type' );
		return;
	}

	$grant_maker->from_subject_token( $self, $self->params( $self->grant_parameters ), @_ );
}

1;
