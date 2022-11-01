##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Subscription/Item.pm
## Version v0.1.1
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/subscription_items/object
package Net::API::Stripe::Billing::Subscription::Item;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.1.1';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub billing_thresholds { return( shift->_set_get_object( 'billing_thresholds', 'Net::API::Stripe::Billing::Thresholds', @_ ) ); }

## Used in upcoming invoice api calls
sub clear_usage { return( shift->_set_get_boolean( 'clear_usage', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub deleted { return( shift->_set_get_boolean( 'deleted', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub plan { return( shift->_set_get_object( 'plan', 'Net::API::Stripe::Billing::Plan', @_ ) ); }

sub price { return( shift->_set_get_object( 'price', 'Net::API::Stripe::Price', @_ ) ); }

sub quantity { return( shift->_set_get_number( 'quantity', @_ ) ); }

sub subscription { return( shift->_set_get_scalar( 'subscription', @_ ) ); }

sub tax_rates { return( shift->_set_get_object_array( 'tax_rates', 'Net::API::Stripe::Tax::Rate', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Subscription::Item - A Stripe Subscription Item Object

=head1 SYNOPSIS

    my $item = $stripe->subscription_item({
        clear_usage => 1,
        metadata => { transaction_id => 1212, customer_id => 123 },
        quantity => 1,
        subscription => 'sub_fake123456789',
    });

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

Subscription items allow you to create customer subscriptions with more than one plan, making it easy to represent complex billing relationships.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Billing::Subscription::Item> object.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "subscription_item"

String representing the object’s type. Objects of the same type share the same value.

=head2 billing_thresholds hash

Define thresholds at which an invoice will be sent, and the related subscription advanced to a new billing period

This is a L<Net::API::Stripe::Billing::Thresholds> object.

=over 4

=item I<usage_gte> integer

Usage threshold that triggers the subscription to create an invoice

=back

=head2 clear_usage() optional

Delete all usage for a given subscription item. Allowed only when deleted is set to true and the current plan’s usage_type is metered.

This is used in making upcoming invoice items api calls as described here: L<https://stripe.com/docs/api/invoices/upcoming_invoice_lines>

=head2 created integer

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 deleted optional

A flag that, if set to true, will delete the specified item.

This is used in making upcoming invoice items api calls as described here: L<https://stripe.com/docs/api/invoices/upcoming_invoice_lines>

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 plan hash, plan object

Hash describing the plan the customer is subscribed to.

This is a L<Net::API::Stripe::Billing::Plan> object.

=head2 price object

The price the customer is subscribed to.

This is a L<Net::API::Stripe::Price> object.

=head2 quantity positive integer or zero

The quantity of the plan to which the customer should be subscribed.

=head2 subscription string

The subscription this subscription_item belongs to.

=head2 tax_rates array of hashes

The tax rates which apply to this subscription_item. When set, the default_tax_rates on the subscription do not apply to this subscription_item.

This is an array of L<Net::API::Stripe::Tax::Rate> objects.

=head1 API SAMPLE

    {
      "id": "si_fake123456789",
      "object": "subscription_item",
      "billing_thresholds": null,
      "created": 1571397912,
      "metadata": {},
      "plan": {
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
      },
      "quantity": 1,
      "subscription": "sub_fake123456789",
      "tax_rates": []
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head2 v0.1.1

Added the methods clear_usage and deleted used in making upcoming invoice item api calls as explained here L<https://stripe.com/docs/api/invoices/upcoming_invoice_lines>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/subscription_items>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
