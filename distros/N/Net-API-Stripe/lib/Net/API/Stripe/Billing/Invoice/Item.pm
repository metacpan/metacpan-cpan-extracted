##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Invoice/Item.pm
## Version v0.100.1
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/10/22
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/invoiceitems
package Net::API::Stripe::Billing::Invoice::Item;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.1';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub date { return( shift->_set_get_datetime( 'date', @_ ) ); }

sub deleted { return( shift->_set_get_boolean( 'deleted', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub discountable { return( shift->_set_get_boolean( 'discountable', @_ ) ); }

sub discounts { return( shift->_set_get_object_array( 'discounts', 'Net::API::Stripe::Billing::Discount', @_ ) ); }

sub invoice { return( shift->_set_get_scalar_or_object( 'invoice', 'Net::API::Stripe::Billing::Invoice', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub period { return( shift->_set_get_object( 'period', 'Net::API::Stripe::Billing::Invoice::Period', @_ ) ); }

sub plan { return( shift->_set_get_object( 'plan', 'Net::API::Stripe::Billing::Plan', @_ ) ); }

sub price { return( shift->_set_get_object( 'price', 'Net::API::Stripe::Price', @_ ) ); }

sub proration { return( shift->_set_get_boolean( 'proration', @_ ) ); }

sub quantity { return( shift->_set_get_number( 'quantity', @_ ) ); }

sub subscription { return( shift->_set_get_scalar_or_object( 'subscription', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub subscription_item { return( shift->_set_get_scalar( 'subscription_item', @_ ) ); }

sub tax_rates { return( shift->_set_get_object_array( 'tax_rates', 'Net::API::Stripe::Tax::Rate', @_ ) ); }

sub test_clock { return( shift->_set_get_scalar_or_object( 'test_clock', 'Net::API::Stripe::Billing::TestClock', @_ ) ); }

sub unified_proration { return( shift->_set_get_scalar( 'unified_proration', @_ ) ); }

sub unit_amount { return( shift->_set_get_number( 'unit_amount', @_ ) ); }

sub unit_amount_decimal { return( shift->_set_get_number( 'unit_amount_decimal', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Invoice::Item - A Stripe Invoice Item Object

=head1 SYNOPSIS

    my $invoice_item = $stripe->invoice_item({
        amount => 2000,
        currency => 'jpy',
        customer => $customer_object,
        date => '2020-03-17',
        description => 'Support services',
        invoice => $invoice_object,
        metadata => { transaction_id => 1212, customer_id => 987 },
        plan => $plan_object,
        proration => 1,
        quantity => 7,
        subscription => $subscription_object,
    });

=head1 VERSION

    v0.100.1

=head1 DESCRIPTION

Sometimes you want to add a charge or credit to a customer, but actually charge or credit the customer's card only at the end of a regular billing cycle. This is useful for combining several charges (to minimize per-transaction fees), or for having Stripe tabulate your usage-based billing totals.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Billing::Invoice::Item> object.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "invoiceitem"

String representing the object’s type. Objects of the same type share the same value.

=head2 amount integer

Amount (in the I<currency> specified) of the invoice item. This should always be equal to I<unit_amount * quantity>.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency (L<https://stripe.com/docs/currencies>).

=head2 customer string (expandable)

The ID of the customer who will be billed when this invoice item is billed. When expanded, this is a L<Net::API::Stripe::Customer> object.

=head2 date timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users.

=head2 discountable boolean

If true, discounts will apply to this invoice item. Always false for prorations.

=head2 discounts

array containing strings. expandable

The discounts which apply to the invoice item. Item discounts are applied before invoice discounts. Use expand[]=discounts to expand each discount.

=head2 invoice string (expandable)

The ID of the invoice this invoice item belongs to. When expanded, this is a L<Net::API::Stripe::Billing::Invoice> object.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 period hash

The period associated with with this invoice item.

This is a L<Net::API::Stripe::Billing::Invoice::Period> object.

=head2 plan hash, plan object

If the invoice item is a proration, the plan of the subscription that the proration was computed for.

This is a L<Net::API::Stripe::Billing::Plan> object.

=head2 price hash, price object

The price of the invoice item.

This is a L<Net::API::Stripe::Price> object.

=head2 proration boolean

Whether the invoice item was created automatically as a proration adjustment when the customer switched plans.

=head2 quantity integer

Quantity of units for the invoice item. If the invoice item is a proration, the quantity of the subscription that the proration was computed for.

=head2 subscription string (expandable)

The subscription that this invoice item has been created for, if any. When expanded, this is a L<Net::API::Stripe::Billing::Subscription> object.

=head2 subscription_item string

The subscription item that this invoice item has been created for, if any.

=head2 tax_rates array of hashes

The tax rates which apply to the invoice item. When set, the default_tax_rates on the invoice do not apply to this invoice item.

This is an array of L<Net::API::Stripe::Tax::Rate> objects.

=head2 unified_proration boolean

For prorations this indicates whether Stripe automatically grouped multiple related debit and credit line items into a single combined line item.

=head2 unit_amount integer

Unit Amount (in the currency specified) of the invoice item.

=head2 unit_amount_decimal decimal string

Same as unit_amount, but contains a decimal value with at most 12 decimal places.

=head1 API SAMPLE

    {
      "id": "ii_fake123456789",
      "object": "invoiceitem",
      "amount": 8000,
      "currency": "jpy",
      "customer": "cus_fake123456789",
      "date": 1551493020,
      "description": "Unused time on Provider, Inc entrepreneur monthly membership after 02 Mar 2019",
      "discountable": false,
      "invoice": "in_fake123456789",
      "livemode": false,
      "metadata": {},
      "period": {
        "end": 1554171359,
        "start": 1551493020
      },
      "plan": {
        "id": "entrepreneur-monthly-jpy",
        "object": "plan",
        "active": true,
        "aggregate_usage": null,
        "amount": 2000,
        "amount_decimal": "2000",
        "billing_scheme": "per_unit",
        "created": 1541833424,
        "currency": "jpy",
        "interval": "month",
        "interval_count": 1,
        "livemode": false,
        "metadata": {},
        "nickname": null,
        "product": "prod_fake123456789",
        "tiers": null,
        "tiers_mode": null,
        "transform_usage": null,
        "trial_period_days": null,
        "usage_type": "licensed"
      },
      "proration": true,
      "quantity": 1,
      "subscription": "sub_fake123456789",
      "subscription_item": "si_fake123456789",
      "tax_rates": [],
      "unit_amount": 8000,
      "unit_amount_decimal": "8000"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/invoiceitems>, L<https://stripe.com/docs/billing/invoices/subscription#adding-upcoming-invoice-items>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
