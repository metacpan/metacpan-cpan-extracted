package RDF::Crypt::Role::WithPrivateKey;

use 5.010;
use Any::Moose 'Role';

use Crypt::OpenSSL::RSA qw[];
use File::Slurp qw[slurp];

use namespace::clean;

BEGIN {
	$RDF::Crypt::Role::WithPrivateKey::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Crypt::Role::WithPrivateKey::VERSION   = '0.002';
}

has private_key => (
	is        => 'ro',
	isa       => 'Crypt::OpenSSL::RSA',
	required  => 1,
);

sub new_from_file
{
	my ($class, $key_file) = @_;
	return $class->new_from_string(scalar slurp($key_file));
}

sub new_from_string
{
	my ($class, $key_string) = @_;
	my $key = Crypt::OpenSSL::RSA->new_private_key($key_string);
	return $class->new_from_privkey($key);
}

sub new_from_privkey
{
	my ($class, $key) = @_;
	$key->use_pkcs1_padding;
	# OpenSSL command-line tool defaults to this...
	$key->use_md5_hash;	
	$class->new(private_key => $key);
}

1;

__END__

=head1 NAME

RDF::Crypt::Role::WithPublicKeys - role for objects that have public keys

=head1 DESCRIPTION

=head2 Attribute

=over

=item C<< private_key >>

Read only; Crypt::OpenSSL::RSA; required.

=back

=head2 Additional Constructor Methods

=over

=item C<< new_from_file($file) >>

Given a filename containing a DER or PEM encoded RSA private key, constructs
an object.

=item C<< new_from_string($str) >>

Given a string containing a DER or PEM encoded RSA private key, constructs
an object.

=item C<< new_from_privkey($key) >>

Given a L<Crypt::OpenSSL::RSA> private key object, constructs an object.

=back

=head1 SEE ALSO

L<RDF::Crypt>,
L<RDF::Crypt::Decrypter>,
L<RDF::Crypt::Signer>.

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

