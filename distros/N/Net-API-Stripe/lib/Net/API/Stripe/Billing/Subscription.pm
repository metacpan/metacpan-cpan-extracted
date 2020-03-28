##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Subscription.pm
## Version 0.1.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/01/19
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
    our( $VERSION ) = '0.1.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub application_fee_percent { shift->_set_get_number( 'application_fee_percent', @_ ); }

sub billing { shift->_set_get_scalar( 'billing', @_ ); }

sub billing_cycle_anchor { shift->_set_get_datetime( 'billing_cycle_anchor', @_ ); }

sub billing_thresholds { return( shift->_set_get_object( 'billing_thresholds', 'Net::API::Stripe::Billing::Thresholds', @_ ) ); }

sub cancel_at { shift->_set_get_datetime( 'cancel_at', @_ ); }

sub cancel_at_period_end { shift->_set_get_boolean( 'cancel_at_period_end', @_ ); }

sub canceled_at { shift->_set_get_datetime( 'canceled_at', @_ ); }

sub collection_method { return( shift->_set_get_scalar( 'collection_method', @_ ) ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub current_period_end { shift->_set_get_datetime( 'current_period_end', @_ ); }

sub current_period_start { shift->_set_get_datetime( 'current_period_start', @_ ); }

sub customer { shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ); }

sub days_until_due { shift->_set_get_number( 'days_until_due', @_ ); }

sub default_payment_method { return( shift->_set_get_scalar_or_object( 'default_payment_method', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub default_source { return( shift->_set_get_scalar_or_object( 'default_source', 'Net::API::Stripe::Payment::Source', @_ ) ); }

sub default_tax_rates { return( shift->_set_get_object_array( 'default_tax_rates', 'Net::API::Stripe::Tax::Rate', @_ ) ); }

sub discount { shift->_set_get_object( 'discount', 'Net::API::Stripe::Billing::Discount', @_ ); }

sub ended_at { shift->_set_get_datetime( 'ended_at', @_ ); }

sub invoice_customer_balance_settings { return( shift->_set_get_hash_as_object( 'invoice_customer_balance_settings', 'Net::API::Stripe::Billing::Invoice::BalanceSettings', @_ ) ); }

sub items { shift->_set_get_object( 'items', 'Net::API::Stripe::Billing::Subscription::Items', @_ ); }

sub latest_invoice { return( shift->_set_get_scalar_or_object( 'latest_invoice', 'Net::API::Stripe::Billing::Invoice', @_ ) ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub next_pending_invoice_item_invoice { return( shift->_set_get_hash_as_object( 'next_pending_invoice_item_invoice', 'Net::API::Billing::Subscription::Item::Invoice', @_ ) ); }

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

sub plan { shift->_set_get_object( 'plan', 'Net::API::Stripe::Billing::Plan', @_ ); }

sub quantity { shift->_set_get_number( 'quantity', @_ ); }

sub schedule { return( shift->_set_get_scalar_or_object( 'schedule', 'Net::API::Stripe::Billing::Subscription::Schedule', @_ ) ); }

sub start { shift->_set_get_datetime( 'start', @_ ); }

sub start_date { shift->_set_get_datetime( 'start_date', @_ ); }

sub status { shift->_set_get_scalar( 'status', @_ ); }

## This one is not documented, but is in Stripe's own API response example
sub tax_percent { shift->_set_get_scalar( 'tax_percent', @_ ); }

sub trial_end { shift->_set_get_datetime( 'trial_end', @_ ); }

sub trial_start { shift->_set_get_datetime( 'trial_start', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Subscription - A Stripe Subscription Object

=head1 SYNOPSIS

=head1 VERSION

    0.1.1

=head1 DESCRIPTION

Subscriptions allow you to charge a customer on a recurring basis.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new C<Net::API::Stripe> objects.
It may also take an hash like arguments, that also are method of the same name.

=over 8

=item I<verbose>

Toggles verbose mode on/off

=item I<debug>

Toggles debug mode on/off

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "subscription"

String representing the object’s type. Objects of the same type share the same value.

=item B<application_fee_percent> decimal

A non-negative decimal between 0 and 100, with at most two decimal places. This represents the percentage of the subscription invoice subtotal that will be transferred to the application owner’s Stripe account.

=item B<billing>()

=item B<billing_cycle_anchor> timestamp

Determines the date of the first full invoice, and, for plans with month or year intervals, the day of the month for subsequent invoices.

=item B<billing_thresholds> hash

Define thresholds at which an invoice will be sent, and the subscription advanced to a new billing period

This is a C<Net::API::Stripe::Billing::Thresholds> object.

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

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<current_period_end> timestamp

End of the current period that the subscription has been invoiced for. At the end of this period, a new invoice will be created.

=item B<current_period_start> timestamp

Start of the current period that the subscription has been invoiced for.

=item B<customer> string (expandable)

ID of the customer who owns the subscription. When expanded, this is a C<Net::API::Stripe::Customer> object.

=item B<days_until_due> integer

Number of days a customer has to pay invoices generated by this subscription. This value will be null for subscriptions where collection_method=charge_automatically.

=item B<default_payment_method> string (expandable)

ID of the default payment method for the subscription. It must belong to the customer associated with the subscription. If not set, invoices will use the default payment method in the customer’s invoice settings.

When expanded, this is a C<Net::API::Stripe::Payment::Method> object.

=item B<default_source> string (expandable)

ID of the default payment source for the subscription. It must belong to the customer associated with the subscription and be in a chargeable state. If not set, defaults to the customer’s default source.

When expanded, this is a C<Net::API::Stripe::Payment::Source> object.

=item B<default_tax_rates> array of hashes

The tax rates that will apply to any subscription item that does not have tax_rates set. Invoices created will have their default_tax_rates populated from the subscription.

This is an array of C<Net::API::Stripe::Tax::Rate> objects.

=item B<discount> hash, discount object

Describes the current discount applied to this subscription, if there is one. When billing, a discount applied to a subscription overrides a discount applied on a customer-wide basis.

This is a C<Net::API::Stripe::Billing::Discount> object.

=item B<ended_at> timestamp

If the subscription has ended, the date the subscription ended.

=item B<invoice_customer_balance_settings>()

=item B<items> list

List of subscription items, each with an attached plan.

This is a C<Net::API::Stripe::Billing::Subscription::Items> object.

=item B<latest_invoice> string (expandable)

The most recent invoice this subscription has generated.

When expanded, this is a C<Net::API::Stripe::Billing::Invoice> object.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<next_pending_invoice_item_invoice>

This is an undocumented property on Stripe, but found in its sample data.

This is managed with a virtual module C<Net::API::Billing::Subscription::Item::Invoice>

=item B<pending_invoice_item_interval>()

=item B<pending_setup_intent> string (expandable)

You can use this SetupIntent to collect user authentication when creating a subscription without immediate payment or updating a subscription’s payment method, allowing you to optimize for off-session payments. Learn more in the SCA Migration Guide.

When expanded, this is a C<Net::API::Stripe::Payment::Intent::Setup> object.

=item B<pending_update>() hash

If specified, pending updates that will be applied to the subscription once the latest_invoice has been paid.

=over 8

=item I<billing_cycle_anchor> timestamp

If the update is applied, determines the date of the first full invoice, and, for plans with month or year intervals, the day of the month for subsequent invoices.

=item I<expires_at> timestamp

The point after which the changes reflected by this update will be discarded and no longer applied.

=item I<subscription_items> array of hashes

List of subscription items (C<Net::APi::Stripe::Billing::Subscription::Item>), each with an attached plan, that will be set if the update is applied.

=item I<trial_end> timestamp

Unix timestamp representing the end of the trial period the customer will get before being charged for the first time, if the update is applied.

=item I<trial_from_plan> boolean

Indicates if a plan’s trial_period_days should be applied to the subscription. Setting trial_end per subscription is preferred, and this defaults to false. Setting this flag to true together with trial_end is not allowed.

=back

=item B<plan> hash, plan object

Hash describing the plan the customer is subscribed to. Only set if the subscription contains a single plan.

This is a C<Net::API::Stripe::Billing::Plan> object.

=item B<quantity> integer

The quantity of the plan to which the customer is subscribed. For example, if your plan is $10/user/month, and your customer has 5 users, you could pass 5 as the quantity to have the customer charged $50 (5 x $10) monthly. Only set if the subscription contains a single plan.

=item B<schedule> string expandable

The schedule attached to the subscription. When expanded, this is a C<Net::API::Stripe::Billing::Subscription::Schedule> object.

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

=item B<tax_percent>()

=item B<trial_end> timestamp

If the subscription has a trial, the end of that trial.

=item B<trial_start> timestamp

If the subscription has a trial, the beginning of that trial.

=back

=head1 API SAMPLE

	{
	  "id": "sub_EccdFNq60pUMDL",
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
	  "customer": "cus_EccdcylryhFDnC",
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
			"id": "si_Eccd4op26fXydB",
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
			  "product": "prod_Dwk1QNPjrMJlY8",
			  "tiers": null,
			  "tiers_mode": null,
			  "transform_usage": null,
			  "trial_period_days": null,
			  "usage_type": "licensed"
			},
			"quantity": 1,
			"subscription": "sub_EccdFNq60pUMDL",
			"tax_rates": []
		  }
		],
		"has_more": false,
		"url": "/v1/subscription_items?subscription=sub_EccdFNq60pUMDL"
	  },
	  "latest_invoice": "in_1EKcARCeyNCl6fY2BaXPdnwG",
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
		"product": "prod_Dwk1QNPjrMJlY8",
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

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
