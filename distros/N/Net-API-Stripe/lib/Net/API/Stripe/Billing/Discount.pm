##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Discount.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/discounts
package Net::API::Stripe::Billing::Discount;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub coupon { shift->_set_get_object( 'coupon', 'Net::API::Stripe::Billing::Coupon', @_ ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub end { shift->_set_get_datetime( 'end', @_ ); }

sub start { shift->_set_get_datetime( 'start', @_ ); }

sub subscription { shift->_set_get_scalar( 'subscription', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Discount - A Stripe Discount

=head1 SYNOPSIS

	my $discount = $stripe->discount({
	    coupon => $stripe->coupon({
			id => 'SUMMER10POFF',
			currency => 'usd',
			duration_in_months => 2,
			max_redemptions => 12,
			name => 'Summer 10% reduction',
			percent_off => 10,
			valid => 1
	    }),
	    customer => $customer_object,
	    # undef() for once or forever
	    end => '2020-12-31',
	    start => '2020-06-01',
	    subscription => 'sub_fake1234567',
	});

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

A discount represents the actual application of a coupon to a particular customer. It contains information about when the discount began and when it will end.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Billing::Discount> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<object> string, value is "discount"

String representing the object’s type. Objects of the same type share the same value.

=item B<coupon> hash, coupon object

Hash describing the coupon applied to create this discount. This is a L<Net::API::Stripe::Billing::Coupon> object.

=item B<customer> string (expandable)

This is the Stripe customer id, or when expanded, this is the L<Net::API::Stripe::Customer> object.

=item B<end> timestamp

If the coupon has a duration of repeating, the date that this discount will end. If the coupon has a duration of once or forever, this attribute will be null.

=item B<start> timestamp

Date that the coupon was applied.

=item B<subscription> string

The subscription that this coupon is applied to, if it is applied to a particular subscription.

=back

=head1 API SAMPLE

	{
	  "object": "discount",
	  "coupon": {
		"id": "25_5OFF",
		"object": "coupon",
		"amount_off": null,
		"created": 1571397911,
		"currency": null,
		"duration": "repeating",
		"duration_in_months": 3,
		"livemode": false,
		"max_redemptions": null,
		"metadata": {},
		"name": "25.5% off",
		"percent_off": 25.5,
		"redeem_by": null,
		"times_redeemed": 0,
		"valid": true
	  },
	  "customer": "cus_fake124567890",
	  "end": 1579346711,
	  "start": 1571397911,
	  "subscription": null
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>, L<https://stripe.com/docs/billing/subscriptions/discounts>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
