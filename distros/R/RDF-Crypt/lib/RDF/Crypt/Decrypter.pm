package RDF::Crypt::Decrypter;

use 5.010;
use Any::Moose;
with qw(
	RDF::Crypt::Role::WithPrivateKey
	RDF::Crypt::Role::DoesDecrypt
	RDF::Crypt::Role::DoesEncrypt
	RDF::Crypt::Role::ToString
);

use MIME::Base64 qw(
	decode_base64
	encode_base64
);

use namespace::clean;

BEGIN {
	$RDF::Crypt::Decrypter::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Crypt::Decrypter::VERSION   = '0.002';
}

sub decrypt_bytes
{
	my ($self, $text) = @_;
	$text = decode_base64($text);
	
	my $key = $self->private_key;
	my $block_size = $key->size - 16;
		
	my $iv = substr($text, 0, $block_size);
	my $removal_chars = unpack('n', substr($text, $block_size, 2));
	my $scrambled   = substr($text, $block_size + 2);
	$text = '';
	my $v = $iv;
	
	while (length $scrambled)
	{
		my $block  = substr($scrambled, 0, $key->size);
		$scrambled = substr($scrambled, length $block);
		
		if (length $block < $block_size)
		{
			$v = substr($v, 0, length $block);
		}
		
		my $clear  = $key->decrypt($block);
		my $unxor  = "$clear" ^ "$v";
		$v         = $block;
		
		$text .= substr($unxor, 0, $block_size);
	}

	return substr($text, 0, (length $text) - $removal_chars);
}

sub encrypt_bytes
{
	my ($self, $text) = @_;
	encode_base64(
		$self->private_key->private_encrypt($text)
	);
}

1;

__END__

=head1 NAME

RDF::Crypt::Decrypter - decrypts encrypted RDF graphs

=head1 SYNOPSIS

 use 5.010;
 use File::Slurp qw< slurp >;
 use RDF::Crypt::Decrypter;
 
 my $dec = RDF::Crypt::Decrypter->new_from_file(
    '/path/to/private-key.pem'
 );
 
 my $scrambled = slurp '/path/to/secret.rdf-crypt';
 my $graph     = $dec->decrypt_model($scrambled);

=head1 DESCRIPTION

A Decrypter object is created using an RSA private key.

RDF::Crypt::Decrypter can also also be used to encrypt graphs for yourself,
using just your private key.

=head2 Roles

=over

=item * L<RDF::Crypt::Role::WithPublicKeys>

=item * L<RDF::Crypt::Role::DoesDecrypt>

=item * L<RDF::Crypt::Role::DoesEncrypt>

=item * L<RDF::Crypt::Role::ToString>

=back

=begin trustme

=item * encrypt_bytes

=item * decrypt_bytes

=end trustme

=head1 SEE ALSO

L<RDF::Crypt>,
L<RDF::Crypt::Encrypter>.

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

