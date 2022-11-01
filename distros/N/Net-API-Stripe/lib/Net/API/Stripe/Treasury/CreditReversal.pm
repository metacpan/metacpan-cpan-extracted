##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Treasury/CreditReversal.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Treasury::CreditReversal;
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

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub network { return( shift->_set_get_scalar( 'network', @_ ) ); }

sub received_credit { return( shift->_set_get_scalar( 'received_credit', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub status_transitions { return( shift->_set_get_class( 'status_transitions',
{ posted_at => { type => "datetime" } }, @_ ) ); }

sub transaction { return( shift->_set_get_scalar_or_object( 'transaction', 'Net::API::Stripe::Treasury::Transaction', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Treasury::CreditReversal - The CreditReversal object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

You can reverse some L<ReceivedCredits|https://stripe.com/docs/api/treasury/received_credits> depending on their network and source flow. Reversing a ReceivedCredit leads to the creation of a new object known as a CreditReversal.

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

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 metadata hash

Set of L<key-value pairs|https://stripe.com/docs/api/metadata> that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 network string

The rails used to reverse the funds.

=head2 received_credit string

The ReceivedCredit being reversed.

=head2 status string

Status of the CreditReversal

=head2 status_transitions hash

Hash containing timestamps of when the object transitioned to a particular C<status>.

It has the following properties:

=over 4

=item C<posted_at> timestamp

Timestamp describing when the CreditReversal changed status to C<posted>

=back

=head2 transaction expandable

The Transaction associated with this object.

When expanded this is an L<Net::API::Stripe::Treasury::Transaction> object.

=head1 API SAMPLE

[
   {
      "amount" : "1000",
      "currency" : "usd",
      "financial_account" : "fa_1Le9F32eZvKYlo2CjbQcDQUE",
      "hosted_regulatory_receipt_url" : "https://payments.stripe.com/regulatory-receipt/CBQaFwoVYWNjdF8xMDMyRDgyZVp2S1lsbzJDKN6u0JgGMgZ5OcNPutk6NpPqyGNMSnPeYuICbWV_67gyzu-WhKrtnutbIUkZW186FSWoCzhS4mHPYChKMkLzDubrcfUuiQ",
      "id" : "credrev_1Le9F42eZvKYlo2CHPmAdXSp",
      "livemode" : 0,
      "metadata" : {},
      "network" : "ach",
      "object" : "treasury.credit_reversal",
      "received_credit" : "rc_1Le9F42eZvKYlo2CM2wIU5bz",
      "status" : "processing",
      "status_transitions" : {
         "posted_at" : null
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

L<Stripe API documentation|https://stripe.com/docs/api/treasury/credit_reversals>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
