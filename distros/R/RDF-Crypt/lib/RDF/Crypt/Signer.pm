package RDF::Crypt::Signer;

use 5.010;
use Any::Moose;
with qw(
	RDF::Crypt::Role::WithPrivateKey
	RDF::Crypt::Role::DoesVerify
	RDF::Crypt::Role::DoesSign	
	RDF::Crypt::Role::StandardSignatureMarkers
	RDF::Crypt::Role::ToString
);

use MIME::Base64 qw(
	encode_base64
	decode_base64
);

use namespace::clean;

BEGIN {
	$RDF::Crypt::Signer::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Crypt::Signer::VERSION   = '0.002';
}

sub sign_bytes
{
	my ($self, $text) = @_;
	encode_base64(
		$self->private_key->sign($text),
		q(),
	);
}

sub verify_bytes
{
	my ($self, $text, $signature) = @_;
	!!$self->private_key->verify(
		$text,
		decode_base64($signature),
	);
}

1;

__END__

=head1 NAME

RDF::Crypt::Signer - signs RDF graphs with RSA

=head1 SYNOPSIS

 use 5.010;
 use File::Slurp qw< slurp >;
 use RDF::Crypt::Signer;
 use RDF::TrineX::Functions qw< parse >;
 
 my $sign = RDF::Crypt::Signer->new_from_file(
    '/path/to/private-key.pem'
 );
 
 my $raw    = slurp '/path/to/important.ttl';
 my $graph  = parse '/path/to/important.ttl';
 
 my $detached_sig                   = $sign->sign_model($graph);
 my $turtle_with_embedded_signature = $sign->sign_embed_turtle($raw);

=head1 DESCRIPTION

A Signer object is created using an RSA private key. The object can be used
to sign multiple RDF graphs. The signature should be independent of the RDF
serialisation used, so that Turtle and RDF/XML files containing equivalent
triples should generate the same signature.

RDF::Crypt::Signer can also be used to verify signatures using the private
key of the signer.

=head2 Roles

=over

=item * L<RDF::Crypt::Role::WithPrivateKey>

=item * L<RDF::Crypt::Role::DoesSign>

=item * L<RDF::Crypt::Role::DoesVerify>

=item * L<RDF::Crypt::Role::StandardSignatureMarkers>

=item * L<RDF::Crypt::Role::ToString>

=back

=begin trustme

=item * sign_bytes

=item * verify_bytes

=item * SIG_MARK

=end trustme

=head1 SEE ALSO

L<RDF::Crypt>,
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

