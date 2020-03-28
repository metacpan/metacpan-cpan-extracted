##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Subscription/Schedule.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/12/25
## Modified 2019/12/25
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::Subscription::Schedule;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub canceled_at { return( shift->_set_get_datetime( 'canceled_at', @_ ) ); }

sub completed_at { return( shift->_set_get_datetime( 'completed_at', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub current_phase
{
	return( shift->_set_get_class( 'current_phase',
		{
		end_date	=> { type => 'datetime' },
		start_date	=> { type => 'datetime' },
		}, @_ )
	);
}

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub default_settings
{
	return( shift->_set_get_class( 'default_settings',
		{
		billing_thresholds => { type => 'object', class => 'Net::API::Stripe::Billing::Thresholds' },
		collection_method => { type => 'scalar' },
		default_payment_method => { type => 'scalar_or_object', class => 'Net::API::Stripe::Payment::Method' },
		invoice_settings => { type => 'class', definition =>
			{
			days_until_due => { type => 'scalar' }
			}}
		}, @_ )
	);
}

sub end_behavior { return( shift->_set_get_scalar( 'end_behavior', @_ ) ); }

sub from_subscription { return( shift->_set_get_scalar_or_object( 'from_subscription', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub invoice_now { return( shift->_set_get_boolean( 'invoice_now', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub phases
{
	return( shift->_set_get_class_array( 'phases',
		{
		application_fee_percent => { type => 'number' },
		billing_thresholds => { type => 'object', class => 'Net::API::Stripe::Billing::Thresholds' },
		collection_method => { type => 'scalar' },
		coupon => { type => 'scalar_or_object', class => 'Net::API::Stripe::Billing::Coupon' },
		default_payment_method => { type => 'scalar_or_object', class => 'Net::API::Stripe::Payment::Method' },
		default_tax_rates => { type => 'object_array', class => 'Net::API::Stripe::Tax::Rate' },
		end_date => { type => 'datetime' },
		invoice_settings => { type => 'class', definition =>
			{
			days_until_due => { type => 'number' }
			}},
		iterations => { type => 'number' },
		plans => { type => 'class_array', definition =>
			{
			billing_thresholds => { type => 'object', class => 'Net::API::Stripe::Billing::Thresholds' },
			plan => { type => 'scalar_or_object', class => 'Net::API::Stripe::Billing::Plan' },
			quantity => { type => 'number' },
			tax_rates => { type => 'object_array', class => 'Net::APi::Stripe::Tax::Rate' },
			}},
		start_date => { type => 'datetime' },
		trial_end => { type => 'datetime' },
		}, @_ )
	);
}

sub preserve_cancel_date { return( shift->_set_get_boolean( 'preserve_cancel_date', @_ ) ); }

sub prorate { return( shift->_set_get_boolean( 'prorate', @_ ) ); }

sub released_at { return( shift->_set_get_datetime( 'released_at', @_ ) ); }

sub released_subscription { return( shift->_set_get_scalar( 'released_subscription', @_ ) ); }

sub start_date { return( shift->_set_get_datetime( 'start_date', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub subscription { return( shift->_set_get_scalar_or_object( 'subscription', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Subscription::Schedule - A Stripe Subscription Schedule Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

A subscription schedule allows you to create and manage the lifecycle of a subscription by predefining expected changes.

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

=item B<object> string, value is C<subscription_schedule>

String representing the object’s type. Objects of the same type share the same value.

=item B<canceled_at> timestamp

Time at which the subscription schedule was canceled. Measured in seconds since the Unix epoch.

=item B<completed_at> timestamp

Time at which the subscription schedule was completed. Measured in seconds since the Unix epoch.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<current_phase> hash

Object representing the start and end dates for the current phase of the subscription schedule, if it is active.

=over 8

=item I<end_date> timestamp

=item I<start_date> timestamp

=back

=item B<customer> string expandable

ID of the customer who owns the subscription schedule. When expanded, this is a C<Net::API::Stripe::Customer> object.

=item B<default_settings> hash

Object representing the subscription schedule’s default settings.

=over 12

=item I<billing_thresholds> hash

Define thresholds at which an invoice will be sent, and the subscription advanced to a new billing period

This is a C<Net::API::Stripe::Billing::Thresholds> object.

=over 16

=item I<amount_gte> integer

Monetary threshold that triggers the subscription to create an invoice

=item I<reset_billing_cycle_anchor> boolean

Indicates if the billing_cycle_anchor should be reset when a threshold is reached. If true, billing_cycle_anchor will be updated to the date/time the threshold was last reached; otherwise, the value will remain unchanged. This value may not be true if the subscription contains items with plans that have aggregate_usage=last_ever.

=back

=item I<collection_method> string

Either charge_automatically, or send_invoice. When charging automatically, Stripe will attempt to pay the underlying subscription at the end of each billing cycle using the default source attached to the customer. When sending an invoice, Stripe will email your customer an invoice with payment instructions.

=item I<default_payment_method> string expandable

ID of the default payment method for the subscription schedule. If not set, invoices will use the default payment method in the customer’s invoice settings. When expanded, this is a C<Net::API::Stripe::Payment::Method> object.

=item I<invoice_settings> hash

The subscription schedule’s default invoice settings.

=over 16

=item I<days_until_due> integer

Number of days within which a customer must pay invoices generated by this subscription schedule. This value will be null for subscription schedules where billing=charge_automatically.

=back

=back

=item B<end_behavior> string

Behavior of the subscription schedule and underlying subscription when it ends.

=item B<from_subscription> string

Migrate an existing subscription to be managed by a subscription schedule. If this parameter is set, a subscription schedule will be created using the subscription’s plan(s), set to auto-renew using the subscription’s interval. When using this parameter, other parameters (such as phase values) cannot be set. To create a subscription schedule with other modifications, Stripe recommends making two separate API calls.

This is used only when creating a subscription schedule.

=item B<invoice_now> boolean

If the subscription schedule is active, indicates whether or not to generate a final invoice that contains any un-invoiced metered usage and new/pending proration invoice items. Defaults to true.

This is used only when cancelling a subscription schedule.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<phases> array of hashes

Configuration for the subscription schedule’s phases.

=over 12

=item I<application_fee_percent> decimal

A non-negative decimal between 0 and 100, with at most two decimal places. This represents the percentage of the subscription invoice subtotal that will be transferred to the application owner’s Stripe account during this phase of the schedule.

=item I<billing_thresholds> hash

Define thresholds at which an invoice will be sent, and the subscription advanced to a new billing period.

This is a C<Net::API::Stripe::Billing::Thresholds> object.

=over 16

=item I<amount_gte> integer

Monetary threshold that triggers the subscription to create an invoice

=item I<reset_billing_cycle_anchor> boolean

Indicates if the billing_cycle_anchor should be reset when a threshold is reached. If true, billing_cycle_anchor will be updated to the date/time the threshold was last reached; otherwise, the value will remain unchanged. This value may not be true if the subscription contains items with plans that have aggregate_usage=last_ever.

=back

=item I<collection_method> string

Either charge_automatically, or send_invoice. When charging automatically, Stripe will attempt to pay the underlying subscription at the end of each billing cycle using the default source attached to the customer. When sending an invoice, Stripe will email your customer an invoice with payment instructions.

=item I<coupon> string expandable

ID of the coupon to use during this phase of the subscription schedule. When expanded, this is a C<Net::API::Stripe::Billing::Coupon> object.

=item I<default_payment_method> string expandable

ID of the default payment method for the subscription schedule. It must belong to the customer associated with the subscription schedule. If not set, invoices will use the default payment method in the customer’s invoice settings.

When expanded, this is a C<Net::API::Stripe::Payment::Method> object.

=item I<default_tax_rates> array of C<Net::API::Stripe::Tax::Rate> objects.

=item I<end_date> timestamp

The end of this phase of the subscription schedule.

=item I<invoice_settings> hash

The subscription schedule’s default invoice settings.

=over 16

=item I<days_until_due> integer

Number of days within which a customer must pay invoices generated by this subscription schedule. This value will be null for subscription schedules where billing=charge_automatically.

=back

=item I<iterations> integer

Integer representing the multiplier applied to the plan interval. For example, iterations=2 applied to a plan with interval=month and interval_count=3 results in a phase of duration 2 * 3 months = 6 months. If set, end_date must not be set.

This option is only used in making calls to create or update a subscription schedule.

=item I<plans> array of hashes

Plans to subscribe during this phase of the subscription schedule.

=over 16

=item I<billing_thresholds> hash

Define thresholds at which an invoice will be sent, and the related subscription advanced to a new billing period

=over 20

=item I<usage_gte> integer

Usage threshold that triggers the subscription to create an invoice

=back

=item I<plan> string expandable

ID of the plan to which the customer should be subscribed. When expanded, this is a C<Net::API::Stripe::Billing::Plan> object.

=item I<quantity> positive integer or zero

Quantity of the plan to which the customer should be subscribed.

=item I<tax_rates> array of C<Net::APi::Stripe::Tax::Rate> objects.

The tax rates which apply to this phase_item. When set, the default_tax_rates on the phase do not apply to this phase_item.

=back

=item I<start_date> timestamp

The start of this phase of the subscription schedule.

=item I<trial_end> timestamp

When the trial ends within the phase.

=back

=item B<preserve_cancel_date> boolean

Keep any cancellation on the subscription that the schedule has set.

This is used only when cancelling subscription schedule.

=item B<preserve_cancel_date> boolean

Keep any cancellation on the subscription that the schedule has set.

This is used only when making a Stripe api call to release a subscription schedule.

=item B<prorate> boolean

This is only used when making B<update> or B<cancel>.

When doing an update and if the update changes the current phase, indicates if the changes should be prorated. Defaults to true.

When cancelling the subscription schedule, if the subscription schedule is active, this indicates if the cancellation should be prorated. Defaults to true.

=item B<released_at> timestamp

Time at which the subscription schedule was released. Measured in seconds since the Unix epoch.

=item B<released_subscription> string

ID of the subscription once managed by the subscription schedule (if it is released).

=item B<start_date> unix timestamp

When the subscription schedule starts. We recommend using now so that it starts the subscription immediately. You can also use a Unix timestamp to backdate the subscription so that it starts on a past date, or set a future date for the subscription to start on. When you backdate, the billing_cycle_anchor of the subscription is equivalent to the start_date.

This is used only when creating a subscription schedule.

=item B<status> string

The present status of the subscription schedule. Possible values are not_started, active, completed, released, and canceled. You can read more about the different states in our behavior guide.

=item B<subscription> string expandable

ID of the subscription managed by the subscription schedule. When expanded, this is a C<Net::API::Stripe::Billing::Subscription> object.

=back

=head1 API SAMPLE

	{
	  "id": "sub_sched_q0liaqLZs27slD",
	  "object": "subscription_schedule",
	  "canceled_at": null,
	  "completed_at": null,
	  "created": 1577193148,
	  "current_phase": null,
	  "customer": "cus_G7ucGt79A501bC",
	  "default_settings": {
		"billing_thresholds": null,
		"collection_method": "charge_automatically",
		"default_payment_method": null,
		"invoice_settings": null
	  },
	  "end_behavior": "cancel",
	  "livemode": false,
	  "metadata": {},
	  "phases": [
		{
		  "application_fee_percent": null,
		  "billing_thresholds": null,
		  "collection_method": null,
		  "coupon": null,
		  "default_payment_method": null,
		  "default_tax_rates": [],
		  "end_date": 1572481590,
		  "invoice_settings": null,
		  "plans": [
			{
			  "billing_thresholds": null,
			  "plan": "gold",
			  "quantity": 1,
			  "tax_rates": []
			}
		  ],
		  "start_date": 1541031990,
		  "tax_percent": null,
		  "trial_end": null
		}
	  ],
	  "released_at": null,
	  "released_subscription": null,
	  "status": "not_started",
	  "subscription": null
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>, L<https://stripe.com/docs/api/subscription_schedules/object>, L<https://stripe.com/docs/billing/subscriptions/subscription-schedules#managing>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

