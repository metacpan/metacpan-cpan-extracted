use utf8;

package SemanticWeb::Schema::DefinedRegion;

# ABSTRACT: A DefinedRegion is a geographic area defined by potentially arbitrary (rather than political

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'DefinedRegion';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has address_country => (
    is        => 'rw',
    predicate => '_has_address_country',
    json_ld   => 'addressCountry',
);



has address_region => (
    is        => 'rw',
    predicate => '_has_address_region',
    json_ld   => 'addressRegion',
);



has postal_code => (
    is        => 'rw',
    predicate => '_has_postal_code',
    json_ld   => 'postalCode',
);



has postal_code_prefix => (
    is        => 'rw',
    predicate => '_has_postal_code_prefix',
    json_ld   => 'postalCodePrefix',
);



has postal_code_range => (
    is        => 'rw',
    predicate => '_has_postal_code_range',
    json_ld   => 'postalCodeRange',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DefinedRegion - A DefinedRegion is a geographic area defined by potentially arbitrary (rather than political

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

=for html <p>A DefinedRegion is a geographic area defined by potentially arbitrary
(rather than political, administrative or natural geographical) criteria.
Properties are provided for defining a region by reference to sets of
postal codes.<br/><br/> Examples: a delivery destination when shopping.
Region where regional pricing is configured.<br/><br/> Requirement 1:
Country: US States: "NY", "CA"<br/><br/> Requirement 2: Country: US
PostalCode Set: { [94000-94585], [97000, 97999], [13000, 13599]} { [12345,
12345], [78945, 78945], } Region = state, canton, prefecture, autonomous
community...<p>

=head1 ATTRIBUTES

=head2 C<address_country>

C<addressCountry>

=for html <p>The country. For example, USA. You can also provide the two-letter <a
href="http://en.wikipedia.org/wiki/ISO_3166-1">ISO 3166-1 alpha-2 country
code</a>.<p>

A address_country should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Country']>

=item C<Str>

=back

=head2 C<_has_address_country>

A predicate for the L</address_country> attribute.

=head2 C<address_region>

C<addressRegion>

=for html <p>The region in which the locality is, and which is in the country. For
example, California or another appropriate first-level <a
href="https://en.wikipedia.org/wiki/List_of_administrative_divisions_by_cou
ntry">Administrative division</a><p>

A address_region should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_address_region>

A predicate for the L</address_region> attribute.

=head2 C<postal_code>

C<postalCode>

The postal code. For example, 94043.

A postal_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_postal_code>

A predicate for the L</postal_code> attribute.

=head2 C<postal_code_prefix>

C<postalCodePrefix>

A defined range of postal codes indicated by a common textual prefix. Used
for non-numeric systems such as UK.

A postal_code_prefix should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_postal_code_prefix>

A predicate for the L</postal_code_prefix> attribute.

=head2 C<postal_code_range>

C<postalCodeRange>

A defined range of postal codes.

A postal_code_range should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PostalCodeRangeSpecification']>

=back

=head2 C<_has_postal_code_range>

A predicate for the L</postal_code_range> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::StructuredValue>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
