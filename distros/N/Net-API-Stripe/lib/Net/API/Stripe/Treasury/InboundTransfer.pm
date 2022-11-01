##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Treasury/InboundTransfer.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Treasury::InboundTransfer;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub cancelable { return( shift->_set_get_boolean( 'cancelable', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_number( 'currency', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub failure_details { return( shift->_set_get_object( 'failure_details', 'Net::API::Stripe::Error', @_ ) ); }

sub financial_account { return( shift->_set_get_scalar( 'financial_account', @_ ) ); }

sub hosted_regulatory_receipt_url { return( shift->_set_get_scalar( 'hosted_regulatory_receipt_url', @_ ) ); }

sub linked_flows { return( shift->_set_get_class( 'linked_flows',
{ received_debit => { type => "scalar" } }, @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub origin_payment_method { return( shift->_set_get_scalar( 'origin_payment_method', @_ ) ); }

sub origin_payment_method_details { return( shift->_set_get_object( 'origin_payment_method_details', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub returned { return( shift->_set_get_boolean( 'returned', @_ ) ); }

sub statement_descriptor { return( shift->_set_get_scalar( 'statement_descriptor', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub status_transitions { return( shift->_set_get_class( 'status_transitions',
{
  failed_at    => { type => "datetime" },
  succeeded_at => { type => "datetime" },
}, @_ ) ); }

sub transaction { return( shift->_set_get_scalar_or_object( 'transaction', 'Net::API::Stripe::Treasury::Transaction', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Treasury::InboundTransfer - The InboundTransfer object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Use L<InboundTransfers|https://stripe.com/docs/treasury/moving-money/financial-accounts/into/inbound-transfers> to add funds to your L<FinancialAccount|https://stripe.com/docs/api/treasury/financial_accounts> via a PaymentMethod that is owned by you. The funds will be transferred via an ACH debit.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 amount integer

Amount (in cents) transferred.

=head2 cancelable boolean

Returns C<true> if the InboundTransfer is able to be canceled.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a L<supported currency|https://stripe.com/docs/currencies>.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users.

=head2 failure_details object

Details about this InboundTransfer's failure. Only set when status is C<failed>.

This is a L<Net::API::Stripe::Error> object.

=head2 financial_account string

The FinancialAccount that received the funds.

=head2 hosted_regulatory_receipt_url string

A L<hosted transaction receipt|https://stripe.com/docs/treasury/moving-money/regulatory-receipts> URL that is provided when money movement is considered regulated under Stripe's money transmission licenses.

=head2 linked_flows hash

Other flows linked to a InboundTransfer.

It has the following properties:

=over 4

=item C<received_debit> string

If funds for this flow were returned after the flow went to the C<succeeded> state, this field contains a reference to the ReceivedDebit return.

=back

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 metadata hash

Set of L<key-value pairs|https://stripe.com/docs/api/metadata> that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 origin_payment_method string

The origin payment method to be debited for an InboundTransfer.

=head2 origin_payment_method_details object

Details about the PaymentMethod for an InboundTransfer.

This is a L<Net::API::Stripe::Payment::Method> object.

=head2 returned boolean

Returns C<true> if the funds for an InboundTransfer were returned after the InboundTransfer went to the C<succeeded> state.

=head2 statement_descriptor string

Statement descriptor shown when funds are debited from the source. Not all payment networks support C<statement_descriptor>.

=head2 status string

Status of the InboundTransfer: C<processing>, C<succeeded>, C<failed>, and C<canceled>. An InboundTransfer is C<processing> if it is created and pending. The status changes to C<succeeded> once the funds have been "confirmed" and a C<transaction> is created and posted. The status changes to C<failed> if the transfer fails.

=head2 status_transitions hash

Hash containing timestamps of when the object transitioned to a particular C<status>.

It has the following properties:

=over 4

=item C<failed_at> timestamp

Timestamp describing when an InboundTransfer changed status to C<failed>.

=item C<succeeded_at> timestamp

Timestamp describing when an InboundTransfer changed status to C<succeeded>.

=back

=head2 transaction expandable

The Transaction associated with this object.

When expanded this is an L<Net::API::Stripe::Treasury::Transaction> object.

=head1 API SAMPLE

[
   {
      "amount" : "10000",
      "cancelable" : 1,
      "created" : "1662261086",
      "currency" : "usd",
      "description" : "InboundTransfer from my external bank account",
      "failure_details" : null,
      "financial_account" : "fa_1Le9F32eZvKYlo2CjbQcDQUE",
      "hosted_regulatory_receipt_url" : "https://payments.stripe.com/regulatory-receipt/CBQaFwoVYWNjdF8xMDMyRDgyZVp2S1lsbzJDKN6u0JgGMgYX_o2noYA6NpN4jXrpZ4wHFa5zF22DiASaNO0VqFyFqmmxq76HgJ6U3fMErijpEIwaJZheg_11U9lfHZvHaQ",
      "id" : "ibt_1Le9F42eZvKYlo2CxDLDB04R",
      "linked_flows" : {
         "received_debit" : null
      },
      "livemode" : 0,
      "metadata" : {},
      "object" : "treasury.inbound_transfer",
      "origin_payment_method" : "pm_1Le9F32eZvKYlo2CpHGQxg2C",
      "origin_payment_method_details" : {
         "billing_details" : {
            "address" : {
               "city" : "San Francisco",
               "country" : "US",
               "line1" : "1234 Fake Street",
               "line2" : null,
               "postal_code" : "94102",
               "state" : "CA"
            },
            "email" : null,
            "name" : "Jane Austen"
         },
         "type" : "us_bank_account",
         "us_bank_account" : {
            "account_holder_type" : "company",
            "account_type" : "checking",
            "bank_name" : "STRIPE TEST BANK",
            "fingerprint" : "1JWtPxqbdX5Gamtc",
            "last4" : "6789",
            "network" : "ach",
            "routing_number" : "110000000"
         }
      },
      "returned" : 0,
      "statement_descriptor" : "transfer",
      "status" : "processing",
      "status_transitions" : {
         "failed_at" : null,
         "succeeded_at" : null
      },
      "transaction" : "trxn_1Le9F32eZvKYlo2C2dtkse82"
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/treasury/inbound_transfers>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
