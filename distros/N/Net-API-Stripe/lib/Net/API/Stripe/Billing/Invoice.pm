##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Invoice.pm
## Version v0.101.1
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/11/20
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/invoices/object
package Net::API::Stripe::Billing::Invoice;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.101.1';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub account_country { return( shift->_set_get_scalar( 'account_country', @_ ) ); }

sub account_name { return( shift->_set_get_scalar( 'account_name', @_ ) ); }

sub account_tax_ids { return( shift->_set_get_object_array( 'account_tax_ids', 'Net::API::Stripe::Billing::TaxID', @_ ) ); }

sub amount_due { return( shift->_set_get_number( 'amount_due', @_ ) ); }

sub amount_paid { return( shift->_set_get_number( 'amount_paid', @_ ) ); }

sub amount_remaining { return( shift->_set_get_number( 'amount_remaining', @_ ) ); }

sub application { return( shift->_set_get_scalar_or_object( 'application', 'Net::API::Stripe::Connect::Account', @_ ) ); }

## 2019-03-14: Stripe renamed this to application_fee
# sub application_fee { return( shift->_set_get_number( 'application_fee', @_ ) ); }
sub application_fee { return( shift->application_fee_amount( @_ ) ); }

sub application_fee_amount { return( shift->_set_get_number( 'application_fee_amount', @_ ) ); }

sub attempt_count { return( shift->_set_get_scalar( 'attempt_count', @_ ) ); }

sub attempted { return( shift->_set_get_boolean( 'attempted', @_ ) ); }

sub auto_advance { return( shift->_set_get_boolean( 'auto_advance', @_ ) ); }

sub automatic_tax { return( shift->_set_get_class( 'automatic_tax',
{
    enabled => { type => 'boolean' },
    status  => { type => 'string' },
}, @_ ) ); }

sub billing { return( shift->_set_get_scalar( 'billing', @_ ) ); }

sub billing_reason { return( shift->_set_get_scalar( 'billing_reason', @_ ) ); }

sub charge { return( shift->_set_get_scalar_or_object( 'charge', 'Net::API::Stripe::Charge', @_ ) ); }

sub closed { return( shift->_set_get_scalar( 'closed', @_ ) ); }

