use strict; use warnings;

package Net::OAuth2Server::Request::Token;
use parent 'Net::OAuth2Server::Request';

sub allowed_methods       { 'POST' }
sub accepted_auth         { 'Basic' }
sub required_parameters   { 'grant_type' }
sub confidential_parameters { 'client_secret' }

sub get_grant {}

sub dispatch {
	my ( $self, @class ) = ( shift, @_ );
	return $self if $self->error;
	for ( @class ) { s/\A\+/__PACKAGE__.'::'/e unless ref }
	my $type = $self->param( 'grant_type' );
	my ( $class ) = defined $type ? grep $type eq $_->grant_type, @class : ();
	$class ? $class->new( %$self ) : $self->set_error_unsupported_grant_type;
}

our $VERSION = '0.004';
