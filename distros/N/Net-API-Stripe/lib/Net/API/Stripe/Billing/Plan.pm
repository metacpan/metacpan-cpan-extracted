##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Plan.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## The product in Billing is the same as the core Product class.
## https://stripe.com/docs/api/service_products/object

## For product objects, see Net::API::Stripe::Product
package Net::API::Stripe::Billing::Plan;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub active { return( shift->_set_get_boolean( 'active', @_ ) ); }

sub aggregate_usage { return( shift->_set_get_scalar( 'aggregate_usage', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub amount_decimal { return( shift->_set_get_number( 'amount_decimal', @_ ) ); }

sub billing_scheme { return( shift->_set_get_scalar( 'billing_scheme', @_ ) ); }

## Not part of the official api documentation, but found in sub object data like in here
## https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card-installments
sub count { return( shift->_set_get_number( 'count', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub deleted { return( shift->_set_get_boolean( 'deleted', @_ ) ); }

sub interval { return( shift->_set_get_scalar( 'interval', @_ ) ); }

sub interval_count { return( shift->_set_get_scalar( 'interval_count', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub nickname { return( shift->_set_get_scalar( 'nickname', @_ ) ); }

sub product { return( shift->_set_get_scalar_or_object( 'product', 'Net::API::Stripe::Product', @_ ) ); }

sub statement_description { return( shift->_set_get_scalar( 'statement_description', @_ ) ); }

sub statement_descriptor { return( shift->_set_get_scalar( 'statement_descriptor', @_ ) ); }

sub tiers { return( shift->_set_get_object( 'tiers', 'Net::API::Stripe::Billing::Plan::Tiers', @_ ) ); }

sub tiers_mode { return( shift->_set_get_scalar( 'tiers_mode', @_ ) ); }

sub transform_usage { return( shift->_set_get_object( 'transform_usage', 'Net::API::Stripe::Billing::Plan::TransformUsage', @_ ) ); }

sub trial_period_days { return( shift->_set_get_number( 'trial_period_days', @_ ) ); }

## Not part of the official api documentation, but found in sub object data like in here
## https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card-installments
sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub usage_type { return( shift->_set_get_scalar( 'usage_type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Plan - A Stripe Plan Object

=head1 SYNOPSIS

    my $plan = $stripe->plan({
        # Or you can just use 1. $stripe->true returns a Module::Generic::Boolean object
        active => $stripe->true,
        amount => 2000,
        billing_scheme => 'per_unit',
        count => 12,
        currency => 'jpy',
        interval => 'month',
        interval_count => 1,
        metadata => { transaction_id => 1212, customer_id => 123 },
        name => 'Professional services subscription gold plan',
        statement_description => 'Provider, Inc Pro Services',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Plans define the base price, currency, and billing cycle for subscriptions. For example, you might have a ¥5/month plan that provides limited access to your products, and a ¥15/month plan that allows full access.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Billing::Plan> object.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "plan"

String representing the object’s type. Objects of the same type share the same value.

=head2 active boolean

Whether the plan is currently available for new subscriptions.

=head2 aggregate_usage string

Specifies a usage aggregation strategy for plans of I<usage_type=metered>. Allowed values are I<sum> for summing up all usage during a period, I<last_during_period> for picking the last usage record reported within a period, I<last_ever> for picking the last usage record ever (across period bounds) or I<max> which picks the usage record with the maximum reported usage during a period. Defaults to I<sum>.

=head2 amount positive integer or zero

The amount in JPY to be charged on the interval specified.

=head2 amount_decimal decimal string

Same as I<amount>, but contains a decimal value with at most 12 decimal places.

=head2 billing_scheme string

Describes how to compute the price per period. Either I<per_unit> or I<tiered>. I<per_unit> indicates that the fixed amount (specified in I<amount>) will be charged per unit in I<quantity> (for plans with I<usage_type=licensed>), or per unit of total usage (for plans with I<usage_type=metered>). I<tiered> indicates that the unit pricing will be computed using a tiering strategy as defined using the I<tiers> and I<tiers_mode> attributes.

=head2 count integer

For fixed_count installment plans, this is the number of installment payments your customer will make to their credit card.

Not part of the official api documentation, but found in sub object data like in here
L<https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card-installments>

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 deleted boolean

Appears only when the plan has been deleted.

=head2 interval string

One of I<day>, I<week>, I<month> or I<year>. The frequency with which a subscription should be billed.

=head2 interval_count positive integer

The number of intervals (specified in the I<interval> property) between subscription billings. For example, I<interval=month> and I<interval_count=3> bills every 3 months.

=head2 livemode boolean

Has the value I<true> if the object exists in live mode or the value I<false> if the object exists in test mode.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 name string

This is an undocumented property, which appears in data returned by Stripe. This contains the name of the plan.

=head2 nickname string

A brief description of the plan, hidden from customers.

=head2 product string (expandable)

The product whose pricing this plan determines. When expanded, this is a L<Net::API::Stripe::Product> object.

=head2 statement_description string

This is an undocumented property, which appears in data returned by Stripe. This contains a description of the plan.

=head2 statement_descriptor string

This is an undocumented property, which appears in data returned by Stripe. This contains a description of the plan.

=head2 tiers array of hashes

Each element represents a pricing tier. This parameter requires I<billing_scheme> to be set to I<tiered>. See also the documentation for I<billing_scheme>.

This is an array of L<Net::API::Stripe::Billing::Plan::Tiers> objects.

=head2 tiers_mode string

Defines if the tiering price should be graduated or volume based. In volume-based tiering, the maximum quantity within a period determines the per unit price, in graduated tiering pricing can successively change as the quantity grows.

=head2 transform_usage hash

Apply a transformation to the reported usage or set quantity before computing the billed price. Cannot be combined with tiers.

This is a L<Net::API::Stripe::Billing::Plan::TransformUsage> object.

=head2 trial_period_days positive integer

Default number of trial days when subscribing a customer to this plan using I<trial_from_plan=true>.

=head2 type string

Type of installment plan, one of fixed_count.

Not part of the official api documentation, but found in sub object data like in here
L<https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card-installments>

=head2 usage_type string

Configures how the quantity per period should be determined, can be either I<metered> or I<licensed>. I<licensed> will automatically bill the I<quantity> set for a plan when adding it to a subscription, I<metered> will aggregate the total usage based on usage records. Defaults to I<licensed>.

=head1 API SAMPLE

    {
      "id": "expert-monthly-jpy",
      "object": "plan",
      "active": true,
      "aggregate_usage": null,
      "amount": 8000,
      "amount_decimal": "8000",
      "billing_scheme": "per_unit",
      "created": 1507273129,
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
    }

=head1 ACTUAL API DATA RETURNED

As you can see, there are extra properties: I<name>, I<statement_description> and I<statement_descriptior>

    {
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
        "name": "MyShop, Inc monthly membership",
        "nickname": null,
        "product": "prod_fake123456789",
        "statement_description": null,
        "statement_descriptor": null,
        "tiers": null,
        "tiers_mode": null,
        "transform_usage": null,
        "trial_period_days": null,
        "usage_type": "licensed"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2018-02-05

Each plan object is now linked to a product object with I<type=service>. The plan object fields I<statement_descriptor> and I<name> attributes have been moved to product objects. Creating a plan now requires passing a I<product> attribute to I<POST /v1/plans>. This may be either an existing product ID or a dictionary of product fields, so that you may continue to create plans without separately creating products.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/plans>, L<https://stripe.com/docs/billing/subscriptions/products-and-plans>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
