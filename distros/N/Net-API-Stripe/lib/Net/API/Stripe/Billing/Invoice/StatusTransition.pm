##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Invoice/StatusTransition.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::Invoice::StatusTransition;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.100.0';
};

sub finalized_at { return( shift->_set_get_datetime( 'finalized_at', @_ ) ); }

sub marked_uncollectible_at { return( shift->_set_get_datetime( 'marked_uncollectible_at', @_ ) ); } 

sub paid_at { return( shift->_set_get_datetime( 'paid_at', @_ ) ); } 

sub voided_at { return( shift->_set_get_datetime( 'voided_at', @_ ) ); } 

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Invoice::StatusTransition - An Invoice Status Transition Object

=head1 SYNOPSIS

    my $status_trans = $invoice->status_transitions({
        finalized_at => '2020-03-17',
        # marked_uncollectible_at => '2020-04-12',
        paid_at => '2020-03-31',
        # voided_at => '2020-04-15',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This is instantiated by method B<status_transitions> in L<Net::API::Stripe::Billing::Invoice>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Billing::Invoice::StatusTransition> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<finalized_at> timestamp

The time that the invoice draft was finalized.

=item B<marked_uncollectible_at> timestamp

The time that the invoice was marked uncollectible.

=item B<paid_at> timestamp

The time that the invoice was paid.

=item B<voided_at> timestamp

The time that the invoice was voided.

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
	  "charge": "ch_fake123456789",
	  "collection_method": "charge_automatically",
	  "created": 1507273919,
	  "currency": "jpy",
	  "custom_fields": null,
	  "customer": "cus_fake123456789",
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
	  "hosted_invoice_url": "https://pay.stripe.com/invoice/invst_fake123456789",
	  "invoice_pdf": "https://pay.stripe.com/invoice/invst_fake123456789/pdf",
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

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/invoices/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
