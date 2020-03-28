##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Invoice/Period.pm
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
package Net::API::Stripe::Billing::Invoice::Period;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub end { shift->_set_get_datetime( 'end', @_ ); }

sub start { shift->_set_get_datetime( 'start', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Invoice::Period - A Stripe Invoice Period Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

The timespan covered by this invoice item.

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

=item B<end> integer

End of the line item’s billing period

=item B<start> integer

Start of the line item’s billing period

=back

=head1 API SAMPLE

	{
	  "id": "in_1B9q03CeyNCl6fY2YNPu6oqa",
	  "object": "invoice",
	  "account_country": "JP",
	  "account_name": "Angels, Inc",
	  "amount_due": 8000,
	  "amount_paid": 8000,
	  "amount_remaining": 0,
	  "application_fee_amount": null,
	  "attempt_count": 1,
	  "attempted": true,
	  "auto_advance": false,
	  "billing": "charge_automatically",
	  "billing_reason": "subscription",
	  "charge": "ch_1B9q03CeyNCl6fY2wu5siR6R",
	  "collection_method": "charge_automatically",
	  "created": 1507273919,
	  "currency": "jpy",
	  "custom_fields": null,
	  "customer": "cus_G0vQn57xCoD5rG",
	  "customer_address": null,
	  "customer_email": "florian@111studio.jp",
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
	  "hosted_invoice_url": "https://pay.stripe.com/invoice/invst_XvyJuu53kQe203lIDyXEYxa7Lh",
	  "invoice_pdf": "https://pay.stripe.com/invoice/invst_XvyJuu53kQe203lIDyXEYxa7Lh/pdf",
	  "lines": {
		"data": [
		  {
			"id": "sli_be2a0c3589f761",
			"object": "line_item",
			"amount": 8000,
			"currency": "jpy",
			"description": "1 × Angels, Inc professional monthly membership (at ¥8,000 / month)",
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
			  "product": "prod_Dwk1QNPjrMJlY8",
			  "tiers": null,
			  "tiers_mode": null,
			  "transform_usage": null,
			  "trial_period_days": null,
			  "usage_type": "licensed"
			},
			"proration": false,
			"quantity": 1,
			"subscription": "sub_EccdFNq60pUMDL",
			"subscription_item": "si_Eccd4op26fXydB",
			"tax_amounts": [],
			"tax_rates": [],
			"type": "subscription"
		  }
		],
		"has_more": false,
		"object": "list",
		"url": "/v1/invoices/in_1B9q03CeyNCl6fY2YNPu6oqa/lines"
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
	  "subscription": "sub_BWtnk6Km6GOapC",
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

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/invoices/line_item>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