sub collection_method { return( shift->_set_get_scalar( 'collection_method', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub custom_fields { return( shift->_set_get_object_array( 'custom_fields', 'Net::API::Stripe::CustomField', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub customer_address { return( shift->_set_get_object( 'customer_address', 'Net::API::Stripe::Address', @_ ) ); }

sub customer_email { return( shift->_set_get_scalar( 'customer_email', @_ ) ); }

sub customer_name { return( shift->_set_get_scalar( 'customer_name', @_ ) ); }

sub customer_phone { return( shift->_set_get_scalar( 'customer_phone', @_ ) ); }

sub customer_shipping { return( shift->_set_get_object( 'customer_shipping', 'Net::API::Stripe::Shipping', @_ ) ); }

sub customer_tax_exempt { return( shift->_set_get_scalar( 'customer_tax_exempt', @_ ) ); }

sub customer_tax_ids { return( shift->_set_get_object_array( 'customer_tax_ids', 'Net::API::Stripe::Customer::TaxId', @_ ) ); }

sub date { return( shift->_set_get_datetime( 'date', @_ ) ); }

sub default_payment_method { return( shift->_set_get_scalar_or_object( 'default_payment_method', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub default_source { return( shift->_set_get_scalar_or_object( 'default_source', 'Net::API::Stripe::Payment::Source', @_ ) ); }

sub default_tax_rates { return( shift->_set_get_object_array( 'default_tax_rates', 'Net::API::Stripe::Tax::Rate', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub discount { return( shift->_set_get_object( 'discount', 'Net::API::Stripe::Billing::Discount', @_ ) ); }

sub discounts { return( shift->_set_get_scalar_or_object_array( 'discounts', 'Net::API::Stripe::Billing::Discount', @_ ) ); }

sub due_date { return( shift->_set_get_datetime( 'due_date', @_ ) ); }

sub ending_balance { return( shift->_set_get_number( 'ending_balance', @_ ) ); }

sub footer { return( shift->_set_get_scalar( 'footer', @_ ) ); }

sub forgiven { return( shift->_set_get_boolean( 'forgiven', @_ ) ); }

## Not used anymore? It's not on the API documentation
sub hosted_invoice_payment_pending { return( shift->_set_get_scalar( 'hosted_invoice_payment_pending', @_ ) ); }

sub hosted_invoice_url { return( shift->_set_get_uri( 'hosted_invoice_url', @_ ) ); }

sub invoice_pdf { return( shift->_set_get_uri( 'invoice_pdf', @_ ) ); }

sub last_finalization_error { return( shift->_set_get_class( 'last_finalization_error',
{
  code => { type => "scalar" },
  doc_url => { type => "scalar" },
  message => { type => "scalar" },
  param => { type => "scalar" },
  payment_method_type => { type => "scalar" },
  type => { type => "scalar" },
}, @_ ) ); }

sub lines { return( shift->_set_get_object( 'lines', 'Net::API::Stripe::Billing::Invoice::Lines', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub next_payment_attempt { return( shift->_set_get_datetime( 'next_payment_attempt', @_ ) ); }

sub number { return( shift->_set_get_scalar( 'number', @_ ) ); }

sub on_behalf_of { return( shift->_set_get_scalar_or_object( 'on_behalf_of', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub paid { return( shift->_set_get_boolean( 'paid', @_ ) ); }

sub paid_out_of_band { return( shift->_set_get_boolean( 'paid_out_of_band', @_ ) ); }

sub payment_intent { return( shift->_set_get_scalar_or_object( 'payment_intent', 'Net::API::Stripe::Payment::Intent', @_ ) ); }

sub payment_settings { return( shift->_set_get_object( 'payment_settings', 'Net::API::Stripe::Payment::Settings', @_ ) ); }

sub period_end { return( shift->_set_get_datetime( 'period_end', @_ ) ); }

sub period_start { return( shift->_set_get_datetime( 'period_start', @_ ) ); }

sub post_payment_credit_notes_amount { return( shift->_set_get_number( 'post_payment_credit_notes_amount', @_ ) ); }

sub pre_payment_credit_notes_amount { return( shift->_set_get_number( ' pre_payment_credit_notes_amount', @_ ) ); }

sub quote { return( shift->_set_get_scalar_or_object( 'quote', 'Net::API::Stripe::Billing::Quote', @_ ) ); }

sub receipt_number { return( shift->_set_get_scalar( 'receipt_number', @_ ) ); }

sub rendering_options { return( shift->_set_get_class( 'rendering_options',
{
    amount_tax_display => { type => 'string' },
}, @_ ) ); }

sub starting_balance { return( shift->_set_get_number( 'starting_balance', @_ ) ); }

sub statement_descriptor { return( shift->_set_get_scalar( 'statement_descriptor', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub status_transitions { return( shift->_set_get_object( 'status_transitions', 'Net::API::Stripe::Billing::Invoice::StatusTransition', @_ ) ); }

sub subscription { return( shift->_set_get_scalar_or_object( 'subscription', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub subscription_proration_date { return( shift->_set_get_scalar( 'subscription_proration_date', @_ ) ); }

sub subtotal { return( shift->_set_get_number( 'subtotal', @_ ) ); }

sub subtotal_excluding_tax { return( shift->_set_get_number( 'subtotal_excluding_tax', @_ ) ); }

sub tax { return( shift->_set_get_number( 'tax', @_ ) ); }

# Does not seem to exist anymore in the API documentation...
sub tax_percent { return( shift->_set_get_number( 'tax_percent', @_ ) ); }

sub test_clock { return( shift->_set_get_scalar_or_object( 'test_clock', 'Net::API::Stripe::Billing::TestClock', @_ ) ); }

sub threshold_reason { return( shift->_set_get_hash( 'threshold_reason', @_ ) ); }

sub total { return( shift->_set_get_number( 'total', @_ ) ); }

sub total_discount_amounts
{
    return( shift->_set_get_class_array( 'total_discount_amounts',
    {
    amount      => { type => 'number' },
    discount    => { type => 'object', class => 'Net::API::Stripe::Billing::Discount' },
    }, @_ ) );
}

sub total_excluding_tax { return( shift->_set_get_number( 'total_excluding_tax', @_ ) ); }

sub total_tax_amounts { return( shift->_set_get_object_array( 'total_tax_amounts', 'Net::API::Stripe::Billing::Invoice::TaxAmount', @_ ) ); }

sub transfer_data { return( shift->_set_get_class( 'transfer_data', {
    amount => { type => "number" },
    destination => { type => "scalar" },
}, @_ ) ); }

sub webhooks_delivered_at { return( shift->_set_get_datetime( 'webhooks_delivered_at', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Invoice - A Stripe Invoice

=head1 SYNOPSIS

    my $stripe = Net::API::Stripe->new( conf_file => './settings.json', expand => 'all' ) || die( Net::API::Stripe->error );
    my $inv = $stripe->invoices( create => 
    {
    account_country => 'jp',
    account_name => 'John Doe',
    amount_due => 2000,
    amount_paid => 500,
    amount_remaining => 1500
    billing => 'charge_automatically',
    charge => 'ch_fake123456789',
    currency => 'jpy',
    customer => $customer_object,
    customer_address => $stripe->address({
        line1 => '1-2-3 Sugamo, Bukyo-ku',
        line2 => 'Taro Bldg'.
        city => 'Tokyo',
        postal_code => '123-4567',
        country => 'jp',
        }),
    customer_email => 'john.doe@example.com',
    customer_name => 'John Doe',
    description => 'Invoice for professional services',
    due_date => '2020-04-01',
    }) || die( $stripe->error );

=head1 VERSION

    v0.101.1

=head1 DESCRIPTION

Invoices are statements of amounts owed by a customer, and are either generated one-off, or generated periodically from a subscription.

They contain invoice items (L<Net::API::Stripe::Billing::Invoice::Item> / L<https://stripe.com/docs/api/invoices#invoiceitems>), and proration adjustments that may be caused by subscription upgrades/downgrades (if necessary).

If your invoice is configured to be billed through automatic charges, Stripe automatically finalizes your invoice and attempts payment. Note that finalizing the invoice, when automatic (L<https://stripe.com/docs/billing/invoices/workflow/#auto_advance>), does not happen immediately as the invoice is created. Stripe waits until one hour after the last webhook was successfully sent (or the last webhook timed out after failing). If you (and the platforms you may have connected to) have no webhooks configured, Stripe waits one hour after creation to finalize the invoice.

If your invoice is configured to be billed by sending an email, then based on your email settings, Stripe will email the invoice to your customer and await payment. These emails can contain a link to a hosted page to pay the invoice.

Stripe applies any customer credit on the account before determining the amount due for the invoice (i.e., the amount that will be actually charged). If the amount due for the invoice is less than L<Stripe's minimum allowed charge per currency|https://stripe.com/docs/currencies#minimum-and-maximum-charge-amounts>, the invoice is automatically marked paid, and Stripe adds the amount due to the customer's running account balance which is applied to the next invoice.

More details on the customer's account balance are L<here|https://stripe.com/docs/api/customers/object#customer_object-account_balance>.

=head1 CONSTRUCTOR

=head2 new

Provided with an hash of key-value properties and this creates a new L<Net::API::Stripe::Billing::Invoice> object.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "invoice"

String representing the object’s type. Objects of the same type share the same value.

=head2 account_country string

The country of the business associated with this invoice, most often the business creating the invoice.

=head2 account_name string

The public name of the business associated with this invoice, most often the business creating the invoice.

=head2 account_tax_ids array containing strings expandable

The account tax IDs associated with the invoice. Only editable when the invoice is a draft.

When expanded, this contains an array of L<Net::API::Stripe::Billing::TaxID> objects.

=head2 amount_due integer

Final amount due at this time for this invoice. If the invoice’s total is smaller than the minimum charge amount, for example, or if there is account credit that can be applied to the invoice, the amount_due may be 0. If there is a positive starting_balance for the invoice (the customer owes money), the amount_due will also take that into account. The charge that gets generated for the invoice will be for the amount specified in amount_due.

=head2 amount_paid integer

The amount, in JPY, that was paid.

=head2 amount_remaining integer

The amount remaining, in JPY, that is due.

=head2 application

Expandable.

Set or gets an L<Net::API::Stripe::Connect::Account> object or id.

ID of the Connect Application that created the invoice.

=head2 application_fee_amount integer

The fee in JPY that will be applied to the invoice and transferred to the application owner’s Stripe account when the invoice is paid.

=head2 attempt_count positive integer or zero

Number of payment attempts made for this invoice, from the perspective of the payment retry schedule. Any payment attempt counts as the first attempt, and subsequently only automatic retries increment the attempt count. In other words, manual payment attempts after the first attempt do not affect the retry schedule.

=head2 attempted boolean

Whether an attempt has been made to pay the invoice. An invoice is not attempted until 1 hour after the invoice.created webhook, for example, so you might not want to display that invoice as unpaid to your users.

=head2 auto_advance boolean

Controls whether Stripe will perform automatic collection of the invoice. When false, the invoice’s state will not automatically advance without an explicit action.

=head2 automatic_tax hash

Settings and latest results for automatic tax lookup for this invoice.

=over 4

=item * C<enabled> boolean

Whether Stripe automatically computes tax on this invoice. Note that incompatible invoice items (invoice items with manually specified tax rates, negative amounts, or tax_behavior=unspecified) cannot be added to automatic tax invoices.

=item * C<status> enum

The status of the most recent automated tax calculation for this invoice.

Possible enum values

=over 8

=item * C<requires_location_inputs>

The location details supplied on the customer aren’t valid or don’t provide enough location information to accurately determine tax rates for the customer.

=item * C<complete>

Stripe successfully calculated tax automatically on this invoice.

=item * C<failed>

The Stripe Tax service failed, please try again later.

=back

=back

=head2 billing string

This is an undocumented property, but that appears in Stripe's own API object example. It contains C<charge_automatically>

=head2 billing_reason string

Indicates the reason why the invoice was created. subscription_cycle indicates an invoice created by a subscription advancing into a new period. subscription_create indicates an invoice created due to creating a subscription. subscription_update indicates an invoice created due to updating a subscription. subscription is set for all old invoices to indicate either a change to a subscription or a period advancement. manual is set for all invoices unrelated to a subscription (for example: created via the invoice editor). The upcoming value is reserved for simulated invoices per the upcoming invoice endpoint. subscription_threshold indicates an invoice created due to a billing threshold being reached.

=head2 charge string (expandable)

ID of the latest charge generated for this invoice, if any. When expanded, this is a L<Net::API::Stripe::Charge> object.

=head2 collection_method string

Either charge_automatically, or send_invoice. When charging automatically, Stripe will attempt to pay this invoice using the default source attached to the customer. When sending an invoice, Stripe will email this invoice to the customer with payment instructions.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 custom_fields array of hashes

Custom fields displayed on the invoice. This is an array of L<Net::API::Stripe::CustomField> objects.

=over 4

=item * <name>

The name of the custom field.

=item * <value>

The value of the custom field.

=back

=head2 customer string (expandable)

This is a Stripe Customer id, or when expanded, this is a L<Net::API::Stripe::Customer> object.

=head2 customer_address hash

The customer’s address. Until the invoice is finalized, this field will equal customer.address. Once the invoice is finalised, this field will no longer be updated.

This is a L<Net::API::Stripe::Address> object.

=head2 customer_email string

The customer’s email. Until the invoice is finalized, this field will equal customer.email. Once the invoice is finalised, this field will no longer be updated.

=head2 customer_name string

The customer’s name. Until the invoice is finalized, this field will equal customer.name. Once the invoice is finalized, this field will no longer be updated.

=head2 customer_phone string

The customer’s phone number. Until the invoice is finalized, this field will equal customer.phone. Once the invoice is finalized, this field will no longer be updated.

=head2 customer_shipping hash

The customer’s shipping information. Until the invoice is finalized, this field will equal customer.shipping. Once the invoice is finalized, this field will no longer be updated.

This is a L<Net::API::Stripe::Shipping> object.

=head2 customer_tax_exempt string

The customer’s tax exempt status. Until the invoice is finalized, this field will equal customer.tax_exempt. Once the invoice is finalized, this field will no longer be updated.

=head2 customer_tax_ids array of hashes

The customer’s tax IDs. Until the invoice is finalized, this field will contain the same tax IDs as customer.tax_ids. Once the invoice is finalized, this field will no longer be updated.

This is a L<Net::API::Stripe::Customer::TaxIds> object.

=head2 default_payment_method string (expandable)

ID of the default payment method for the invoice. It must belong to the customer associated with the invoice. If not set, defaults to the subscription’s default payment method, if any, or to the default payment method in the customer’s invoice settings.

When expanded, this is a L<Net::API::Stripe::Payment::Method> object.

=head2 default_source string (expandable)

ID of the default payment source for the invoice. It must belong to the customer associated with the invoice and be in a chargeable state. If not set, defaults to the subscription’s default source, if any, or to the customer’s default source.

When expanded, this is a L<Net::API::Stripe::Payment::Source> object.

=head2 default_tax_rates array of hashes

The tax rates applied to this invoice, if any.

This is an array of L<Net::API::Stripe::Tax::Rate> object.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users. Referenced as ‘memo’ in the Dashboard.

=head2 discount hash, discount object

This is a L<Net::API::Stripe::Billing::Discount> object

=head2 discounts expandable

The discounts applied to the invoice. Line item discounts are applied before invoice discounts. Use `expand[]=discounts` to expand each discount.

When expanded this is an L<Net::API::Stripe::Billing::Discount> object.

=head2 due_date timestamp

The date on which payment for this invoice is due. This value will be null for invoices where collection_method=charge_automatically.

=head2 ending_balance integer

Ending customer balance after the invoice is finalized. Invoices are finalized approximately an hour after successful webhook delivery or when payment collection is attempted for the invoice. If the invoice has not been finalized yet, this will be null.

=head2 footer string

Footer displayed on the invoice.

=head2 forgiven boolean

Boolean value defining if the invoice was paid.

Not part of the Stripe documentation anymore but present in data returned.

=head2 hosted_invoice_url string

The URL for the hosted invoice page, which allows customers to view and pay an invoice. If the invoice has not been finalized yet, this will be null.

=head2 invoice_pdf string

The link to download the PDF for the invoice. If the invoice has not been finalized yet, this will be null.

=head2 last_finalization_error hash

The error encountered during the previous attempt to finalize the invoice. This field is cleared when the invoice is successfully finalized.

It has the following properties:

=over 4

=item I<code> string

For some errors that could be handled programmatically, a short string indicating the [error code](/docs/error-codes) reported.

=item I<doc_url> string

A URL to more information about the [error code](/docs/error-codes) reported.

=item I<message> string

A human-readable message providing more details about the error. For card errors, these messages can be shown to your users.

=item I<param> string

If the error is parameter-specific, the parameter related to the error. For example, you can use this to display a message near the correct form field.

=item I<payment_method_type> string

If the error is specific to the type of payment method, the payment method type that had a problem. This field is only populated for invoice-related errors.

=item I<type> string

The type of error returned. One of C<api_connection_error>, C<api_error>, C<authentication_error>, C<card_error>, C<idempotency_error>, C<invalid_request_error>, or C<rate_limit_error>

=back

=head2 lines list

The individual line items that make up the invoice. lines is sorted as follows: invoice items in reverse chronological order, followed by the subscription, if any.

This is a L<Net::API::Stripe::Billing::Invoice::Lines> object.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 next_payment_attempt timestamp

The time at which payment will next be attempted. This value will be null for invoices where collection_method=send_invoice.

=head2 number string

A unique, identifying string that appears on emails sent to the customer for this invoice. This starts with the customer’s unique invoice_prefix if it is specified.

=head2 on_behalf_of

Expandable

Sets or gets an L<Net::API::Stripe::Connect::Account> object or id.

=head2 paid boolean

Whether payment was successfully collected for this invoice. An invoice can be paid (most commonly) with a charge or with credit from the customer’s account balance.

=head2 paid_out_of_band boolean

Returns true if the invoice was manually marked paid, returns false if the invoice hasn’t been paid yet or was paid on Stripe.

=head2 payment_intent string (expandable)

The PaymentIntent associated with this invoice. The PaymentIntent is generated when the invoice is finalized, and can then be used to pay the invoice. Note that voiding an invoice will cancel the PaymentIntent.

When expanded, this is a L<Net::API::Stripe::Payment::Intent> object.

=head2 payment_settings hash

Sets or gets a L<Net::API::Stripe::Payment::Settings> object.

=head2 period_end timestamp

End of the usage period during which invoice items were added to this invoice.

=head2 period_start timestamp

Start of the usage period during which invoice items were added to this invoice.

=head2 post_payment_credit_notes_amount integer

Total amount of all post-payment credit notes issued for this invoice.

=head2 pre_payment_credit_notes_amount integer

Total amount of all pre-payment credit notes issued for this invoice.

=head2 quote

Expandable.

Sets or gets a L<Net::API::Stripe::Billing::Quote> object or id.

=head2 receipt_number string

This is the transaction number that appears on email receipts sent for this invoice.

=head2 rendering_options hash

Options for invoice PDF rendering.

=over 4

=item * C<amount_tax_display> string

How line-item prices and amounts will be displayed with respect to tax on invoice PDFs.

=back

=head2 starting_balance integer

Starting customer balance before the invoice is finalized. If the invoice has not been finalized yet, this will be the current customer balance.

=head2 statement_descriptor string

Extra information about an invoice for the customer’s credit card statement.

=head2 status string

The status of the invoice, one of draft, open, paid, uncollectible, or void. Learn more

=head2 status_transitions hash

This is a L<Net::API::Stripe::Billing::Invoice::StatusTransition> object.

=head2 subscription string (expandable)

The subscription that this invoice was prepared for, if any. When expanded, this is a L<Net::API::Stripe::Billing::Subscription> object.

=head2 subscription_proration_date integer

Only set for upcoming invoices that preview prorations. The time used to calculate prorations.

=head2 subtotal integer

Total of all subscriptions, invoice items, and prorations on the invoice before any discount or tax is applied.

=head2 subtotal_excluding_tax integer

The integer amount in JPY representing the subtotal of the invoice before any invoice level discount or tax is applied. Item discounts are already incorporated

=head2 tax integer

The amount of tax on this invoice. This is the sum of all the tax amounts on this invoice.

=head2 test_clock string

Expandable

Sets or gets the L<Net::API::Stripe::Billing::TestClock> object or ID of the test clock this invoice belongs to.

=head2 threshold_reason hash

If billing_reason is set to subscription_threshold this returns more information on which threshold rules triggered the invoice.

=over 4

=item * C<amount_gte> integer

The total invoice amount threshold boundary if it triggered the threshold invoice.

=item * C<item_reasons> array of hashes

Indicates which line items triggered a threshold invoice.

=over 8

=item * C<line_item_ids> array containing strings

The IDs of the line items that triggered the threshold invoice.

=item * C<usage_gte> integer

The quantity threshold boundary that applied to the given line item.

=back

=back

=head2 total integer

Total after discounts and taxes.

=head2 total_discount_amounts array of hashes

The aggregate amounts calculated per discount across all line items.

=over 4

=item * C<amount> integer

The amount, in JPY, of the discount.

=item * C<discount> string

Expandable

The discount that was applied to get this discount amount.

=back

=head2 total_excluding_tax integer

The integer amount in JPY representing the total amount of the invoice including all discounts but excluding all tax.

Properties are:

=over 4

=item I<amount> integer

The amount, in JPY, of the discount.

=item I<discount> string expandable

The discount that was applied to get this discount amount.

=back

=head2 total_tax_amounts array of hashes

The aggregate amounts calculated per tax rate for all line items.

This is an array of L<Net::API::Stripe::Billing::Invoice::TaxAmount> objects.

=head2 transfer_data hash

The account (if any) the payment will be attributed to for tax reporting, and where funds from the payment will be transferred to for the invoice.

It has the following properties:

=over 4

=item I<amount> integer

The amount in JPY that will be transferred to the destination account when the invoice is paid. By default, the entire amount is transferred to the destination.

=item I<destination> string

The account where funds from the payment will be transferred to upon payment success.

=back

=head2 webhooks_delivered_at timestamp

The time at which webhooks for this invoice were successfully delivered (if the invoice had no webhooks to deliver, this will match created). Invoice payment is delayed until webhooks are delivered, or until all webhook delivery attempts have been exhausted.

=head1 API SAMPLE

{
  "id": "in_fake1234567890",
  "object": "invoice",
  "account_country": "JP",
  "account_name": "Angels, Inc",
  "account_tax_ids": null,
  "amount_due": 5300,
  "amount_paid": 0,
  "amount_remaining": 5300,
  "application": null,
  "application_fee_amount": null,
  "attempt_count": 0,
  "attempted": false,
  "auto_advance": true,
  "automatic_tax": {
    "enabled": false,
    "status": null
  },
  "billing_reason": "manual",
  "charge": null,
  "collection_method": "charge_automatically",
  "created": 1657660441,
  "currency": "jpy",
  "custom_fields": null,
  "customer": "cus_fake123456789990",
  "customer_address": null,
  "customer_email": null,
  "customer_name": null,
  "customer_phone": null,
  "customer_shipping": null,
  "customer_tax_exempt": "none",
  "customer_tax_ids": [],
  "default_payment_method": null,
  "default_source": null,
  "default_tax_rates": [],
  "description": null,
  "discount": null,
  "discounts": [],
  "due_date": null,
  "ending_balance": null,
  "footer": null,
  "hosted_invoice_url": null,
  "invoice_pdf": null,
  "last_finalization_error": null,
  "lines": {
    "object": "list",
    "data": [
      {
        "id": "il_fake1234567890",
        "object": "line_item",
        "amount": 5300,
        "amount_excluding_tax": 5300,
        "currency": "jpy",
        "description": "My First Invoice Item (created for API docs)",
        "discount_amounts": [],
        "discountable": true,
        "discounts": [],
        "invoice_item": "ii_fake1234567890",
        "livemode": false,
        "metadata": {},
        "period": {
          "end": 1657660440,
          "start": 1657660440
        },
        "price": {
          "id": "price_fake1234567890",
          "object": "price",
          "active": true,
          "billing_scheme": "per_unit",
          "created": 1649731261,
          "currency": "jpy",
          "custom_unit_amount": null,
          "livemode": false,
          "lookup_key": null,
          "metadata": {},
          "nickname": null,
          "product": "prod_fake1234567890",
          "recurring": null,
          "tax_behavior": "unspecified",
          "tiers_mode": null,
          "transform_quantity": null,
          "type": "one_time",
          "unit_amount": 5300,
          "unit_amount_decimal": "5300"
        },
        "proration": false,
        "proration_details": {
          "credited_items": null
        },
        "quantity": 1,
        "subscription": null,
        "tax_amounts": [],
        "tax_rates": [],
        "type": "invoiceitem",
        "unit_amount_excluding_tax": "5300"
      }
    ],
    "has_more": false,
    "url": "/v1/invoices/in_fake1234567890/lines"
  },
  "livemode": false,
  "metadata": {},
  "next_payment_attempt": 1657664041,
  "number": null,
  "on_behalf_of": null,
  "paid": false,
  "paid_out_of_band": false,
  "payment_intent": null,
  "payment_settings": {
    "payment_method_options": null,
    "payment_method_types": null
  },
  "period_end": 1657660440,
  "period_start": 1657660440,
  "post_payment_credit_notes_amount": 0,
  "pre_payment_credit_notes_amount": 0,
  "quote": null,
  "receipt_number": null,
  "rendering_options": null,
  "starting_balance": 0,
  "statement_descriptor": null,
  "status": "draft",
  "status_transitions": {
    "finalized_at": null,
    "marked_uncollectible_at": null,
    "paid_at": null,
    "voided_at": null
  },
  "subscription": null,
  "subtotal": 5300,
  "subtotal_excluding_tax": 5300,
  "tax": null,
  "test_clock": null,
  "total": 5300,
  "total_discount_amounts": [],
  "total_excluding_tax": 5300,
  "total_tax_amounts": [],
  "transfer_data": null,
  "webhooks_delivered_at": null
}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2019-12-03

Customer balances applied to all invoices are now debited or credited back to the customer when voided. Earlier, applied customer balances were not returned back to the customer and were consumed.

=over 4

=item * To achieve this behavior in earlier API versions:

=over 8

=item * Set consume_applied_balance to false when voiding invoices in /v1/invoices/:id/void.

=item * Set invoice_customer_balance_settings[consume_applied_balance_on_void] to false in /v1/subscriptions create or update to force this behavior for Invoices voided by a Subscription.

=item * Set subscription_data[invoice_customer_balance_settings][consume_applied_balance_on_void] to false in /v1/checkout/sessions create to force this behavior for Invoices voided by Subscriptions created with Checkout.

=back

=back

=head2 2019-03-14

There are a few changes to the invoice object:

=over 4

=item * A I<status_transitions> hash now contains the timestamps when an invoice was finalized, paid, marked uncollectible, or voided.

=item * The I<date> property has been renamed to created.

=item * The I<finalized_at> property has been moved into the I<status_transitions> hash.

=back

=head2 2018-11-08

The I<closed> property on the invoice object controls automatic collection. I<closed> has been deprecated in favor of the more specific I<auto_advance> field. Where you might have set I<closed=true> on invoices in the past, set I<auto_advance=false>.

=head2 2018-11-08

Instead of checking the I<forgiven> field on an invoice, check for the I<uncollectible> status.

Instead of setting the I<forgiven> field on an invoice, mark it as uncollectible.

=head2 2022-08-27

Stripe has removed L</tax_percent> from objects and requests in favor of L<tax rates|https://stripe.com/docs/api/tax_rates>.

=head2 2022-07-12

The following methods were added by Stripe:

=over 4

=item * L</application>

=item * L</automatic_tax>

=item * L</on_behalf_of>

=item * L</paid_out_of_band>

=item * L</payment_settings>

=item * L</quote>

=item * L</rendering_options>

=item * L</subtotal_excluding_tax>

=item * L</test_clock>

=item * L</total_excluding_tax>

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/invoices>, L<https://stripe.com/docs/billing/invoices/sending>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
