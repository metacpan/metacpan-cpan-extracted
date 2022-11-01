##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Checkout/Session.pm
## Version v0.102.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/checkout/sessions
package Net::API::Stripe::Checkout::Session;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.102.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub after_expiration { return( shift->_set_get_class( 'after_expiration',
{
    recovery => 
    {
        type => 'class',
        definition =>
        {
            allow_promotion_codes => { type => 'boolean' },
            enabled => { type => 'boolean' },
            expires_at => { type => 'datetime' },
            url => { type => 'uri' },
        }
    }
}, @_ ) ); }

sub allow_promotion_codes { return( shift->_set_get_boolean( 'allow_promotion_codes', @_ ) ); }

sub amount_subtotal { return( shift->_set_get_number( 'amount_subtotal', @_ ) ); }

sub amount_total { return( shift->_set_get_number( 'amount_total', @_ ) ); }

sub automatic_tax { return( shift->_set_get_class( 'automatic_tax',
{
    enabled => { type => 'boolean' },
    status => { type => 'scalar' },
}, @_ ) ); }

sub billing_address_collection { return( shift->_set_get_scalar( 'billing_address_collection', @_ ) ); }

sub cancel_url { return( shift->_set_get_uri( 'cancel_url', @_ ) ); }

sub client_reference_id { return( shift->_set_get_scalar( 'client_reference_id', @_ ) ); }

sub consent { return( shift->_set_get_class( 'consent',
{
    promotions => { type => 'scalar' },
}, @_ ) ); }

sub consent_collection { return( shift->_set_get_class( 'consent',
{
    promotions => { type => 'scalar' },
}, @_ ) ); }

