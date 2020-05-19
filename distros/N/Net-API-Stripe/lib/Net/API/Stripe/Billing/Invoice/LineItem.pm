##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Invoice/LineItem.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/invoices/line_item
package Net::API::Stripe::Billing::Invoice::LineItem;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub description { shift->_set_get_scalar( 'description', @_ ); }

sub discountable { shift->_set_get_boolean( 'discountable', @_ ); }

sub invoice_item { shift->_set_get_scalar( 'invoice_item', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub period { shift->_set_get_object( 'period', 'Net::API::Stripe::Billing::Invoice::Period', @_ ); }

sub plan { shift->_set_get_object( 'plan', 'Net::API::Stripe::Billing::Plan', @_ ); }

sub proration { shift->_set_get_boolean( 'proration', @_ ); }

sub quantity { shift->_set_get_number( 'quantity', @_ ); }

sub subscription { shift->_set_get_scalar( 'subscription', @_ ); }

sub subscription_item { shift->_set_get_scalar( 'subscription_item', @_ ); }

sub tax_amounts { return( shift->_set_get_object_array( 'tax_amounts', 'Net::API::Stripe::Billing::Invoice::TaxAmount', @_ ) ); }

sub tax_rates { return( shift->_set_get_object_array( 'tax_rates', 'Net::API::Stripe::Tax::Rate', @_ ) ); }

## The source type: invoiceitem or subscription
sub type { shift->_set_get_scalar( 'type', @_ ); }

sub unified_proration { return( shift->_set_get_scalar( 'unified_proration', @_ ) ); }

sub unique_id { return( shift->_set_get_scalar( 'unique_id', @_ ) ); }

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

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Billing::Invoice::LineItem> object.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "line_item"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> integer

The amount, in JPY.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<description> string

An arbitrary string attached to the object. Often useful for displaying to users.

=item B<discountable> boolean

If true, discounts will apply to this line item. Always false for prorations.

=item B<invoice_item> string

=item B<livemode> boolean

Whether this is a test line item.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Note that for line items with type=subscription this will reflect the metadata of the subscription that caused the line item to be created.

=item B<period> hash

The timespan covered by this invoice item.

This is a L<Net::API::Stripe::Billing::Invoice::Period> object.

=item B<plan> hash, plan object

The plan of the subscription, if the line item is a subscription or a proration.

This is a L<Net::API::Stripe::Billing::Plan> object.

=item B<proration> boolean

Whether this is a proration.

=item B<quantity> integer

The quantity of the subscription, if the line item is a subscription or a proration.

=item B<subscription> string

The subscription that the invoice item pertains to, if any.

=item B<subscription_item> string

The subscription item that generated this invoice item. Left empty if the line item is not an explicit result of a subscription.

=item B<tax_amounts> array of hashes

The amount of tax calculated per tax rate for this line item

This is an array of L<Net::API::Stripe::Billing::Invoice::TaxAmount> objects.

=item B<tax_rates> array of hashes

The tax rates which apply to the line item.

This is an array of L<Net::API::Stripe::Tax::Rate> objects.

=item B<type> string

A string identifying the type of the source of this line item, either an invoiceitem or a subscription.

=item B<unified_proration> boolean

For prorations this indicates whether Stripe automatically grouped multiple related debit and credit line items into a single combined line item.

=back

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
