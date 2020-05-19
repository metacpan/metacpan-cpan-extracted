##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Coupon.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/coupons/object
package Net::API::Stripe::Billing::Coupon;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount_off { return( shift->_set_get_number( 'amount_off', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub deleted { return( shift->_set_get_boolean( 'deleted', @_ ) ); }

sub duration { return( shift->_set_get_scalar( 'duration', @_ ) ); }

sub duration_in_months { return( shift->_set_get_scalar( 'duration_in_months', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub max_redemptions { return( shift->_set_get_scalar( 'max_redemptions', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub percent_off { return( shift->_set_get_scalar( 'percent_off', @_ ) ); }

sub redeem_by { return( shift->_set_get_datetime( 'redeem_by', @_ ) ); }

sub times_redeemed { return( shift->_set_get_scalar( 'times_redeemed', @_ ) ); }

sub valid { return( shift->_set_get_boolean( 'valid', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Coupon - A Stripe Coupon Object

=head1 SYNOPSIS

    my $coupon = $stripe->coupons( create => 
    {
    id => 'SUMMER10POFF',
    currency => 'usd',
    duration_in_months => 2,
    max_redemptions => 12,
    name => 'Summer 10% reduction',
    percent_off => 10,
    valid => 1
    }) || die( $stripe->error );

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

A coupon contains information about a percent-off or amount-off discount you might want to apply to a customer. Coupons may be applied to invoices (L<Net::API::Stripe::Billing::Invoice> / L<https://stripe.com/docs/api/coupons#invoices>) or orders (L<Net::API::Stripe::Order> / L<https://stripe.com/docs/api/coupons#create_order-coupon>). Coupons do not work with conventional one-off charges (L<Net::API::Stripe::Charge> / L<https://stripe.com/docs/api/coupons#create_charge>), but you can implement a custom coupon system (L<https://stripe.com/docs/recipes/coupons-for-charges>) in your application.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Billing::Coupon> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "coupon"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount_off> positive integer

Amount (in the currency specified) that will be taken off the subtotal of any invoices for this customer.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<currency> currency

If amount_off has been set, the three-letter ISO code for the currency of the amount to take off.

=item B<deleted> boolean

This property exists only when the object has been deleted.

=item B<duration> string

One of forever, once, and repeating. Describes how long a customer who applies this coupon will get the discount.

=item B<duration_in_months> positive integer

If duration is repeating, the number of months the coupon applies. Null if coupon duration is forever or once.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<max_redemptions> positive integer

Maximum number of times this coupon can be redeemed, in total, across all customers, before it is no longer valid.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<name> string

Name of the coupon displayed to customers on for instance invoices or receipts.

=item B<percent_off> decimal

Percent that will be taken off the subtotal of any invoices for this customer for the duration of the coupon. For example, a coupon with percent_off of 50 will make a ¥100 invoice ¥50 instead.

=item B<redeem_by> timestamp

Date after which the coupon can no longer be redeemed. This is a C<DateTime> object.

=item B<times_redeemed> positive integer or zero

Number of times this coupon has been applied to a customer.

=item B<valid> boolean

Taking account of the above properties, whether this coupon can still be applied to a customer.

=back

=head1 API SAMPLE

	{
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
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2018-07-27

The percent_off field of coupons was changed from Integer to Float, with a precision of two decimal places.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/coupons/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

