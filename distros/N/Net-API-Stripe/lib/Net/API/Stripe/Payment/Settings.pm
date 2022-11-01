##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Settings.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/07/15
## Modified 2022/07/15
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Settings;
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

sub default_mandate { return( shift->_set_get_object_without_init( 'default_mandate', 'Net::API::Stripe::Mandate', @_ ) ); }

sub payment_method_options { return( shift->_set_get_object( 'payment_method_options', 'Net::API::Stripe::Payment::Method::Options', @_ ) ); }

sub payment_method_types { return( shift->_set_get_array( 'payment_method_types', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::Stripe::Payment::Settings - Stripe API

=head1 SYNOPSIS

    use Net::API::Stripe::Payment::Settings;
    my $this = Net::API::Stripe::Payment::Settings->new || die( Net::API::Stripe::Payment::Settings->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Configuration settings for the PaymentIntent that is generated when the invoice is finalized.

=head1 METHODS

=head2 payment_method_options

Payment-method-specific configuration to provide to the invoice’s PaymentIntent.

=over 4

=item * C<acss_debit> hash

If paying by acss_debit, this sub-hash contains details about the Canadian pre-authorized debit payment method options to pass to the invoice’s PaymentIntent.

=over 8

=item * C<mandate_options> hash

Additional fields for Mandate creation

=item * C<verification_method> enum

Bank account verification method.

Possible enum values

=over 12

=item * C<automatic>

Instant verification with fallback to microdeposits.

=item * Cinstant>

Instant verification.

=item * Cmicrodeposits>

Verification using microdeposits.

=back

=back

=item * C<bancontact> hash

If paying by bancontact, this sub-hash contains details about the Bancontact payment method options to pass to the invoice’s PaymentIntent.

=over 8

=item * C<preferred_language> enum

Preferred language of the Bancontact authorization page that the customer is redirected to.

Possible enum values

=over 12

=item * C<en>

English

=item * C<de>

German

=item * C<fr>

French

=item * C<nl>

Dutch

=back

=back

=item * C<card> hash

If paying by card, this sub-hash contains details about the Card payment method options to pass to the invoice’s PaymentIntent.

=over 8

=item * C<request_three_d_secure> enum advanced

We strongly recommend that you rely on our SCA Engine to automatically prompt your customers for authentication based on risk level and other requirements. However, if you wish to request 3D Secure based on logic from your own fraud engine, provide this option. Read our guide on manually requesting 3D Secure for more information on how this configuration interacts with Radar and our SCA Engine.

Possible enum values

=over 12

=item * C<automatic>

Triggers 3D Secure authentication only if it is required.

=item * C<any>

Requires 3D Secure authentication if it is available.

=back

=back

=item * C<customer_balance> hash

If paying by customer_balance, this sub-hash contains details about the Bank transfer payment method options to pass to the invoice’s PaymentIntent.

=over 8

=item * C<bank_transfer> hash

Configuration for the bank transfer funding type, if the funding_type is set to bank_transfer.

=over 12

=item * C<eu_bank_transfer> hash preview feature

Configuration for eu_bank_transfer funding type.

=over 16

=item * C<country> string

The desired country code of the bank account information. Permitted values include: DE, ES, FR, IE, or NL.

=back

=item * C<type> string

The bank transfer type that can be used for funding. Permitted values include: C<eu_bank_transfer>, C<gb_bank_transfer>, C<jp_bank_transfer>, or C<mx_bank_transfer>.

=back

=item * C<funding_type> string

The funding method type to be used when there are not enough funds in the customer balance. Permitted values include: bank_transfer.

=back

=item * C<konbini> hash

If paying by konbini, this sub-hash contains details about the Konbini payment method options to pass to the invoice’s PaymentIntent.

=item * C<us_bank_account> hash

If paying by us_bank_account, this sub-hash contains details about the ACH direct debit payment method options to pass to the invoice’s PaymentIntent.

=over 8

=item * C<financial_connections> hash preview feature

Additional fields for Financial Connections Session creation

=over 12

=item * C<permissions> array of enum values

The list of permissions to request. The payment_method permission must be included.

Possible enum values

=over 16

=item * C<payment_method>

Allows the creation of a payment method from the account.

=item * C<balances>

Allows accessing balance data from the account.

=item * C<transactions>

Allows accessing transactions data from the account.

=back

=back

=item * C<verification_method> enum

Bank account verification method.

Possible enum values

=over 12

=item * C<automatic>

Instant verification with fallback to microdeposits.

=item * C<instant>

Instant verification only.

=item * C<microdeposits>

Verification using microdeposits. Cannot be used with Stripe Checkout or Hosted Invoices.

=back

=back

=back

=head2 payment_method_types array of enum values

The list of payment method types (e.g. card) to provide to the invoice’s PaymentIntent. If not set, Stripe attempts to automatically determine the types to use by looking at the invoice’s default payment method, the subscription’s default payment method, the customer’s default payment method, and your invoice template settings.

Possible enum values

=over 4

=item * C<ach_credit_transfer> USD only

ACH bank transfer

The collection_method must be send_invoice.

=item * C<ach_debit> USD only

ACH

=item * C<acss_debit> USD and CAD

Canadian pre-authorized debit

=item * C<au_becs_debit> AUD only

BECS Direct Debit

=item * C<bacs_debit> GBP only

Bacs Direct Debit

=item * C<bancontact> EUR only

Bancontact

The collection_method must be send_invoice.

=item * C<boleto> BRL only

Boleto

=item * C<card>

Card

=item * C<customer_balance> EUR, GBP, and 3 other currencies

Bank transfer

The collection_method must be send_invoice.

=item * C<eps> EUR only

EPS

The collection_method must be send_invoice.

=item * C<fpx> MYR only

FPX

The collection_method must be send_invoice.

=item * C<giropay> EUR only

giropay

The collection_method must be send_invoice.

=item * C<grabpay> MYR and SGD

GrabPay

The collection_method must be send_invoice.

=item * C<ideal> EUR only

iDEAL

The collection_method must be send_invoice.

=item * C<konbini> JPY only

Konbini

The collection_method must be send_invoice.

=item * C<link> USD only

Link

=item * C<p24> EUR and PLN

Przelewy24

The collection_method must be send_invoice.

=item * C<paynow> SGD only

PayNow

The collection_method must be send_invoice.

=item * C<promptpay> THB only

PromptPay

The collection_method must be send_invoice.

=item * C<sepa_debit> EUR only

SEPA Direct Debit

=item * C<sofort> EUR only

SOFORT

The collection_method must be send_invoice.

=item * C<us_bank_account> USD only

ACH direct debit

=item * C<wechat_pay> USD, EUR, and 11 other currencies

WeChat Pay

The collection_method must be send_invoice.

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://stripe.com/docs/api/invoices/object>

L<https://stripe.com/docs/api/subscriptions/object>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
