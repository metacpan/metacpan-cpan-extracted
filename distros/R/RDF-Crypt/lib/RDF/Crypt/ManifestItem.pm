package RDF::Crypt::ManifestItem;

use 5.010;
use Any::Moose;

use namespace::clean;

BEGIN {
	$RDF::Crypt::ManifestItem::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Crypt::ManifestItem::VERSION   = '0.002';
}

my $x = q*
		push @rows, RDF::Crypt::ManifestItem->new(
			manifest     => $data,
			scheme       => ($row->{scheme} ? $row->{scheme}->uri : 'http://ontologi.es/wotox#RDF-Crypt'),
			verification => $verifier->verify_model($docs{ $row->{document} }, $row->{signature}),
			document     => $row->{document}->uri,
			signature    => $row->{signature}->literal_value,
			signer       => $row->{signer},
			signed_at    => ($row->{signedAt} ? $row->{signedAt}->literal_value : undef),
*;

has manifest => (
	is           => 'ro',
	isa          => 'RDF::Trine::Model',
	required     => 1,
	weak_ref     => 1,
);

has scheme => (
	is           => 'ro',
	isa          => 'Str',
	required     => 1,
);

has verification => (
	is           => 'ro',
);

has document => (
	is           => 'ro',
	isa          => 'Str',
	required     => 1,
);

has signature => (
	is           => 'ro',
	isa          => 'Str',
	required     => 1,
);

has signer => (
	is           => 'ro',
	isa          => 'RDF::Trine::Node',
	required     => 1,
);

has signed_at => (
	is           => 'ro',
	isa          => 'Str | Undef',
);

1;


__END__

=head1 NAME

RDF::Crypt::ManifestItem - item in a manifest

=head1 DESCRIPTION

These objects are returned by C<verify_manifest>.

=head2 Attributes

=over

=item C<document> 

Read only; Str; required.

The URI of the thing that was signed.

=item C<signer> 

Read only; RDF::Trine::Node; required.

The URI/bnode of the agent that signed it.

=item C<signed_at>

Read only; Str|Undef.

Signature datetime as ISO 8601 string.

=item C<signature>

Read only; Str; required.

Base64-encoded RSA signature.

=item C<verification>

true/false/undef (see C<verify_model>).

=item C<manifest> 

Read only; RDF::Trine::Model; required; weak ref.

The manifest this item was extracted from.

=item C<scheme> 

Read only; Str; required.

A URI identifying the signature scheme.

=back

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

