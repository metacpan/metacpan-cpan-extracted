##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Dispute/Evidence.pm
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
## https://stripe.com/docs/api/disputes/evidence_object
package Net::API::Stripe::Dispute::Evidence;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub access_activity_log { shift->_set_get_scalar( 'access_activity_log', @_ ); }

sub billing_address { shift->_set_get_scalar( 'billing_address', @_ ); }

sub cancellation_policy { shift->_set_get_scalar_or_object( 'cancellation_policy', 'Net::API::Stripe::File', @_ ); }

sub cancellation_policy_disclosure { shift->_set_get_scalar( 'cancellation_policy_disclosure', @_ ); }

sub cancellation_rebuttal { shift->_set_get_scalar( 'cancellation_rebuttal', @_ ); }

sub customer_communication { shift->_set_get_scalar_or_object( 'customer_communication', 'Net::API::Stripe::File', @_ ); }

sub customer_email_address { shift->_set_get_scalar( 'customer_email_address', @_ ); }

sub customer_name { shift->_set_get_scalar( 'customer_name', @_ ); }

sub customer_purchase_ip { shift->_set_get_scalar( 'customer_purchase_ip', @_ ); }

sub customer_signature { shift->_set_get_scalar_or_object( 'customer_signature', 'Net::API::Stripe::File', @_ ); }

sub duplicate_charge_documentation { shift->_set_get_scalar_or_object( 'duplicate_charge_documentation', 'Net::API::Stripe::File', @_ ); }

sub duplicate_charge_explanation { shift->_set_get_scalar( 'duplicate_charge_explanation', @_ ); }

sub duplicate_charge_id { shift->_set_get_scalar( 'duplicate_charge_id', @_ ); }

sub product_description { shift->_set_get_scalar( 'product_description', @_ ); }

sub receipt { shift->_set_get_scalar_or_object( 'receipt', 'Net::API::Stripe::File', @_ ); }

sub refund_policy { shift->_set_get_scalar_or_object( 'refund_policy', 'Net::API::Stripe::File', @_ ); }

sub refund_policy_disclosure { shift->_set_get_scalar( 'refund_policy_disclosure', @_ ); }

sub refund_refusal_explanation { shift->_set_get_scalar( 'refund_refusal_explanation', @_ ); }

sub service_date { shift->_set_get_scalar( 'service_date', @_ ); }

sub service_documentation { shift->_set_get_scalar_or_object( 'service_documentation', 'Net::API::Stripe::File', @_ ); }

sub shipping_address { shift->_set_get_scalar( 'shipping_address', @_ ); }

sub shipping_carrier { shift->_set_get_scalar( 'shipping_carrier', @_ ); }

sub shipping_date { shift->_set_get_scalar( 'shipping_date', @_ ); }

sub shipping_documentation { shift->_set_get_scalar_or_object( 'shipping_documentation', 'Net::API::Stripe::File', @_ ); }

sub shipping_tracking_number { shift->_set_get_scalar( 'shipping_tracking_number', @_ ); }

sub uncategorized_file { shift->_set_get_scalar_or_object( 'uncategorized_file', 'Net::API::Stripe::File', @_ ); }

sub uncategorized_text { shift->_set_get_scalar( 'uncategorized_text', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Balance - An interface to Stripe API

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

A dispute occurs when a customer questions your charge with their card issuer. When this happens, you're given the opportunity to respond to the dispute with evidence that shows that the charge is legitimate. You can find more information about the dispute process in our Disputes and Fraud (L<https://stripe.com/docs/disputes>) documentation.

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

=item B<access_activity_log> string

Any server or activity logs showing proof that the customer accessed or downloaded the purchased digital product. This information should include IP addresses, corresponding timestamps, and any detailed recorded activity.

=item B<billing_address> string

The billing address provided by the customer.

=item B<cancellation_policy> string (expandable)

(ID of a file upload) Your subscription cancellation policy, as shown to the customer.

When expanded, this is a C<Net::API::Stripe::File> object.

=item B<cancellation_policy_disclosure> string

An explanation of how and when the customer was shown your refund policy prior to purchase.

=item B<cancellation_rebuttal> string

A justification for why the customer’s subscription was not canceled.

=item B<customer_communication> string (expandable)

(ID of a file upload) Any communication with the customer that you feel is relevant to your case. Examples include emails proving that the customer received the product or service, or demonstrating their use of or satisfaction with the product or service.

When expanded, this is a C<Net::API::Stripe::File> object.

=item B<customer_email_address> string

The email address of the customer.

=item B<customer_name> string

The name of the customer.

=item B<customer_purchase_ip> string

The IP address that the customer used when making the purchase.

=item B<customer_signature> string (expandable)

(ID of a file upload) A relevant document or contract showing the customer’s signature.

When expanded, this is a C<Net::API::Stripe::File> object.

=item B<duplicate_charge_documentation> string (expandable)

(ID of a file upload) Documentation for the prior charge that can uniquely identify the charge, such as a receipt, shipping label, work order, etc. This document should be paired with a similar document from the disputed payment that proves the two payments are separate.

When expanded, this is a C<Net::API::Stripe::File> object.

=item B<duplicate_charge_explanation> string

An explanation of the difference between the disputed charge versus the prior charge that appears to be a duplicate.

=item B<duplicate_charge_id> string

The Stripe ID for the prior charge which appears to be a duplicate of the disputed charge.

=item B<product_description> string

A description of the product or service that was sold.

=item B<receipt> string (expandable)

(ID of a file upload) Any receipt or message sent to the customer notifying them of the charge.

When expanded, this is a C<Net::API::Stripe::File> object.

=item B<refund_policy> string (expandable)

(ID of a file upload) Your refund policy, as shown to the customer.

When expanded, this is a C<Net::API::Stripe::File> object.

=item B<refund_policy_disclosure> string

Documentation demonstrating that the customer was shown your refund policy prior to purchase.

=item B<refund_refusal_explanation> string

A justification for why the customer is not entitled to a refund.

=item B<service_date> string

The date on which the customer received or began receiving the purchased service, in a clear human-readable format.

=item B<service_documentation> string (expandable)

(ID of a file upload) Documentation showing proof that a service was provided to the customer. This could include a copy of a signed contract, work order, or other form of written agreement.

When expanded, this is a C<Net::API::Stripe::File> object.

=item B<shipping_address> string

The address to which a physical product was shipped. You should try to include as complete address information as possible.

=item B<shipping_carrier> string

The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc. If multiple carriers were used for this purchase, please separate them with commas.

=item B<shipping_date> string

The date on which a physical product began its route to the shipping address, in a clear human-readable format.

=item B<shipping_documentation> string (expandable)

(ID of a file upload) Documentation showing proof that a product was shipped to the customer at the same address the customer provided to you. This could include a copy of the shipment receipt, shipping label, etc. It should show the customer’s full shipping address, if possible.

=item B<shipping_tracking_number> string

The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.

=item B<uncategorized_file> string (expandable)

(ID of a file upload) Any additional evidence or statements.

=item B<uncategorized_text> string

Any additional evidence or statements.

=back

=head1 API SAMPLE

	{
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
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/disputes/evidence_object#dispute_evidence_object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
