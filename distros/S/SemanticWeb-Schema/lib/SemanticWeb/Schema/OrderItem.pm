use utf8;

package SemanticWeb::Schema::OrderItem;

# ABSTRACT: An order item is a line of an order

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'OrderItem';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has order_delivery => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'orderDelivery',
);



has order_item_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'orderItemNumber',
);



has order_item_status => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'orderItemStatus',
);



has order_quantity => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'orderQuantity',
);



has ordered_item => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'orderedItem',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::OrderItem - An order item is a line of an order

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

An order item is a line of an order. It includes the quantity and shipping
details of a bought offer.

=head1 ATTRIBUTES

=head2 C<order_delivery>

C<orderDelivery>

The delivery of the parcel related to this order or order item.

A order_delivery should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ParcelDelivery']>

=back

=head2 C<order_item_number>

C<orderItemNumber>

The identifier of the order item.

A order_item_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<order_item_status>

C<orderItemStatus>

The current status of the order item.

A order_item_status should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::OrderStatus']>

=back

=head2 C<order_quantity>

C<orderQuantity>

The number of the item ordered. If the property is not set, assume the
quantity is one.

A order_quantity should be one of the following types:

=over

=item C<Num>

=back

=head2 C<ordered_item>

C<orderedItem>

The item ordered.

A ordered_item should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=item C<InstanceOf['SemanticWeb::Schema::OrderItem']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
