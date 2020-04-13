##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Invoice.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
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
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub account_country { return( shift->_set_get_scalar( 'account_country', @_ ) ); }

sub account_name { return( shift->_set_get_scalar( 'account_name', @_ ) ); }

sub amount_due { shift->_set_get_number( 'amount_due', @_ ); }

sub amount_paid { shift->_set_get_number( 'amount_paid', @_ ); }

sub amount_remaining { shift->_set_get_number( 'amount_remaining', @_ ); }

## 2019-03-14: Stripe renamed this to application_fee
# sub application_fee { shift->_set_get_number( 'application_fee', @_ ); }
sub application_fee { return( shift->application_fee_amount( @_ ) ); }

sub application_fee_amount { return( shift->_set_get_number( 'application_fee_amount', @_ ) ); }

sub attempt_count { shift->_set_get_scalar( 'attempt_count', @_ ); }

sub attempted { shift->_set_get_boolean( 'attempted', @_ ); }

sub auto_advance { shift->_set_get_boolean( 'auto_advance', @_ ); }

sub billing { shift->_set_get_scalar( 'billing', @_ ); }

sub billing_reason { shift->_set_get_scalar( 'billing_reason', @_ ); }

sub charge { shift->_set_get_scalar_or_object( 'charge', 'Net::API::Stripe::Charge', @_ ); }

sub closed { shift->_set_get_scalar( 'closed', @_ ); }

