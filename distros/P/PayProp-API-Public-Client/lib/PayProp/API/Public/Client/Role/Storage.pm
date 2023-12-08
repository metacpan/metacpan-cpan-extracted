package PayProp::API::Public::Client::Role::Storage;

use strict;
use warnings;

use Mouse::Role;
with qw/ PayProp::API::Public::Client::Role::Encrypt /;

use PayProp::API::Public::Client::Exception::Storage;

has cache_prefix => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub { 'PayPropAPIToken_' }
);

has cache_ttl_in_seconds => (
	is => 'ro',
	isa => 'Int',
	lazy => 1,
	default => sub { 3600 * 12 } # TTL: 12 hours
);

has throw_on_storage_unavailable => ( is => 'ro', isa => 'Bool', lazy => 1, default => sub { 0 } );

requires qw/
	_set_p
	_get_p
	_ping_p
	_delete_p
/;

sub ping_p {
	my ( $self ) = @_;

	return $self
		->_ping_p
		->catch( sub { $self->_handle_exception( @_ ) } )
	;
}

sub set_p {
	my ( $self, $key, $token ) = @_;

	die 'key and token are required for set_p' unless $key && $token;

	return $self
		->encrypt_hex_p( $token )
		->then( sub {
			my ( $encrypted_token ) = @_;

			return $self->_set_p( $key, $encrypted_token );
		} )
		->catch( sub { $self->_handle_exception( @_ ) } )
	;
}

sub get_p {
	my ( $self, $key ) = @_;

	die 'key is required for get_p' unless $key;

	return $self
		->_get_p( $key )
		->then( sub { $self->decrypt_hex_p( @_ ) } )
		->catch( sub { $self->_handle_exception( @_ ) } )
	;
}

sub delete_p {
	my ( $self, $key ) = @_;

	die 'key is required for delete_p' unless $key;

	return $self
		->_delete_p( $key )
		->catch( sub { $self->_handle_exception( @_ ) } )
	;
}

sub _handle_exception {
	my ( $self, $exception ) = @_;

	$exception //= 'UNKKNOWN STORAGE ERROR';

	# stop promise chain
	PayProp::API::Public::Client::Exception::Storage->throw("$exception")
		if $self->throw_on_storage_unavailable
	;

	warn "$exception";

	return undef; # continue promise chain
}

1;

__END__

=encoding utf-8

=head1 NAME

	PayProp::API::Public::Client::Role::Storage - Role to encapsulate storage SETers and GETers.

=head1 SYNOPSIS

	package Module::Requiring::Storage;
	with qw/ PayProp::API::Public::Client::Role::Storage /;

	# To be implemented by the consumer of the role
	sub _set_p { ... }
	sub _get_p { ... }
	sub _ping_p { ... }
	sub _delete_p { ... }

	__PACKAGE__->meta->make_immutable;

	my $Module = Module::Requiring::Storage->new( encryption_secret => 's3cr3t123123' );
	$Module
		->set_p( 'KEY', 'VALUE' )
		->then( sub { ... } )
		->wait
	;

=head1 DESCRIPTION

Storage role that defines how storage solutions must be implemented.

It's expected to return C<Mojo::Promise> from implemented methods.
See C<PayProp::API::Public::Client::Authorization::Storage::Memcached> for an example implementation.

=head1 METHODS

=head2 ping_p

Ping method to be overriden via C<_ping_p> to check if storage is available.

	my $Promise = $self->ping_p;

Return:

	C<Mojo::Promise> containing truthy value on success.
	Throws C<PayProp::API::Public::Client::Exception::Storage> if storage is not available and C<throw_on_storage_unavailable> is set to truthy value.

=head2 set_p

Set method to be overriden via C<_set_p> to store value.

	my $Promise = $self->set_p( 'KEY', 'VALUE' );

Return:

	C<Mojo::Promise> containing truthy value on success. Throws on missing key or value.
	Throws C<PayProp::API::Public::Client::Exception::Storage> if storage is not available and C<throw_on_storage_unavailable> is set to truthy value.

=head2 get_p

Get method to be overriden via C<_get_p> to retrieve stored value.

	my $Promise = $self->get_p('KEY');

Return:

	C<Mojo::Promise> containing stored value on success. Throws on missing key.
	Throws C<PayProp::API::Public::Client::Exception::Storage> if storage is not available and C<throw_on_storage_unavailable> is set to truthy value.

=head2 delete_p

Delete method to be overriden via C<_delete_p> to remove stored value.

	my $Promise = $self->delete_p('KEY');

Return:

	C<Mojo::Promise> containing truthy value on success. Throws on missing key.
	Throws C<PayProp::API::Public::Client::Exception::Storage> if storage is not available and C<throw_on_storage_unavailable> is set to truthy value.


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