sub currency { return( shift->_set_get_number( 'currency', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub customer_creation { return( shift->_set_get_scalar( 'customer_creation', @_ ) ); }

sub customer_details { return( shift->_set_get_object( 'customer_details', 'Net::API::Stripe::Customer', @_ ) ); }

sub customer_email { return( shift->_set_get_scalar( 'customer_email', @_ ) ); }

sub display_items { return( shift->_set_get_object_array( 'display_items', 'Net::API::Stripe::Checkout::Item', @_ ) ); }

sub expires_at { return( shift->_set_get_datetime( 'expires_at', @_ ) ); }

sub interval { return( shift->_set_get_scalar( 'interval', @_ ) ); }

sub interval_count { return( shift->_set_get_scalar( 'interval_count', @_ ) ); }

sub line_items { return( shift->_set_get_object( 'line_items', 'Net::API::Stripe::List', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub locale { return( shift->_set_get_scalar( 'locale', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

# payment, setup, or subscription

sub mode { return( shift->_set_get_scalar( 'mode', @_ ) ); }

sub payment_intent { return( shift->_set_get_scalar_or_object( 'payment_intent', 'Net::API::Stripe::Payment::Intent', @_ ) ); }

sub payment_intent_data { return( shift->_set_get_object( 'payment_intent_data', 'Net::API::Stripe::Payment::Intent', @_ ) ); }

sub payment_link { return( shift->_set_get_scalar_or_object( 'payment_link', 'Net::API::Stripe::Payment::Link', @_ ) ); }

sub payment_method_collection { return( shift->_set_get_scalar( 'payment_method_collection', @_ ) ); }

sub payment_method_options { return( shift->_set_get_object( 'payment_method_options', 'Net::API::Stripe::Payment::Method::Options', @_ ) ); }

sub payment_method_types { return( shift->_set_get_array( 'payment_method_types', @_ ) ); }

sub payment_status { return( shift->_set_get_scalar( 'payment_status', @_ ) ); }

sub phone_number_collection { return( shift->_set_get_class( 'phone_number_collection',
{
    enabled => { type => 'boolean' },
}, @_ ) ); }

sub recovered_from { return( shift->_set_get_scalar( 'recovered_from', @_ ) ); }

sub setup_intent { return( shift->_set_get_scalar_or_object( 'setup_intent', 'Net::API::Stripe::Payment::Intent::Setup', @_ ) ); }

sub setup_intent_data { return( shift->_set_get_object( 'setup_intent_data', 'Net::API::Stripe::Payment::Intent::Setup', @_ ) ); }

sub shipping { return( shift->_set_get_class( 'shipping',
{
  address => { package => "Net::API::Stripe::Address", type => "object" },
  name => { type => "scalar" },
}, @_ ) ); }

sub shipping_address_collection { return( shift->_set_get_class( 'shipping_address_collection',
{ allowed_countries => { type => "array" } }, @_ ) ); }

sub shipping_cost { return( shift->_set_get_object( 'shipping_cost', 'Net::API::Stripe::Checkout::Session', @_ ) ); }

sub shipping_details { return( shift->_set_get_object( 'shipping_details', 'Net::API::Stripe::Billing::Details', @_ ) ); }

sub shipping_options { return( shift->_set_get_class_array( 'shipping_options',
{
    shipping_amount => { type => 'integer' },
    shipping_rate => { type => 'object', class => 'Net::API::Stripe::Shipping::Rate' },
}, @_ ) ); }

sub shipping_rate { return( shift->_set_get_scalar_or_object( 'shipping_rate', 'Net::API::Stripe::Shipping::Rate', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub submit_type { return( shift->_set_get_scalar( 'submit_type', @_ ) ); }

sub subscription { return( shift->_set_get_scalar_or_object( 'subscription', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub subscription_data { return( shift->_set_get_object( 'subscription_data', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub success_url { return( shift->_set_get_uri( 'success_url', @_ ) ); }

sub tax_id_collection { return( shift->_set_get_class( 'tax_id_collection',
{
    enabled => { type => 'boolean' },
}, @_ ) ); }

sub total_details { return( shift->_set_get_class( 'total_details',
{
  amount_discount => { type => "number" },
  amount_shipping => { type => "integer" },
  amount_tax      => { type => "number" },
  breakdown       => {
                       definition => {
                         discounts => {
                           definition => { amount => { type => "number" }, discount => { type => "hash" } },
                           type => "class_array",
                         },
                         taxes => {
                           definition => {
                             amount => { type => "number" },
                             rate   => { class => "Net::API::Stripe::Tax::Rate", type => "object" },
                           },
                           type => "class_array",
                         },
                       },
                       type => "class",
                     },
}, @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Checkout::Session - A Stripe Checkout Session Object

=head1 SYNOPSIS

    my $session = $stripe->session({
        # This easy to implement with Net::API::REST
        cancel_url => 'https://api.example.com/v1/stripe/cancel',
        success_url => 'https://api.example.com/v1/stripe/success',
        client_reference_id => '1F7F749C-D9C9-46EB-B692-986628BD7302',
        customer => $customer_object,
        customer_email => 'john.doe@example.com',
        # Japanese please
        locale => 'ja',
        mode => 'subscription',
        payment_intent => $payment_intent_object,
        submit_type => 'pay',
        subscription => $subscription_object,
    });

=head1 VERSION

    v0.102.0

=head1 DESCRIPTION

A Checkout Session represents your customer's session as they pay for one-time purchases or subscriptions through Checkout (L<https://stripe.com/docs/payments/checkout>). Stripe recommends creating a new Session each time your customer attempts to pay.

Once payment is successful, the Checkout Session will contain a reference to the Customer (L<Net::API::Stripe::Customer> / L<https://stripe.com/docs/api/customers>), and either the successful PaymentIntent (L<Net::API::Stripe::Payment::Intent> / L<https://stripe.com/docs/api/payment_intents>) or an active Subscription (L<Net::API::Stripe::Billing::Subscription> / L<https://stripe.com/docs/api/subscriptions>).

You can create a Checkout Session on your server and pass its ID to the client to begin Checkout.

=head1 CONSTRUCTOR

=head2 new

Creates a new L<Net::API::Stripe::Checkout::Session> object.

=head1 METHODS

=head2 id string

Unique identifier for the object. Used to pass to redirectToCheckout in Stripe.js.

=head2 object string, value is "checkout.session"

String representing the object’s type. Objects of the same type share the same value.

=head2 after_expiration hash

When set, provides configuration for actions to take if this Checkout Session expires.

=over 4

=item recovery

=over 8

=item allow_promotion_codes boolean

Enables user redeemable promotion codes on the recovered Checkout Sessions. Defaults to false

=item enabled boolean

If true, a recovery url will be generated to recover this Checkout Session if it expires before a transaction is completed. It will be attached to the Checkout Session object upon expiration.

=item expires_at timestamp

The timestamp at which the recovery URL will expire.

=item url string

URL that creates a new Checkout Session when clicked that is a copy of this expired Checkout Session

=back

=back

=head2 allow_promotion_codes boolean

Enables user redeemable promotion codes.

=head2 amount_subtotal integer

Total of all items before discounts or taxes are applied.

=head2 amount_total integer

Total of all items after discounts and taxes are applied.

=head2 automatic_tax hash

Details on the state of automatic tax for the session, including the status of the latest tax calculation.

=over 4

=item enabled boolean

Indicates whether automatic tax is enabled for the session

=item status enum

The status of the most recent automated tax calculation for this session.

Possible enum values

=over 4

=item requires_location_inputs

The location details entered by the customer aren’t valid or don’t provide enough location information to accurately determine tax rates.

=item complete

Stripe successfully calculated tax automatically for this session.

=item failed

The Stripe Tax service failed.

=back

=back

=head2 billing_address_collection string

The value (auto or required) for whether Checkout collected the customer’s billing address.

=head2 cancel_url string

The URL the customer will be directed to if they decide to cancel payment and return to your website.

This is a L<URI> object.

=head2 client_reference_id string

A unique string to reference the Checkout Session. This can be a customer ID, a cart ID, or similar, and can be used to reconcile the session with your internal systems.

=head2 consent hash

Results of consent_collection for this session.

=over 4

=item promotions string

If C<opt_in>, the customer consents to receiving promotional communications from the merchant about this Checkout Session.

=back

=head2 consent_collection  hash

When set, provides configuration for the Checkout Session to gather active consent from customers.

=over 4

=item promotions string

If set to C<auto>, enables the collection of customer consent for promotional communications. The Checkout Session will determine whether to display an option to opt into promotional communication from the merchant depending on the customer’s locale. Only available to US merchants.

=back

=head2 currency currency

Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a L<supported currency|https://stripe.com/docs/currencies>.

=head2 customer string (expandable)

The ID of the customer for this session. For Checkout Sessions in payment or subscription mode, Checkout will create a new customer object based on information provided during the session unless an existing customer was provided when the session was created.

When expanded, this is a L<Net::API::Stripe::Customer> object.

=head2 customer_creation enum

Configure whether a Checkout Session creates a Customer when the Checkout Session completes.

=over 4

=item if_required

The Checkout Session will only create a Customer if it is required for Session confirmation. Currently, only subscription mode Sessions require a Customer.

=item always

The Checkout Session will always create a Customer when a Session confirmation is attempted.

=back

=head2 customer_details object

The customer details including the customer's tax exempt status and the customer's tax IDs. Only the customer's email is present on Sessions in C<setup> mode.

This is a L<Net::API::Stripe::Customer> object.

=head2 customer_email string

If provided, this value will be used when the Customer object is created. If not provided, customers will be asked to enter their email address. Use this parameter to prefill customer data if you already have an email on file. To access information about the customer once a session is complete, use the customer field.

=head2 display_items array of hashes

The line items, plans, or SKUs purchased by the customer.

This is an array of L<Net::API::Stripe::Checkout::Item> objects.

=head2 expires_at timestamp

The timestamp at which the Checkout Session will expire.

=head2 interval string

One of I<day>, I<week>, I<month> or I<year>. The frequency with which a subscription should be billed.

=head2 interval_count positive integer

The number of intervals (specified in the I<interval> property) between subscription billings. For example, I<interval=month> and I<interval_count=3> bills every 3 months.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 locale string

The IETF language tag of the locale Checkout is displayed in. If blank or auto, the browser’s locale is used.

=head2 metadata hash

Set of L<key-value pairs|https://stripe.com/docs/api/metadata> that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 mode string

The mode of the Checkout Session, one of payment, setup, or subscription.

=head2 payment_intent string (expandable)

The ID of the PaymentIntent for Checkout Sessions in payment mode. If it is expanded, it contains a L<Net::API::Stripe::Payment::Intent> object.

=head2 payment_intent_data object

A subset of parameters to be passed to PaymentIntent creation for Checkout Sessions in payment mode.

This is a L<Net::API::Stripe::Payment::Intent> object and used to create a checkout session.

=head2 payment_link string expandable

The ID of the Payment Link that created this Session.

When expanded, it contains a L<Net::API::Stripe::Payment::Link> object.

=head2 payment_method_collection string

Configure whether a Checkout Session should collect a payment method.

=head2 payment_method_options hash

Payment-method-specific configuration for the PaymentIntent or SetupIntent of this CheckoutSession.

=over 4

=item acss_debit hash

If the Checkout Session’s payment_method_types includes acss_debit, this hash contains the configurations that will be applied to each payment attempt of that type.

=over 8

=item currency enum

Currency supported by the bank account. Returned when the Session is in setup mode.

=over 12

=item cad

Canadian dollars

=item usd

US dollars

=back

=item mandate_options hash

Additional fields for Mandate creation

=over 8

=item custom_mandate_url string

A URL for custom mandate text

=item default_for array of enum values

List of Stripe products where this mandate can be selected automatically. Returned when the Session is in setup mode.

Possible enum values

=over 12

=item invoice

Enables payments for Stripe Invoices. C<subscription> must also be provided.

=item subscription

Enables payments for Stripe Subscriptions. C<invoice> must also be provided.

=back

=item interval_description string

Description of the interval. Only required if the C<payment_schedule> parameter is C<interval> or C<combined>.

=item payment_schedule enum

Payment schedule for the mandate.

Possible enum values

=over 12

=item interval

Payments are initiated at a regular pre-defined interval

=item sporadic

Payments are initiated sporadically

=item combined

Payments can be initiated at a pre-defined interval or sporadically

=back

=item transaction_type enum

Transaction type of the mandate.

Possible enum values

=over 12

=item personal

Transactions are made for personal reasons

=item business

Transactions are made for business reasons

=back

=back

=item verification_method enum

Bank account verification method.

=over 8

=item automatic

Instant verification with fallback to microdeposits.

=item instant

Instant verification.

=item microdeposits

Verification using microdeposits.

=back

=back

=item boleto hash

If the Checkout Session’s payment_method_types includes boleto, this hash contains the configurations that will be applied to each payment attempt of that type.

=over 8

=item expires_after_days integer

The number of calendar days before a Boleto voucher expires. For example, if you create a Boleto voucher on Monday and you set expires_after_days to 2, the Boleto voucher will expire on Wednesday at 23:59 America/Sao_Paulo time.

=back

=item oxxo hash

If the Checkout Session’s payment_method_types includes oxxo, this hash contains the configurations that will be applied to each payment attempt of that type.

=over 8

=item expires_after_days integer

The number of calendar days before an OXXO invoice expires. For example, if you create an OXXO invoice on Monday and you set expires_after_days to 2, the OXXO invoice will expire on Wednesday at 23:59 America/Mexico_City time.

=back

=back

=head2 payment_method_types array containing strings

A list of the types of payment methods (e.g. card) this Checkout Session is allowed to accept.

=head2 payment_status string

The payment status of the Checkout Session, one of C<paid>, C<unpaid>, or C<no_payment_required>.
You can use this value to decide when to fulfill your customer's order.

=head2 phone_number_collection hash

Details on the state of phone number collection for the session.

=over 4

=item enabled boolean

Indicates whether phone number collection is enabled for the session

=back

=head2 recovered_from string

The ID of the original expired Checkout Session that triggered the recovery flow.

=head2 setup_intent string (expandable)

The ID of the SetupIntent for Checkout Sessions in setup mode.

When expanded, this is a L<Net::API::Stripe::Payment::Intent> object.

=head2 setup_intent_data object

A subset of parameters to be passed to SetupIntent creation for Checkout Sessions in setup mode.

This is a L<Net::API::Stripe::Payment::Intent> object and used to create a checkout session.

=head2 shipping object

Shipping information for this Checkout Session.

This is a L<Net::API::Stripe::Shipping> object.

It has the following properties:

=over 4

=item I<address> object

Shipping address.

This is a L<Net::API::Stripe::Address> object.

=item I<name> string

Recipient name.

=back

=head2 shipping_address_collection hash

When set, provides configuration for Checkout to collect a shipping address from a customer.

It has the following properties:

=over 4

=item I<allowed_countries> array

An array of two-letter ISO country codes representing which countries Checkout should provide as options for
shipping locations. Unsupported country codes: C<AS, CX, CC, CU, HM, IR, KP, MH, FM, NF, MP, PW, SD, SY, UM, VI>.

=back

=head2 shipping_cost object

The details of the customer cost of shipping, including the customer chosen ShippingRate.

This is a L<Net::API::Stripe::Checkout::Session> object.

=head2 shipping_details object

Shipping information for this Checkout Session.

This is a L<Net::API::Stripe::Billing::Details> object.

=head2 shipping_options array of hashes

The shipping rate options applied to this Session.

=over 4

=item shipping_amount integer

A non-negative integer in cents representing how much to charge.

=item shipping_rate string expandable

The shipping rate.

=back

=head2 shipping_rate string expandable

The ID of the ShippingRate for Checkout Sessions in payment mode.

=head2 status enum

The status of the Checkout Session, one of open, complete, or expired.

Possible enum values

=over 4

=item open

The checkout session is still in progress. Payment processing has not started

=item complete

The checkout session is complete. Payment processing may still be in progress

=item expired

The checkout session has expired. No further processing will occur

=back

=head2 submit_type string

Describes the type of transaction being performed by Checkout in order to customize relevant text on the page, such as the submit button. submit_type can only be specified on Checkout Sessions in payment mode, but not Checkout Sessions in subscription or setup mode. Supported values are C<auto>, C<book>, C<donate>, or C<pay>.

=head2 subscription string (expandable)

The ID of the subscription for Checkout Sessions in subscription mode. If it is expanded, this is the L<Net::API::Stripe::Billing::Subscription> object.

=head2 subscription_data object

A subset of parameters to be passed to subscription creation for Checkout Sessions in subscription mode.

This is a L<Net::API::Stripe::Billing::Subscription> object and used to create a checkout session.

=head2 success_url string

The URL the customer will be directed to after the payment or subscription creation is successful.

=head2 tax_id_collection hash

Details on the state of tax ID collection for the session.

Hide child attributes

=over 4

=item enabled boolean

Indicates whether tax ID collection is enabled for the session

=back

=head2 total_details hash

Tax and discount details for the computed total amount.

It has the following properties:

=over 4

=item I<amount_discount> integer

This is the sum of all the line item discounts.

=item amount_shipping integer

This is the sum of all the line item shipping amounts.

=item I<amount_tax> integer

This is the sum of all the line item tax amounts.

=item I<breakdown> hash

Breakdown of individual tax and discount amounts that add up to the totals.

=over 8

=item I<discounts> array

The aggregated line item discounts.

=over 12

=item I<amount> integer

The amount discounted.

=item I<discount> hash

The discount applied.

=back

=item I<taxes> array

The aggregated line item tax amounts by rate.

=over 12

=item I<amount> integer

Amount of tax applied for this rate.

=item I<rate> hash

The tax rate applied.

When expanded, this is a L<Net::API::Stripe::Tax::Rate> object.

=back

=back

=back

=head2 url string

The URL to the Checkout Session.

=head1 API SAMPLE

    {
      "id": "cs_test_ksjfkjfkljslfkjlfkflsfklskflskflskfs",
      "object": "checkout.session",
      "billing_address_collection": null,
      "cancel_url": "https://example.com/cancel",
      "client_reference_id": null,
      "customer": null,
      "customer_email": null,
      "display_items": [
        {
          "amount": 1500,
          "currency": "usd",
          "custom": {
            "description": "Comfortable cotton t-shirt",
            "images": null,
            "name": "T-shirt"
          },
          "quantity": 2,
          "type": "custom"
        }
      ],
      "livemode": false,
      "locale": null,
      "mode": null,
      "payment_intent": "pi_fake123456789",
      "payment_method_types": [
        "card"
      ],
      "setup_intent": null,
      "submit_type": null,
      "subscription": null,
      "success_url": "https://example.com/success"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/checkout/sessions>, L<https://stripe.com/docs/payments/checkout/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
