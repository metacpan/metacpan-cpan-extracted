##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/CreditNote/LineItem.pm
## Version v0.101.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/01/25
## Modified 2022/10/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::CreditNote::LineItem;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.101.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub amount_excluding_tax { return( shift->_set_get_number( 'amount_excluding_tax', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub discount_amount { return( shift->_set_get_number( 'discount_amount', @_ ) ); }

sub discount_amounts { return( shift->_set_get_class_array( 'discount_amounts', {
    amount => { type => "number" },
    discount => { type => "scalar" },
}, @_ ) ); }

sub invoice_line_item { return( shift->_set_get_scalar( 'invoice_line_item', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub quantity { return( shift->_set_get_number( 'quantity', @_ ) ); }

sub tax_amounts
{
    return( shift->_set_get_class_array( 'tax_amounts',
    {
    amount        => { type => 'number' },
    inclusive    => { type => 'boolean' },
    tax_rate    => { type => 'scalar_or_object', class => 'Net::API::Stripe::Tax::Rate' },
    }, @_ ) );
}

sub tax_rates { return( shift->_set_get_object_array( 'tax_rates', 'Net::API::Stripe::Tax::Rate', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub unit_amount { return( shift->_set_get_number( 'unit_amount', @_ ) ); }

sub unit_amount_decimal { return( shift->_set_get_number( 'unit_amount_decimal', @_ ) ); }

sub unit_amount_excluding_tax { return( shift->_set_get_number( 'unit_amount_excluding_tax', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::CreditNote::LineItem - Stripe API Credit note Line Item Object

=head1 SYNOPSIS

    my $line = $stripe->credit_note_line_item({
        amount => 10000,
        description => 'Product return credit note',
        livemode => $stripe->false,
        quantity => 2,
        type => 'custom_line_item',
    });

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

    my $credit_line = $stripe->credit_note_line_item({
        amount => 2000,
        description => 'Credit note line text',
        discount_amount => 500,
        quantity => 2,
        type => 'invoice_line_item',
    });

=head1 CONSTRUCTOR

=head2 new( %arg )

Creates a new L<Net::API::Stripe::Billing::CreditNote::LineItem> object

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "credit_note_line_item"

String representing the object’s type. Objects of the same type share the same value.

=head2 amount integer

The integer amount in JPY representing the gross amount being credited for this line item, excluding (exclusive) tax and discounts.

=head2 amount_excluding_tax integer

The integer amount in JPY representing the amount being credited for this line item, excluding all tax and discounts.

=head2 description string

Description of the item being credited.

=head2 discount_amount integer

The integer amount in JPY representing the discount being credited for this line item.

=head2 discount_amounts array of hash

The amount of discount calculated per discount for this line item

It has the following properties:

=over 4

=item I<amount> integer

The amount, in JPY, of the discount.

=item I<discount> string

The discount that was applied to get this discount amount.

=back

=head2 invoice_line_item string

ID of the invoice line item being credited

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 quantity integer

The number of units of product being credited.

=head2 tax_amounts array of objects

The amount of tax calculated per tax rate for this line item.

This is a dynamic class with the following properties:

=over 4

=item I<amount> integer

The amount, in JPY, of the tax.

=item I<inclusive> boolean

Whether this tax amount is inclusive or exclusive.

=item I<tax_rate> string expandable

The tax rate that was applied to get this tax amount.

When expanded, this is a L<Net::API::Stripe::Tax::Rate> object.

=back

=head2 tax_rates array of L<Net::API::Stripe::Tax::Rate> objects

The tax rates which apply to the line item.

=head2 type string

The type of the credit note line item, one of C<custom_line_item> or C<invoice_line_item>. When the type is C<invoice_line_item> there is an additional C<invoice_line_item> property on the resource the value of which is the id of the credited line item on the invoice.

=head2 unit_amount integer

The cost of each unit of product being credited.

=head2 unit_amount_decimal decimal string

Same as unit_amount, but contains a decimal value with at most 12 decimal places.

=head2 unit_amount_excluding_tax decimal_string

The amount in JPY representing the unit amount being credited for this line item, excluding all tax and discounts.

=head1 API SAMPLE

    {
      "id": "cnli_fake124567890",
      "object": "credit_note_line_item",
      "amount": 1000,
      "description": "My First Invoice Item (created for API docs)",
      "discount_amount": 0,
      "invoice_line_item": "il_fake124567890",
      "livemode": false,
      "quantity": 1,
      "tax_amounts": [],
      "tax_rates": [],
      "type": "invoice_line_item",
      "unit_amount": null,
      "unit_amount_decimal": null
    }

=head1 HISTORY

=head2 v0.100.0

Initial version

=head1 STRIPE HISTORY

=head2 2019-12-03

The id field of all invoice line items have changed and are now prefixed with il_. The new id has consistent prefixes across all line items, is globally unique, and can be used for pagination.

=over 4

=item * You can no longer use the prefix of the id to determine the source of the line item. Instead use the type field for this purpose.

=item * For lines with type=invoiceitem, use the invoice_item field to reference or update the originating Invoice Item object.

=item * The Invoice Line Item object on earlier API versions also have a unique_id field to be used for migrating internal references before upgrading to this version.

=item * When setting a tax rate to individual line items, use the new id. Users on earlier API versions can pass in either a line item id or unique_id.

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://stripe.com/docs/api/credit_notes/line_item>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2020 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
