package PayProp::API::Public::Client::Role::Encrypt;

use strict;
use warnings;

use Mouse::Role;

use Crypt::CBC;
use Mojo::Promise;


has encryption_secret => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has Crypt => (
	is => 'ro',
	isa => 'Crypt::CBC',
	lazy => 1,
	default => sub {
		my ( $self ) = @_;

		return Crypt::CBC->new(
			-key => $self->encryption_secret,
			-pass => $self->encryption_secret,
			-pbkdf => 'pbkdf2',
			-cipher => 'Cipher::AES',
		);
	},
);

sub encrypt_hex_p {
	my ( $self, $to_encrypt ) = @_;

	return Mojo::Promise
		->new( sub {
			my ( $resolve ) = @_;

			return $resolve->( $self->Crypt->encrypt_hex( $to_encrypt ) );
		} )
	;
}

sub decrypt_hex_p {
	my ( $self, $to_decrypt ) = @_;

	return Mojo::Promise
		->new( sub {
			my ( $resolve ) = @_;

			my $decrypted_value;
			eval { $decrypted_value = $self->Crypt->decrypt_hex( $to_decrypt ) };

			return $resolve->( $decrypted_value );
		} )
	;
}

1;

__END__

=encoding utf-8

=head1 NAME

	PayProp::API::Public::Client::Role::Encrypt - Role to encapsulate value encryption.

=head1 SYNOPSIS

	package Module::Requiring::Ecryption;
	with qw/ PayProp::API::Public::Client::Role::Encrypt /;

	...;

	__PACKAGE__->meta->make_immutable;

	my $Module = Module::Requiring::Ecryption->new( encryption_secret => 'meh' );
	my $Promise = $Module
		->encrypt_hex_p('TO_ENCRYPT')
		->then(sub {
			my ( $encrypted_value ) = @_;
			...;
		})
		->wait
	;

=head1 DESCRIPTION

Define methods to encrypt and decrypt tokens, and return C<Mojo::Promise>.

=head1 METHODS

=head2 encrypt_hex_p

Method to encrypt given value.

	$self
		->encrypt_hex_p('TO_ENCRYPT')
		->then(sub {
			my ( $encrypted_value ) = @_;
			...;
		})
		->wait
	;

Returns C<Mojo::Promise> that resolved with encrypted value on success.

=head2 decrypt_hex_p

Method to decrypt given value.

	$self
		->decrypt_hex_p('TO_DECRYPT')
		->then(sub {
			my ( $decrypted_value ) = @_;
			...;
		})
		->wait
	;

Returns C<Mojo::Promise> that resolved with decrypted value on success.

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
