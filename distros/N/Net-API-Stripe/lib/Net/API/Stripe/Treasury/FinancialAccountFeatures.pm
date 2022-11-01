##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Treasury/FinancialAccountFeatures.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Treasury::FinancialAccountFeatures;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub card_issuing { return( shift->_set_get_object( 'card_issuing', 'Net::API::Stripe::Connect::Account::Capability', @_ ) ); }

sub deposit_insurance { return( shift->_set_get_object( 'deposit_insurance', 'Net::API::Stripe::Connect::Account::Capability', @_ ) ); }

sub financial_addresses { return( shift->_set_get_class( 'financial_addresses',
{
  aba => {
           package => "Net::API::Stripe::Connect::Account::Capability",
           type => "object",
         },
}, @_ ) ); }

sub inbound_transfers { return( shift->_set_get_class( 'inbound_transfers',
{
  ach => {
           package => "Net::API::Stripe::Connect::Account::Capability",
           type => "object",
         },
}, @_ ) ); }

sub intra_stripe_flows { return( shift->_set_get_object( 'intra_stripe_flows', 'Net::API::Stripe::Connect::Account::Capability', @_ ) ); }

sub outbound_payments { return( shift->_set_get_class( 'outbound_payments',
{
  ach => {
    package => "Net::API::Stripe::Connect::Account::Capability",
    type => "object",
  },
  us_domestic_wire => {
    package => "Net::API::Stripe::Connect::Account::Capability",
    type => "object",
  },
}, @_ ) ); }

sub outbound_transfers { return( shift->_set_get_class( 'outbound_transfers',
{
  ach => {
    package => "Net::API::Stripe::Connect::Account::Capability",
    type => "object",
  },
  us_domestic_wire => {
    package => "Net::API::Stripe::Connect::Account::Capability",
    type => "object",
  },
}, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Treasury::FinancialAccountFeatures - The FinancialAccount Feature object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Encodes whether a FinancialAccount has access to a particular Feature, with a C<status> enum and associated C<status_details>. Stripe or the platform can control Features via the requested field.

=head1 METHODS

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 card_issuing object

Contains a Feature encoding the FinancialAccount's ability to be used with the Issuing product, including attaching cards to and drawing funds from.

This is a L<Net::API::Stripe::Connect::Account::Capability> object.

=head2 deposit_insurance object

Represents whether this FinancialAccount is eligible for deposit insurance. Various factors determine the insurance amount.

This is a L<Net::API::Stripe::Connect::Account::Capability> object.

=head2 financial_addresses hash

Contains Features that add FinancialAddresses to the FinancialAccount.

It has the following properties:

=over 4

=item C<aba> hash

Adds an ABA FinancialAddress to the FinancialAccount.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.

=back

=head2 inbound_transfers hash

Contains settings related to adding funds to a FinancialAccount from another Account with the same owner.

It has the following properties:

=over 4

=item C<ach> hash

Enables ACH Debits via the InboundTransfers API.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.

=back

=head2 intra_stripe_flows object

Represents the ability for this FinancialAccount to send money to, or receive money from other FinancialAccounts (for example, via OutboundPayment).

This is a L<Net::API::Stripe::Connect::Account::Capability> object.

=head2 outbound_payments hash

Contains Features related to initiating money movement out of the FinancialAccount to someone else's bucket of money.

It has the following properties:

=over 4

=item C<ach> hash

Enables ACH transfers via the OutboundPayments API.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.

=item C<us_domestic_wire> hash

Enables US domestic wire tranfers via the OutboundPayments API.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.

=back

=head2 outbound_transfers hash

Contains a Feature and settings related to moving money out of the FinancialAccount into another Account with the same owner.

It has the following properties:

=over 4

=item C<ach> hash

Enables ACH transfers via the OutboundTransfers API.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.

=item C<us_domestic_wire> hash

Enables US domestic wire tranfers via the OutboundTransfers API.

When expanded, this is a L<Net::API::Stripe::Connect::Account::Capability> object.

=back

=head1 API SAMPLE

[
   {
      "card_issuing" : {
         "requested" : 1,
         "status" : "active",
         "status_details" : []
      },
      "deposit_insurance" : {
         "requested" : 1,
         "status" : "active",
         "status_details" : []
      },
      "financial_addresses" : {
         "aba" : {
            "requested" : 1,
            "status" : "active",
            "status_details" : []
         }
      },
      "inbound_transfers" : {
         "ach" : {
            "requested" : 1,
            "status" : "active",
            "status_details" : []
         }
      },
      "intra_stripe_flows" : {
         "requested" : 1,
         "status" : "active",
         "status_details" : []
      },
      "object" : "treasury.financial_account_features",
      "outbound_payments" : {
         "ach" : {
            "requested" : 1,
            "status" : "active",
            "status_details" : []
         },
         "us_domestic_wire" : {
            "requested" : 1,
            "status" : "active",
            "status_details" : []
         }
      },
      "outbound_transfers" : {
         "ach" : {
            "requested" : 1,
            "status" : "active",
            "status_details" : []
         },
         "us_domestic_wire" : {
            "requested" : 1,
            "status" : "active",
            "status_details" : []
         }
      }
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/treasury/financial_account_features>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
