##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Treasury/OutboundTransfer.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Treasury::OutboundTransfer;
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

sub destination_payment_method { return( shift->_set_get_scalar( 'destination_payment_method', @_ ) ); }

sub destination_payment_method_details { return( shift->_set_get_object( 'destination_payment_method_details', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub expected_arrival_date { return( shift->_set_get_datetime( 'expected_arrival_date', @_ ) ); }

sub financial_account { return( shift->_set_get_scalar( 'financial_account', @_ ) ); }

sub hosted_regulatory_receipt_url { return( shift->_set_get_scalar( 'hosted_regulatory_receipt_url', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub returned_details { return( shift->_set_get_class( 'returned_details',
{
  code => { type => "scalar" },
  transaction => {
    package => "Net::API::Stripe::Treasury::Transaction",
    type => "scalar_or_object",
  },
}, @_ ) ); }

sub statement_descriptor { return( shift->_set_get_scalar( 'statement_descriptor', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub status_transitions { return( shift->_set_get_class( 'status_transitions',
{
  canceled_at => { type => "datetime" },
  failed_at   => { type => "datetime" },
  posted_at   => { type => "datetime" },
  returned_at => { type => "datetime" },
}, @_ ) ); }

sub transaction { return( shift->_set_get_scalar_or_object( 'transaction', 'Net::API::Stripe::Treasury::Transaction', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Treasury::OutboundTransfer - The OutboundTransfer object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Use OutboundTransfers to transfer funds from a L<FinancialAccount|https://stripe.com/docs/api/treasury/financial_accounts> to a PaymentMethod belonging to the same entity. To send funds to a different party, use L<OutboundPayments|https://stripe.com/docs/api/treasury/outbound_payments> instead. You can send funds over ACH rails or through a domestic wire transfer to a user's own external bank account.

Simulate OutboundTransfer state changes with the C</v1/test_helpers/treasury/outbound_transfers> endpoints. These methods can only be called on test mode objects.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 amount integer

Amount (in cents) transferred.

=head2 cancelable boolean

Returns C<true> if the object can be canceled, and C<false> otherwise.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a L<supported currency|https://stripe.com/docs/currencies>.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users.

=head2 destination_payment_method string

The PaymentMethod used as the payment instrument for an OutboundTransfer.

=head2 destination_payment_method_details object

Details about the PaymentMethod for an OutboundTransfer

This is a L<Net::API::Stripe::Payment::Method> object.

=head2 expected_arrival_date timestamp

The date when funds are expected to arrive in the destination account.

=head2 financial_account string

The FinancialAccount that funds were pulled from.

=head2 hosted_regulatory_receipt_url string

A L<hosted transaction receipt|https://stripe.com/docs/treasury/moving-money/regulatory-receipts> URL that is provided when money movement is considered regulated under Stripe's money transmission licenses.

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 metadata hash

Set of L<key-value pairs|https://stripe.com/docs/api/metadata> that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 returned_details hash

Details about a returned OutboundTransfer. Only set when the status is C<returned>.

It has the following properties:

=over 4

=item C<code> string

Reason for the return.

=item C<transaction> string expandable

The Transaction associated with this object.

When expanded this is an L<Net::API::Stripe::Treasury::Transaction> object.

=back

=head2 statement_descriptor string

Information about the OutboundTransfer to be sent to the recipient account.

=head2 status string

Current status of the OutboundTransfer: C<processing>, C<failed>, C<canceled>, C<posted>, C<returned>. An OutboundTransfer is C<processing> if it has been created and is pending. The status changes to C<posted> once the OutboundTransfer has been "confirmed" and funds have left the account, or to C<failed> or C<canceled>. If an OutboundTransfer fails to arrive at its destination, its status will change to C<returned>.

=head2 status_transitions hash

Hash containing timestamps of when the object transitioned to a particular C<status>.

It has the following properties:

=over 4

=item C<canceled_at> timestamp

Timestamp describing when an OutboundTransfer changed status to C<canceled>

=item C<failed_at> timestamp

Timestamp describing when an OutboundTransfer changed status to C<failed>

=item C<posted_at> timestamp

Timestamp describing when an OutboundTransfer changed status to C<posted>

=item C<returned_at> timestamp

Timestamp describing when an OutboundTransfer changed status to C<returned>

=back

=head2 transaction expandable

The Transaction associated with this object.

When expanded this is an L<Net::API::Stripe::Treasury::Transaction> object.

=head1 API SAMPLE

[
   {
      "amount" : "10000",
      "cancelable" : 1,
      "created" : "1662261085",
      "currency" : "usd",
      "description" : "OutboundTransfer to my external bank account",
      "destination_payment_method" : "pm_1Le9F32eZvKYlo2CpHGQxg2C",
      "destination_payment_method_details" : {
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
      "expected_arrival_date" : "1662422400",
      "financial_account" : "fa_1Le9F32eZvKYlo2CjbQcDQUE",
      "hosted_regulatory_receipt_url" : "https://payments.stripe.com/regulatory-receipt/CBQaFwoVYWNjdF8xMDMyRDgyZVp2S1lsbzJDKN6u0JgGMgYg10dl2l46NpNi7-U4RHGRK4gmazw1MJMHmoXQhqSVwlK_KfXIpam3FgzagG7PLAcDtvccPlM_sJNFGTBUBQ",
      "id" : "obt_1Le9F32eZvKYlo2CPQD5jo2F",
      "livemode" : 0,
      "metadata" : {},
      "object" : "treasury.outbound_transfer",
      "returned_details" : null,
      "statement_descriptor" : "transfer",
      "status" : "processing",
      "status_transitions" : {
         "canceled_at" : null,
         "failed_at" : null,
         "posted_at" : null,
         "returned_at" : null
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

L<Stripe API documentation|https://stripe.com/docs/api/treasury/outbound_transfers>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
