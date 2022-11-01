##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Treasury/Transaction.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Treasury::Transaction;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub balance_impact { return( shift->_set_get_class( 'balance_impact',
{
  cash => { type => "number" },
  inbound_pending => { type => "number" },
  outbound_pending => { type => "number" },
}, @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_number( 'currency', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub entries { return( shift->_set_get_object( 'entries', 'Net::API::Stripe::List', @_ ) ); }

sub financial_account { return( shift->_set_get_scalar( 'financial_account', @_ ) ); }

sub flow { return( shift->_set_get_scalar( 'flow', @_ ) ); }

sub flow_details { return( shift->_set_get_class( 'flow_details',
{
  credit_reversal       => {
                             package => "Net::API::Stripe::Treasury::CreditReversal",
                             type => "object",
                           },
  debit_reversal        => {
                             package => "Net::API::Stripe::Treasury::DebitReversal",
                             type => "object",
                           },
  inbound_transfer      => {
                             package => "Net::API::Stripe::Treasury::InboundTransfer",
                             type => "object",
                           },
  issuing_authorization => { type => "hash" },
  outbound_payment      => {
                             package => "Net::API::Stripe::Treasury::OutboundPayment",
                             type => "object",
                           },
  outbound_transfer     => {
                             package => "Net::API::Stripe::Treasury::OutboundTransfer",
                             type => "object",
                           },
  received_credit       => {
                             package => "Net::API::Stripe::Treasury::ReceivedCredit",
                             type => "object",
                           },
  received_debit        => {
                             package => "Net::API::Stripe::Treasury::ReceivedDebit",
                             type => "object",
                           },
  type                  => { type => "scalar" },
}, @_ ) ); }

sub flow_type { return( shift->_set_get_scalar( 'flow_type', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub status_transitions { return( shift->_set_get_class( 'status_transitions',
{
  posted_at => { type => "datetime" },
  void_at   => { type => "datetime" },
}, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Treasury::Transaction - The Transaction object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Transactions represent changes to a L<FinancialAccount's|https://stripe.com/docs/api/treasury/financial_accounts> balance.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 amount integer

Amount (in cents) transferred.

=head2 balance_impact hash

The change made to each of the FinancialAccount's sub-balances by the Transaction.

It has the following properties:

=over 4

=item C<cash> integer

The change made to funds the user can spend right now.

=item C<inbound_pending> integer

The change made to funds that are not spendable yet, but will become available at a later time.

=item C<outbound_pending> integer

The change made to funds in the account, but not spendable because they are being held for pending outbound flows.

=back

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a L<supported currency|https://stripe.com/docs/currencies>.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users.

=head2 entries object

A list of TransactionEntries that are part of this Transaction. This cannot be expanded in any list endpoints.

This is a L<Net::API::Stripe::List> object.

=head2 financial_account string

The FinancialAccount associated with this object.

=head2 flow string

ID of the flow that created the Transaction.

=head2 flow_details hash

Details of the flow that created the Transaction.

It has the following properties:

=over 4

=item C<credit_reversal> hash

The CreditReversal object associated with the Transaction. Set if C<type=credit_reversal>.

When expanded, this is a L<Net::API::Stripe::Treasury::CreditReversal> object.

=item C<debit_reversal> hash

The DebitReversal object associated with the Transaction. Set if C<type=debit_reversal>.

When expanded, this is a L<Net::API::Stripe::Treasury::DebitReversal> object.

=item C<inbound_transfer> hash

The InboundTransfer object associated with the Transaction. Set if C<type=inbound_transfer>.

When expanded, this is a L<Net::API::Stripe::Treasury::InboundTransfer> object.

=item C<issuing_authorization> hash

The Issuing authorization object associated with the Transaction. Set if C<type=issuing_authorization>.

=item C<outbound_payment> hash

The OutboundPayment object associated with the Transaction. Set if C<type=outbound_payment>.

When expanded, this is a L<Net::API::Stripe::Treasury::OutboundPayment> object.

=item C<outbound_transfer> hash

The OutboundTransfer object associated with the Transaction. Set if C<type=outbound_transfer>.

When expanded, this is a L<Net::API::Stripe::Treasury::OutboundTransfer> object.

=item C<received_credit> hash

The ReceivedCredit object associated with the Transaction. Set if C<type=received_credit>.

When expanded, this is a L<Net::API::Stripe::Treasury::ReceivedCredit> object.

=item C<received_debit> hash

The ReceivedDebit object associated with the Transaction. Set if C<type=received_debit>.

When expanded, this is a L<Net::API::Stripe::Treasury::ReceivedDebit> object.

=item C<type> string

Type of the flow that created the Transaction. Set to the same value as C<flow_type>.

=back

=head2 flow_type string

Type of the flow that created the Transaction.

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 status string

Status of the Transaction.

=head2 status_transitions hash

Hash containing timestamps of when the object transitioned to a particular C<status>.

It has the following properties:

=over 4

=item C<posted_at> timestamp

Timestamp describing when the Transaction changed status to C<posted>.

=item C<void_at> timestamp

Timestamp describing when the Transaction changed status to C<void>.

=back

=head1 API SAMPLE

[
   {
      "amount" : "-100",
      "balance_impact" : {
         "cash" : "-100",
         "inbound_pending" : "0",
         "outbound_pending" : "100"
      },
      "created" : "1662261085",
      "currency" : "usd",
      "description" : "Jane Austen (6789) | Outbound transfer | transfer",
      "financial_account" : "fa_1Le9F32eZvKYlo2CjbQcDQUE",
      "flow" : "obt_1Le9F32eZvKYlo2CPQD5jo2F",
      "flow_type" : "outbound_transfer",
      "id" : "trxn_1Le9F32eZvKYlo2C2dtkse82",
      "livemode" : 0,
      "object" : "treasury.transaction",
      "status" : "open",
      "status_transitions" : {
         "posted_at" : null,
         "void_at" : null
      }
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/treasury/transactions>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
