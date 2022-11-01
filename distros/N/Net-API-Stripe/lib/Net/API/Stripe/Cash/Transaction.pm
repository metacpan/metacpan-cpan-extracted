##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Cash/Transaction.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/07/06
## Modified 2022/07/06
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Cash::Transaction;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub applied_to_payment
{
    return( shift->_set_get_class( 'settings',
    {
    payment_intent => { type => 'scalar_or_object', package => 'Net::API::Stripe::Payment::Intent' },
    }, @_ ) );
}

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub ending_balance { return( shift->_set_get_number( 'ending_balance', @_ ) ); }

sub funded
{
    return( shift->_set_get_class( 'funded',
    {
    bank_transfer => { type => 'class', definition =>
        {
        eu_bank_transfer => { type => 'class', definition =>
            {
            bic => { type => 'string' },
            iban_last4 => { type => 'string' },
            sender_name => { type => 'string' },
            }},
        reference => { type => 'string' },
        type => { type => 'string' },
        }},
    }, @_ ) );
}

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub net_amount { return( shift->_set_get_number( 'net_amount', @_ ) ); }

sub refunded_from_payment
{
    return( shift->_set_get_class( 'refunded_from_payment',
    {
    refund => { type => 'scalar_or_object', package => 'Net::API::Stripe::Refund' },
    }, @_ ) );
}

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub unapplied_from_payment
{
    return( shift->_set_get_class( 'unapplied_from_payment',
    {
    payment_intent => { type => 'scalar_or_object', package => 'Net::API::Stripe::Payment::Intent' },
    }, @_ ) );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::Stripe::Cash::Transaction - Stripe API

=head1 SYNOPSIS

    use Net::API::Stripe::Cash::Transaction;
    my $this = Net::API::Stripe::Cash::Transaction->new || die( Net::API::Stripe::Cash::Transaction->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

=head1 METHODS

=head2 id

String

Unique identifier for the object.

Object string, value is "customer_cash_balance_transaction"

String representing the object’s type. Objects of the same type share the same value.

=head2 applied_to_payment

Hash

If this is a type=applied_to_payment transaction, contains information about how funds were applied.

=over 4

=item * C<payment_intent>

String

Expandable

The Payment Intent that funds were applied to.

=back

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency string

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 customer string

Expandable

The customer whose available cash balance changed as a result of this transaction.

=head2 ending_balance integer

The total available cash balance for the specified currency after this transaction was applied. Represented in the smallest currency unit.

=head2 funded

Hash

If this is a type=funded transaction, contains information about the funding.

=over 4

=item * C<bank_transfer>

Hash

Information about the bank transfer that funded the customer’s cash balance.

=over 8

=item * C<eu_bank_transfer>

Hash

EU-specific details of the bank transfer.

=over 12

=item * C<bic>

String

The BIC of the bank of the sender of the funding.

=item * C<iban_last4>

String

The last 4 digits of the IBAN of the sender of the funding.

=item * C<sender_name>

String

The full name of the sender, as supplied by the sending bank.

=back

=item * C<reference>

String

The user-supplied reference field on the bank transfer.

=item * C<type>

String

The funding method type used to fund the customer balance. Permitted values include: us_bank_account, eu_bank_account, id_bank_account, gb_bank_account, jp_bank_account, mx_bank_account, eu_bank_transfer, gb_bank_transfer, id_bank_transfer, jp_bank_transfer, mx_bank_transfer, or us_bank_transfer.

=back

=back

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 net_amount integer

The amount by which the cash balance changed, represented in the smallest currency unit. A positive value represents funds being added to the cash balance, a negative value represents funds being removed from the cash balance.

=head2 refunded_from_payment

Hash

If this is a type=refunded_from_payment transaction, contains information about the source of the refund.

=over 4

=item * C<refund>

String. Expandable

The Refund that moved these funds into the customer’s cash balance.

=back

=head2 type string

The type of the cash balance transaction. One of adjustment, applied_to_invoice, credit_note, initial, invoice_too_large, invoice_too_small, migration, unspent_receiver_credit, or unapplied_from_invoice. New types may be added in future. See Customer Balances to learn more about these types.

=head2 unapplied_from_payment

Hash

If this is a type=unapplied_from_payment transaction, contains information about how funds were unapplied.

=over 4

=item * C<payment_intent>

String. Expandable

The Payment Intent that funds were unapplied from.

=back

=head1 API SAMPLE

    {
      "id": "ccsbtxn_1LIVZqCeyNCl6fY2APWGE8ro",
      "object": "customer_cash_balance_transaction",
      "created": 1657103726,
      "currency": "jpy",
      "customer": "cus_AODr7KhjWjH7Yk",
      "ending_balance": 10000,
      "funded": {
        "bank_transfer": {
          "reference": null,
          "type": "jp_bank_transfer"
        }
      },
      "livemode": false,
      "net_amount": 5000,
      "type": "funded"
    }
=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/cash_balance_transactions/object>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
