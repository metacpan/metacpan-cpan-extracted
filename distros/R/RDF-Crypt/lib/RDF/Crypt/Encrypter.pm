package RDF::Crypt::Encrypter;

use 5.010;
use Any::Moose;
with qw(
	RDF::Crypt::Role::WithPublicKeys
	RDF::Crypt::Role::DoesEncrypt
	RDF::Crypt::Role::ToString
);

use Crypt::OpenSSL::Random qw[random_bytes];
use MIME::Base64 qw[decode_base64 encode_base64];
use RDF::TrineX::Functions -shortcuts;
use MIME::Base64 qw[];
use Sys::Hostname qw[];

use namespace::clean;

BEGIN {
	$RDF::Crypt::Encrypter::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Crypt::Encrypter::VERSION   = '0.002';
}

sub encrypt_bytes
{
	my ($self, $text) = @_;
	
	my $key = $self->public_keys->[-1];
	confess('Public key too small. Must be at least 64 bytes.') unless $key->size >= 64;
	
	my $block_size = $key->size - 16;
	my $v = my $iv = random_bytes($block_size);
	
	my ($scrambled, $last_length) = ('', 0);
	while (length $text)
	{
		my $block   = substr($text, 0, $block_size);
		$text       = substr($text, length $block);
		
		$v = substr($v, 0, length $block)
			if length $block < $block_size;
			
		$last_length = length $block;
		
		$scrambled .= 
			(my $cypher = $key->encrypt("$block" ^ "$v"));
		$v = substr($cypher, 0, $block_size);
	}

	return encode_base64($iv . pack('n', ($block_size - $last_length)) . $scrambled);
}

1;

__END__

=head1 NAME

RDF::Crypt::Encrypter - encrypts RDF graphs

=head1 SYNOPSIS

 use 5.010;
 use RDF::Crypt::Encrypter;
 use RDF::TrineX::Functions qw< parse >;
 
 my $enc = RDF::Crypt::Encrypter->new_from_webid(
    'http://www.example.com/people/alice#me'
 );
 
 my $graph     = parse '/path/to/secret.ttl';
 my $scrambled = $enc->encrypt_model($graph);

=head1 DESCRIPTION

An Encrypter object is created using an RSA public key. The object can be used
to encrypt an RDF graph for a recipient.

=head2 Roles

=over

=item * L<RDF::Crypt::Role::WithPublicKeys>

=item * L<RDF::Crypt::Role::DoesEncrypt>

=item * L<RDF::Crypt::Role::ToString>

=back

=begin trustme

=item * encrypt_bytes

=end trustme

=head1 SEE ALSO

L<RDF::Crypt>,
L<RDF::Crypt::Decrypter>.

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

