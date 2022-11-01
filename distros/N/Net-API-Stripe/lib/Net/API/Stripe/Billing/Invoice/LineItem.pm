##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Invoice/LineItem.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/invoices/line_item
package Net::API::Stripe::Billing::Invoice::LineItem;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::List::Item );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

# NOTE: method id is inherited

# NOTE: method object is inherited

# NOTE: method amount is inherited

sub amount_excluding_tax { return( shift->_set_get_number( 'amount_excluding_tax', @_ ) ); }

# NOTE: method currency is inherited

# NOTE: method description is inherited

sub discount_amounts
{
    return( shift->_set_get_class_array( 'discount_amounts',
    {
    amount      => { type => 'number' },
    discount    => { type => 'object', class => 'Net::API::Stripe::Billing::Discount' },
    }, @_ ) );
}

sub discountable { return( shift->_set_get_boolean( 'discountable', @_ ) ); }

sub discounts { return( shift->_set_get_scalar_or_object_array( 'discounts', 'Net::API::Stripe::Billing::Discount', @_ ) ); }

sub invoice_item { return( shift->_set_get_scalar( 'invoice_item', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub period { return( shift->_set_get_object( 'period', 'Net::API::Stripe::Billing::Invoice::Period', @_ ) ); }

sub plan { return( shift->_set_get_object( 'plan', 'Net::API::Stripe::Billing::Plan', @_ ) ); }

# NOTE: method price is inherited

sub proration { return( shift->_set_get_boolean( 'proration', @_ ) ); }

sub proration_details { return( shift->_set_get_class( 'proration_details',
{
    credited_items => { type => 'class', definition =>
        {
        invoice => { type => 'string' },
        invoice_line_items => { type => 'array' },
        }},
}, @_ ) ); }

# NOTE: method quantity is inherited

sub subscription { return( shift->_set_get_scalar( 'subscription', @_ ) ); }

sub subscription_item { return( shift->_set_get_scalar( 'subscription_item', @_ ) ); }

sub tax_amounts { return( shift->_set_get_object_array( 'tax_amounts', 'Net::API::Stripe::Billing::Invoice::TaxAmount', @_ ) ); }

sub tax_rates { return( shift->_set_get_object_array( 'tax_rates', 'Net::API::Stripe::Tax::Rate', @_ ) ); }

# The source type: invoiceitem or subscription
# NOTE: method type is inherited

sub unified_proration { return( shift->_set_get_scalar( 'unified_proration', @_ ) ); }

sub unique_id { return( shift->_set_get_scalar( 'unique_id', @_ ) ); }

sub unit_amount_excluding_tax { return( shift->_set_get_number( 'unit_amount_excluding_tax', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Invoice::LineItem - A Stripe Invoice Line Item Object

=head1 SYNOPSIS

    my $line_item = $stripe->invoice_line_item({
        amount => 2000,
        currency => 'jpy',
        description 'Professional service work',
        discountable => 0,
        metadata => { transaction_id => 1212, customer_id => 987 },
        plan => $plan_object,
        proration => 0,
        quantity => 7,
        subscription => 'sub_fake123456789',
        type => 'subscription',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This is a Stripe L<Net::API::Stripe::Billing::Invoice::LineItem> object as documented here: L<https://stripe.com/docs/api/invoices/line_item>

=head1 CONSTRUCTOR

=head2 new

Creates a new L<Net::API::Stripe::Billing::Invoice::LineItem> object.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "line_item"

String representing the object’s type. Objects of the same type share the same value.

=head2 amount integer

The amount, in its smallest representation, such as cents. For example, $9 would be 900, and ¥1000 (Japanese Yen) would be 1000.

=head2 amount_excluding_tax

The integer amount representing the amount for this line item, excluding all tax and discounts.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users.

=head2 discount_amounts array of hashes

The amount of discount calculated per discount for this line item.

Properties are:

=over 4

=item I<amount> integer

The amount of the discount.

=item I<discount> string expandable

The discount that was applied to get this discount amount.

When expanded, this is a L<Net::API::Stripe::Billing::Discount> object.

=back

=head2 discountable boolean

If true, discounts will apply to this line item. Always false for prorations.

=head2 discounts expandable

The discounts applied to the invoice line item. Line item discounts are applied before invoice discounts. Use C<expand[]=discounts> to expand each discount.

When expanded this is an L<Net::API::Stripe::Billing::Discount> object.

=head2 invoice_item string

The ID of the invoice item associated with this line item if any.

=head2 livemode boolean

Whether this is a test line item.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Note that for line items with type=subscription this will reflect the metadata of the subscription that caused the line item to be created.

=head2 period hash

The timespan covered by this invoice item.

This is a L<Net::API::Stripe::Billing::Invoice::Period> object.

=head2 plan hash, plan object

The plan of the subscription, if the line item is a subscription or a proration.

This is a L<Net::API::Stripe::Billing::Plan> object.

=head2 price object

The price of the line item.

This is a L<Net::API::Stripe::Price> object.

=head2 proration boolean

Whether this is a proration.

=head2 proration_details

Additional details for proration line items

=over 4

credited_items hash

For a credit proration line_item, the original debit line_items to which the credit proration applies.

=over 8

=item * C<invoice> string

Invoice containing the credited invoice line items

=item * C<invoice_line_items> array containing strings

Credited invoice line items

=back

=back

=head2 quantity integer

The quantity of the subscription, if the line item is a subscription or a proration.

=head2 subscription string

The subscription that the invoice item pertains to, if any.

=head2 subscription_item string

The subscription item that generated this invoice item. Left empty if the line item is not an explicit result of a subscription.

=head2 tax_amounts array of hashes

The amount of tax calculated per tax rate for this line item

This is an array of L<Net::API::Stripe::Billing::Invoice::TaxAmount> objects.

=head2 tax_rates array of hashes

The tax rates which apply to the line item.

This is an array of L<Net::API::Stripe::Tax::Rate> objects.

=head2 type string

A string identifying the type of the source of this line item, either an invoiceitem or a subscription.

=head2 unified_proration boolean

For prorations this indicates whether Stripe automatically grouped multiple related debit and credit line items into a single combined line item.

=head2 unit_amount_excluding_tax

The amount in the currency smallest representation, such as cents representing the unit amount for this line item, excluding all tax and discounts. Example 900 for C<$9> or 1000 for ¥1000 (Japanese Yen).

=head1 API SAMPLE

    {
      "id": "ii_fake123456789",
      "object": "line_item",
      "amount": -2000,
      "currency": "jpy",
      "description": "Unused time on Provider, Inc entrepreneur monthly membership after 02 Mar 2019",
      "discountable": false,
      "invoice_item": "ii_fake123456789",
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
      "tax_amounts": [],
      "tax_rates": [],
      "type": "invoiceitem"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2019-12-03

The id field of all invoice line items have changed and are now prefixed with il_. The new id has consistent prefixes across all line items, is globally unique, and can be used for pagination.

=over 4

=item You can no longer use the prefix of the id to determine the source of the line item. Instead use the type field for this purpose.

=item For lines with type=invoiceitem, use the invoice_item field to reference or update the originating Invoice Item object.

=item The Invoice Line Item object on earlier API versions also have a unique_id field to be used for migrating internal references before upgrading to this version.

=item When setting a tax rate to individual line items, use the new id. Users on earlier API versions can pass in either a line item id or unique_id.

=back

=head2 2022-07-12

The following methods have been aded by Stripe:

=over 4

=item * L</amount_excluding_tax>

=item * L</proration_details>

=item * L</unit_amount_excluding_tax>

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/invoices/line_item>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
