##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Order/StatusTransitions.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Order::StatusTransitions;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub canceled { shift->_set_get_datetime( 'canceled', @_ ); }

sub fulfiled { shift->_set_get_datetime( 'fulfiled', @_ ); }

sub paid { shift->_set_get_datetime( 'paid', @_ ); }

sub returned { shift->_set_get_datetime( 'returned', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Order::StatusTransitions - A Stripe Order Status Transitions Object

=head1 SYNOPSIS

    my $st = $order->status_transitions({
        canceled => undef,
        fulfiled => '2020-04-12',
        paid => '2020-04-30',
        returned => undef,
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

The timestamps at which the order status was updated.

This is instantiated by method B<status_transitions> in module L<Net::API::Stripe::Order>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Order::StatusTransitions> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<canceled> timestamp

When set, this returns a C<DateTime> object.

=item B<fulfiled> timestamp

When set, this returns a C<DateTime> object.

=item B<paid> timestamp

When set, this returns a C<DateTime> object.

=item B<returned> timestamp

When set, this returns a C<DateTime> object.

=back

=head1 API SAMPLE

	{
	  "id": "or_fake123456789",
	  "object": "order",
	  "amount": 1500,
	  "amount_returned": null,
	  "application": null,
	  "application_fee": null,
	  "charge": null,
	  "created": 1571480453,
	  "currency": "jpy",
	  "customer": null,
	  "email": null,
	  "items": [
		{
		  "object": "order_item",
		  "amount": 1500,
		  "currency": "jpy",
		  "description": "T-shirt",
		  "parent": "sk_fake123456789",
		  "quantity": null,
		  "type": "sku"
		}
	  ],
	  "livemode": false,
	  "metadata": {},
	  "returns": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/order_returns?order=or_fake123456789"
	  },
	  "selected_shipping_method": null,
	  "shipping": {
		"address": {
		  "city": "Anytown",
		  "country": "US",
		  "line1": "1234 Main street",
		  "line2": null,
		  "postal_code": "123456",
		  "state": null
		},
		"carrier": null,
		"name": "Jenny Rosen",
		"phone": null,
		"tracking_number": null
	  },
	  "shipping_methods": null,
	  "status": "created",
	  "status_transitions": {
		"canceled": null,
		"fulfiled": null,
		"paid": null,
		"returned": null
	  },
	  "updated": 1571480453
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/orders/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
