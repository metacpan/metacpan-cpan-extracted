##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/CreditNote.pm
## Version v0.200.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/credit_notes
package Net::API::Stripe::Billing::CreditNote;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.200.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub customer_balance_transaction { return( shift->_set_get_scalar_or_object( 'customer_balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

sub invoice { return( shift->_set_get_scalar_or_object( 'invoice', 'Net::API::Stripe::Billing::Invoice', @_ ) ); }

sub lines { return( shift->_set_get_object_array( 'lines', 'Net::API::Stripe::List', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub memo { return( shift->_set_get_scalar( 'memo', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub number { return( shift->_set_get_number( 'number', @_ ) ); }

sub out_of_band_amount { return( shift->_set_get_number( 'out_of_band_amount', @_ ) ); }

sub pdf { return( shift->_set_get_scalar( 'pdf', @_ ) ); }

sub reason { return( shift->_set_get_scalar( 'reason', @_ ) ); }

sub refund { return( shift->_set_get_scalar_or_object( 'refund', 'Net::API::Stripe::Refund', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub subtotal { return( shift->_set_get_number( 'subtotal', @_ ) ); }

sub tax_amounts
{
	return( shift->_set_get_class( 'tax_amounts',
	{
	amount		=> { type => 'number' },
	inclusive	=> { type => 'boolean' },
	tax_rate	=> { type => 'scalar_or_object', class => 'Net::API::Stripe::Tax::Rate' },
	}, @_ ) );
}

sub total { return( shift->_set_get_number( 'total', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub voided_at { return( shift->_set_get_datetime( 'voided_at', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::CreditNote - A Stripe Credit Note Object

=head1 SYNOPSIS

    my $note = $stripe->credite_note({
        amount => 2000,
        memo => 'Credit note for your purchase on 2020-03-17',
        currency => 'eur',
        # Required
        invoice => $invoice_object,
        number => 'CR2020031701',
        metadata => { transac_id => 1212, client_id => 789, ts => 1584403200 }
        total => 2000
    });

=head1 VERSION

    v0.200.0

=head1 DESCRIPTION

Issue a credit note to adjust an invoice's amount after the invoice is finalized.

=head2 CREATING A CREDIT NOTE

Issue a credit note to adjust the amount of a finalized invoice. For a status=open invoice, a credit note reduces its amount_due. For a status=paid invoice, a credit note does not affect its amount_due. Instead, it can result in any combination of the following:

=over 4

=item * Refund: create a new refund (using refund_amount) or link an existing refund (using refund).

=item * Customer balance credit: credit the customer’s balance (using credit_amount) which will be automatically applied to their next invoice when it’s finalized.

=item * Outside of Stripe credit: record the amount that is or will be credited outside of Stripe (using out_of_band_amount).

=back

For post-payment credit notes the sum of the refund, credit and outside of Stripe amounts must equal the credit note total.

You may issue multiple credit notes for an invoice. Each credit note will increment the invoice’s pre_payment_credit_notes_amount or post_payment_credit_notes_amount depending on its status at the time of credit note creation.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Billing::CreditNote> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "credit_note"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> integer

The integer amount in JPY representing the total amount of the credit note, including tax.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<customer> string (expandable)

ID of the customer. When expanded, this is a L<Net::API::Stripe::Customer> object.

=item B<customer_balance_transaction> string (expandable)

Customer balance transaction related to this credit note. When expanded, this is a L<Net::API::Stripe::Balance::Transaction> object.

=item B<invoice> string (expandable)

ID of the invoice. When expanded, this is a L<Net::API::Stripe::Billing::Invoice> object.

=item B<lines>() list

Line items that make up the credit note.

This is a L<Net::API::Stripe::List> object with a list of L<Net::API::Stripe::Billing::CreditNote::LineItem>

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<memo> string

Customer-facing text that appears on the credit note PDF.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<number> string

A unique number that identifies this particular credit note and appears on the PDF of the credit note and its associated invoice.

=item B<out_of_band_amount>() integer

Amount that was credited outside of Stripe.

=item B<pdf> string

The link to download the PDF of the credit note.

=item B<reason> string

Reason for issuing this credit note, one of duplicate, fraudulent, order_change, or product_unsatisfactory

=item B<refund> string (expandable)

Refund related to this credit note. When expanded, this is a L<Net::API::Stripe::Refund> object.

=item B<status> string

Status of this credit note, one of issued or void. Learn more about voiding credit notes.

=item B<subtotal>() integer

The integer amount in JPY representing the amount of the credit note, excluding tax and discount.

=item B<total>() integer

The integer amount in JPY representing the total amount of the credit note, including tax and discount.

=item B<tax_amounts>() array of objects

The amount of tax calculated per tax rate for this line item.

This is a dynamic class with the following properties:

=over 8

=item I<amount> integer

The amount, in JPY, of the tax.

=item I<inclusive> boolean

Whether this tax amount is inclusive or exclusive.

=item I<tax_rate> string expandable

The tax rate that was applied to get this tax amount.

When expanded, this is a L<Net::API::Stripe::Tax::Rate> object.

=back

=item B<type> string

Type of this credit note, one of post_payment or pre_payment. A pre_payment credit note means it was issued when the invoice was open. A post_payment credit note means it was issued when the invoice was paid.

=item B<voided_at> timestamp

The time that the credit note was voided. This is a C<DateTime> object.

=back

=head1 API SAMPLE

	{
	  "id": "cn_fake124567890",
	  "object": "credit_note",
	  "amount": 1690,
	  "created": 1571397911,
	  "currency": "jpy",
	  "customer": "cus_fake124567890",
	  "customer_balance_transaction": null,
	  "invoice": "in_fake124567890",
	  "livemode": false,
	  "memo": null,
	  "metadata": {},
	  "number": "ABCD-1234-CN-01",
	  "pdf": "https://pay.stripe.com/credit_notes/acct_19eGgRCeyNCl6fY2/cnst_123456789/pdf",
	  "reason": null,
	  "refund": null,
	  "status": "issued",
	  "type": "pre_payment",
	  "voided_at": null
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/credit_notes>, L<https://stripe.com/docs/billing/invoices/credit-notes>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
