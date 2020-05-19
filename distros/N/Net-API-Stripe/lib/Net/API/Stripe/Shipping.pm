##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Shipping.pm
## Version v0.100.1
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Shipping;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.1';
};

sub address { return( shift->_set_get_object( 'address', 'Net::API::Stripe::Address', @_ ) ); }

sub carrier { return( shift->_set_get_scalar( 'carrier', @_ ) ); }

sub eta { return( shift->_set_get_datetime( 'eta', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub phone { return( shift->_set_get_scalar( 'phone', @_ ) ); }

sub service { return( shift->_set_get_scalar( 'service', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub tracking_number { return( shift->_set_get_scalar( 'tracking_number', @_ ) ); }

sub tracking_url { return( shift->_set_get_uri( 'tracking_url', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Shipping - A Stripe Shipping Object

=head1 SYNOPSIS

    my $shipping = $stripe->shipping({
        address => $address_object,
        carrier => 'DHL',
        eta => '2020-04-12T08:00:00',
        name => 'John Doe',
        phone => '+81-(0)90-1234-5678',
        service => 'express',
        status => 'pending',
        tracking_number => 1234567890,
        tracking_url => 'https://track.example.com/1234567890',
        type => 'individual',
    });

=head1 VERSION

    v0.100.1

=head1 DESCRIPTION

Where and how things will be shipped.

This is inherited by: L<Net::API::Stripe::Charge::Shipping>, L<Net::API::Stripe::Customer::Shipping>, L<Net::API::Stripe::Issuing::Card::Shipping>, L<Net::API::Stripe::Order::Shipping>, C<Net::API::Stripe::>, C<Net::API::Stripe::>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Shipping> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<address> hash

Shipping address.

This is a L<Net::API::Stripe::Address> object, if any.

=item B<carrier> string

The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.

=item B<eta> timestamp

A unix timestamp representing a best estimate of when the card will be delivered.

=item B<name> string

Recipient name.

=item B<phone> string

Recipient phone (including extension).

=item B<service> string

Shipment service, such as standard or express. Possible enum values

=over 8

=item I<standard>

Cards arrive in 2-6 business days.

=item I<express>

Cards arrive in 2 business days.

=item I<priority>

Cards arrive in 1 business day.

=back

=item B<status> string

The delivery status of the card. One of pending, shipped, delivered, returned, failure, or canceled.

=item B<tracking_number> string

A tracking number for a card shipment. This is a C<URI> object.

=item B<tracking_url> string

A link to the shipping carrier’s site where you can view detailed information about a card shipment.

This returns a L<URI> object.

=item B<type> string

One of bulk or individual. Bulk shipments will be grouped and mailed together, while individual ones will not.

=back

=head1 API SAMPLE

	{
	  "id": "ic_fake123456789",
	  "object": "issuing.card",
	  "authorization_controls": {
		"allowed_categories": null,
		"blocked_categories": null,
		"currency": "usd",
		"max_amount": 10000,
		"max_approvals": 1,
		"spending_limits": [],
		"spending_limits_currency": null
	  },
	  "brand": "Visa",
	  "cardholder": {
		"id": "ich_fake123456789",
		"object": "issuing.cardholder",
		"authorization_controls": {
		  "allowed_categories": [],
		  "blocked_categories": [],
		  "spending_limits": [],
		  "spending_limits_currency": null
		},
		"billing": {
		  "address": {
			"city": "Beverly Hills",
			"country": "US",
			"line1": "123 Fake St",
			"line2": "Apt 3",
			"postal_code": "90210",
			"state": "CA"
		  },
		  "name": "Jenny Rosen"
		},
		"company": null,
		"created": 1540111055,
		"email": "jenny@example.com",
		"individual": null,
		"is_default": false,
		"livemode": false,
		"metadata": {},
		"name": "Jenny Rosen",
		"phone_number": "+18008675309",
		"requirements": {
		  "disabled_reason": null,
		  "past_due": []
		},
		"status": "active",
		"type": "individual"
	  },
	  "created": 1571652525,
	  "currency": "usd",
	  "exp_month": 8,
	  "exp_year": 2020,
	  "last4": "4242",
	  "livemode": false,
	  "metadata": {},
	  "name": "Jenny Rosen",
	  "pin": null,
	  "replacement_for": null,
	  "replacement_reason": null,
	  "shipping": null,
	  "status": "active",
	  "type": "physical"
	}

=head1 HISTORY

=head2 v0.100.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/issuing/cards/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
