##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Treasury/DebitReversal.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Treasury::DebitReversal;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub currency { return( shift->_set_get_number( 'currency', @_ ) ); }

sub financial_account { return( shift->_set_get_scalar( 'financial_account', @_ ) ); }

sub hosted_regulatory_receipt_url { return( shift->_set_get_scalar( 'hosted_regulatory_receipt_url', @_ ) ); }

sub linked_flows { return( shift->_set_get_class( 'linked_flows',
{ issuing_dispute => { type => "scalar" } }, @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub network { return( shift->_set_get_scalar( 'network', @_ ) ); }

sub received_debit { return( shift->_set_get_scalar( 'received_debit', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub status_transitions { return( shift->_set_get_object( 'status_transitions', 'Net::API::Stripe::Billing::Subscription::Schedule', @_ ) ); }

sub transaction { return( shift->_set_get_scalar_or_object( 'transaction', 'Net::API::Stripe::Treasury::Transaction', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Treasury::DebitReversal - The DebitReversal object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

You can reverse some L<ReceivedDebits|https://stripe.com/docs/api/treasury/received_debits> depending on their network and source flow. Reversing a ReceivedDebit leads to the creation of a new object known as a DebitReversal.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 amount integer

Amount (in cents) transferred.

=head2 currency currency

Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a L<supported currency|https://stripe.com/docs/currencies>.

=head2 financial_account string

The FinancialAccount to reverse funds from.

=head2 hosted_regulatory_receipt_url string

A L<hosted transaction receipt|https://stripe.com/docs/treasury/moving-money/regulatory-receipts> URL that is provided when money movement is considered regulated under Stripe's money transmission licenses.

=head2 linked_flows hash

Other flows linked to a DebitReversal.

It has the following properties:

=over 4

=item C<issuing_dispute> string

Set if there is an Issuing dispute associated with the DebitReversal.

=back

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 metadata hash

Set of L<key-value pairs|https://stripe.com/docs/api/metadata> that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 network string

The rails used to reverse the funds.

=head2 received_debit string

The ReceivedDebit being reversed.

=head2 status string

Status of the DebitReversal

=head2 status_transitions object

Hash containing timestamps of when the object transitioned to a particular C<status>.

This is a L<Net::API::Stripe::Billing::Subscription::Schedule> object.

=head2 transaction expandable

The Transaction associated with this object.

When expanded this is an L<Net::API::Stripe::Treasury::Transaction> object.

=head1 API SAMPLE

[
   {
      "amount" : "1000",
      "currency" : "usd",
      "financial_account" : "fa_1Le9F32eZvKYlo2CjbQcDQUE",
      "hosted_regulatory_receipt_url" : "https://payments.stripe.com/regulatory-receipt/CBQaFwoVYWNjdF8xMDMyRDgyZVp2S1lsbzJDKN6u0JgGMgZ5wklFW6A6NpM6vaRPqAA3MfviuxTVdP3EJG4azU5gXKVEXCmp3Kb06tC0LoZCqWCdfl0iQhcDzdQfLekmyQ",
      "id" : "debrev_1Le9F42eZvKYlo2Cb7q6jmDW",
      "linked_flows" : null,
      "livemode" : 0,
      "metadata" : {},
      "network" : "ach",
      "object" : "treasury.debit_reversal",
      "received_debit" : "rd_1Le9F42eZvKYlo2C0TIJJqNP",
      "status" : "processing",
      "status_transitions" : {
         "completed_at" : null
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

L<Stripe API documentation|https://stripe.com/docs/api/treasury/debit_reversals>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
