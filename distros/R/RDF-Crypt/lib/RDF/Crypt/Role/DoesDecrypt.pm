package RDF::Crypt::Role::DoesDecrypt;

use 5.010;
use Any::Moose 'Role';

use Encode qw(decode);
use RDF::TrineX::Functions -shortcuts;

use namespace::clean;

BEGIN {
	$RDF::Crypt::Role::DoesDecrypt::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Crypt::Role::DoesDecrypt::VERSION   = '0.002';
}

requires 'decrypt_bytes';

sub decrypt_text
{
	my ($self, $text) = @_;
	decode(
		'utf-8',
		$self->decrypt_bytes($text),
	);
}

sub decrypt_model
{
	my ($self, $text, %opts) = @_;
	$opts{using} ||= 'RDFXML';
	rdf_parse(
		$self->decrypt_text($text),
		%opts,
	);
}

1;

__END__

=head1 NAME

RDF::Crypt::Role::DoesDecrypt - unscrambling methods

=head1 DESCRIPTION

=head2 Object Methods

=over

=item C<< decrypt_model($text, %opts) >>

Given a string that represents an encrypted RDF graph, decrypts and
parses it. Any options are passed along to L<RDF::TrineX::Functions>
C<parse> function.

Returns an L<RDF::Trine::Model>.

=item C<< decrypt_text($str) >>

Decrypts a literal string which may or may not have anything
to do with RDF.

=back

=head2 Required Methods

This role does not implement these methods, but requires classes to
implement them instead:

=over

=item C<< decrypt_bytes($str) >>

Unscrambles an octet string.

=back

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

