##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Method/Details.pm
## Version v0.103.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/08/11
## Modified 2022/10/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Method::Options;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION @EXPORT_OK %EXPORT_TAGS );
    our @EXPORT_OK = qw(
        ach_credit_transfer ach_debit acss_debit affirm afterpay_clearpay alipay au_becs_debit
        bacs_debit bancontact blik boleto card card_present customer_balance eps fpx
        giropay grabpay ideal interac_present klarna konbini multibanco oxxo p24 sepa_debit
        sofort stripe_account us_bank_account wechat
    );
    our %EXPORT_TAGS = ( all => \@EXPORT_OK );
    our( $VERSION ) = 'v0.103.0';
};

use strict;
use warnings;

sub ach_credit_transfer { return( shift->_set_get_object( 'ach_credit_transfer', 'Net::API::Stripe::Payment::Source::ACHCreditTransfer', @_ ) ); }

sub ach_debit { return( shift->_set_get_object( 'ach_debit', 'Net::API::Stripe::Payment::Source::ACHDebit', @_ ) ); }

sub acss_debit { return( shift->_set_get_object( 'acss_debit', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub affirm { return( shift->_set_get_class( 'affirm',
{
    capture_method => { type => 'string' },
    setup_future_usage => { type => 'string' },
}, @_ ) ); }

sub afterpay_clearpay { return( shift->_set_get_class( 'afterpay_clearpay',
{
    capture_method => { type => 'string' },
    reference => { type => 'string' },
    setup_future_usage => { type => 'string' },
}, @_ ) ); }

sub alipay { return( shift->_set_get_class( 'alipay',
{
  fingerprint    => { type => "scalar" },
  setup_future_usage => { type => "scalar" },
  transaction_id => { type => "scalar" },
}, @_ ) ); }

sub au_becs_debit { return( shift->_set_get_class( 'au_becs_debit',
{
  bsb_number => { type => "scalar" },
  fingerprint => { type => "scalar" },
  last4 => { type => "scalar" },
  mandate => { type => "scalar" },
  setup_future_usage => { type => "scalar" },
}, @_ ) ); }

sub bacs_debit { return( shift->_set_get_class( 'bacs_debit',
{
  fingerprint       => { type => "scalar" },
  last4             => { type => "scalar" },
  mandate           => { type => "scalar" },
  network_status    => { type => "scalar" },
  reference         => { type => "scalar" },
  setup_future_usage => { type => "scalar" },
  sort_code         => { type => "scalar" },
  url               => { type => "uri" },
}, @_ ) ); }

sub bancontact { return( shift->_set_get_class( 'bancontact',
{
  bank_code => { type => "scalar" },
  bank_name => { type => "scalar" },
  bic => { type => "scalar" },
  generated_sepa_debit => {
    package => "Net::API::Stripe::Payment::Method",
    type => "scalar_or_object",
  },
  generated_sepa_debit_mandate => { package => "Net::API::Stripe::Mandate", type => "scalar_or_object" },
  iban_last4 => { type => "scalar" },
  preferred_language => { type => "scalar" },
  setup_future_usage => { type => "scalar" },
  verified_name => { type => "scalar" },
}, @_ ) ); }

sub blik { return( shift->_set_get_object( 'blik', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub boleto { return( shift->_set_get_class( 'boleto',
{
    expires_after_days => { type => 'integer' },
    setup_future_usage => { type => "scalar" },
}, @_ ) ); }

# sub card { return( shift->_set_get_object( 'card', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub card { return( shift->_set_get_object( 'card', 'Net::API::Stripe::Payment::Card', @_ ) ); }

sub card_present { return( shift->_set_get_object( 'card_present', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub customer_balance { return( shift->_set_get_class( 'customer_balance',
{
  bank_transfer      => {
                          definition => {
                            eu_bank_transfer => { package => "Net::API::Stripe::Address", type => "object" },
                            requested_address_types => { type => "array" },
                            type => { type => "scalar" },
                          },
                          type => "class",
                        },
  funding_type       => { type => "scalar" },
  setup_future_usage => { type => "scalar" },
}, @_ ) ); }

sub eps { return( shift->_set_get_object( 'eps', 'Net::API::Stripe::Connect::Account::Verification', @_ ) ); }

sub fpx { return( shift->_set_get_object( 'fpx', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub giropay { return( shift->_set_get_object( 'giropay', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub grabpay { return( shift->_set_get_object( 'grabpay', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub ideal { return( shift->_set_get_object( 'ideal', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub interac_present { return( shift->_set_get_object( 'interac_present', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub klarna { return( shift->_set_get_object( 'klarna', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub konbini { return( shift->_set_get_class( 'konbini',
{
  confirmation_number => { type => "scalar" },
  expires_after_days  => { type => "number" },
  expires_at          => { type => "datetime" },
  product_description => { type => "scalar" },
  setup_future_usage  => { type => "scalar" },
}, @_ ) ); }

sub multibanco { return( shift->_set_get_class( 'multibanco',
{
    entity => { type => "scalar" },
    reference => { type => "scalar" },
}, @_ ) ); }

sub oxxo { return( shift->_set_get_object( 'oxxo', 'Net::API::Stripe::Issuing::Card', @_ ) ); }

sub p24 { return( shift->_set_get_object( 'p24', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub sepa_debit { return( shift->_set_get_object( 'sepa_debit', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub sofort { return( shift->_set_get_class( 'sofort',
{
  preferred_language => { type => "scalar" },
  setup_future_usage => { type => "scalar" },
}, @_ ) ); }

sub stripe_account { return( shift->_set_get_hash_as_object( 'stripe_account', 'Net::API::Stripe::Payment::Method::Options::StripeAccount', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub us_bank_account { return( shift->_set_get_class( 'us_bank_account',
{
  financial_connections => {
                             definition => { permissions => { type => "array" } },
                             type => "class",
                           },
  setup_future_usage    => { type => "scalar" },
  verification_method   => { type => "scalar" },
}, @_ ) ); }

sub wechat { return( shift->_set_get_hash_as_object( 'wechat', 'Net::API::Stripe::Payment::Method::Options::WeChat', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Method::Options - A Stripe Payment Method Details

=head1 SYNOPSIS

    my $details = $stripe->charge->payment_method_details({
        card => $card_object,
        type => 'card',
    });

=head1 VERSION

    v0.103.0

=head1 DESCRIPTION

Transaction-specific details of the payment method used in the payment.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Payment::Method::Options> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 ach_credit_transfer hash

If this is a ach_credit_transfer payment, this hash contains a snapshot of the transaction specific details of the ach_credit_transfer payment method.

This is a L<Net::API::Stripe::Payment::Source::ACHCreditTransfer> object

=head2 ach_debit hash

If this is a ach_debit payment, this hash contains a snapshot of the transaction specific details of the ach_debit payment method.

This is a L<Net::API::Stripe::Payment::Source::ACHDebit> object.

=head2 acss_debit object

If the PaymentIntent's paymentI<method>types includes C<acss_debit>, this hash contains the configurations that will be applied to each payment attempt of that type.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object.

=head2 affirm

If this is an affirm PaymentMethod, this hash contains details about the Affirm payment method.

It has the following properties:

=over 4

=item * C<capture_method>

Controls when the funds will be captured from the customer’s account.

Possible enum values

=over 8

=item * C<manual>

Use manual if you intend to place the funds on hold and want to override the top-level capture_method value for this payment method.

=back

=item * C<setup_future_usage>

Indicates that you intend to make future payments with this PaymentIntent’s payment method.

Providing this parameter will attach the payment method to the PaymentIntent’s Customer, if present, after the PaymentIntent is confirmed and any required actions from the user are complete. If no Customer was provided, the payment method can still be attached to a Customer after the transaction completes.

When processing card payments, Stripe also uses setup_future_usage to dynamically optimize your payment flow and comply with regional legislation and network rules, such as SCA.

Possible enum values

=over 8

=item * C<none>

Use none if you do not intend to reuse this payment method and want to override the top-level setup_future_usage value for this payment method.

=back

=back

=head2 afterpay_clearpay

If this is an AfterpayClearpay PaymentMethod, this hash contains details about the AfterpayClearpay payment method.

=head2 alipay hash

If this is a C<alipay> payment, this hash contains a snapshot of the transaction specific details of the C<alipay> payment method.

It has the following properties that can be access as methods:

=over 4

=item * C<fingerprint> string

Uniquely identifies this particular Alipay account. You can use this attribute to check whether two Alipay accounts are the same.

=item * C<transaction_id> string

Transaction ID of this particular Alipay transaction.

=back

=head2 au_becs_debit hash

If this is a C<au_becs_debit> payment, this hash contains a snapshot of the transaction specific details of the C<au_becs_debit> payment method.

It has the following properties that can be accessed as methods:

=over 4

=item * C<bsb_number> string

Bank-State-Branch number of the bank account.

=item * C<fingerprint> string

Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.

=item * C<last4> string

Last four digits of the bank account number.

=item * C<mandate> string

ID of the mandate used to make this payment.

=back

=head2 bacs_debit hash

If this is a C<bacs_debit> payment, this hash contains a snapshot of the transaction specific details of the C<bacs_debit> payment method.

It has the following properties:

=over 4

=item * C<fingerprint> string

Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.

=item * C<last4> string

Last four digits of the bank account number.

=item * C<mandate> string

ID of the mandate used to make this payment.

=item * C<sort_code> string

Sort code of the bank account. (e.g., C<10-20-30>)

=back

=head2 bancontact hash

If this is a C<bancontact> payment, this hash contains a snapshot of the transaction specific details of the C<bancontact> payment method.

It has the following properties:

=over 4

=item * C<bank_code> string

Bank code of bank associated with the bank account.

=item * C<bank_name> string

Name of the bank associated with the bank account.

=item * C<bic> string

Bank Identifier Code of the bank associated with the bank account.

=item * C<generated_sepa_debit> string expandable

The ID of the SEPA Direct Debit PaymentMethod which was generated by this Charge.

When expanded this is an L<Net::API::Stripe::Payment::Method> object.

=item * C<generated_sepa_debit_mandate> string expandable

The mandate for the SEPA Direct Debit PaymentMethod which was generated by this Charge.

When expanded this is an L<Net::API::Stripe::Mandate> object.

=item * C<iban_last4> string

Last four characters of the IBAN.

=item * C<preferred_language> string

Preferred language of the Bancontact authorization page that the customer is redirected to.
Can be one of C<en>, C<de>, C<fr>, or C<nl>

=item * C<verified_name> string

Owner's verified full name. Values are verified or provided by Bancontact directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=back

=head2 blik object

If the SetupIntent's paymentI<method>types includes C<blik>, this hash contains the configurations that will be applied to each setup attempt of that type.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object.

=head2 boleto hash

If this is a boleto PaymentMethod, this hash contains details about the Boleto payment method.

Possible properties are:

=over 4

=item * C<fingerprint> string preview feature

=item * C<tax_id> string

Uniquely identifies the customer tax id (CNPJ or CPF)

=back

=head2 card hash

If this is a card payment, this hash contains a snapshot of the transaction specific details of the card payment method.

This is a L<Net::API::Stripe::Payment::Card> object.

=head2 card_present object

This hash contains the snapshot of the C<card_present> transaction-specific details which generated this C<card> payment method.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object.

=head2 customer_balance hash

If the PaymentIntent's paymentI<method>types includes C<customer_balance>, this hash contains the configurations that will be applied to each payment attempt of that type.

It has the following properties:

=over 4

=item C<bank_transfer> hash

Configuration for the bank transfer funding type, if the C<funding_type> is set to C<bank_transfer>.

=over 8

=item C<eu_bank_transfer> hash

Configuration for eu_bank_transfer

When expanded, this is a L<Net::API::Stripe::Address> object.

=item C<requested_address_types> array

List of address types that should be returned in the financial_addresses response. If not specified, all valid types will be returned.

Permitted values include: C<sort_code>, C<zengin>, C<iban>, or C<spei>.

=item C<type> string

The bank transfer type that this PaymentIntent is allowed to use for funding Permitted values include: C<eu_bank_transfer>, C<gb_bank_transfer>, C<jp_bank_transfer>, or C<mx_bank_transfer>.


=back

=item C<funding_type> string

The funding method type to be used when there are not enough funds in the customer balance. Permitted values include: C<bank_transfer>.

=item C<setup_future_usage> string

Indicates that you intend to make future payments with this PaymentIntent's payment method.

Providing this parameter will L<attach the payment method|https://stripe.com/docs/payments/save-during-payment> to the PaymentIntent's Customer, if present, after the PaymentIntent is confirmed and any required actions from the user are complete. If no Customer was provided, the payment method can still be L<attached|https://stripe.com/docs/api/payment_methods/attach> to a Customer after the transaction completes.

When processing card payments, Stripe also uses C<setup_future_usage> to dynamically optimize your payment flow and comply with regional legislation and network rules, such as L<SCA|https://stripe.com/docs/strong-customer-authentication>.

=back

=head2 eps object

If this is a C<eps> payment, this hash contains a snapshot of the transaction specific details of the C<eps> payment method.

This is a L<Net::API::Stripe::Connect::Account::Verification> object.

The properties used are:

=over 4

=item * C<bank> bank

The customer’s bank. Should be one of arzte_und_apotheker_bank, austrian_anadi_bank_ag, bank_austria, bankhaus_carl_spangler, bankhaus_schelhammer_und_schattera_ag, bawag_psk_ag, bks_bank_ag, brull_kallmus_bank_ag, btv_vier_lander_bank, capital_bank_grawe_gruppe_ag, dolomitenbank, easybank_ag, erste_bank_und_sparkassen, hypo_alpeadriabank_international_ag, hypo_noe_lb_fur_niederosterreich_u_wien, hypo_oberosterreich_salzburg_steiermark, hypo_tirol_bank_ag, hypo_vorarlberg_bank_ag, hypo_bank_burgenland_aktiengesellschaft, marchfelder_bank, oberbank_ag, raiffeisen_bankengruppe_osterreich, schoellerbank_ag, sparda_bank_wien, volksbank_gruppe, volkskreditbank_ag, or vr_bank_braunau.

=item * C<verified_name> string

Owner’s verified full name. Values are verified or provided by EPS directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=back

=head2 fpx object

If the PaymentIntent's paymentI<method>types includes C<fpx>, this hash contains the configurations that will be applied to each payment attempt of that type.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object.

=head2 giropay object

If the PaymentIntent's paymentI<method>types includes C<giropay>, this hash contains the configurations that will be applied to each payment attempt of that type.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object.

=head2 grabpay object

If the PaymentIntent's paymentI<method>types includes C<grabpay>, this hash contains the configurations that will be applied to each payment attempt of that type.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object.

=head2 ideal object

If the PaymentIntent's paymentI<method>types includes C<ideal>, this hash contains the configurations that will be applied to each payment attempt of that type.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object.

=head2 interac_present object

If this is a C<interac_present> payment, this hash contains a snapshot of the transaction specific details of the C<interac_present> payment method.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object.

=head2 klarna object

If the PaymentIntent's paymentI<method>types includes C<klarna>, this hash contains the configurations that will be applied to each payment attempt of that type.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object.

=head2 konbini hash

If the PaymentIntent's paymentI<method>types includes C<konbini>, this hash contains the configurations that will be applied to each payment attempt of that type.

It has the following properties:

=over 4

=item C<confirmation_number> string

An optional 10 to 11 digit numeric-only string determining the confirmation code at applicable convenience stores.

=item C<expires_after_days> integer

The number of calendar days (between 1 and 60) after which Konbini payment instructions will expire. For example, if a PaymentIntent is confirmed with Konbini and C<expires_after_days> set to 2 on Monday JST, the instructions will expire on Wednesday 23:59:59 JST.

=item C<expires_at> timestamp

The timestamp at which the Konbini payment instructions will expire. Only one of C<expires_after_days> or C<expires_at> may be set.

=item C<product_description> string

A product descriptor of up to 22 characters, which will appear to customers at the convenience store.

=item C<setup_future_usage> string

Indicates that you intend to make future payments with this PaymentIntent's payment method.

Providing this parameter will L<attach the payment method|https://stripe.com/docs/payments/save-during-payment> to the PaymentIntent's Customer, if present, after the PaymentIntent is confirmed and any required actions from the user are complete. If no Customer was provided, the payment method can still be L<attached|https://stripe.com/docs/api/payment_methods/attach> to a Customer after the transaction completes.

When processing card payments, Stripe also uses C<setup_future_usage> to dynamically optimize your payment flow and comply with regional legislation and network rules, such as L<SCA|https://stripe.com/docs/strong-customer-authentication>.

=back

=head2 link hash

If this is an Link PaymentMethod, this hash contains details about the Link payment method.

=head2 multibanco hash

If this is a C<multibanco> payment, this hash contains a snapshot of the transaction specific details of the C<multibanco> payment method.

This is a L<Net::API::Stripe::Payment::Method::Options::MultiBanco> object.

It has the following properties:

=over 4

=item * C<entity> string

Entity number associated with this Multibanco payment.

=item * C<reference> string

Reference number associated with this Multibanco payment.

=back

=head2 oxxo object

If this is a C<oxxo> payment, this hash contains a snapshot of the transaction specific details of the C<oxxo> payment method.

This is a L<Net::API::Stripe::Billing::CreditNote> object.

=head2 p24 object

If the PaymentIntent's paymentI<method>types includes C<p24>, this hash contains the configurations that will be applied to each payment attempt of that type.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object.

=head2 paynow hash

If this is a paynow PaymentMethod, this hash contains details about the PayNow payment method.

=head2 promptpay hash

If this is a promptpay PaymentMethod, this hash contains details about the PromptPay payment method.

=head2 sepa_debit hash

If this is a sepa_debit payment, this hash contains a snapshot of the transaction specific details of the sepa_debit payment method.

=over 4

=item * C<bank_code> string

Bank code of bank associated with the bank account.

=item * C<branch_code> string

Branch code of bank associated with the bank account.

=item * C<country> string

Two-letter ISO code representing the country the bank account is located in.

=item * C<fingerprint> string

Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.

=item * C<generated_from> hash

Information about the object that generated this PaymentMethod.

=over 8

=item * C<charge> string

This is expandable to a L<Net::API::Stripe::Charge> object.

The ID of the Charge that generated this PaymentMethod, if any.

=item * C<setup_attempt> string

This is expandable to a L<Net::API::Stripe::SetupAttempt> object.

The ID of the SetupAttempt that generated this PaymentMethod, if any.

=back

=item * C<last4> string

Last four characters of the IBAN.

=item * C<mandate> string

ID of the mandate used to make this payment.

=back

=head2 sofort hash

If the PaymentIntent's paymentI<method>types includes C<sofort>, this hash contains the configurations that will be applied to each payment attempt of that type.

It has the following properties:

=over 4

=item C<preferred_language> string

Preferred language of the SOFORT authorization page that the customer is redirected to.

=item C<setup_future_usage> string

Indicates that you intend to make future payments with this PaymentIntent's payment method.

Providing this parameter will L<attach the payment method|https://stripe.com/docs/payments/save-during-payment> to the PaymentIntent's Customer, if present, after the PaymentIntent is confirmed and any required actions from the user are complete. If no Customer was provided, the payment method can still be L<attached|https://stripe.com/docs/api/payment_methods/attach> to a Customer after the transaction completes.

When processing card payments, Stripe also uses C<setup_future_usage> to dynamically optimize your payment flow and comply with regional legislation and network rules, such as L<SCA|https://stripe.com/docs/strong-customer-authentication>.

=back

=head2 stripe_account hash

If this is a stripe_account payment, this hash contains a snapshot of the transaction specific details of the stripe_account payment method.

This is a L<Net::API::Stripe::Payment::Method::Options::StripeAccount> object.

=head2 type string

The type of transaction-specific details of the payment method used in the payment, one of ach_credit_transfer, ach_debit, alipay, bancontact, card, card_present, eps, giropay, ideal, klarna, multibanco, p24, sepa_debit, sofort, stripe_account, or wechat. An additional hash is included on payment_method_details with a name matching this value. It contains information specific to the payment method.

=head2 us_bank_account hash

If the PaymentIntent's paymentI<method>types includes C<us_bank_account>, this hash contains the configurations that will be applied to each payment attempt of that type.

It has the following properties:

=over 4

=item C<financial_connections> hash

Additional fields for Financial Connections Session creation

=over 8

=item C<permissions> array

The list of permissions to request. The C<payment_method> permission must be included.


=back

=item C<setup_future_usage> string

Indicates that you intend to make future payments with this PaymentIntent's payment method.

Providing this parameter will L<attach the payment method|https://stripe.com/docs/payments/save-during-payment> to the PaymentIntent's Customer, if present, after the PaymentIntent is confirmed and any required actions from the user are complete. If no Customer was provided, the payment method can still be L<attached|https://stripe.com/docs/api/payment_methods/attach> to a Customer after the transaction completes.

When processing card payments, Stripe also uses C<setup_future_usage> to dynamically optimize your payment flow and comply with regional legislation and network rules, such as L<SCA|https://stripe.com/docs/strong-customer-authentication>.

=item C<verification_method> string

Bank account verification method.

=back

=head2 wechat hash

If this is a wechat payment, this hash contains a snapshot of the transaction specific details of the wechat payment method.

This is a L<Net::API::Stripe::Payment::Method::Options::WeChat> object.

=head2 wechat_pay hash

If this is an wechat_pay PaymentMethod, this hash contains details about the wechat_pay payment method.

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2019-12-24

Stripe added the property B<sepa_debit>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/charges/object#charge_object-payment_method_details>

L<https://stripe.com/docs/api/payment_methods/object>, L<https://stripe.com/docs/api/charges/object#charge_object-payment_method_details>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