sub collection_method { shift->_set_get_scalar( 'collection_method', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub custom_fields { return( shift->_set_get_object_array( 'custom_fields', 'Net::API::Stripe::CustomField', @_ ) ); }

sub customer { shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ); }

sub customer_address { return( shift->_set_get_object( 'customer_address', 'Net::API::Stripe::Address', @_ ) ); }

sub customer_email { return( shift->_set_get_scalar( 'customer_email', @_ ) ); }

sub customer_name { return( shift->_set_get_scalar( 'customer_name', @_ ) ); }

sub customer_phone { return( shift->_set_get_scalar( 'customer_phone', @_ ) ); }

sub customer_shipping { return( shift->_set_get_object( 'customer_shipping', 'Net::API::Stripe::Shipping', @_ ) ); }

sub customer_tax_exempt { shift->_set_get_scalar( 'customer_tax_exempt', @_ ); }

sub customer_tax_ids { shift->_set_get_object_array( 'customer_tax_ids', 'Net::API::Stripe::Customer::TaxId', @_ ); }

sub date { shift->_set_get_datetime( 'date', @_ ); }

sub default_payment_method { return( shift->_set_get_scalar_or_object( 'default_payment_method', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub default_source { return( shift->_set_get_scalar_or_object( 'default_source', 'Net::API::Stripe::Payment::Source', @_ ) ); }

sub default_tax_rates { return( shift->_set_get_object_array( 'default_tax_rates', 'Net::API::Stripe::Tax::Rate', @_ ) ); }

sub description { shift->_set_get_scalar( 'description', @_ ); }

sub discount { shift->_set_get_object( 'discount', 'Net::API::Stripe::Billing::Discount', @_ ); }

sub due_date { shift->_set_get_datetime( 'due_date', @_ ); }

sub ending_balance { shift->_set_get_number( 'ending_balance', @_ ); }

sub footer { shift->_set_get_scalar( 'footer', @_ ); }

sub forgiven { shift->_set_get_scalar( 'forgiven', @_ ); }

## Not used anymore? It's not on the API documentation
sub hosted_invoice_payment_pending { shift->_set_get_scalar( 'hosted_invoice_payment_pending', @_ ); }

sub hosted_invoice_url { shift->_set_get_uri( 'hosted_invoice_url', @_ ); }

sub invoice_pdf { shift->_set_get_uri( 'invoice_pdf', @_ ); }

sub lines { shift->_set_get_object( 'lines', 'Net::API::Stripe::Billing::Invoice::Lines', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub next_payment_attempt { shift->_set_get_datetime( 'next_payment_attempt', @_ ); }

sub number { shift->_set_get_scalar( 'number', @_ ); }

sub paid { shift->_set_get_boolean( 'paid', @_ ); }

sub payment_intent { shift->_set_get_scalar_or_object( 'payment_intent', 'Net::API::Stripe::Payment::Intent', @_ ); }

sub period_end { shift->_set_get_datetime( 'period_end', @_ ); }

sub period_start { shift->_set_get_datetime( 'period_start', @_ ); }

sub post_payment_credit_notes_amount { return( shift->_set_get_number( 'post_payment_credit_notes_amount', @_ ) ); }

sub pre_payment_credit_notes_amount { return( shift->_set_get_number( ' pre_payment_credit_notes_amount', @_ ) ); }

sub receipt_number { shift->_set_get_scalar( 'receipt_number', @_ ); }

sub starting_balance { shift->_set_get_number( 'starting_balance', @_ ); }

sub statement_descriptor { shift->_set_get_scalar( 'statement_descriptor', @_ ); }

sub status { shift->_set_get_scalar( 'status', @_ ); }

sub status_transitions { return( shift->_set_get_object( 'status_transitions', 'Net::API::Stripe::Billing::Invoice::StatusTransition', @_ ) ); }

sub subscription { shift->_set_get_scalar_or_object( 'subscription', 'Net::API::Stripe::Billing::Subscription', @_ ); }

sub subscription_proration_date { shift->_set_get_scalar( 'subscription_proration_date', @_ ); }

sub subtotal { shift->_set_get_number( 'subtotal', @_ ); }

sub tax { shift->_set_get_number( 'tax', @_ ); }

## Does not seem to exist anymore in the API documentation...
sub tax_percent { shift->_set_get_number( 'tax_percent', @_ ); }

sub threshold_reason { return( shift->_set_get_hash( 'threshold_reason', @_ ) ); }

sub total { shift->_set_get_number( 'total', @_ ); }

sub total_tax_amounts { shift->_set_get_object_array( 'total_tax_amounts', 'Net::API::Stripe::Billing::Invoice::TaxAmount', @_ ); }

sub webhooks_delivered_at { shift->_set_get_datetime( 'webhooks_delivered_at', @_ ); }

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

    0.1

=head1 DESCRIPTION

Invoices are statements of amounts owed by a customer, and are either generated one-off, or generated periodically from a subscription.

They contain invoice items (L<Net::API::Stripe::Billing::Invoice::Item> / L<https://stripe.com/docs/api/invoices#invoiceitems>), and proration adjustments that may be caused by subscription upgrades/downgrades (if necessary).

If your invoice is configured to be billed through automatic charges, Stripe automatically finalizes your invoice and attempts payment. Note that finalizing the invoice, when automatic (L<https://stripe.com/docs/billing/invoices/workflow/#auto_advance>), does not happen immediately as the invoice is created. Stripe waits until one hour after the last webhook was successfully sent (or the last webhook timed out after failing). If you (and the platforms you may have connected to) have no webhooks configured, Stripe waits one hour after creation to finalize the invoice.

If your invoice is configured to be billed by sending an email, then based on your email settings, Stripe will email the invoice to your customer and await payment. These emails can contain a link to a hosted page to pay the invoice.

Stripe applies any customer credit on the account before determining the amount due for the invoice (i.e., the amount that will be actually charged). If the amount due for the invoice is less than L<Stripe's minimum allowed charge per currency|https://stripe.com/docs/currencies#minimum-and-maximum-charge-amounts>, the invoice is automatically marked paid, and Stripe adds the amount due to the customer's running account balance which is applied to the next invoice.

More details on the customer's account balance are L<here|https://stripe.com/docs/api/customers/object#customer_object-account_balance>.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Billing::Invoice> object.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "invoice"

String representing the object’s type. Objects of the same type share the same value.

=item B<account_country> string

The country of the business associated with this invoice, most often the business creating the invoice.

=item B<account_name> string

The public name of the business associated with this invoice, most often the business creating the invoice.

=item B<amount_due> integer

Final amount due at this time for this invoice. If the invoice’s total is smaller than the minimum charge amount, for example, or if there is account credit that can be applied to the invoice, the amount_due may be 0. If there is a positive starting_balance for the invoice (the customer owes money), the amount_due will also take that into account. The charge that gets generated for the invoice will be for the amount specified in amount_due.

=item B<amount_paid> integer

The amount, in JPY, that was paid.

=item B<amount_remaining> integer

The amount remaining, in JPY, that is due.

=item B<application_fee_amount> integer

The fee in JPY that will be applied to the invoice and transferred to the application owner’s Stripe account when the invoice is paid.

=item B<attempt_count> positive integer or zero

Number of payment attempts made for this invoice, from the perspective of the payment retry schedule. Any payment attempt counts as the first attempt, and subsequently only automatic retries increment the attempt count. In other words, manual payment attempts after the first attempt do not affect the retry schedule.

=item B<attempted> boolean

Whether an attempt has been made to pay the invoice. An invoice is not attempted until 1 hour after the invoice.created webhook, for example, so you might not want to display that invoice as unpaid to your users.

=item B<auto_advance> boolean

Controls whether Stripe will perform automatic collection of the invoice. When false, the invoice’s state will not automatically advance without an explicit action.

=item B<billing> string

This is an undocumented property, but that appears in Stripe's own API object example. It contains C<charge_automatically>

=item B<billing_reason> string

Indicates the reason why the invoice was created. subscription_cycle indicates an invoice created by a subscription advancing into a new period. subscription_create indicates an invoice created due to creating a subscription. subscription_update indicates an invoice created due to updating a subscription. subscription is set for all old invoices to indicate either a change to a subscription or a period advancement. manual is set for all invoices unrelated to a subscription (for example: created via the invoice editor). The upcoming value is reserved for simulated invoices per the upcoming invoice endpoint. subscription_threshold indicates an invoice created due to a billing threshold being reached.

=item B<charge> string (expandable)

ID of the latest charge generated for this invoice, if any. When expanded, this is a C<Net::API::Stripe::Charge> object.

=item B<collection_method> string

Either charge_automatically, or send_invoice. When charging automatically, Stripe will attempt to pay this invoice using the default source attached to the customer. When sending an invoice, Stripe will email this invoice to the customer with payment instructions.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<custom_fields> array of hashes

Custom fields displayed on the invoice. This is an array of C<Net::API::Stripe::CustomField> objects.

=item B<customer> string (expandable)

This is a Stripe Customer id, or when expanded, this is a C<Net::API::Stripe::Customer> object.

=item B<customer_address> hash

The customer’s address. Until the invoice is finalized, this field will equal customer.address. Once the invoice is finalised, this field will no longer be updated.

This is a C<Net::API::Stripe::Address> object.

=item B<customer_email> string

The customer’s email. Until the invoice is finalized, this field will equal customer.email. Once the invoice is finalised, this field will no longer be updated.

=item B<customer_name> string

The customer’s name. Until the invoice is finalized, this field will equal customer.name. Once the invoice is finalized, this field will no longer be updated.

=item B<customer_phone> string

The customer’s phone number. Until the invoice is finalized, this field will equal customer.phone. Once the invoice is finalized, this field will no longer be updated.

=item B<customer_shipping> hash

The customer’s shipping information. Until the invoice is finalized, this field will equal customer.shipping. Once the invoice is finalized, this field will no longer be updated.

This is a C<Net::API::Stripe::Shipping> object.

=item B<customer_tax_exempt> string

The customer’s tax exempt status. Until the invoice is finalized, this field will equal customer.tax_exempt. Once the invoice is finalized, this field will no longer be updated.

=item B<customer_tax_ids> array of hashes

The customer’s tax IDs. Until the invoice is finalized, this field will contain the same tax IDs as customer.tax_ids. Once the invoice is finalized, this field will no longer be updated.

This is a C<Net::API::Stripe::Customer::TaxIds> object.

=item B<default_payment_method> string (expandable)

ID of the default payment method for the invoice. It must belong to the customer associated with the invoice. If not set, defaults to the subscription’s default payment method, if any, or to the default payment method in the customer’s invoice settings.

When expanded, this is a C<Net::API::Stripe::Payment::Method> object.

=item B<default_source> string (expandable)

ID of the default payment source for the invoice. It must belong to the customer associated with the invoice and be in a chargeable state. If not set, defaults to the subscription’s default source, if any, or to the customer’s default source.

When expanded, this is a C<Net::API::Stripe::Payment::Source> object.

=item B<default_tax_rates> array of hashes

The tax rates applied to this invoice, if any.

This is an array of C<Net::API::Stripe::Tax::Rate> object.

=item B<description> string

An arbitrary string attached to the object. Often useful for displaying to users. Referenced as ‘memo’ in the Dashboard.

=item B<discount> hash, discount object

This is a C<Net::API::Stripe::Billing::Discount> object

=item B<due_date> timestamp

The date on which payment for this invoice is due. This value will be null for invoices where collection_method=charge_automatically.

=item B<ending_balance> integer

Ending customer balance after the invoice is finalized. Invoices are finalized approximately an hour after successful webhook delivery or when payment collection is attempted for the invoice. If the invoice has not been finalized yet, this will be null.

=item B<footer> string

Footer displayed on the invoice.

=item B<forgiven> boolean

=item B<hosted_invoice_url> string

The URL for the hosted invoice page, which allows customers to view and pay an invoice. If the invoice has not been finalized yet, this will be null.

=item B<invoice_pdf> string

The link to download the PDF for the invoice. If the invoice has not been finalized yet, this will be null.

=item B<lines> list

The individual line items that make up the invoice. lines is sorted as follows: invoice items in reverse chronological order, followed by the subscription, if any.

This is a C<Net::API::Stripe::Billing::Invoice::Lines> object.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<next_payment_attempt> timestamp

The time at which payment will next be attempted. This value will be null for invoices where collection_method=send_invoice.

=item B<number> string

A unique, identifying string that appears on emails sent to the customer for this invoice. This starts with the customer’s unique invoice_prefix if it is specified.

=item B<paid> boolean

Whether payment was successfully collected for this invoice. An invoice can be paid (most commonly) with a charge or with credit from the customer’s account balance.

=item B<payment_intent> string (expandable)

The PaymentIntent associated with this invoice. The PaymentIntent is generated when the invoice is finalized, and can then be used to pay the invoice. Note that voiding an invoice will cancel the PaymentIntent.

When expanded, this is a C<Net::API::Stripe::Payment::Intent> object.

=item B<period_end> timestamp

End of the usage period during which invoice items were added to this invoice.

=item B<period_start> timestamp

Start of the usage period during which invoice items were added to this invoice.

=item B<post_payment_credit_notes_amount> integer

Total amount of all post-payment credit notes issued for this invoice.

=item B<pre_payment_credit_notes_amount> integer

Total amount of all pre-payment credit notes issued for this invoice.

=item B<receipt_number> string

This is the transaction number that appears on email receipts sent for this invoice.

=item B<starting_balance> integer

Starting customer balance before the invoice is finalized. If the invoice has not been finalized yet, this will be the current customer balance.

=item B<statement_descriptor> string

Extra information about an invoice for the customer’s credit card statement.

=item B<status> string

The status of the invoice, one of draft, open, paid, uncollectible, or void. Learn more

=item B<status_transitions> hash

This is a C<Net::API::Stripe::Billing::Invoice::StatusTransition> object.

=item B<subscription> string (expandable)

The subscription that this invoice was prepared for, if any. When expanded, this is a C<Net::API::Stripe::Billing::Subscription> object.

=item B<subscription_proration_date> integer

Only set for upcoming invoices that preview prorations. The time used to calculate prorations.

=item B<subtotal> integer

Total of all subscriptions, invoice items, and prorations on the invoice before any discount or tax is applied.

=item B<tax> integer

The amount of tax on this invoice. This is the sum of all the tax amounts on this invoice.

=item B<threshold_reason> hash

If billing_reason is set to subscription_threshold this returns more information on which threshold rules triggered the invoice.

=item B<total> integer

Total after discounts and taxes.

=item B<total_tax_amounts> array of hashes

The aggregate amounts calculated per tax rate for all line items.

This is an array of C<Net::API::Stripe::Billing::Invoice::TaxAmount> objects.

=item B<webhooks_delivered_at> timestamp

The time at which webhooks for this invoice were successfully delivered (if the invoice had no webhooks to deliver, this will match created). Invoice payment is delayed until webhooks are delivered, or until all webhook delivery attempts have been exhausted.

=back

=head1 API SAMPLE

    {
      "id": "in_fake123456789",
      "object": "invoice",
      "account_country": "JP",
      "account_name": "Provider, Inc",
      "amount_due": 8000,
      "amount_paid": 8000,
      "amount_remaining": 0,
      "application_fee_amount": null,
      "attempt_count": 1,
      "attempted": true,
      "auto_advance": false,
      "billing": "charge_automatically",
      "billing_reason": "subscription",
      "charge": "ch_fake1234567890",
      "collection_method": "charge_automatically",
      "created": 1507273919,
      "currency": "jpy",
      "custom_fields": null,
      "customer": "cus_fake1234567890",
      "customer_address": null,
      "customer_email": "john.doe@example.com",
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
      "due_date": null,
      "ending_balance": 0,
      "footer": null,
      "hosted_invoice_url": "https://pay.stripe.com/invoice/invst_lksjkljslmckhsjcbncmbcn",
      "invoice_pdf": "https://pay.stripe.com/invoice/invst_lksjkljslmckhsjcbncmbcn/pdf",
      "lines": {
        "data": [
          {
            "id": "sli_fake123456789",
            "object": "line_item",
            "amount": 8000,
            "currency": "jpy",
            "description": "1 × Provider, Inc professional monthly membership (at ¥8,000 / month)",
            "discountable": true,
            "livemode": false,
            "metadata": {},
            "period": {
              "end": 1559441759,
              "start": 1556763359
            },
            "plan": {
              "id": "professional-monthly-jpy",
              "object": "plan",
              "active": true,
              "aggregate_usage": null,
              "amount": 8000,
              "amount_decimal": "8000",
              "billing_scheme": "per_unit",
              "created": 1541833564,
              "currency": "jpy",
              "interval": "month",
              "interval_count": 1,
              "livemode": false,
              "metadata": {},
              "nickname": null,
              "product": "prod_fake123456789",
              "tiers": null,
              "tiers_mode": null,
              "transform_usage": null,
              "trial_period_days": null,
              "usage_type": "licensed"
            },
            "proration": false,
            "quantity": 1,
            "subscription": "sub_fake123456789",
            "subscription_item": "si_fake123456789",
            "tax_amounts": [],
            "tax_rates": [],
            "type": "subscription"
          }
        ],
        "has_more": false,
        "object": "list",
        "url": "/v1/invoices/in_fake123456789/lines"
      },
      "livemode": false,
      "metadata": {},
      "next_payment_attempt": null,
      "number": "53DB91F-0001",
      "paid": true,
      "payment_intent": null,
      "period_end": 1507273919,
      "period_start": 1507273919,
      "post_payment_credit_notes_amount": 0,
      "pre_payment_credit_notes_amount": 0,
      "receipt_number": "2066-1929",
      "starting_balance": 0,
      "statement_descriptor": null,
      "status": "paid",
      "status_transitions": {
        "finalized_at": 1507273919,
        "marked_uncollectible_at": null,
        "paid_at": 1507273919,
        "voided_at": null
      },
      "subscription": "sub_fake123456789",
      "subtotal": 8000,
      "tax": null,
      "tax_percent": null,
      "total": 8000,
      "total_tax_amounts": [],
      "webhooks_delivered_at": 1507273920
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head1 2019-12-03

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
