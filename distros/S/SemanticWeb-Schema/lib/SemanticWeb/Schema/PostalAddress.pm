use utf8;

package SemanticWeb::Schema::PostalAddress;

# ABSTRACT: The mailing address.

use Moo;

extends qw/ SemanticWeb::Schema::ContactPoint /;


use MooX::JSON_LD 'PostalAddress';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has address_country => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'addressCountry',
);



has address_locality => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'addressLocality',
);



has address_region => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'addressRegion',
);



has post_office_box_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'postOfficeBoxNumber',
);



has postal_code => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'postalCode',
);



has street_address => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'streetAddress',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PostalAddress - The mailing address.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

The mailing address.

=head1 ATTRIBUTES

=head2 C<address_country>

C<addressCountry>

=for html The country. For example, USA. You can also provide the two-letter <a
href="http://en.wikipedia.org/wiki/ISO_3166-1">ISO 3166-1 alpha-2 country
code</a>.

A address_country should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Country']>

=item C<Str>

=back

=head2 C<address_locality>

C<addressLocality>

The locality in which the street address is, and which is in the region.
For example, Mountain View.

A address_locality should be one of the following types:

=over

=item C<Str>

=back

=head2 C<address_region>

C<addressRegion>

=for html The region in which the locality is, and which is in the country. For
example, California or another appropriate first-level <a
href="https://en.wikipedia.org/wiki/List_of_administrative_divisions_by_cou
ntry">Administrative division</a>

A address_region should be one of the following types:

=over

=item C<Str>

=back

=head2 C<post_office_box_number>

C<postOfficeBoxNumber>

The post office box number for PO box addresses.

A post_office_box_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<postal_code>

C<postalCode>

The postal code. For example, 94043.

A postal_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<street_address>

C<streetAddress>

The street address. For example, 1600 Amphitheatre Pkwy.

A street_address should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::ContactPoint>

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
