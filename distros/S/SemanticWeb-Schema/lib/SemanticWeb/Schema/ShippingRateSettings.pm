use utf8;

package SemanticWeb::Schema::ShippingRateSettings;

# ABSTRACT: A ShippingRateSettings represents re-usable pieces of shipping information

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'ShippingRateSettings';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has does_not_ship => (
    is        => 'rw',
    predicate => '_has_does_not_ship',
    json_ld   => 'doesNotShip',
);



has free_shipping_threshold => (
    is        => 'rw',
    predicate => '_has_free_shipping_threshold',
    json_ld   => 'freeShippingThreshold',
);



has is_unlabelled_fallback => (
    is        => 'rw',
    predicate => '_has_is_unlabelled_fallback',
    json_ld   => 'isUnlabelledFallback',
);



has shipping_destination => (
    is        => 'rw',
    predicate => '_has_shipping_destination',
    json_ld   => 'shippingDestination',
);



has shipping_label => (
    is        => 'rw',
    predicate => '_has_shipping_label',
    json_ld   => 'shippingLabel',
);



has shipping_rate => (
    is        => 'rw',
    predicate => '_has_shipping_rate',
    json_ld   => 'shippingRate',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ShippingRateSettings - A ShippingRateSettings represents re-usable pieces of shipping information

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

=for html <p>A ShippingRateSettings represents re-usable pieces of shipping
information. It is designed for publication on an URL that may be
referenced via the <a class="localLink"
href="http://schema.org/shippingSettingsLink">shippingSettingsLink</a>
property of a <a class="localLink"
href="http://schema.org/OfferShippingSpecification">OfferShippingSpecificat
ion</a>. Several occurrences can be published, distinguished and matched
(i.e. identified/referenced) by their different values for <a
class="localLink"
href="http://schema.org/shippingLabel">shippingLabel</a>.<p>

=head1 ATTRIBUTES

=head2 C<does_not_ship>

C<doesNotShip>

=for html <p>Indicates, as part of an <a class="localLink"
href="http://schema.org/OfferShippingDetails">OfferShippingDetails</a>,
when shipping to a particular <a class="localLink"
href="http://schema.org/shippingDestination">shippingDestination</a> is not
available.<p>

A does_not_ship should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_does_not_ship>

A predicate for the L</does_not_ship> attribute.

=head2 C<free_shipping_threshold>

C<freeShippingThreshold>

=for html <p>A monetary value above which (or equal to) the shipping rate becomes
free. Intended to be used via an <a class="localLink"
href="http://schema.org/OfferShippingSpecification">OfferShippingSpecificat
ion</a> with <a class="localLink"
href="http://schema.org/shippingSettingsLink">shippingSettingsLink</a>
matching this <a class="localLink"
href="http://schema.org/ShippingSettings">ShippingSettings</a>.<p>

A free_shipping_threshold should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DeliveryChargeSpecification']>

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=back

=head2 C<_has_free_shipping_threshold>

A predicate for the L</free_shipping_threshold> attribute.

=head2 C<is_unlabelled_fallback>

C<isUnlabelledFallback>

=for html <p>This can be marked 'true' to indicate that some published
ShippingRateSettings are intended to apply to all <a class="localLink"
href="http://schema.org/OfferShippingDetails">OfferShippingDetails</a>
published by the same merchant, when referenced by a <a class="localLink"
href="http://schema.org/shippingSettingsLink">shippingSettingsLink</a> in
those settings. It is not meaningful to use a 'true' value for this
property alongside a shippingLabel, since this property is for use with
unlabelled ShippingRateSettings.<p>

A is_unlabelled_fallback should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_is_unlabelled_fallback>

A predicate for the L</is_unlabelled_fallback> attribute.

=head2 C<shipping_destination>

C<shippingDestination>

indicates (possibly multiple) shipping destinations. These can be defined
in several ways e.g. postalCode ranges.

A shipping_destination should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DefinedRegion']>

=back

=head2 C<_has_shipping_destination>

A predicate for the L</shipping_destination> attribute.

=head2 C<shipping_label>

C<shippingLabel>

=for html <p>Label to match an <a class="localLink"
href="http://schema.org/OfferShippingDetails">OfferShippingDetails</a> with
a <a class="localLink"
href="http://schema.org/ShippingRateSettings">ShippingRateSettings</a>
(within the context of a <a class="localLink"
href="http://schema.org/shippingSettingsLink">shippingSettingsLink</a>
cross-reference).<p>

A shipping_label should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_shipping_label>

A predicate for the L</shipping_label> attribute.

=head2 C<shipping_rate>

C<shippingRate>

=for html <p>The shipping rate is the cost of shipping to the specified destination.
Typically, the maxValue and currency values (of the <a class="localLink"
href="http://schema.org/MonetaryAmount">MonetaryAmount</a>) are most
appropriate.<p>

A shipping_rate should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=back

=head2 C<_has_shipping_rate>

A predicate for the L</shipping_rate> attribute.

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
