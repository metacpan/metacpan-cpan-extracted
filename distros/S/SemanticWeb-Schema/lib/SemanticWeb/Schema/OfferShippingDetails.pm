use utf8;

package SemanticWeb::Schema::OfferShippingDetails;

# ABSTRACT: OfferShippingDetails represents information about shipping destinations

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'OfferShippingDetails';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has delivery_time => (
    is        => 'rw',
    predicate => '_has_delivery_time',
    json_ld   => 'deliveryTime',
);



has does_not_ship => (
    is        => 'rw',
    predicate => '_has_does_not_ship',
    json_ld   => 'doesNotShip',
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



has shipping_settings_link => (
    is        => 'rw',
    predicate => '_has_shipping_settings_link',
    json_ld   => 'shippingSettingsLink',
);



has transit_time_label => (
    is        => 'rw',
    predicate => '_has_transit_time_label',
    json_ld   => 'transitTimeLabel',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::OfferShippingDetails - OfferShippingDetails represents information about shipping destinations

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

=for html <p>OfferShippingDetails represents information about shipping
destinations.<br/><br/> Multiple of these entities can be used to represent
different shipping rates for different destinations:<br/><br/> One entity
for Alaska/Hawaii. A different one for continental US.A different one for
all France.<br/><br/> Multiple of these entities can be used to represent
different shipping costs and delivery times.<br/><br/> Two entities that
are identical but differ in rate and time:<br/><br/> e.g. Cheaper and
slower: $5 in 5-7days or Fast and expensive: $15 in 1-2 days<p>

=head1 ATTRIBUTES

=head2 C<delivery_time>

C<deliveryTime>

The total delay between the receipt of the order and the goods reaching the
final customer.

A delivery_time should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ShippingDeliveryTime']>

=back

=head2 C<_has_delivery_time>

A predicate for the L</delivery_time> attribute.

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

=head2 C<shipping_settings_link>

C<shippingSettingsLink>

=for html <p>Link to a page containing <a class="localLink"
href="http://schema.org/ShippingRateSettings">ShippingRateSettings</a> and
<a class="localLink"
href="http://schema.org/DeliveryTimeSettings">DeliveryTimeSettings</a>
details.<p>

A shipping_settings_link should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_shipping_settings_link>

A predicate for the L</shipping_settings_link> attribute.

=head2 C<transit_time_label>

C<transitTimeLabel>

=for html <p>Label to match an <a class="localLink"
href="http://schema.org/OfferShippingDetails">OfferShippingDetails</a> with
a <a class="localLink"
href="http://schema.org/DeliveryTimeSettings">DeliveryTimeSettings</a>
(within the context of a <a class="localLink"
href="http://schema.org/shippingSettingsLink">shippingSettingsLink</a>
cross-reference).<p>

A transit_time_label should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_transit_time_label>

A predicate for the L</transit_time_label> attribute.

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
