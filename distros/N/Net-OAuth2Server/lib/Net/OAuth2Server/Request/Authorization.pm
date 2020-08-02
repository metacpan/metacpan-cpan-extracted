use strict; use warnings;

package Net::OAuth2Server::Request::Authorization;
use parent 'Net::OAuth2Server::Request';
use Object::Tiny::Lvalue qw( response_type redirect_uri );

sub allowed_methods     { qw( GET HEAD POST ) }
sub required_parameters { 'response_type' }
sub set_parameters      { qw( scope response_type ) }

sub get_grant {
	my ( $self, $grant_maker ) = ( shift, shift );
	# need validated redirect_uri so cannot shortcircuit on $self->error
	my $grant = $grant_maker->for_authorization(
		$self,
		$self->param( 'client_id' ) || return,
		$self->response_type,
		$self->scope,
		$self->param( 'redirect_uri' ),
		@_,
	);
	# must compensate for lack of shortcircuit now
	$self->error ? () : $grant || ();
}

our $VERSION = '0.002';
