use utf8;

package SemanticWeb::Schema::UnitPriceSpecification;

# ABSTRACT: The price asked for a given offer by the respective organization or person.

use Moo;

extends qw/ SemanticWeb::Schema::PriceSpecification /;


use MooX::JSON_LD 'UnitPriceSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.0';


has billing_increment => (
    is        => 'rw',
    predicate => '_has_billing_increment',
    json_ld   => 'billingIncrement',
);



has price_type => (
    is        => 'rw',
    predicate => '_has_price_type',
    json_ld   => 'priceType',
);



has reference_quantity => (
    is        => 'rw',
    predicate => '_has_reference_quantity',
    json_ld   => 'referenceQuantity',
);



has unit_code => (
    is        => 'rw',
    predicate => '_has_unit_code',
    json_ld   => 'unitCode',
);



has unit_text => (
    is        => 'rw',
    predicate => '_has_unit_text',
    json_ld   => 'unitText',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::UnitPriceSpecification - The price asked for a given offer by the respective organization or person.

=head1 VERSION

version v7.0.0

=head1 DESCRIPTION

The price asked for a given offer by the respective organization or person.

=head1 ATTRIBUTES

=head2 C<billing_increment>

C<billingIncrement>

This property specifies the minimal quantity and rounding increment that
will be the basis for the billing. The unit of measurement is specified by
the unitCode property.

A billing_increment should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_billing_increment>

A predicate for the L</billing_increment> attribute.

=head2 C<price_type>

C<priceType>

A short text or acronym indicating multiple price specifications for the
same offer, e.g. SRP for the suggested retail price or INVOICE for the
invoice price, mostly used in the car industry.

A price_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_price_type>

A predicate for the L</price_type> attribute.

=head2 C<reference_quantity>

C<referenceQuantity>

The reference quantity for which a certain price applies, e.g. 1 EUR per 4
kWh of electricity. This property is a replacement for unitOfMeasurement
for the advanced cases where the price does not relate to a standard unit.

A reference_quantity should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_reference_quantity>

A predicate for the L</reference_quantity> attribute.

=head2 C<unit_code>

C<unitCode>

The unit of measurement given using the UN/CEFACT Common Code (3
characters) or a URL. Other codes than the UN/CEFACT Common Code may be
used with a prefix followed by a colon.

A unit_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_unit_code>

A predicate for the L</unit_code> attribute.

=head2 C<unit_text>

C<unitText>

=for html <p>A string or text indicating the unit of measurement. Useful if you
cannot provide a standard unit code for <a href='unitCode'>unitCode</a>.<p>

A unit_text should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_unit_text>

A predicate for the L</unit_text> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::PriceSpecification>

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
