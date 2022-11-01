##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Treasury/ReceivedCredit.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Treasury::ReceivedCredit;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_number( 'currency', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub failure_code { return( shift->_set_get_scalar( 'failure_code', @_ ) ); }

sub financial_account { return( shift->_set_get_scalar( 'financial_account', @_ ) ); }

sub hosted_regulatory_receipt_url { return( shift->_set_get_scalar( 'hosted_regulatory_receipt_url', @_ ) ); }

sub initiating_payment_method_details { return( shift->_set_get_class( 'initiating_payment_method_details',
{
  balance => { type => "scalar" },
  billing_details => { package => "Net::API::Stripe::Billing::Details", type => "object" },
  financial_account => {
    package => "Net::API::Stripe::Connect::ExternalAccount::Card",
    type => "object",
  },
  issuing_card => { type => "scalar" },
  type => { type => "scalar" },
  us_bank_account => {
    package => "Net::API::Stripe::Connect::ExternalAccount::Bank",
    type => "object",
  },
}, @_ ) ); }

sub linked_flows { return( shift->_set_get_class( 'linked_flows',
{
  credit_reversal       => { type => "scalar" },
  issuing_authorization => { type => "scalar" },
  issuing_transaction   => { type => "scalar" },
  source_flow           => { type => "scalar" },
  source_flow_details   => {
                             definition => {
                               credit_reversal => {
                                 package => "Net::API::Stripe::Treasury::CreditReversal",
                                 type => "object",
                               },
                               outbound_payment => {
                                 package => "Net::API::Stripe::Treasury::OutboundPayment",
                                 type => "object",
                               },
                               payout => { type => "hash" },
                               type => { type => "scalar" },
                             },
                             type => "class",
                           },
  source_flow_type      => { type => "scalar" },
}, @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub network { return( shift->_set_get_scalar( 'network', @_ ) ); }

sub reversal_details { return( shift->_set_get_class( 'reversal_details',
{
  deadline => { type => "datetime" },
  restricted_reason => { type => "scalar" },
}, @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub transaction { return( shift->_set_get_scalar_or_object( 'transaction', 'Net::API::Stripe::Treasury::Transaction', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Treasury::ReceivedCredit - The ReceivedCredit object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

ReceivedCredits represent funds sent to a L<FinancialAccount|https://stripe.com/docs/api/treasury/financial_accounts> (for example, via ACH or wire). These money movements are not initiated from the FinancialAccount.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 amount integer

Amount (in cents) transferred.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a L<supported currency|https://stripe.com/docs/currencies>.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users.

=head2 failure_code string

Reason for the failure. A ReceivedCredit might fail because the receiving FinancialAccount is closed or frozen.

=head2 financial_account string

The FinancialAccount that received the funds.

=head2 hosted_regulatory_receipt_url string

A L<hosted transaction receipt|https://stripe.com/docs/treasury/moving-money/regulatory-receipts> URL that is provided when money movement is considered regulated under Stripe's money transmission licenses.

=head2 initiating_payment_method_details hash

Details about the PaymentMethod used to send a ReceivedCredit.

It has the following properties:

=over 4

=item C<balance> string

Set when C<type> is C<balance>.

=item C<billing_details> hash

The contact details of the person or business referenced by the received payment method details.

When expanded, this is a L<Net::API::Stripe::Billing::Details> object.

=item C<financial_account> hash

Set when C<type> is C<financial_account>. This is a L<FinancialAccount|https://stripe.com/docs/api/treasury/financial_accounts> ID.

When expanded, this is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object.

=item C<issuing_card> string

Set when C<type> is C<issuing_card>. This is an L<Issuing Card|https://stripe.com/docs/api/issuing/cards> ID.

=item C<type> string

Polymorphic type matching the originating money movement's source. This can be an external account, a Stripe balance, or a FinancialAccount.

=item C<us_bank_account> hash

Set when C<type> is C<us_bank_account>.

When expanded, this is a L<Net::API::Stripe::Connect::ExternalAccount::Bank> object.

=back

=head2 linked_flows hash

Other flows linked to a ReceivedCredit.

It has the following properties:

=over 4

=item C<credit_reversal> string

The CreditReversal created as a result of this ReceivedCredit being reversed.

=item C<issuing_authorization> string

Set if the ReceivedCredit was created due to an L<Issuing Authorization|https://stripe.com/docs/api/issuing/authorizations> object.

=item C<issuing_transaction> string

Set if the ReceivedCredit is also viewable as an L<Issuing transaction|https://stripe.com/docs/api/issuing/transactions> object.

=item C<source_flow> string

ID of the source flow. Set if C<network> is C<stripe> and the source flow is visible to the user. Examples of source flows include OutboundPayments, payouts, or CreditReversals.

=item C<source_flow_details> hash

The expandable object of the source flow.

=over 8

=item C<credit_reversal> hash

Details about a L<CreditReversal|https://stripe.com/docs/api/treasury/credit_reversals>.

When expanded, this is a L<Net::API::Stripe::Treasury::CreditReversal> object.

=item C<outbound_payment> hash

Details about an L<OutboundPayment|https://stripe.com/docs/api/treasury/outbound_payments>.

When expanded, this is a L<Net::API::Stripe::Treasury::OutboundPayment> object.

=item C<payout> hash

Details about a L<Payout|https://stripe.com/docs/api/payouts>.

=item C<type> string

The type of the source flow that originated the ReceivedCredit.


=back

=item C<source_flow_type> string

The type of flow that originated the ReceivedCredit (for example, C<outbound_payment>).

=back

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 network string

The rails used to send the funds.

=head2 reversal_details hash

Details describing when a ReceivedCredit may be reversed.

It has the following properties:

=over 4

=item C<deadline> timestamp

Time before which a ReceivedCredit can be reversed.

=item C<restricted_reason> string

Set if a ReceivedCredit cannot be reversed.

=back

=head2 status string

Status of the ReceivedCredit. ReceivedCredits are created either C<succeeded> (approved) or C<failed> (declined). If a ReceivedCredit is declined, the failure reason can be found in the C<failure_code> field.

=head2 transaction expandable

The Transaction associated with this object.

When expanded this is an L<Net::API::Stripe::Treasury::Transaction> object.

=head1 API SAMPLE

[
   {
      "amount" : "1234",
      "created" : "1662261086",
      "currency" : "usd",
      "description" : "Stripe Test",
      "failure_code" : null,
      "financial_account" : "fa_1Le9F32eZvKYlo2CjbQcDQUE",
      "hosted_regulatory_receipt_url" : "https://payments.stripe.com/regulatory-receipt/CBQaFwoVYWNjdF8xMDMyRDgyZVp2S1lsbzJDKN6u0JgGMgYDYytXp4Q6NpNxnyW6ja3A-rXLfX65n1xJ84o7-KJYCHHCamuKkO61-lq-6oeQnW0rKTXcVFx_UTYtQ73i9w",
      "id" : "rc_1Le9F42eZvKYlo2CM2wIU5bz",
      "initiating_payment_method_details" : {
         "billing_details" : {
            "address" : {
               "city" : null,
               "country" : null,
               "line1" : null,
               "line2" : null,
               "postal_code" : null,
               "state" : null
            },
            "email" : null,
            "name" : "Jane Austen"
         },
         "type" : "us_bank_account",
         "us_bank_account" : {
            "bank_name" : "STRIPE TEST BANK",
            "last4" : "6789",
            "routing_number" : "110000000"
         }
      },
      "linked_flows" : {
         "credit_reversal" : null,
         "issuing_authorization" : null,
         "issuing_transaction" : null,
         "source_flow" : null,
         "source_flow_type" : null
      },
      "livemode" : 0,
      "network" : "ach",
      "object" : "treasury.received_credit",
      "reversal_details" : {
         "deadline" : "1662508800",
         "restricted_reason" : null
      },
      "status" : "succeeded",
      "transaction" : "trxn_1Le9F32eZvKYlo2C2dtkse82"
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/treasury/received_credits>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
