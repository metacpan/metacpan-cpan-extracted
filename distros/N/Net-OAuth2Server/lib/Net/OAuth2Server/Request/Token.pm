use strict; use warnings;

package Net::OAuth2Server::Request::Token;
use parent 'Net::OAuth2Server::Request';

sub allowed_methods       { 'POST' }
sub accepted_auth         { 'Basic' }
sub required_parameters   { 'grant_type' }
sub required_confidential { 'client_secret' }

sub dispatch {
	my ( $self, @class ) = ( shift, @_ );
	return $self if $self->error;
	my %grant_type_class = map { s/\A(\+?)/__PACKAGE__.'::' x !$1/e unless ref; ( $_->grant_type, $_ ) } @class;
	my $class = $grant_type_class{ $self->param( 'grant_type' ) };
	$class ? $class->new( %$self ) : $self->with_error_unsupported_grant_type;
}

our $VERSION = '0.001';
