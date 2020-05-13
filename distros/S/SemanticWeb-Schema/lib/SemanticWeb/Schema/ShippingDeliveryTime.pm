use utf8;

package SemanticWeb::Schema::ShippingDeliveryTime;

# ABSTRACT: ShippingDeliveryTime provides various pieces of information about delivery times for shipping.

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'ShippingDeliveryTime';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has business_days => (
    is        => 'rw',
    predicate => '_has_business_days',
    json_ld   => 'businessDays',
);



has cutoff_time => (
    is        => 'rw',
    predicate => '_has_cutoff_time',
    json_ld   => 'cutoffTime',
);



has handling_time => (
    is        => 'rw',
    predicate => '_has_handling_time',
    json_ld   => 'handlingTime',
);



has transit_time => (
    is        => 'rw',
    predicate => '_has_transit_time',
    json_ld   => 'transitTime',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ShippingDeliveryTime - ShippingDeliveryTime provides various pieces of information about delivery times for shipping.

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

ShippingDeliveryTime provides various pieces of information about delivery
times for shipping.

=head1 ATTRIBUTES

=head2 C<business_days>

C<businessDays>

Days of the week when the merchant typically operates, indicated via
opening hours markup.

A business_days should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::OpeningHoursSpecification']>

=back

=head2 C<_has_business_days>

A predicate for the L</business_days> attribute.

=head2 C<cutoff_time>

C<cutoffTime>

=for html <p>Order cutoff time allows merchants to describe the time after which they
will no longer process orders received on that day. For orders processed
after cutoff time, one day gets added to the delivery time estimate. This
property is expected to be most typically used via the <a class="localLink"
href="http://schema.org/ShippingRateSettings">ShippingRateSettings</a>
publication pattern. The time is indicated using the time notation from the
ISO-8601 DateTime format, e.g. 14:45:15Z would represent a daily cutoff at
14:45h UTC.<p>

A cutoff_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_cutoff_time>

A predicate for the L</cutoff_time> attribute.

=head2 C<handling_time>

C<handlingTime>

The typical delay between the receipt of the order and the goods either
leaving the warehouse or being prepared for pickup, in case the delivery
method is on site pickup. Typical properties: minValue, maxValue, unitCode
(d for DAY). This is by common convention assumed to mean business days (if
a unitCode is used, coded as "d"), i.e. only counting days when the
business normally operates.

A handling_time should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_handling_time>

A predicate for the L</handling_time> attribute.

=head2 C<transit_time>

C<transitTime>

The typical delay the order has been sent for delivery and the goods reach
the final customer. Typical properties: minValue, maxValue, unitCode (d for
DAY).

A transit_time should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_transit_time>

A predicate for the L</transit_time> attribute.

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
