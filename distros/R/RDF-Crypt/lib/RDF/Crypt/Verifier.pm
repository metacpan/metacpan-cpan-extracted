package RDF::Crypt::Verifier;

use 5.010;
use Any::Moose;
with qw(
	RDF::Crypt::Role::WithPublicKeys
	RDF::Crypt::Role::DoesVerify
	RDF::Crypt::Role::StandardSignatureMarkers
	RDF::Crypt::Role::ToString
);

use MIME::Base64 qw[decode_base64];
use RDF::TrineX::Functions -shortcuts;

use namespace::clean;

BEGIN {
	$RDF::Crypt::Verifier::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Crypt::Verifier::VERSION   = '0.002';
}

sub verify_bytes
{
	my ($self, $text, $signature) = @_;
	
	foreach my $key (@{ $self->public_keys })
	{
		return 1
			if $key->verify($text, decode_base64($signature))
	}
	
	return undef;
}

1;
__END__

=head1 NAME

RDF::Crypt::Verifier - verifies signed RDF graphs

=head1 SYNOPSIS

 use 5.010;
 use File::Slurp qw< slurp >;
 use RDF::Crypt::Verifier;
 use RDF::TrineX::Functions qw< parse >;
 
 my $verify = RDF::Crypt::Verifier->new_from_file(
    '/path/to/public-key.pem'
 );
 
 my $graph      = parse '/path/to/important.ttl';
 my $signature  = slurp '/path/to/important.ttl.sig';
 
 say "graph is trusted"
   if $v->verify_model($graph, $signature);

=head1 DESCRIPTION

A Verifier object is created using an RSA public key. The object can be used
to verify signatures for multiple RDF graphs.

=head2 Roles

=over

=item * L<RDF::Crypt::Role::WithPublicKeys>

=item * L<RDF::Crypt::Role::DoesVerify>

=item * L<RDF::Crypt::Role::StandardSignatureMarkers>

=item * L<RDF::Crypt::Role::ToString>

=back

=begin trustme

=item * verify_bytes

=end trustme

=head1 SEE ALSO

L<RDF::Crypt>,
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

