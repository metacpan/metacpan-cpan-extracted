##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Intent/NextAction.pm
## Version v0.101.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Intent::NextAction;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.101.0';
};

use strict;
use warnings;

sub alipay_handle_redirect { return( shift->_set_get_class( 'alipay_handle_redirect', {
    native_data => { type => "scalar" },
    native_url => { type => "scalar" },
    return_url => { type => "scalar" },
    url => { type => "scalar" },
}, @_ ) ); }

sub boleto_display_details { return( shift->_set_get_class( 'boleto_display_details',
{
  expires_at => { type => "datetime" },
  hosted_voucher_url => { type => "scalar" },
  number => { type => "scalar" },
  pdf => { type => "scalar" },
}, @_ ) ); }

sub card_await_notification { return( shift->_set_get_class( 'card_await_notification',
{
  charge_attempt_at          => { type => "datetime" },
  customer_approval_required => { type => "boolean" },
}, @_ ) ); }

sub display_bank_transfer_instructions { return( shift->_set_get_class( 'display_bank_transfer_instructions',
{
  amount_remaining => { type => "number" },
  currency => { type => "number" },
  financial_addresses => {
    definition => {
      iban => {
        definition => {
          account_holder_name => { type => "scalar" },
          bic => { type => "scalar" },
          country => { type => "scalar" },
          iban => { type => "scalar" },
        },
        type => "class",
      },
      sort_code => {
        definition => {
          account_holder_name => { type => "scalar" },
          account_number => { type => "scalar" },
          sort_code => { type => "scalar" },
        },
        type => "class",
      },
      spei => {
        definition => {
          bank_code => { type => "scalar" },
          bank_name => { type => "scalar" },
          clabe => { type => "scalar" },
        },
        type => "class",
      },
      supported_networks => { type => "array" },
      type => { type => "scalar" },
      zengin => {
        definition => {
          account_holder_name => { type => "scalar" },
          account_number      => { type => "scalar" },
          account_type        => { type => "scalar" },
          bank_code           => { type => "scalar" },
          bank_name           => { type => "scalar" },
          branch_code         => { type => "scalar" },
          branch_name         => { type => "scalar" },
        },
        type => "class",
      },
    },
    type => "class_array",
  },
  hosted_instructions_url => { type => "scalar" },
  reference => { type => "scalar" },
  type => { type => "scalar" },
}, @_ ) ); }

sub konbini_display_details { return( shift->_set_get_class( 'konbini_display_details',
{
  expires_at => { type => "datetime" },
  hosted_voucher_url => { type => "scalar" },
  stores => {
    definition => {
      familymart => {
                      definition => {
                        confirmation_number => { type => "scalar" },
                        payment_code => { type => "scalar" },
                      },
                      type => "class",
                    },
      lawson     => {
                      definition => {
                        confirmation_number => { type => "scalar" },
                        payment_code => { type => "scalar" },
                      },
                      type => "class",
                    },
      ministop   => {
                      definition => {
                        confirmation_number => { type => "scalar" },
                        payment_code => { type => "scalar" },
                      },
                      type => "class",
                    },
      seicomart  => {
                      definition => {
                        confirmation_number => { type => "scalar" },
                        payment_code => { type => "scalar" },
                      },
                      type => "class",
                    },
    },
    type => "class",
  },
}, @_ ) ); }

sub oxxo_display_details { return( shift->_set_get_class( 'oxxo_display_details', {
    expires_after => { type => "datetime" },
    hosted_voucher_url => { type => "scalar" },
    number => { type => "scalar" },
}, @_ ) ); }

# sub redirect_to_url { return( shift->_set_get_hash( 'redirect_to_url', @_ ) ); }

sub paynow_display_qr_code { return( shift->_set_get_class( 'paynow_display_qr_code',
{
  data => { type => "scalar" },
  image_url_png => { type => "scalar" },
  image_url_svg => { type => "scalar" },
}, @_ ) ); }

sub promptpay_display_qr_code { return( shift->_set_get_class( 'promptpay_display_qr_code',
{
  data => { type => "scalar" },
  hosted_instructions_url => { type => "scalar" },
  image_url_png => { type => "scalar" },
  image_url_svg => { type => "scalar" },
}, @_ ) ); }

sub redirect_to_url
{
    return( shift->_set_get_class( 'redirect_to_url', 
    {
    return_url => { type => 'uri' },
    url => { type => 'uri' },
    }, @_ ) );
}

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub use_stripe_sdk { return( shift->_set_get_hash( 'use_stripe_sdk', @_ ) ); }

sub verify_with_microdeposits { return( shift->_set_get_class( 'verify_with_microdeposits',
{
  arrival_date            => { type => "datetime" },
  hosted_verification_url => { type => "scalar" },
  microdeposit_type       => { type => "scalar" },
}, @_ ) ); }

sub wechat_pay_display_qr_code { return( shift->_set_get_class( 'wechat_pay_display_qr_code',
{
  data => { type => "scalar" },
  image_data_url => { type => "scalar" },
  image_url_png => { type => "scalar" },
  image_url_svg => { type => "scalar" },
}, @_ ) ); }

