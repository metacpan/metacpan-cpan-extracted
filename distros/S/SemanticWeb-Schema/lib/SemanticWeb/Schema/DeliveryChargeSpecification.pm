use utf8;

package SemanticWeb::Schema::DeliveryChargeSpecification;

# ABSTRACT: The price for the delivery of an offer using a particular delivery method.

use Moo;

extends qw/ SemanticWeb::Schema::PriceSpecification /;


use MooX::JSON_LD 'DeliveryChargeSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.1';


has applies_to_delivery_method => (
    is        => 'rw',
    predicate => '_has_applies_to_delivery_method',
    json_ld   => 'appliesToDeliveryMethod',
);



has area_served => (
    is        => 'rw',
    predicate => '_has_area_served',
    json_ld   => 'areaServed',
);



has eligible_region => (
    is        => 'rw',
    predicate => '_has_eligible_region',
    json_ld   => 'eligibleRegion',
);



has ineligible_region => (
    is        => 'rw',
    predicate => '_has_ineligible_region',
    json_ld   => 'ineligibleRegion',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DeliveryChargeSpecification - The price for the delivery of an offer using a particular delivery method.

=head1 VERSION

version v6.0.1

=head1 DESCRIPTION

The price for the delivery of an offer using a particular delivery method.

=head1 ATTRIBUTES

=head2 C<applies_to_delivery_method>

C<appliesToDeliveryMethod>

The delivery method(s) to which the delivery charge or payment charge
specification applies.

A applies_to_delivery_method should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DeliveryMethod']>

=back

=head2 C<_has_applies_to_delivery_method>

A predicate for the L</applies_to_delivery_method> attribute.

=head2 C<area_served>

C<areaServed>

The geographic area where a service or offered item is provided.

A area_served should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<Str>

=back

=head2 C<_has_area_served>

A predicate for the L</area_served> attribute.

=head2 C<eligible_region>

C<eligibleRegion>

=for html <p>The ISO 3166-1 (ISO 3166-1 alpha-2) or ISO 3166-2 code, the place, or
the GeoShape for the geo-political region(s) for which the offer or
delivery charge specification is valid.<br/><br/> See also <a
class="localLink"
href="http://schema.org/ineligibleRegion">ineligibleRegion</a>.<p>

A eligible_region should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<Str>

=back

=head2 C<_has_eligible_region>

A predicate for the L</eligible_region> attribute.

=head2 C<ineligible_region>

C<ineligibleRegion>

=for html <p>The ISO 3166-1 (ISO 3166-1 alpha-2) or ISO 3166-2 code, the place, or
the GeoShape for the geo-political region(s) for which the offer or
delivery charge specification is not valid, e.g. a region where the
transaction is not allowed.<br/><br/> See also <a class="localLink"
href="http://schema.org/eligibleRegion">eligibleRegion</a>.<p>

A ineligible_region should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<Str>

=back

=head2 C<_has_ineligible_region>

A predicate for the L</ineligible_region> attribute.

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
