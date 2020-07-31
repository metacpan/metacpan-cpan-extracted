use utf8;

package SemanticWeb::Schema::DeliveryTimeSettings;

# ABSTRACT: A DeliveryTimeSettings represents re-usable pieces of shipping information

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'DeliveryTimeSettings';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has delivery_time => (
    is        => 'rw',
    predicate => '_has_delivery_time',
    json_ld   => 'deliveryTime',
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

SemanticWeb::Schema::DeliveryTimeSettings - A DeliveryTimeSettings represents re-usable pieces of shipping information

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

=for html <p>A DeliveryTimeSettings represents re-usable pieces of shipping
information, relating to timing. It is designed for publication on an URL
that may be referenced via the <a class="localLink"
href="http://schema.org/shippingSettingsLink">shippingSettingsLink</a>
property of a <a class="localLink"
href="http://schema.org/OfferShippingDetails">OfferShippingDetails</a>.
Several occurrences can be published, distinguished (and
identified/referenced) by their different values for <a class="localLink"
href="http://schema.org/transitTimeLabel">transitTimeLabel</a>.<p>

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

=head2 C<is_unlabelled_fallback>

C<isUnlabelledFallback>

=for html <p>This can be marked 'true' to indicate that some published <a
class="localLink"
href="http://schema.org/DeliveryTimeSettings">DeliveryTimeSettings</a> or
<a class="localLink"
href="http://schema.org/ShippingRateSettings">ShippingRateSettings</a> are
intended to apply to all <a class="localLink"
href="http://schema.org/OfferShippingDetails">OfferShippingDetails</a>
published by the same merchant, when referenced by a <a class="localLink"
href="http://schema.org/shippingSettingsLink">shippingSettingsLink</a> in
those settings. It is not meaningful to use a 'true' value for this
property alongside a transitTimeLabel (for <a class="localLink"
href="http://schema.org/DeliveryTimeSettings">DeliveryTimeSettings</a>) or
shippingLabel (for <a class="localLink"
href="http://schema.org/ShippingRateSettings">ShippingRateSettings</a>),
since this property is for use with unlabelled settings.<p>

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
