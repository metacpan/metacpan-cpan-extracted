use utf8;

package SemanticWeb::Schema::GeoCoordinates;

# ABSTRACT: The geographic coordinates of a place or event.

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'GeoCoordinates';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.2';


has address => (
    is        => 'rw',
    predicate => '_has_address',
    json_ld   => 'address',
);



has address_country => (
    is        => 'rw',
    predicate => '_has_address_country',
    json_ld   => 'addressCountry',
);



has elevation => (
    is        => 'rw',
    predicate => '_has_elevation',
    json_ld   => 'elevation',
);



has latitude => (
    is        => 'rw',
    predicate => '_has_latitude',
    json_ld   => 'latitude',
);



has longitude => (
    is        => 'rw',
    predicate => '_has_longitude',
    json_ld   => 'longitude',
);



has postal_code => (
    is        => 'rw',
    predicate => '_has_postal_code',
    json_ld   => 'postalCode',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::GeoCoordinates - The geographic coordinates of a place or event.

=head1 VERSION

version v7.0.2

=head1 DESCRIPTION

The geographic coordinates of a place or event.

=head1 ATTRIBUTES

=head2 C<address>

Physical address of the item.

A address should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PostalAddress']>

=item C<Str>

=back

=head2 C<_has_address>

A predicate for the L</address> attribute.

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

=head2 C<elevation>

=for html <p>The elevation of a location (<a
href="https://en.wikipedia.org/wiki/World_Geodetic_System">WGS 84</a>).
Values may be of the form 'NUMBER UNIT<em>OF</em>MEASUREMENT' (e.g., '1,000
m', '3,200 ft') while numbers alone should be assumed to be a value in
meters.<p>

A elevation should be one of the following types:

=over

=item C<Num>

=item C<Str>

=back

=head2 C<_has_elevation>

A predicate for the L</elevation> attribute.

=head2 C<latitude>

=for html <p>The latitude of a location. For example <code>37.42242</code> (<a
href="https://en.wikipedia.org/wiki/World_Geodetic_System">WGS 84</a>).<p>

A latitude should be one of the following types:

=over

=item C<Num>

=item C<Str>

=back

=head2 C<_has_latitude>

A predicate for the L</latitude> attribute.

=head2 C<longitude>

=for html <p>The longitude of a location. For example <code>-122.08585</code> (<a
href="https://en.wikipedia.org/wiki/World_Geodetic_System">WGS 84</a>).<p>

A longitude should be one of the following types:

=over

=item C<Num>

=item C<Str>

=back

=head2 C<_has_longitude>

A predicate for the L</longitude> attribute.

=head2 C<postal_code>

C<postalCode>

The postal code. For example, 94043.

A postal_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_postal_code>

A predicate for the L</postal_code> attribute.

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
