##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Price.pm
## Version v0.1.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2020/05/15
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## "A list of up to 5 attributes that each SKU can provide values for (e.g., ["color", "size"]). Only applicable to products of type=good."
package Net::API::Stripe::Price;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub active { return( shift->_set_get_boolean( 'active', @_ ) ); }

sub billing_scheme { return( shift->_set_get_scalar( 'billing_scheme', @_ ) ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub deleted { return( shift->_set_get_boolean( 'deleted', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub lookup_key { return( shift->_set_get_scalar( 'lookup_key', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub nickname { return( shift->_set_get_scalar( 'nickname', @_ ) ); }

sub product { return( shift->_set_get_scalar_or_object( 'prodduct', @_ ) ); }

sub product_data { return( shift->_set_get_object( 'product_data', @_ ) ); }

sub recurring { return( shift->_set_get_class( 'recurring', 
{
    aggregate_usage     => { type => 'string' },
    interval            => { type => 'string' },
    interval_count      => { type => 'number' },
    trial_period_days   => { type => 'number' },
    usage_type          => { type => 'string' },
}) ); }

sub tiers { return( shift->_set_get_class_array( 'tiers', 
{
    flat_amount         => { type => 'number' },
    flat_amount_decimal => { type => 'number' },
    unit_amount         => { type => 'number' },
    unit_amount_decimal => { type => 'number' },
    up_to               => { type => 'number' },
}, @_ ) ); }

sub tiers_mode { return( shift->_set_get_scalar( 'tiers_mode', @_ ) ); }

sub transform_quantity { return( shift->_set_get_class( 'transform_quantity',
{
    divide_by   => { type => 'number' },
    round       => { type => 'string' },
}, @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub unit_amount { return( shift->_set_get_number( 'unit_amount', @_ ) ); }

sub unit_amount_decimal { return( shift->_set_get_number( 'unit_amount_decimal', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Price - A Stripe Price Object

=head1 SYNOPSIS

    my $prod = $stripe->product({
        active => $stripe->true,
        unit_amount => 2000,
        currency => 'jpy',
        metadata => { product_id => 123, customer_id => 456 },
        nickname => 'jpy premium price',
        product => 'prod_fake123456789',
        recurring => 
            {
            interval => 'month',
            interval_count => 1,
            trial_period_days => 14,
            usage_type => 'licensed',
            },
        livemode => $stripe->false,
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Prices define the unit cost, currency, and (optional) billing cycle for both recurring and one-time purchases of products. Products help you track inventory or provisioning, and prices help you track payment terms. Different physical goods or levels of service should be represented by products, and pricing options should be represented by prices. This approach lets you change prices without having to change your provisioning scheme.

For example, you might have a single "gold" product that has prices for $10/month, $100/year, and €9 once.

Related guides: L<Set up a subscription|https://stripe.com/docs/billing/subscriptions/set-up-subscription>, L<create an invoice|https://stripe.com/docs/billing/invoices/create>, and more about L<products and prices|https://stripe.com/docs/billing/prices-guide>.

Documentation on Products for use with Subscriptions can be found at L<Subscription Products|https://stripe.com/docs/api/prices#prices>.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Price> object.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "price"

String representing the object’s type. Objects of the same type share the same value.

=item B<active> boolean

Whether the price can be used for new purchases.

=item B<billing_scheme> string

Describes how to compute the price per period. Either I<per_unit> or I<tiered>. I≤per_unit> indicates that the fixed amount (specified in I<unit_amount> or I<unit_amount_decimal>) will be charged per unit in C<quantity> (for prices with C<usage_type=licensed>), or per unit of total usage (for prices with C<usage_type=metered>). I<tiered> indicates that the unit pricing will be computed using a tiering strategy as defined using the I<tiers> and I<tiers_mode> attributes.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=iten B<currency> string

Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a supported L<currency|https://stripe.com/docs/currencies>.

=item B<deleted> boolean

Set to true when the price has been deleted.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<lookup_key> string

A lookup key used to retrieve prices dynamically from a static string.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<nickname> string

A brief description of the plan, hidden from customers.

=item B<product> string (expandable)

The ID of the product this price is associated with. When expanded, this is a L<Net::API::Stripe::Product> object.

=item B<product_data> hash

These fields can be used to create a new product that this price will belong to. This is a L<Net::API::Stripe::Product> object

This is used when creating a Stripe price object, and to create a product in the process as well.

=item B<recurring> hash

The recurring components of a price such as interval and usage_type.

This has the following properties, that look very much like a L<Net::API::Stripe::Billing::Plan>:

=over 8

=item I<interval>

Specifies billing frequency. Either C<day>, C<week>, C<month> or C<year>.

=item I<aggregate_usage>

Specifies a usage aggregation strategy for prices of C<usage_type=metered>. Allowed values are sum for summing up all usage during a period, C<last_during_period> for using the last usage record reported within a period, last_ever for using the last usage record ever (across period bounds) or max which uses the usage record with the maximum reported usage during a period. Defaults to sum.

=item I<interval_count>

The number of intervals between subscription billings. For example, interval=month and interval_count=3 bills every 3 months. Maximum of one year interval allowed (1 year, 12 months, or 52 weeks).

=item I<trial_period_days>

Default number of trial days when subscribing a customer to this price using C<trial_from_plan=true>.

=item I<usage_type>

Configures how the quantity per period should be determined. Can be either C<metered> or C<licensed>. C<licensed> automatically bills the quantity set when adding it to a subscription. metered aggregates the total usage based on usage records. Defaults to C<licensed>.

=back

=item B<tiers> hash

Each element represents a pricing tier. This parameter requires C<billing_scheme> to be set to C<tiered>. See also the documentation for C<billing_scheme>.

The possible properties are:

=over 8

=item I<up_to> number

Specifies the upper bound of this tier. The lower bound of a tier is the upper bound of the previous tier adding one. Use C<inf> to define a fallback tier.

=item I<flat_amount> number

The flat billing amount for an entire tier, regardless of the number of units in the tier.

=item I<flat_amount_decimal>

Same as C≤flat_amount>, but accepts a decimal value representing an integer in the minor units of the currency. Only one of C≤flat_amount> and C<flat_amount_decimal> can be set.

=item I<unit_amount>

The per unit billing amount for each individual unit for which this tier applies.

=item I<unit_amount_decimal>

Same as C≤unit_amount>, but accepts a decimal value with at most 12 decimal places. Only one of C<unit_amount> and C<unit_amount_decimal> can be set.

=back

=item B<tiers_mode> string

Defines if the tiering price should be C<graduated> or C<volume> based. In C≤volume>-based tiering, the maximum quantity within a period determines the per unit price, in C<graduated> tiering pricing can successively change as the quantity grows.

=item B<transform_quantity> hash

Apply a transformation to the reported usage or set quantity before computing the billed price. Cannot be combined with C<tiers>.

Possible properties are:

=over 8

=item I<divide_by> number

Divide usage by this number.

=item I<round> string

After division, either round the result C<up> or C<down>.

=back

=item B<type> string

One of C<one_time> or C<recurring> depending on whether the price is for a one-time purchase or a recurring (subscription) purchase.

=item B<unit_amount> number

The unit amount in JPY to be charged, represented as a whole integer if possible.

=item B<unit_amount_decimal> number

The unit amount in JPY to be charged, represented as a decimal string with at most 12 decimal places.

=back

=head1 API SAMPLE

    {
      "id": "gold",
      "object": "price",
      "active": true,
      "billing_scheme": "per_unit",
      "created": 1589335030,
      "currency": "jpy",
      "livemode": false,
      "lookup_key": null,
      "metadata": {},
      "nickname": null,
      "product": "prod_fake123456789",
      "recurring": {
        "aggregate_usage": null,
        "interval": "month",
        "interval_count": 1,
        "trial_period_days": null,
        "usage_type": "licensed"
      },
      "tiers": null,
      "tiers_mode": null,
      "transform_quantity": null,
      "type": "recurring",
      "unit_amount": 2000,
      "unit_amount_decimal": "2000"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

This was released some time in early 2020.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/prices#prices>, L<https://stripe.com/docs/billing/subscriptions/set-up-subscription>, L<https://stripe.com/docs/billing/invoices/create>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
