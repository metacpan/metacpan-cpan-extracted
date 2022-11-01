##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Subscription/Schedule.pm
## Version v0.101.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/12/25
## Modified 2022/10/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::Subscription::Schedule;
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

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub application { return( shift->_set_get_scalar_or_object( 'application', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub canceled_at { return( shift->_set_get_datetime( 'canceled_at', @_ ) ); }

sub completed_at { return( shift->_set_get_datetime( 'completed_at', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub current_phase
{
    return( shift->_set_get_class( 'current_phase',
        {
        end_date    => { type => 'datetime' },
        start_date    => { type => 'datetime' },
        }, @_ )
    );
}

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub default_settings { return( shift->_set_get_object( 'default_settings', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub end_behavior { return( shift->_set_get_scalar( 'end_behavior', @_ ) ); }

sub from_subscription { return( shift->_set_get_scalar_or_object( 'from_subscription', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub invoice_now { return( shift->_set_get_boolean( 'invoice_now', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub phases { return( shift->_set_get_object_array( 'phases', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub preserve_cancel_date { return( shift->_set_get_boolean( 'preserve_cancel_date', @_ ) ); }

sub prorate { return( shift->_set_get_boolean( 'prorate', @_ ) ); }

sub proration_behavior { return( shift->_set_get_scalar( 'proration_behavior', @_ ) ); }

sub released_at { return( shift->_set_get_datetime( 'released_at', @_ ) ); }

sub released_subscription { return( shift->_set_get_scalar( 'released_subscription', @_ ) ); }

sub renewal_interval { return( shift->_set_get_scalar( 'renewal_interval', @_ ) ); }

sub start_date { return( shift->_set_get_datetime( 'start_date', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub subscription { return( shift->_set_get_scalar_or_object( 'subscription', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

## Undocumented but appears in data returned

sub tax_percent { return( shift->_set_get_number( 'tax_percent', @_ ) ); }

## Undocumented but appears in data returned

sub test_clock { return( shift->_set_get_scalar_or_object( 'test_clock', 'Net::API::Stripe::Billing::TestHelpersTestClock', @_ ) ); }

sub transfer_data
{
    return( shift->_set_get_class( 'transfer_data',
    {
    amount_percent  => { type => 'number' },
    destination     => { type => 'object', class => 'Net::API::Stripe::Connect::Account' },
    }, @_ ) );
}

## Undocumented but appears in data returned

sub trial_end { return( shift->_set_get_datetime( 'trial_end', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Subscription::Schedule - A Stripe Subscription Schedule Object

=head1 SYNOPSIS

    my $sched = $stripe->schedule({
        customer => $customer_object,
        invoice_now => 1,
        end_behavior => 'release',
    });

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

A subscription schedule allows you to create and manage the lifecycle of a subscription by predefining expected changes.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Billing::Subscription::Schedule> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is C<subscription_schedule>

String representing the object’s type. Objects of the same type share the same value.

=head2 application expandable

ID of the Connect Application that created the schedule.

When expanded this is an L<Net::API::Stripe::Connect::Account> object.

=head2 canceled_at timestamp

Time at which the subscription schedule was canceled. Measured in seconds since the Unix epoch.

=head2 completed_at timestamp

Time at which the subscription schedule was completed. Measured in seconds since the Unix epoch.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 current_phase hash

Object representing the start and end dates for the current phase of the subscription schedule, if it is active.

=over 4

=item I<end_date> timestamp

=item I<start_date> timestamp

=back

=head2 customer string expandable

ID of the customer who owns the subscription schedule. When expanded, this is a L<Net::API::Stripe::Customer> object.

=head2 default_settings object

Object representing the subscription schedule's default settings.

This is a L<Net::API::Stripe::Billing::Subscription> object.

=head2 end_behavior string

Configures how the subscription schedule behaves when it ends. Possible values are I<release> or I<cancel> with the default being release. release will end the subscription schedule and keep the underlying subscription running.cancel will end the subscription schedule and cancel the underlying subscription. 

=head2 from_subscription string

Migrate an existing subscription to be managed by a subscription schedule. If this parameter is set, a subscription schedule will be created using the subscription’s plan(s), set to auto-renew using the subscription’s interval. When using this parameter, other parameters (such as phase values) cannot be set. To create a subscription schedule with other modifications, Stripe recommends making two separate API calls.

This is used only when creating a subscription schedule.

=head2 invoice_now boolean

If the subscription schedule is active, indicates whether or not to generate a final invoice that contains any un-invoiced metered usage and new/pending proration invoice items. Defaults to true.

This is used only when cancelling a subscription schedule.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 phases array of objects

Configuration for the subscription schedule's phases.

This is a L<Net::API::Stripe::Billing::Subscription> object.

=head2 preserve_cancel_date boolean

Keep any cancellation on the subscription that the schedule has set.

This is used only when making a Stripe api call to release a subscription schedule.

=head2 prorate boolean

This is only used when making B<update> or B<cancel>.

When doing an update and if the update changes the current phase, indicates if the changes should be prorated. Defaults to true.

When cancelling the subscription schedule, if the subscription schedule is active, this indicates if the cancellation should be prorated. Defaults to true.

=head2 proration_behavior string

Determines how to handle prorations resulting from the billing_cycle_anchor. Valid values are I<create_prorations> or I<none>.

Passing I<create_prorations> will cause proration invoice items to be created when applicable. Prorations can be disabled by passing I<none>. If no value is passed, the default is create_prorations.

This property is not documented on Stripe api documentation, but appears in data returned as of 2020-12-02.

=head2 released_at timestamp

Time at which the subscription schedule was released. Measured in seconds since the Unix epoch.

=head2 released_subscription string

ID of the subscription once managed by the subscription schedule (if it is released).

=head2 renewal_interval

This property was found in the data returned from Stripe, but is not documented yet as of 2020-12-03.

=head2 start_date unix timestamp

When the subscription schedule starts. Stripe recommends using now so that it starts the subscription immediately. You can also use a Unix timestamp to backdate the subscription so that it starts on a past date, or set a future date for the subscription to start on. When you backdate, the billing_cycle_anchor of the subscription is equivalent to the start_date.

This is used only when creating a subscription schedule.

=head2 status string

The present status of the subscription schedule. Possible values are not_started, active, completed, released, and canceled. You can read more about the different states in Stripe behavior guide.

=head2 subscription string expandable

ID of the subscription managed by the subscription schedule. When expanded, this is a L<Net::API::Stripe::Billing::Subscription> object.

=head2 tax_percent decimal (deprecated)

A non-negative decimal (with at most four decimal places) between 0 and 100. This represents the percentage of the subscription invoice subtotal that will be calculated and added as tax to the final amount in each billing period. For example, a plan which charges $10/month with a tax_percent of 20.0 will charge $12 per invoice. To unset a previously-set value, pass an empty string. This field has been deprecated and will be removed in a future API version, for further information view the migration docs for tax_rates.

This is an undocumented property for Subscription Schedule that usually belonging to L<Subscription|Net::API::Stripe::Billing::Subscription>, but that appears in data returned by Stripe.

=head2 test_clock expandable

ID of the test clock this subscription schedule belongs to.

When expanded this is an L<Net::API::Stripe::Billing::TestHelpersTestClock> object.

=head2 transfer_data hash

This is for Connect only.

The account (if any) the subscription’s payments will be attributed to for tax reporting, and where funds from each payment will be transferred to for each of the subscription’s invoices.

This is an undocumented property for Subscription Schedule that usually belonging to L<Subscription|Net::API::Stripe::Billing::Subscription>, but that appears in data returned by Stripe.

=over 4

=item I<amount_percent> decimal

A non-negative decimal between 0 and 100, with at most two decimal places. This represents the percentage of the subscription invoice subtotal that will be transferred to the destination account. By default, the entire amount is transferred to the destination.

=item I<destination> string expandable

The account where funds from the payment will be transferred to upon payment success.

=back

=head2 trial_end timestamp

If the subscription has a trial, the end of that trial.

This is an undocumented property for Subscription Schedule that usually belonging to L<Subscription|Net::API::Stripe::Billing::Subscription>, but that appears in data returned by Stripe.

=head1 API SAMPLE

    {
      "id": "sub_sched_fake123456789",
      "object": "subscription_schedule",
      "canceled_at": null,
      "completed_at": null,
      "created": 1577193148,
      "current_phase": null,
      "customer": "cus_fake123456789",
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

See also L<use cases|https://stripe.com/docs/billing/subscriptions/subscription-schedules/use-cases>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
