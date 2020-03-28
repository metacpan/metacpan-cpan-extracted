##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Thresholds.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::Thresholds;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub amount_gte { return( shift->_set_get_scalar( 'amount_gte', @_ ) ); }

sub item_reasons { return( shift->_set_get_hash_as_object( 'item_reasons', 'Net::API::Stripe::Billing::Thresholds::ItemReasons', @_ ) ); }

sub reset_billing_cycle_anchor { return( shift->_set_get_scalar( 'reset_billing_cycle_anchor', @_ ) ); }

sub usage_gte { return( shift->_set_get_scalar( 'usage_gte', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Thresholds - A Stripe Billing Thresholds Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

Define thresholds at which an invoice will be sent, and the subscription advanced to a new billing period

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

=item B<amount_gte> integer

Monetary threshold that triggers the subscription to create an invoice

=item B<item_reasons> array of hashes

Indicates which line items triggered a threshold invoice.

This is an array of C<Net::API::Stripe::Billing::Thresholds::ItemReasons> objects.

=item B<reset_billing_cycle_anchor> boolean

Indicates if the billing_cycle_anchor should be reset when a threshold is reached. If true, billing_cycle_anchor will be updated to the date/time the threshold was last reached; otherwise, the value will remain unchanged. This value may not be true if the subscription contains items with plans that have aggregate_usage=last_ever.

=item B<usage_gte> integer

The quantity threshold boundary that applied to the given line item.

=back

=head1 API SAMPLE

	{
	  "id": "sub_EccdFNq60pUMDL",
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
		"product": "prod_Dwk1QNPjrMJlY8",
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

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
