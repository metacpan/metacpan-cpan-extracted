package RDF::Crypt::Role::WithPublicKeys;

use 5.010;
use Any::Moose 'Role';

use Crypt::OpenSSL::RSA qw[];
use File::Slurp qw[slurp];
use RDF::TrineX::Functions -shortcuts;
use Web::ID;

use namespace::clean;

BEGIN {
	$RDF::Crypt::Role::WithPublicKeys::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Crypt::Role::WithPublicKeys::VERSION   = '0.002';
}

has public_keys => (
	is         => 'ro',
	isa        => 'ArrayRef[Crypt::OpenSSL::RSA]',
	lazy_build => 1,
);

has webid => (
	is         => 'ro',
	isa        => 'Str',
	required   => 0,
);

has webid_san => (
	is         => 'ro',
	isa        => 'Web::ID::SAN::URI | Undef',
	lazy_build => 1,
	handles    => {
		webid_model  => 'model',
	},
);

sub new_from_file
{
	my ($class, $key_file) = @_;
	return $class->new_from_string( scalar slurp($key_file) );
}

sub new_from_string
{
	my ($class, $key_string) = @_;
	my $key = Crypt::OpenSSL::RSA->new_public_key($key_string);
	$class->new_from_pubkey($key);
}

sub new_from_pubkey
{
	my ($class, $key) = @_;
	$key->use_pkcs1_padding;
	# OpenSSL command-line tool defaults to this...
	$key->use_md5_hash;
	$class->new( public_keys => [$key] );
}

sub new_from_webid
{
	my ($class, $uri) = @_;
	$class->new(
		webid => "$uri",
	);
}

sub _build_webid_san
{
	my ($self) = @_;
	Web::ID::SAN::URI->new(value => $self->webid)
}

sub _build_public_keys
{
	my ($self) = @_;
	return unless $self->webid_san;
	
	[
		map {
			Crypt::OpenSSL::RSA->new_key_from_parameters(
				Crypt::OpenSSL::Bignum->new_from_decimal($_->modulus->bstr),   # n
				Crypt::OpenSSL::Bignum->new_from_decimal($_->exponent->bstr),  # e
			)
		}
		$self->webid_san->associated_keys
	]
}

1;

__END__

=head1 NAME

RDF::Crypt::Role::WithPublicKeys - role for objects that have public keys

=head1 DESCRIPTION

=head2 Attributes

=over

=item C<< public_keys >>

Read only; ArrayRef[Crypt::OpenSSL::RSA]; lazy build.

=item C<< webid >>

Read only; Str.

=item C<< webid_san >>

Read only; Web::ID::SAN::URI|Undef; lazy build.

=back

=head2 Additional Constructor Methods

=over

=item C<< new_from_file($file) >>

Given a filename containing a DER or PEM encoded RSA public key, constructs
an object.

=item C<< new_from_string($str) >>

Given a string containing a DER or PEM encoded RSA public key, constructs
an object.

=item C<< new_from_pubkey($key) >>

Given a L<Crypt::OpenSSL::RSA> public key object, constructs an object.

=item C<< new_from_webid($uri) >>

Given a WebID URI with one of more FOAF+SSL public keys, constructs an 
object. If multiple public keys are associated with the same WebID, then
the one with the largest key size (most secure) is typically used.

=back

=head2 Object Method

=over

=item C<< webid_model >>

Calls C<model> on C<webid_san>.

=back

=head1 SEE ALSO

L<RDF::Crypt>,
L<RDF::Crypt::Encrypter>,
L<RDF::Crypt::Verifier>.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010, 2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

