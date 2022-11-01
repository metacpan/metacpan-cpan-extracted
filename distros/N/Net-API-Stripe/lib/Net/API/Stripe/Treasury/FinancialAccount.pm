##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Treasury/FinancialAccount.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Treasury::FinancialAccount;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub active_features { return( shift->_set_get_array( 'active_features', @_ ) ); }

sub balance { return( shift->_set_get_class( 'balance',
{
  cash => { type => "hash" },
  inbound_pending => { type => "hash" },
  outbound_pending => { type => "hash" },
}, @_ ) ); }

sub country { return( shift->_set_get_scalar( 'country', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub features { return( shift->_set_get_class( 'features',
{
  card_issuing        => {
                           package => "Net::API::Stripe::Connect::Account::Capability",
                           type => "object",
                         },
  deposit_insurance   => {
                           package => "Net::API::Stripe::Connect::Account::Capability",
                           type => "object",
                         },
  financial_addresses => {
                           definition => {
                             aba => {
                                      package => "Net::API::Stripe::Connect::Account::Capability",
                                      type => "object",
                                    },
                           },
                           type => "class",
                         },
  inbound_transfers   => {
                           definition => {
                             ach => {
                                      package => "Net::API::Stripe::Connect::Account::Capability",
                                      type => "object",
                                    },
                           },
                           type => "class",
                         },
  intra_stripe_flows  => {
                           package => "Net::API::Stripe::Connect::Account::Capability",
                           type => "object",
                         },
  object              => { type => "scalar" },
  outbound_payments   => {
                           definition => {
                             ach => {
                               package => "Net::API::Stripe::Connect::Account::Capability",
                               type => "object",
                             },
                             us_domestic_wire => {
                               package => "Net::API::Stripe::Connect::Account::Capability",
                               type => "object",
                             },
                           },
                           type => "class",
                         },
  outbound_transfers  => {
                           definition => {
                             ach => {
                               package => "Net::API::Stripe::Connect::Account::Capability",
                               type => "object",
                             },
                             us_domestic_wire => {
                               package => "Net::API::Stripe::Connect::Account::Capability",
                               type => "object",
                             },
                           },
                           type => "class",
                         },
}, @_ ) ); }

sub financial_addresses { return( shift->_set_get_class_array( 'financial_addresses',
{
  aba => {
    package => "Net::API::Stripe::Connect::ExternalAccount::Bank",
    type => "object",
  },
  supported_networks => { type => "array" },
  type => { type => "scalar" },
}, @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub pending_features { return( shift->_set_get_array( 'pending_features', @_ ) ); }

sub platform_restrictions { return( shift->_set_get_class( 'platform_restrictions',
{
  inbound_flows  => { type => "scalar" },
  outbound_flows => { type => "scalar" },
}, @_ ) ); }

sub restricted_features { return( shift->_set_get_array( 'restricted_features', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub status_details { return( shift->_set_get_object( 'status_details', 'Net::API::Stripe::Billing::Invoice', @_ ) ); }

sub supported_currencies { return( shift->_set_get_array( 'supported_currencies', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Treasury::FinancialAccount - The FinancialAccount object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Stripe Treasury provides users with a container for money called a FinancialAccount that is separate from their Payments balance. FinancialAccounts serve as the source and destination of Treasury’s money movement APIs.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 active_features array

The array of paths to active Features in the Features hash.

=head2 balance hash

The single multi-currency balance of the FinancialAccount. Positive values represent money that belongs to the user while negative values represent funds the user owes. Currently, FinancialAccounts can only carry balances in USD.

It has the following properties:

=over 4

=item C<cash> hash

Funds the user can spend right now.

=item C<inbound_pending> hash

Funds not spendable yet, but will become available at a later time.

=item C<outbound_pending> hash

Funds in the account, but not spendable because they are being held for pending outbound flows.

=back

=head2 country string

Two-letter country code (L<ISO 3166-1 alpha-2|https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)>.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 features hash

The features and their statuses for this FinancialAccount.

It has the following properties:

=over 4

=item C<card_issuing> hash

Contains a Feature encoding the FinancialAccount's ability to be used with the Issuing product, including attaching cards to and drawing funds from.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.

=item C<deposit_insurance> hash

Represents whether this FinancialAccount is eligible for deposit insurance. Various factors determine the insurance amount.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.

=item C<financial_addresses> hash

Contains Features that add FinancialAddresses to the FinancialAccount.

=over 8

=item C<aba> hash

Adds an ABA FinancialAddress to the FinancialAccount.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.


=back

=item C<inbound_transfers> hash

Contains settings related to adding funds to a FinancialAccount from another Account with the same owner.

=over 8

=item C<ach> hash

Enables ACH Debits via the InboundTransfers API.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.


=back

=item C<intra_stripe_flows> hash

Represents the ability for this FinancialAccount to send money to, or receive money from other FinancialAccounts (for example, via OutboundPayment).

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.

=item C<object> string

String representing the object's type. Objects of the same type share the same value.

=item C<outbound_payments> hash

Contains Features related to initiating money movement out of the FinancialAccount to someone else's bucket of money.

=over 8

=item C<ach> hash

Enables ACH transfers via the OutboundPayments API.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.

=item C<us_domestic_wire> hash

Enables US domestic wire tranfers via the OutboundPayments API.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.


=back

=item C<outbound_transfers> hash

Contains a Feature and settings related to moving money out of the FinancialAccount into another Account with the same owner.

=over 8

=item C<ach> hash

Enables ACH transfers via the OutboundTransfers API.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.

=item C<us_domestic_wire> hash

Enables US domestic wire tranfers via the OutboundTransfers API.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.


=back

=back

=head2 financial_addresses array of hash

The set of credentials that resolve to a FinancialAccount.

It has the following properties:

=over 4

=item C<aba> hash

Identifying information for the ABA address

When expanded, this is a L<Net::API::Stripe::Connect::ExternalAccount::Bank> object.

=item C<supported_networks> array

The list of networks that the address supports

=item C<type> string

The type of financial address

=back

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 metadata hash

Set of L<key-value pairs|https://stripe.com/docs/api/metadata> that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 pending_features array

The array of paths to pending Features in the Features hash.

=head2 platform_restrictions hash

The set of functionalities that the platform can restrict on the FinancialAccount.

It has the following properties:

=over 4

=item C<inbound_flows> string

Restricts all inbound money movement.

=item C<outbound_flows> string

Restricts all outbound money movement.

=back

=head2 restricted_features array

The array of paths to restricted Features in the Features hash.

=head2 status string

The enum specifying what state the account is in.

=head2 status_details object

Details related to the status of this FinancialAccount.

This is a L<Net::API::Stripe::Billing::Invoice> object.

=head2 supported_currencies array

The currencies the FinancialAccount can hold a balance in. Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase.

=head1 API SAMPLE

[
   {
      "active_features" : [
         "financial_addresses.aba",
         "outbound_payments.ach",
         "outbound_payments.us_domestic_wire"
      ],
      "balance" : {
         "cash" : {
            "usd" : "0"
         },
         "inbound_pending" : {
            "usd" : "0"
         },
         "outbound_pending" : {
            "usd" : "0"
         }
      },
      "country" : "US",
      "created" : "1662261085",
      "financial_addresses" : [
         {
            "aba" : {
               "account_holder_name" : "Jenny Rosen",
               "account_number_last4" : "7890",
               "bank_name" : "STRIPE TEST BANK",
               "routing_number" : "0000000001"
            },
            "supported_networks" : [
               "ach",
               "us_domestic_wire"
            ],
            "type" : "aba"
         }
      ],
      "id" : "fa_1Le9F32eZvKYlo2CjbQcDQUE",
      "livemode" : 1,
      "metadata" : null,
      "object" : "treasury.financial_account",
      "pending_features" : [],
      "restricted_features" : [],
      "status" : "open",
      "status_details" : {
         "closed" : null
      },
      "supported_currencies" : [
         "usd"
      ]
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/treasury/financial_accounts>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
