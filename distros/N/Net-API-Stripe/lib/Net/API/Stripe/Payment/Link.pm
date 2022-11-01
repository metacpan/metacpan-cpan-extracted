##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Link.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/28
## Modified 2022/10/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Link;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub active { return( shift->_set_get_boolean( 'active', @_ ) ); }

sub after_completion { return( shift->_set_get_class( 'after_completion', 
{
    hosted_confirmation => { type => 'class', definition => 
        {
        custom_message => { type => 'scalar' }
        } },
    redirect => { type => 'class', definition => 
        {
        url => { type => 'uri' },
        } },
    type => { type => 'scalar' },
}, @_ ) ); }

sub allow_promotion_codes { return( shift->_set_get_boolean( 'allow_promotion_codes', @_ ) ); }

sub application_fee_amount { return( shift->_set_get_number( 'application_fee_amount', @_ ) ); }

sub application_fee_percent { return( shift->_set_get_number( 'application_fee_percent', @_ ) ); }

sub automatic_tax { return( shift->_set_get_class( 'automatic_tax',
{
    enabled => { type => 'boolean' },
}, @_ ) ); }

sub billing_address_collection { return( shift->_set_get_scalar( 'billing_address_collection', @_ ) ); }

sub consent_collection { return( shift->_set_get_class( 'promotions',
{
    promotions => { type => 'string' },
}, @_ ) ); }

sub currency { return( shift->_set_get_number( 'currency', @_ ) ); }

sub customer_creation { return( shift->_set_get_scalar( 'customer_creation', @_ ) ); }

