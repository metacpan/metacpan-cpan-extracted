##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/List/Item.pm
## Version v0.2.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::List::Item;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.2.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub adjustable_quantity { return( shift->_set_get_class( 'adjustable_quantity',
{
  enabled => { type => "boolean" },
  maximum => { type => "integer" },
  minimum => { type => "integer" },
}, @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub amount_discount { return( shift->_set_get_number( 'amount_discount', @_ ) ); }

sub amount_subtotal { return( shift->_set_get_number( 'amount_subtotal', @_ ) ); }

sub amount_tax { return( shift->_set_get_number( 'amount_tax', @_ ) ); }

sub amount_total { return( shift->_set_get_number( 'amount_total', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub discounts { return( shift->_set_get_class( 'discounts',
{
    amount => { type => 'integer' },
    discount => { package => 'Net::API::Stripe::Billing::Discount' },
}, @_ ) ); }

sub price { return( shift->_set_get_scalar_or_object( 'price', 'Net::API::Stripe::Price', @_ ) ); }

sub quantity { return( shift->_set_get_number( 'quantity', @_ ) ); }

sub taxes { return( shift->_set_get_class( 'taxes',
{
    amount => { type => 'integer' },
    rate => { package => 'Net::API::Stripe::Tax::Rate' },
}, @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::List::Item - A Stripe Payment Link Item

=head1 SYNOPSIS

    my $item = $stripe->payment_link->line_items([
    {
        object => 'list',
        data =>
        {
            amount_subtotal => 2000,
            amount_total => 2200,
            currency => 'jpy',
            description => 'Some item',
            discounts => 0,
            price =>
                {
                id => $price_id,
                object => 'price',
                active => $stripe->true,
                billing_scheme => 'per_unit',
                created => $timestamp,
                currency => 'JPY',
                livemode => $stripe->true,
                lookup_key => $key,
                metadata => { customer => 123 },
                nickname => $nickname,
                product => $product_id,
                recurring => 
                    {
                    aggregate_usage => 'sum',
                    interval => 'month',
                    interval_count => 'month',
                    usage_type => 'licensed',
                    },
                },
                tax_behavior => 'recurring',
                tiers => 
                    {
                    flat_amount => 10000,
                    flat_amount_decimal => 10000,
                    unit_amount => 1000,
                    unit_amount_decimal => 1000,
                    up_to => $value,
                    },
                tiers_mode => 'graduated',
                transform_quantity => 
                    {
                    divide_by => $value,
                    round => 'up',
                    },
                type => 'recurring',
                unit_amount => 10000,
                unit_amount_decimal => 500,
            },
            quantity => 2,
            taxes =>
                {
                amount => 200,
                rate => $rate_id,
                },
        },
        has_more => $stripe->true,
        url => 'https://buy.stripe.com/test_1234567890qwertyuiop',
    }]);

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The line items representing what is being sold.

This field is not included by default. To include it in the response, expand the line_items field.

This is used by:

=over 4

=item L<Net::API::Stripe::Payment::Link> object and called from the method B<line_items>

=item L<Net::API::Stripe::Order::Item>

=back

=head1 CONSTRUCTOR

=head2 new

Creates a new L<Net::API::Stripe::List::Item> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "item"

String representing the object’s type. Objects of the same type share the same value.

=head2 amount integer

A positive integer in the smallest currency unit (that is, 100 cents for $1.00, or 1 for ¥1, Japanese Yen being a zero-decimal currency) representing the total amount for the line item.

=head2 amount_discount integer

=head2 amount_subtotal integer

Total before any discounts or taxes are applied.

=head2 amount_tax integer

=head2 amount_total integer

Total after discounts and taxes.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users. Defaults to product name.

=head2 discounts array of hashes expandable

The discounts applied to the line item.

This field is not included by default. To include it in the response, expand the discounts field.

=over 4

=item amount integer

The amount discounted.

=item discount hash, discount object

The discount applied.

=back

=head2 price hash

The price used to generate the line item.

=head2 quantity positive integer or zero

The quantity of products being purchased.

=head2 taxes array of hashes expandable

The taxes applied to the line item.

This field is not included by default. To include it in the response, expand the taxes field.

=over 4

=item amount integer

Amount of tax applied for this rate.

=item rate hash

The tax rate id or hash applied.

=back

=head2 type string

The type of line item.

=head1 API SAMPLE

    {
      "id": "li_1234567890qwertyuiop",
      "object": "item",
      "amount_subtotal": 0,
      "amount_total": 0,
      "currency": "jpy",
      "description": "テスト5円",
      "price": {
        "id": "price_1234567890qwertyuiop",
        "object": "price",
        "active": true,
        "billing_scheme": "per_unit",
        "created": 1634704866,
        "currency": "jpy",
        "livemode": false,
        "lookup_key": null,
        "metadata": {},
        "nickname": null,
        "product": "prod_1234567890qwertyuiop",
        "recurring": null,
        "tax_behavior": "unspecified",
        "tiers_mode": null,
        "transform_quantity": null,
        "type": "one_time",
        "unit_amount": 5,
        "unit_amount_decimal": "5"
      },
      "quantity": 1
    }

    {
        "id": "il_1234567890qwertyuiop",
        "object": "line_item",
        "amount": 5,
        "currency": "jpy",
        "description": "My First Invoice Item (created for API docs)",
        "discount_amounts": [],
        "discountable": true,
        "discounts": [],
        "invoice_item": "ii_1234567890qwertyuiop",
        "livemode": false,
        "metadata": {},
        "period": {
          "end": 1643371794,
          "start": 1643371794
        },
        "price": {
          "id": "price_1234567890qwertyuiop",
          "object": "price",
          "active": true,
          "billing_scheme": "per_unit",
          "created": 1634704866,
          "currency": "jpy",
          "livemode": false,
          "lookup_key": null,
          "metadata": {},
          "nickname": null,
          "product": "prod_1234567890qwertyuiop",
          "recurring": null,
          "tax_behavior": "unspecified",
          "tiers_mode": null,
          "transform_quantity": null,
          "type": "one_time",
          "unit_amount": 5,
          "unit_amount_decimal": "5"
        },
        "proration": false,
        "quantity": 1,
        "subscription": null,
        "tax_amounts": [],
        "tax_rates": [],
        "type": "invoiceitem"
    }

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>

L<Invoice line item|https://stripe.com/docs/api/invoices/object#invoice_object-lines>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

