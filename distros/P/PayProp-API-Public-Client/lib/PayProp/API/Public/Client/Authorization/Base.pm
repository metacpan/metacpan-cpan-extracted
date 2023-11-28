package PayProp::API::Public::Client::Authorization::Base;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::Attribute::Token /;
with qw/ PayProp::API::Public::Client::Role::Attribute::Storage /;

use Mojo::Promise;


has is_token_from_storage => ( is => 'rw', isa => 'Bool' );

sub token_request_p {
	my ( $self ) = @_;

	$self->is_token_from_storage( 0 );

	return $self->_token_request_p unless $self->has_storage;

	return $self
		->storage
		->get_p( $self->storage_key )
		->then( sub {
			my ( $token ) = @_;

			if ( $token ) {
				$self->is_token_from_storage( 1 );

				return {
					token => $token,
					token_type => $self->token_type,
				};
			}

			return $self
				->_token_request_p
				->then( sub {
					my ( $token_info ) = @_;

					return $self
						->storage
						->set_p( $self->storage_key, $token_info->{token} )
						->then( sub { $token_info } )
					;
				} )
			;
		} )
	;
}

sub remove_token_from_storage_p {
	my ( $self ) = @_;

	$self->is_token_from_storage( 0 );

	return Mojo::Promise
		->new( sub {
			my ( $resolve ) = @_;

			return $resolve->(
				! $self->has_storage
					? 1
					: $self->storage->delete_p( $self->storage_key )
			);
		} )
	;
}

sub _token_request_p { die '_token_request_p not implemented' }

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=head1 NAME

PayProp::API::Public::Client::Authorization::Base - Base module for authorization modules.

=head1 SYNOPSIS

	{
		package PayProp::API::Public::Client::Authorization::Custom;

		use Mouse;
		extends qw/ PayProp::API::Public::Client::Authorization::Base /;

		...;

		__PACKAGE__->meta->make_immutable;
	}

	my $CustomAuthorization = PayProp::API::Public::Client::Authorization::Custom->new;

=head1 DESCRIPTION

*DO NOT INSTANTIATE THIS MODULE DIRECTLY*

Base authorization module for alternative implementations. This module expects for C<PayProp::API::Public::Client::Authorization::*>
modules to define their own implementation on how the token should be returned. The base module will handle retrieving token either
directly or from a defined storage solution.

The only requirement this module has is for extending modules to override C<_token_request_p> method that returns a C<Mojo::Promise>
containing C<token> and C<token_type> in a HashRef.

See L<PayProp::API::Public::Client::Authorization::ClientCredentials> implementation using storage and request pattern, and
L<PayProp::API::Public::Client::Authorization::APIKey> for returning token information directly.

=head1 ATTRIBUTES

C<PayProp::API::Public::Client::Authorization::Base> implements the following attributes.

=head2 is_token_from_storage

	$CustomAuthorization->is_token_from_storage(0);
	my $is_token_from_storage = $CustomAuthorization->is_token_from_storage;

=head1 METHODS

=head2 token_request_p

	### APIkey ###

	$APIKeyAuthorization
		->_token_request_p
		->then( sub {
			my ( $token_info ) = @_;

			cmp_deeply
				$token_info,
				{
					token => 'AgencyAPIKey',
					token_type => 'APIkey',
				}
		} )
		->wait
	;


	### OAuth v2.0 client access token ###

	$ClientCredentials
		->_token_request_p
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

=head1 AUTHOR

Yanga Kandeni E<lt>yangak@cpan.orgE<gt>

Valters Skrupskis E<lt>malishew@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2023- PayProp

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

L<https://github.com/Humanstate/api-client-public-module>

=cut