sub line_items { return( shift->_set_get_object( 'line_items', 'Net::API::Stripe::List', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub on_behalf_of { return( shift->_set_get_scalar_or_object( 'on_behalf_of', @_ ) ); }

sub payment_intent_data { return( shift->_set_get_class( 'payment_intent_data',
{
    capture_method => { type => 'string' },
    setup_future_usage => { type => 'string' },
}, @_ ) ); }

sub payment_method_collection { return( shift->_set_get_scalar( 'payment_method_collection', @_ ) ); }

sub payment_method_types { return( shift->_set_get_array( 'payment_method_types', @_ ) ); }

sub phone_number_collection { return( shift->_set_get_class( 'phone_number_collection', 
{
    enabled => { type => 'boolean' },
}, @_ ) ); }

sub shipping_address_collection { return( shift->_set_get_class( 'shipping_address_collection',
{
    allowed_countries => { type => 'string' },
}, @_ ) ); }

sub shipping_options { return( shift->_set_get_class( 'shipping_options',
{
    shipping_amount => { type => 'integer' },
    shipping_rate => { type => 'scalar_or_object', class => 'Net::API::Stripe::Tax::Rate' },
}, @_ ) ); }

sub submit_type { return( shift->_set_get_scalar( 'submit_type', @_ ) ); }

sub subscription_data { return( shift->_set_get_object( 'subscription_data', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub tax_id_collection { return( shift->_set_get_class( 'tax_id_collection',
{
    enabled => { type => 'boolean' },
}, @_ ) ); }

sub transfer_data { return( shift->_set_get_class( 'transfer_data',
{
    amount => { type => 'integer' },
    destination => { type => 'scalar_or_object', class => 'Net::API::Stripe::Connect::Account' },
}, @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Link - A Stripe Payment Link Object

=head1 SYNOPSIS

    my $link = $stripe->payment_link({
        active => $stripe->true,
        after_completion => 
        {
            hosted_confirmation => 
            {
            custom_message => $some_message,
            },
            redirect => 
            {
            url => 'https://example.org/some/where',
            },
            type => 'hosted_confirmation',
        },
        allow_promotion_codes => $stripe->true,
        application_fee_amount => 1000,
        application_fee_percent => 20,
        automatic_tax => { enabled => $stripe->true },
        billing_address_collection => {},
        line_items => {},
        livemode => $stripe->false,
        metadata => { tax_id => 123, customer_id => 456 },
        object => $object,
        on_behalf_of => $account,
        payment_method_types => 'card',
        phone_number_collection => { enabled => $stripe->true },
        shipping_address_collection => 
        {
        allowed_countries => [qw( JP US FR DE UK )],
        },
        subscription_data => { trial_period_days => 30 },
        transfer_data => 
        {
        amount => 10000,
        destination => 'acct_1234567890qwertyuiop',
        },
        url => 'https://buy.stripe.com/test_123456789qwertyuiop',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

A payment link is a shareable URL that will take your customers to a hosted payment page. A payment link can be shared and used multiple times.

When a customer opens a payment link it will open a L<new checkout session|https://stripe.com/docs/api/payment_links/payment_links#checkout_sessions> to render the payment page. L<You can use checkout session events|https://stripe.com/docs/api/events/types#event_types-checkout.session.completed> to track payments through payment links.

Related guide: L<Payment Links API|https://stripe.com/docs/payments/payment-links/api>.

=head1 CONSTRUCTOR

=head2 new

Creates a new L<Net::API::Stripe::Tax::Rate> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "payment_link"

String representing the object’s type. Objects of the same type share the same value.

=head2 active boolean

Whether the payment link’s C<url> is active. If C<false>, customers visiting the URL will be shown a page saying that the link has been deactivated.

=head2 after_completion hash

Behavior after the purchase is complete.

=over 4

=item hosted_confirmation hash

Configuration when C<type=hosted_confirmation>.

=over 8

=item custom_message string

The custom message that is displayed to the customer after the purchase is complete.

=back

=item redirect hash

Configuration when type=redirect.

=over 8

=item url string

The URL the customer will be redirected to after the purchase is complete.

=back

=item type enum

The specified behavior after the purchase is complete.

Possible enum values

=over 8

=item redirect

Redirects the customer to the specified C<url> after the purchase is complete.

=item hosted_confirmation

Displays a message on the hosted surface after the purchase is complete.

=back

=back

=head2 allow_promotion_codes boolean

Whether user redeemable promotion codes are enabled.

=head2 application_fee_amount integer

The amount of the application fee (if any) that will be requested to be applied to the payment and transferred to the application owner’s Stripe account.

=head2 application_fee_percent decimal

This represents the percentage of the subscription invoice subtotal that will be transferred to the application owner’s Stripe account.

=head2 automatic_tax hash

Configuration details for automatic tax collection.

=over 4

=item enabled boolean

If true, tax will be calculated automatically using the customer’s location.

=back

=head2 billing_address_collection enum

Configuration for collecting the customer’s billing address.

Possible enum values

=over 4

=item auto Default

Checkout will only collect the billing address when necessary.

=item required

Checkout will always collect the customer’s billing address.

=back

=head2 currency currency

Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a L<supported currency|https://stripe.com/docs/currencies>.

=head2 line_items list

The line items representing what is being sold.

This field is not included by default. To include it in the response, expand the line_items field.

=over 4

=item object string, value is "list"

String representing the object’s type. Objects of the same type share the same value. Always has the value list.

=item data array of hashes

Details about each object.

=item has_more boolean

True if this list has another page of items after this one that can be fetched.

=item url string

The URL where this list can be accessed.

=back

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 on_behalf_of string expandable

The account on behalf of which to charge. See the Connect documentation for details.

=head2 payment_method_collection string

Configuration for collecting a payment method during checkout.

=head2 payment_method_types array of enum values

The list of payment method types that customers can use. When C<null>, Stripe will dynamically show relevant payment methods you’ve enabled in your L<payment method settings|https://dashboard.stripe.com/settings/payment_methods>.

Possible enum values: C<card>

=head2 phone_number_collection hash

Controls phone number collection settings during checkout.

=over 4

=item enabled boolean

If true, a phone number will be collected during checkout.

=back

=head2 shipping_address_collection hash

Configuration for collecting the customer’s shipping address.

shipping_address_collection.allowed_countries array of enum values

An array of two-letter ISO country codes representing which countries Checkout should provide as options for shipping locations. Unsupported country codes: AS, CX, CC, CU, HM, IR, KP, MH, FM, NF, MP, PW, SD, SY, UM, VI.

=head2 subscription_data object

When creating a subscription, the specified configuration data will be used. There must be at least one line item with a recurring price to use C<subscription_data>.

This is a L<Net::API::Stripe::Billing::Subscription> object.

=head2 transfer_data hash

The account (if any) the payments will be attributed to for tax reporting, and where funds from each payment will be transferred to.

=over 4

=item amount integer

The amount in JPY that will be transferred to the destination account. By default, the entire amount is transferred to the destination.

=item destination string

The connected account receiving the transfer.

=back

=head2 url

The public URL that can be shared with customers.

=head1 API SAMPLE

    {
      "id": "plink_1234567890qwertyuiop",
      "object": "payment_link",
      "active": true,
      "after_completion": {
        "hosted_confirmation": {
          "custom_message": null
        },
        "type": "hosted_confirmation"
      },
      "allow_promotion_codes": false,
      "application_fee_amount": null,
      "application_fee_percent": null,
      "automatic_tax": {
        "enabled": false
      },
      "billing_address_collection": "auto",
      "livemode": false,
      "metadata": {},
      "on_behalf_of": null,
      "payment_method_types": null,
      "phone_number_collection": {
        "enabled": false
      },
      "shipping_address_collection": null,
      "subscription_data": null,
      "transfer_data": null,
      "url": "https://buy.stripe.com/test_1234567890qwertyuiop"
    }

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/payment_links/payment_links/object#payment_link_object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
