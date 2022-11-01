##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Customer/BalanceTransaction.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/customer_balance_transactions
package Net::API::Stripe::Customer::BalanceTransaction;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub credit_note { return( shift->_set_get_scalar_or_object( 'credit_note', 'Net::API::Stripe::Billing::CreditNote', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub ending_balance { return( shift->_set_get_number( 'ending_balance', @_ ) ); }

sub invoice { return( shift->_set_get_scalar_or_object( 'invoice', 'Net::API::Stripe::Billing::Invoice', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Customer::BalanceTransaction - A Stripe Customer Balance Tranaction Object

=head1 SYNOPSIS

    my $bt = $stripe->balance_transaction({
        amount => 2000,
        currency => 'jpy',
        customer => $customer_object,
        description => 'Payment for professional service',
        invoice => $invoice_object,
        metadata => { transaction_id => 123 },
        type => 'initial',
    });

Crediting the customer:

    my $bt = $stripe->balance_transaction({
        amount => -2000,
        credit_note => $credit_note_object,
        currency => 'jpy',
        customer => $customer_object,
        description => 'Credit note for cancelled invoice',
        invoice => $invoice_object,
        metadata => { transaction_id => 123 },
        type => 'credit_note',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Each customer has a I<balance> value, which denotes a debit or credit that's automatically applied to their next invoice upon finalization. You may modify the value directly by using the update customer API (L<https://stripe.com/docs/api/customers/update>), or by creating a Customer Balance Transaction, which increments or decrements the customer's I<balance> by the specified I<amount>.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Customer::BalanceTransaction> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "customer_balance_transaction"

String representing the object’s type. Objects of the same type share the same value.

=head2 amount integer

The amount of the transaction. A negative value is a credit for the customer’s balance, and a positive value is a debit to the customer’s balance.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 credit_note string (expandable)

The ID of the credit note (if any) related to the transaction. When expanded this is a L<Net::API::Stripe::Billing::CreditNote> object.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 customer string (expandable)

The ID of the customer the transaction belongs to. When expanded, this is a L<Net::API::Stripe::Customer> object.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users.

=head2 ending_balance integer

The customer’s balance after the transaction was applied. A negative value decreases the amount due on the customer’s next invoice. A positive value increases the amount due on the customer’s next invoice.

=head2 invoice string (expandable)

The ID of the invoice (if any) related to the transaction. When expanded, this is a L<Net::API::Stripe::Billing::Invoice> object.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 type string

Transaction type: adjustment, applied_to_invoice, credit_note, initial, invoice_too_large, invoice_too_small, unapplied_from_invoice, or unspent_receiver_credit. See the Customer Balance page to learn more about transaction types.

=head1 API SAMPLE

    {
      "object": "balance",
      "available": [
        {
          "amount": 0,
          "currency": "jpy",
          "source_types": {
            "card": 0
          }
        }
      ],
      "connect_reserved": [
        {
          "amount": 0,
          "currency": "jpy"
        }
      ],
      "livemode": false,
      "pending": [
        {
          "amount": 7712,
          "currency": "jpy",
          "source_types": {
            "card": 7712
          }
        }
      ]
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/customer_balance_transactions>, L<https://stripe.com/docs/billing/customer/balance>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
