##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Subscription.pm
## Version 0.1
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/03/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/subscriptions
package Net::API::Stripe::Billing::Subscription;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.3';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub application_fee_percent { return( shift->_set_get_number( 'application_fee_percent', @_ ) ); }

sub backdate_start_date { return( shift->_set_get_datetime( 'backdate_start_date', @_ ) ); }

sub billing { return( shift->_set_get_scalar( 'billing', @_ ) ); }

sub billing_cycle_anchor { return( shift->_set_get_datetime( 'billing_cycle_anchor', @_ ) ); }

sub billing_thresholds { return( shift->_set_get_object( 'billing_thresholds', 'Net::API::Stripe::Billing::Thresholds', @_ ) ); }

sub cancel_at { return( shift->_set_get_datetime( 'cancel_at', @_ ) ); }

sub cancel_at_period_end { return( shift->_set_get_boolean( 'cancel_at_period_end', @_ ) ); }

sub canceled_at { return( shift->_set_get_datetime( 'canceled_at', @_ ) ); }

sub collection_method { return( shift->_set_get_scalar( 'collection_method', @_ ) ); }

sub coupon { return( shift->_set_get_scalar( 'coupon', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub current_period_end { return( shift->_set_get_datetime( 'current_period_end', @_ ) ); }

sub current_period_start { return( shift->_set_get_datetime( 'current_period_start', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub days_until_due { return( shift->_set_get_number( 'days_until_due', @_ ) ); }

sub default_payment_method { return( shift->_set_get_scalar_or_object( 'default_payment_method', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub default_source { return( shift->_set_get_scalar_or_object( 'default_source', 'Net::API::Stripe::Payment::Source', @_ ) ); }

sub default_tax_rates { return( shift->_set_get_object_array( 'default_tax_rates', 'Net::API::Stripe::Tax::Rate', @_ ) ); }

sub discount { return( shift->_set_get_object( 'discount', 'Net::API::Stripe::Billing::Discount', @_ ) ); }

sub ended_at { return( shift->_set_get_datetime( 'ended_at', @_ ) ); }

sub invoice_customer_balance_settings { return( shift->_set_get_hash_as_object( 'invoice_customer_balance_settings', 'Net::API::Stripe::Billing::Invoice::BalanceSettings', @_ ) ); }

sub items { return( shift->_set_get_object( 'items', 'Net::API::Stripe::Billing::Subscription::Items', @_ ) ); }

sub latest_invoice { return( shift->_set_get_scalar_or_object( 'latest_invoice', 'Net::API::Stripe::Billing::Invoice', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub next_pending_invoice_item_invoice { return( shift->_set_get_hash_as_object( 'next_pending_invoice_item_invoice', 'Net::API::Billing::Subscription::Item::Invoice', @_ ) ); }

sub off_session { return( shift->_set_get_boolean( 'off_session', @_ ) ); }

sub pause_collection 
{
	return( shift->_set_get_class( 'pause_collection',
	{
	behavior => { type => 'scalar' },
	resumes_at => { type => 'datetime' },
	}, @_ ) );
}

sub payment_behavior { return( shift->_set_get_scalar( 'payment_behavior', @_ ) ); }

sub pending_invoice_item_interval { return( shift->_set_get_object( 'pending_invoice_item_interval', 'Net::API::Stripe::Billing::Plan', @_ ) ); }

sub pending_setup_intent { return( shift->_set_get_scalar_or_object( 'pending_setup_intent', 'Net::API::Stripe::Payment::Intent::Setup', @_ ) ); }

sub pending_update
{
	return( shift->_set_get_class( 'pending_update',
	{
	billing_cycle_anchor => { type => 'datetime' },
	expires_at => { type => 'datetime' },
	subscription_items => { type => 'object_array_object', class => 'Net::API::Stripe::Billing::Subscription::Item' },
	trial_end => { type => 'datetime' },
	trial_from_plan => { type => 'boolean' },
	}, @_ ) );
}

sub plan { return( shift->_set_get_object( 'plan', 'Net::API::Stripe::Billing::Plan', @_ ) ); }

sub prorate { return( shift->_set_get_boolean( 'prorate', @_ ) ); }

sub proration_behavior { return( shift->_set_get_scalar( 'proration_behavior', @_ ) ); }

sub quantity { return( shift->_set_get_number( 'quantity', @_ ) ); }

sub schedule { return( shift->_set_get_scalar_or_object( 'schedule', 'Net::API::Stripe::Billing::Subscription::Schedule', @_ ) ); }

sub start { return( shift->_set_get_datetime( 'start', @_ ) ); }

sub start_date { return( shift->_set_get_datetime( 'start_date', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub tax_percent { return( shift->_set_get_number( 'tax_percent', @_ ) ); }

sub trial_end { return( shift->_set_get_datetime( 'trial_end', @_ ) ); }

sub trial_from_plan { return( shift->_set_get_boolean( 'trial_from_plan', @_ ) ); }

sub trial_period_days { return( shift->_set_get_number( 'trial_period_days', @_ ) ); }

sub trial_start { return( shift->_set_get_datetime( 'trial_start', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Subscription - A Stripe Subscription Object

=head1 SYNOPSIS

    my $sub = $stripe->subscription({
        application_fee_percent => 2,
        # Could also be a unix timestamp
        backdate_start_date => '2020-01-01',
        billing_cycle_anchor => '2020-04-01',
        coupon => 'SUMMER10POFF',
        current_period_end => '2020-06-30',
        customer => $cust_object,
        days_until_due => 7,
        default_payment_method => 'pm_fake123456789',
        metadata => { transaction_id => 1212, customer_id => 123 },
        off_session => $stripe->true,
        payment_behavior => 'error_if_incomplete',
        plan => $plan_object,
        quantity => 1,
    });

=head1 VERSION

    0.3

=head1 DESCRIPTION

Subscriptions allow you to charge a customer on a recurring basis.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Billing::Subscription> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "subscription"

String representing the object’s type. Objects of the same type share the same value.

=item B<application_fee_percent> decimal

A non-negative decimal between 0 and 100, with at most two decimal places. This represents the percentage of the subscription invoice subtotal that will be transferred to the application owner’s Stripe account.

=item B<backdate_start_date>

For new subscriptions, a past timestamp to backdate the subscription’s start date to. If set, the first invoice will contain a proration for the timespan between the start date and the current time. Can be combined with trials and the billing cycle anchor.

=item B<billing>()

=item B<billing_cycle_anchor> timestamp

Determines the date of the first full invoice, and, for plans with month or year intervals, the day of the month for subsequent invoices.

=item B<billing_thresholds> hash

Define thresholds at which an invoice will be sent, and the subscription advanced to a new billing period

This is a L<Net::API::Stripe::Billing::Thresholds> object.

=over 8

=item B<amount_gte> integer

Monetary threshold that triggers the subscription to create an invoice

=item B<reset_billing_cycle_anchor> boolean

Indicates if the billing_cycle_anchor should be reset when a threshold is reached. If true, billing_cycle_anchor will be updated to the date/time the threshold was last reached; otherwise, the value will remain unchanged. This value may not be true if the subscription contains items with plans that have aggregate_usage=last_ever.

=back

=item B<cancel_at> timestamp

This is an undocumented property returned by Stripe, and I assume this is a duplicate to the B<canceled_at> one.

This is added here, so returned data does not yield a warning, but obviously this should not be used otherwise.

According to Stripe support as of 2019-11-07, this is:

If the associated subscription has been set up to be canceled at a future date, the ‘cancel_at’ property is used to specify the future timestamp of when it will be canceled.

=item B<cancel_at_period_end> boolean

If the subscription has been canceled with the at_period_end flag set to true, cancel_at_period_end on the subscription will be true. You can use this attribute to determine whether a subscription that has a status of active is scheduled to be canceled at the end of the current period.

=item B<canceled_at> timestamp

If the subscription has been canceled, the date of that cancellation. If the subscription was canceled with cancel_at_period_end, canceled_at will still reflect the date of the initial cancellation request, not the end of the subscription period when the subscription is automatically moved to a canceled state.

=item B<collection_method> string

Either charge_automatically, or send_invoice. When charging automatically, Stripe will attempt to pay this subscription at the end of the cycle using the default source attached to the customer. When sending an invoice, Stripe will email your customer an invoice with payment instructions.

=item B<coupon> string

The code of the coupon to apply to this subscription. A coupon applied to a subscription will only affect invoices created for that particular subscription.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<current_period_end> timestamp

End of the current period that the subscription has been invoiced for. At the end of this period, a new invoice will be created.

=item B<current_period_start> timestamp

Start of the current period that the subscription has been invoiced for.

=item B<customer> string (expandable)

ID of the customer who owns the subscription. When expanded, this is a L<Net::API::Stripe::Customer> object.

=item B<days_until_due> integer

Number of days a customer has to pay invoices generated by this subscription. This value will be null for subscriptions where collection_method=charge_automatically.

=item B<default_payment_method> string (expandable)

ID of the default payment method for the subscription. It must belong to the customer associated with the subscription. If not set, invoices will use the default payment method in the customer’s invoice settings.

When expanded, this is a L<Net::API::Stripe::Payment::Method> object.

=item B<default_source> string (expandable)

ID of the default payment source for the subscription. It must belong to the customer associated with the subscription and be in a chargeable state. If not set, defaults to the customer’s default source.

When expanded, this is a L<Net::API::Stripe::Payment::Source> object.

=item B<default_tax_rates> array of hashes

The tax rates that will apply to any subscription item that does not have tax_rates set. Invoices created will have their default_tax_rates populated from the subscription.

This is an array of L<Net::API::Stripe::Tax::Rate> objects.

=item B<discount> hash, discount object

Describes the current discount applied to this subscription, if there is one. When billing, a discount applied to a subscription overrides a discount applied on a customer-wide basis.

This is a L<Net::API::Stripe::Billing::Discount> object.

=item B<ended_at> timestamp

If the subscription has ended, the date the subscription ended.

=item B<invoice_customer_balance_settings>()

=item B<items> list

List of subscription items, each with an attached plan.

This is a L<Net::API::Stripe::Billing::Subscription::Items> object.

=item B<latest_invoice> string (expandable)

The most recent invoice this subscription has generated.

When expanded, this is a L<Net::API::Stripe::Billing::Invoice> object.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<next_pending_invoice_item_invoice>

This is an undocumented property on Stripe, but found in its sample data.

This is managed with a virtual module L<Net::API::Billing::Subscription::Item::Invoice>

=item B<pause_collection> hash

If specified, payment collection for this subscription will be paused.

=over 8

=item I<pause_collection.behavior> string

The payment collection behavior for this subscription while paused. One of keep_as_draft, mark_uncollectible, or void.

=item I<resumes_at> timestamp

The time after which the subscription will resume collecting payments.

=back

=item B<off_session> boolean

Indicates if a customer is on or off-session while an invoice payment is attempted.

=item B<payment_behavior> string

Use I<allow_incomplete> to create subscriptions with status=incomplete if the first invoice cannot be paid. Creating subscriptions with this status allows you to manage scenarios where additional user actions are needed to pay a subscription’s invoice. For example, SCA regulation may require 3DS authentication to complete payment. See the SCA Migration Guide for Billing to learn more. This is the default behavior.

Use I<error_if_incomplete> if you want Stripe to return an HTTP 402 status code if a subscription’s first invoice cannot be paid. For example, if a payment method requires 3DS authentication due to SCA regulation and further user action is needed, this parameter does not create a subscription and returns an error instead. This was the default behavior for API versions prior to 2019-03-14. See the changelog to learn more.

I<pending_if_incomplete> is only used with updates and cannot be passed when creating a subscription.
Possible enum values

=over 8

=item I<allow_incomplete>

=item I<error_if_incomplete>

=item I<pending_if_incomplete>

=back

=item B<pending_invoice_item_interval>()

Specifies an interval for how often to bill for any pending invoice items. It is analogous to calling Create an invoice for the given subscription at the specified interval.

=over 8

=item I<interval> required

Specifies invoicing frequency. Either day, week, month or year.

=item I<interval_count> optional

The number of intervals between invoices. For example, interval=month and interval_count=3 bills every 3 months. Maximum of one year interval allowed (1 year, 12 months, or 52 weeks).

=back

=item B<pending_setup_intent> string (expandable)

You can use this SetupIntent to collect user authentication when creating a subscription without immediate payment or updating a subscription’s payment method, allowing you to optimize for off-session payments. Learn more in the SCA Migration Guide.

When expanded, this is a L<Net::API::Stripe::Payment::Intent::Setup> object.

=item B<pending_update>() hash

If specified, pending updates that will be applied to the subscription once the latest_invoice has been paid.

=over 8

=item I<billing_cycle_anchor> timestamp

If the update is applied, determines the date of the first full invoice, and, for plans with month or year intervals, the day of the month for subsequent invoices.

=item I<expires_at> timestamp

The point after which the changes reflected by this update will be discarded and no longer applied.

=item I<subscription_items> array of hashes

List of subscription items (L<Net::APi::Stripe::Billing::Subscription::Item>), each with an attached plan, that will be set if the update is applied.

=item I<trial_end> timestamp

Unix timestamp representing the end of the trial period the customer will get before being charged for the first time, if the update is applied.

=item I<trial_from_plan> boolean

Indicates if a plan’s trial_period_days should be applied to the subscription. Setting trial_end per subscription is preferred, and this defaults to false. Setting this flag to true together with trial_end is not allowed.

=back

=item B<plan> hash, plan object

Hash describing the plan the customer is subscribed to. Only set if the subscription contains a single plan.

This is a L<Net::API::Stripe::Billing::Plan> object.

=item B<prorate> boolean (deprecated)

Boolean (defaults to true) telling us whether to credit for unused time when the billing cycle changes (e.g. when switching plans, resetting billing_cycle_anchor=now, or starting a trial), or if an item’s quantity changes. If false, the anchor period will be free (similar to a trial) and no proration adjustments will be created. This field has been deprecated and will be removed in a future API version. Use proration_behavior=create_prorations as a replacement for prorate=true and proration_behavior=none for prorate=false.

=item B<proration_behavior> string

Determines how to handle prorations resulting from the billing_cycle_anchor. Valid values are I<create_prorations> or I<none>.

Passing I<create_prorations> will cause proration invoice items to be created when applicable. Prorations can be disabled by passing I<none>. If no value is passed, the default is create_prorations.

=item B<quantity> integer

The quantity of the plan to which the customer is subscribed. For example, if your plan is $10/user/month, and your customer has 5 users, you could pass 5 as the quantity to have the customer charged $50 (5 x $10) monthly. Only set if the subscription contains a single plan.

=item B<schedule> string expandable

The schedule attached to the subscription. When expanded, this is a L<Net::API::Stripe::Billing::Subscription::Schedule> object.

=item B<start> timestamp

Date of the last substantial change to this subscription. For example, a change to the items array, or a change of status, will reset this timestamp.

=item B<start_date> timestamp

Date when the subscription was first created. The date might differ from the created date due to backdating.

=item B<status> string

Possible values are incomplete, incomplete_expired, trialing, active, past_due, canceled, or unpaid.

For collection_method=charge_automatically a subscription moves into incomplete if the initial payment attempt fails. A subscription in this state can only have metadata and default_source updated. Once the first invoice is paid, the subscription moves into an active state. If the first invoice is not paid within 23 hours, the subscription transitions to incomplete_expired. This is a terminal state, the open invoice will be voided and no further invoices will be generated.

A subscription that is currently in a trial period is trialing and moves to active when the trial period is over.

If subscription collection_method=charge_automatically it becomes past_due when payment to renew it fails and canceled or unpaid (depending on your subscriptions settings) when Stripe has exhausted all payment retry attempts.

If subscription collection_method=send_invoice it becomes past_due when its invoice is not paid by the due date, and canceled or unpaid if it is still not paid by an additional deadline after that. Note that when a subscription has a status of unpaid, no subsequent invoices will be attempted (invoices will be created, but then immediately automatically closed). After receiving updated payment information from a customer, you may choose to reopen and pay their closed invoices.

=item B<tax_percent> decimal (deprecated)

A non-negative decimal (with at most four decimal places) between 0 and 100. This represents the percentage of the subscription invoice subtotal that will be calculated and added as tax to the final amount in each billing period. For example, a plan which charges $10/month with a tax_percent of 20.0 will charge $12 per invoice. To unset a previously-set value, pass an empty string. This field has been deprecated and will be removed in a future API version, for further information view the migration docs for tax_rates.

=item B<trial_end> timestamp

If the subscription has a trial, the end of that trial.

=item B<trial_from_plan> boolean

Indicates if a plan’s trial_period_days should be applied to the subscription. Setting trial_end per subscription is preferred, and this defaults to false. Setting this flag to true together with trial_end is not allowed.

=item B<trial_period_days> integer

Integer representing the number of trial period days before the customer is charged for the first time. This will always overwrite any trials that might apply via a subscribed plan.

=item B<trial_start> timestamp

If the subscription has a trial, the beginning of that trial.

=back

=head1 API SAMPLE

	{
	  "id": "sub_fake123456789",
	  "object": "subscription",
	  "application_fee_percent": null,
	  "billing": "charge_automatically",
	  "billing_cycle_anchor": 1551492959,
	  "billing_thresholds": null,
	  "cancel_at_period_end": false,
	  "canceled_at": 1555726796,
	  "collection_method": "charge_automatically",
	  "created": 1551492959,
	  "current_period_end": 1556763359,
	  "current_period_start": 1554171359,
	  "customer": "cus_fake123456789",
	  "days_until_due": null,
	  "default_payment_method": null,
	  "default_source": null,
	  "default_tax_rates": [],
	  "discount": null,
	  "ended_at": 1555726796,
	  "items": {
		"object": "list",
		"data": [
		  {
			"id": "si_fake123456789",
			"object": "subscription_item",
			"billing_thresholds": null,
			"created": 1551492959,
			"metadata": {},
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
			"quantity": 1,
			"subscription": "sub_fake123456789",
			"tax_rates": []
		  }
		],
		"has_more": false,
		"url": "/v1/subscription_items?subscription=sub_fake123456789"
	  },
	  "latest_invoice": "in_fake123456789",
	  "livemode": false,
	  "metadata": {},
	  "pending_setup_intent": null,
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
	  "quantity": 1,
	  "start": 1554430777,
	  "start_date": 1551492959,
	  "status": "canceled",
	  "tax_percent": null,
	  "trial_end": null,
	  "trial_start": null
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/subscriptions>, L<https://stripe.com/docs/billing/subscriptions/creating>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
