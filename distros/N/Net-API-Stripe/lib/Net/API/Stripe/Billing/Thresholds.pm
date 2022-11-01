##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Thresholds.pm
## Version v0.101.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::Thresholds;
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

sub amount_gte { return( shift->_set_get_number( 'amount_gte', @_ ) ); }

sub item_reasons { return( shift->_set_get_class_array( 'item_reasons',
{
  line_item_ids => { type => "array" },
  usage_gte     => { type => "number" },
}, @_ ) ); }

sub reset_billing_cycle_anchor { return( shift->_set_get_scalar( 'reset_billing_cycle_anchor', @_ ) ); }

sub usage_gte { return( shift->_set_get_scalar( 'usage_gte', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Thresholds - A Stripe Billing Thresholds Object

=head1 SYNOPSIS

    my $obj = $subscription->billing_thresholds({
        amount_gte => 1000,
        reset_billing_cycle_anchor => $stripe->true,
    });

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

Define thresholds at which an invoice will be sent, and the subscription advanced to a new billing period

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Billing::Thresholds> object.

=head1 METHODS

=head2 amount_gte integer

Monetary threshold that triggers the subscription to create an invoice

=head2 item_reasons array of hash

Indicates which line items triggered a threshold invoice.

It has the following properties:

=over 4

=item C<line_item_ids> string_array

The IDs of the line items that triggered the threshold invoice.

=item C<usage_gte> integer

The quantity threshold boundary that applied to the given line item.

=back

=head2 reset_billing_cycle_anchor boolean

Indicates if the billing_cycle_anchor should be reset when a threshold is reached. If true, billing_cycle_anchor will be updated to the date/time the threshold was last reached; otherwise, the value will remain unchanged. This value may not be true if the subscription contains items with plans that have aggregate_usage=last_ever.

=head2 usage_gte integer

The quantity threshold boundary that applied to the given line item.

=head1 API SAMPLE

    {
      "id": "sub_fake123456789",
      "object": "subscription",
      "application_fee_percent": null,
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
      "next_pending_invoice_item_invoice": null,
      "pending_invoice_item_interval": null,
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

L<https://stripe.com/docs/api/subscriptions/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
