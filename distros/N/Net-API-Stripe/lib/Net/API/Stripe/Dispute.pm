##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Dispute.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/disputes/object
package Net::API::Stripe::Dispute;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub balance_transaction { return( shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

## Array that contains Net::API::Stripe::Balance::Transaction
sub balance_transactions { return( shift->_set_get_object_array( 'balance_transactions', 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

sub charge { return( shift->_set_get_scalar_or_object( 'charge', 'Net::API::Stripe::Charge', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub disputed_transaction { return( shift->_set_get_scalar_or_object( 'disputed_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

sub evidence { return( shift->_set_get_object( 'evidence', 'Net::API::Stripe::Dispute::Evidence', @_ ) ); }

sub evidence_details { return( shift->_set_get_object( 'evidence_details', 'Net::API::Stripe::Dispute::EvidenceDetails', @_ ) ); }

sub is_charge_refundable { return( shift->_set_get_boolean( 'is_charge_refundable', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub reason { return( shift->_set_get_scalar( 'reason', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Dispute - A Stripe Dispute Object

=head1 SYNOPSIS

    my $dispute = $stripe->dispute({
        amount => 2000,
        # could also use a Net::API::Stripe::Charge object
        charge => 'ch_fake124567890',
        currency => 'jpy',
        # Or a Stripe transaction id such as trn_fake1234567890
        disputed_transaction => $transaction_object,
        evidence => $dispute_evidence_object,
        is_charge_refundable => $stripe->true,
        metadata => { transaction_id => 123, customer_id => 456 },
        reason => 'insufficient_funds',
        status => 'warning_needs_response',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    0.1

=head1 DESCRIPTION

From the documentation:

A dispute occurs when a customer questions your charge with their card issuer. When this happens, you're given the opportunity to respond to the dispute with evidence that shows that the charge is legitimate. You can find more information about the dispute process in L<Stripe Disputes and Fraud documentation|https://stripe.com/docs/disputes>.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Dispute> object.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "dispute"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> integer

Disputed amount. Usually the amount of the charge, but can differ (usually because of currency fluctuation or because only part of the order is disputed).

=item B<balance_transaction>

It seems this property is removed from the API documentation or maybe an omission?

This is an id or a L<Net::API::Stripe::Balance::Transaction> object.

=item B<balance_transactions> array, contains: balance_transaction object

List of zero, one, or two balance transactions that show funds withdrawn and reinstated to your Stripe account as a result of this dispute.

This is an array of L<Net::API::Stripe::Balance::Transaction> objects.

=item B<charge> string (expandable)

ID of the charge that was disputed or an L<Net::API::Stripe::Charge> object.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<disputed_transaction> string (expandable)

When expanded, this is a L<Net::API::Stripe::Balance::Transaction> object.

=item B<evidence> hash

Evidence provided to respond to a dispute. Updating any field in the hash will submit all fields in the hash for review.

=over 8

=item B<access_activity_log>

=item B<billing_address>

=item B<cancellation_policy>

=item B<cancellation_policy_disclosure>

=item B<cancellation_rebuttal>

=item B<customer_communication>

=item B<customer_email_address>

=item B<customer_name>

=item B<customer_purchase_ip>

=item B<customer_signature>

=item B<duplicate_charge_documentation>

=item B<duplicate_charge_explanation>

=item B<duplicate_charge_id>

=item B<product_description>

=item B<receipt>

=item B<refund_policy>

=item B<refund_policy_disclosure>

=item B<refund_refusal_explanation>

=item B<service_date>

=item B<service_documentation>

=item B<shipping_address>

=item B<shipping_carrier>

=item B<shipping_date>

=item B<shipping_documentation>

=item B<shipping_tracking_number>

=item B<uncategorized_file>

=item B<uncategorized_text>

=back

=item B<evidence_details> hash

Information about the evidence submission. This is a L<Net::API::Stripe::Dispute::EvidenceDetails> object.

=item B<is_charge_refundable> boolean

If true, it is still possible to refund the disputed payment. Once the payment has been fully refunded, no further funds will be withdrawn from your Stripe account as a result of this dispute.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<reason> string

Reason given by cardholder for dispute. Possible values are bank_cannot_process, check_returned, credit_not_processed, customer_initiated, debit_not_authorized, duplicate, fraudulent, general, incorrect_account_details, insufficient_funds, product_not_received, product_unacceptable, subscription_canceled, or unrecognized. Read more about dispute reasons.

=item B<status> string

Current status of dispute. Possible values are warning_needs_response, warning_under_review, warning_closed, needs_response, under_review, charge_refunded, won, or lost.

=back

=head1 API SAMPLE

	{
	  "id": "dp_fake123456789",
	  "object": "dispute",
	  "amount": 1000,
	  "balance_transactions": [],
	  "charge": "ch_fake123456789",
	  "created": 1571197169,
	  "currency": "jpy",
	  "evidence": {
		"access_activity_log": null,
		"billing_address": null,
		"cancellation_policy": null,
		"cancellation_policy_disclosure": null,
		"cancellation_rebuttal": null,
		"customer_communication": null,
		"customer_email_address": null,
		"customer_name": null,
		"customer_purchase_ip": null,
		"customer_signature": null,
		"duplicate_charge_documentation": null,
		"duplicate_charge_explanation": null,
		"duplicate_charge_id": null,
		"product_description": null,
		"receipt": null,
		"refund_policy": null,
		"refund_policy_disclosure": null,
		"refund_refusal_explanation": null,
		"service_date": null,
		"service_documentation": null,
		"shipping_address": null,
		"shipping_carrier": null,
		"shipping_date": null,
		"shipping_documentation": null,
		"shipping_tracking_number": null,
		"uncategorized_file": null,
		"uncategorized_text": null
	  },
	  "evidence_details": {
		"due_by": 1572911999,
		"has_evidence": false,
		"past_due": false,
		"submission_count": 0
	  },
	  "is_charge_refundable": true,
	  "livemode": false,
	  "metadata": {},
	  "reason": "general",
	  "status": "warning_needs_response"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/disputes>, L<https://stripe.com/docs/disputes>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