sub wechat_pay_redirect_to_android_app { return( shift->_set_get_class( 'wechat_pay_redirect_to_android_app',
{
  app_id     => { type => "scalar" },
  nonce_str  => { type => "scalar" },
  package    => { type => "scalar" },
  partner_id => { type => "scalar" },
  prepay_id  => { type => "scalar" },
  sign       => { type => "scalar" },
  timestamp  => { type => "scalar" },
}, @_ ) ); }

sub wechat_pay_redirect_to_ios_app { return( shift->_set_get_class( 'wechat_pay_redirect_to_ios_app',
{ native_url => { type => "scalar" } }, @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Intent::NextAction - A Stripe Payment Next Action Object

=head1 SYNOPSIS

    my $next = $stripe->payment_intent->next_action({
        redirect_to_url => 
        {
        return_url => 'https://example.com/pay/return',
        url => 'https://example.com/pay/auth',
        },
        type => 'redirect_to_url',
    });

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

If present, this property tells you what actions you need to take in order for your customer to fulfill a payment using the provided source.

It used to be NextSourceAction, but the naming changed in Stripe API as of 2019-02-11

This is instantiated by method B<next_action> in module L<Net::API::Stripe::Payment::Intent>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Payment::Intent::NextAction> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 boleto_display_details hash

Contains Boleto details necessary for the customer to complete the payment.

It has the following properties:

=over 4

=item C<expires_at> timestamp

The timestamp after which the boleto expires.

=item C<hosted_voucher_url> string

The URL to the hosted boleto voucher page, which allows customers to view the boleto voucher.

=item C<number> string

The boleto number.

=item C<pdf> string

The URL to the downloadable boleto voucher PDF.

=back

=head2 card_await_notification hash

Contains instructions for processing off session recurring payments with Indian issued cards.

It has the following properties:

=over 4

=item C<charge_attempt_at> timestamp

The time that payment will be attempted. If customer approval is required, they need to provide approval before this time.

=item C<customer_approval_required> boolean

For payments greater than INR 15000, the customer must provide explicit approval of the payment with their bank. For payments of lower amount, no customer action is required.

=back

=head2 display_bank_transfer_instructions hash

Contains the bank transfer details necessary for the customer to complete the payment.

It has the following properties:

=over 4

=item C<amount_remaining> integer

The remaining amount that needs to be transferred to complete the payment.

=item C<currency> currency

Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a L<supported currency|https://stripe.com/docs/currencies>.

=item C<financial_addresses> array

A list of financial addresses that can be used to fund the customer balance

=over 8

=item C<iban> hash

An IBAN-based FinancialAddress

=over 12

=item C<account_holder_name> string

The name of the person or business that owns the bank account

=item C<bic> string

The BIC/SWIFT code of the account.

=item C<country> string

Two-letter country code (L<ISO 3166-1 alpha-2|https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)>.

=item C<iban> string

The IBAN of the account.


=back

=item C<sort_code> hash

An account number and sort code-based FinancialAddress

=over 12

=item C<account_holder_name> string

The name of the person or business that owns the bank account

=item C<account_number> string

The account number

=item C<sort_code> string

The six-digit sort code


=back

=item C<spei> hash

A SPEI-based FinancialAddress

=over 12

=item C<bank_code> string

The three-digit bank code

=item C<bank_name> string

The short banking institution name

=item C<clabe> string

The CLABE number


=back

=item C<supported_networks> array

The payment networks supported by this FinancialAddress

=item C<type> string

The type of financial address

=item C<zengin> hash

A Zengin-based FinancialAddress

=over 12

=item C<account_holder_name> string

The account holder name

=item C<account_number> string

The account number

=item C<account_type> string

The bank account type. In Japan, this can only be C<futsu> or C<toza>.

=item C<bank_code> string

The bank code of the account

=item C<bank_name> string

The bank name of the account

=item C<branch_code> string

The branch code of the account

=item C<branch_name> string

The branch name of the account


=back


=back

=item C<hosted_instructions_url> string

A link to a hosted page that guides your customer through completing the transfer.

=item C<reference> string

A string identifying this payment. Instruct your customer to include this code in the reference or memo field of their bank transfer.

=item C<type> string

Type of bank transfer

=back

=head2 konbini_display_details hash

Contains Konbini details necessary for the customer to complete the payment.

It has the following properties:

=over 4

=item C<expires_at> timestamp

The timestamp at which the pending Konbini payment expires.

=item C<hosted_voucher_url> string

The URL for the Konbini payment instructions page, which allows customers to view and print a Konbini voucher.

=item C<stores> hash

Payment instruction details grouped by convenience store chain.

=over 8

=item C<familymart> hash

FamilyMart instruction details.

=over 12

=item C<confirmation_number> string

The confirmation number.

=item C<payment_code> string

The payment code.


=back

=item C<lawson> hash

Lawson instruction details.

=over 12

=item C<confirmation_number> string

The confirmation number.

=item C<payment_code> string

The payment code.


=back

=item C<ministop> hash

Ministop instruction details.

=over 12

=item C<confirmation_number> string

The confirmation number.

=item C<payment_code> string

The payment code.


=back

=item C<seicomart> hash

Seicomart instruction details.

=over 12

=item C<confirmation_number> string

The confirmation number.

=item C<payment_code> string

The payment code.


=back


=back

=back

=head2 paynow_display_qr_code hash

The field that contains PayNow QR code info

It has the following properties:

=over 4

=item C<data> string

The raw data string used to generate QR code, it should be used together with QR code library.

=item C<image_url_png> string

The image_url_png string used to render QR code

=item C<image_url_svg> string

The image_url_svg string used to render QR code

=back

=head2 promptpay_display_qr_code hash

The field that contains PromptPay QR code info

It has the following properties:

=over 4

=item C<data> string

The raw data string used to generate QR code, it should be used together with QR code library.

=item C<hosted_instructions_url> string

The URL to the hosted PromptPay instructions page, which allows customers to view the PromptPay QR code.

=item C<image_url_png> string

The imageI<url>png string used to render QR code, can be used as <img src="…" />

=item C<image_url_svg> string

The imageI<url>svg string used to render QR code, can be used as <img src="…" />

=back

=head2 redirect_to_url hash

Contains instructions for authenticating a payment by redirecting your customer to another page or application.

This is actually a dynamic class L<Net::API::Stripe::Payment::Intent::NextAction::RedirectToUrl> so the following property can be accessed as methods:

=over 4

=item I<return_url> string

If the customer does not exit their browser while authenticating, they will be redirected to this specified URL after completion.

=item I<url> string

The URL you must redirect your customer to in order to authenticate the payment.

=back

=head2 type string

Type of the next action to perform, one of redirect_to_url or use_stripe_sdk.

=head2 use_stripe_sdk hash

When confirming a PaymentIntent with Stripe.js, Stripe.js depends on the contents of this dictionary to invoke authentication flows. The shape of the contents is subject to change and is only intended to be used by Stripe.js.

=head2 verify_with_microdeposits hash

Contains details describing microdeposits verification flow.

It has the following properties:

=over 4

=item C<arrival_date> timestamp

The timestamp when the microdeposits are expected to land.

=item C<hosted_verification_url> string

The URL for the hosted verification page, which allows customers to verify their bank account.

=item C<microdeposit_type> string

The type of the microdeposit sent to the customer. Used to distinguish between different verification methods.

=back

=head2 wechat_pay_display_qr_code hash

The field that contains WeChat Pay QR code info

It has the following properties:

=over 4

=item C<data> string

The data being used to generate QR code

=item C<image_data_url> string

The base64 image data for a pre-generated QR code

=item C<image_url_png> string

The image_url_png string used to render QR code

=item C<image_url_svg> string

The image_url_svg string used to render QR code

=back

=head2 wechat_pay_redirect_to_android_app hash

Info required for android app to app redirect

It has the following properties:

=over 4

=item C<app_id> string

app_id is the APP ID registered on WeChat open platform

=item C<nonce_str> string

nonce_str is a random string

=item C<package> string

package is static value

=item C<partner_id> string

an unique merchant ID assigned by WeChat Pay

=item C<prepay_id> string

an unique trading ID assigned by WeChat Pay

=item C<sign> string

A signature

=item C<timestamp> string

Specifies the current time in epoch format

=back

=head2 wechat_pay_redirect_to_ios_app hash

Info required for iOS app to app redirect

It has the following properties:

=over 4

=item C<native_url> string

An universal link that redirect to WeChat Pay app

=back

=head1 API SAMPLE

    {
      "id": "pi_fake123456789",
      "object": "payment_intent",
      "amount": 1099,
      "amount_capturable": 0,
      "amount_received": 0,
      "application": null,
      "application_fee_amount": null,
      "canceled_at": null,
      "cancellation_reason": null,
      "capture_method": "automatic",
      "charges": {
        "object": "list",
        "data": [],
        "has_more": false,
        "url": "/v1/charges?payment_intent=pi_fake123456789"
      },
      "client_secret": "pi_fake123456789_secret_ksjfjfbsjbfsmbfmf",
      "confirmation_method": "automatic",
      "created": 1556596976,
      "currency": "jpy",
      "customer": null,
      "description": null,
      "invoice": null,
      "last_payment_error": null,
      "livemode": false,
      "metadata": {},
      "next_action": null,
      "on_behalf_of": null,
      "payment_method": null,
      "payment_method_options": {},
      "payment_method_types": [
        "card"
      ],
      "receipt_email": null,
      "review": null,
      "setup_future_usage": null,
      "shipping": null,
      "statement_descriptor": null,
      "statement_descriptor_suffix": null,
      "status": "requires_payment_method",
      "transfer_data": null,
      "transfer_group": null
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/payment_intents/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
