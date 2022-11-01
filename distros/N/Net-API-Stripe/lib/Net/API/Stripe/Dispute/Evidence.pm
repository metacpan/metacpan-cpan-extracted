##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Dispute/Evidence.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/disputes/evidence_object
package Net::API::Stripe::Dispute::Evidence;
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

sub access_activity_log { return( shift->_set_get_scalar( 'access_activity_log', @_ ) ); }

sub billing_address { return( shift->_set_get_scalar( 'billing_address', @_ ) ); }

sub cancellation_policy { return( shift->_set_get_scalar_or_object( 'cancellation_policy', 'Net::API::Stripe::File', @_ ) ); }

sub cancellation_policy_disclosure { return( shift->_set_get_scalar( 'cancellation_policy_disclosure', @_ ) ); }

sub cancellation_rebuttal { return( shift->_set_get_scalar( 'cancellation_rebuttal', @_ ) ); }

sub customer_communication { return( shift->_set_get_scalar_or_object( 'customer_communication', 'Net::API::Stripe::File', @_ ) ); }

sub customer_email_address { return( shift->_set_get_scalar( 'customer_email_address', @_ ) ); }

sub customer_name { return( shift->_set_get_scalar( 'customer_name', @_ ) ); }

sub customer_purchase_ip { return( shift->_set_get_scalar( 'customer_purchase_ip', @_ ) ); }

sub customer_signature { return( shift->_set_get_scalar_or_object( 'customer_signature', 'Net::API::Stripe::File', @_ ) ); }

sub duplicate_charge_documentation { return( shift->_set_get_scalar_or_object( 'duplicate_charge_documentation', 'Net::API::Stripe::File', @_ ) ); }

sub duplicate_charge_explanation { return( shift->_set_get_scalar( 'duplicate_charge_explanation', @_ ) ); }

sub duplicate_charge_id { return( shift->_set_get_scalar( 'duplicate_charge_id', @_ ) ); }

sub product_description { return( shift->_set_get_scalar( 'product_description', @_ ) ); }

sub receipt { return( shift->_set_get_scalar_or_object( 'receipt', 'Net::API::Stripe::File', @_ ) ); }

sub refund_policy { return( shift->_set_get_scalar_or_object( 'refund_policy', 'Net::API::Stripe::File', @_ ) ); }

sub refund_policy_disclosure { return( shift->_set_get_scalar( 'refund_policy_disclosure', @_ ) ); }

sub refund_refusal_explanation { return( shift->_set_get_scalar( 'refund_refusal_explanation', @_ ) ); }

sub service_date { return( shift->_set_get_scalar( 'service_date', @_ ) ); }

sub service_documentation { return( shift->_set_get_scalar_or_object( 'service_documentation', 'Net::API::Stripe::File', @_ ) ); }

sub shipping_address { return( shift->_set_get_scalar( 'shipping_address', @_ ) ); }

sub shipping_carrier { return( shift->_set_get_scalar( 'shipping_carrier', @_ ) ); }

sub shipping_date { return( shift->_set_get_scalar( 'shipping_date', @_ ) ); }

sub shipping_documentation { return( shift->_set_get_scalar_or_object( 'shipping_documentation', 'Net::API::Stripe::File', @_ ) ); }

sub shipping_tracking_number { return( shift->_set_get_scalar( 'shipping_tracking_number', @_ ) ); }

sub uncategorized_file { return( shift->_set_get_scalar_or_object( 'uncategorized_file', 'Net::API::Stripe::File', @_ ) ); }

sub uncategorized_text { return( shift->_set_get_scalar( 'uncategorized_text', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Dispute::Evidence - A Stripe Dispute Evidence Object

=head1 SYNOPSIS

    my $evidence = $stripe->dispute->evidence({
        access_activity_log => null,
        billing_address => '1-2-3 Kudan-Minami, Chiyoda-ku',
        cancellation_policy => undef,
        cancellation_policy_disclosure => undef,
        cancellation_rebuttal => undef,
        customer_communication => undef,
        customer_email_address => 'john.doe@example.com',
        customer_name => 'John Doe',
        customer_purchase_ip => '1.2.3.4',
        customer_signature => undef,
        duplicate_charge_documentation => undef,
        duplicate_charge_explanation => undef,
        duplicate_charge_id => undef,
        product_description => 'Professional service',
        receipt => undef,
        refund_policy => undef,
        refund_policy_disclosure => undef,
        refund_refusal_explanation => 'Customer has already used Big Corp, Inc service billed',
        service_date => '2020-04-07',
        service_documentation => undef,
        shipping_address => undef,
        shipping_carrier => undef,
        shipping_date => undef,
        shipping_documentation => undef,
        shipping_tracking_number => undef,
        uncategorized_file => undef,
        uncategorized_text => undef,
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

A dispute occurs when a customer questions your charge with their card issuer. When this happens, you're given the opportunity to respond to the dispute with evidence that shows that the charge is legitimate. You can find more information about the dispute process in L<Stripe Disputes and Fraud documentation|https://stripe.com/docs/disputes>.

This is instantiated by method B<evidence> in module L<Net::API::Stripe::Dispute>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Dispute::Evidence> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 access_activity_log string

Any server or activity logs showing proof that the customer accessed or downloaded the purchased digital product. This information should include IP addresses, corresponding timestamps, and any detailed recorded activity.

=head2 billing_address string

The billing address provided by the customer.

=head2 cancellation_policy string (expandable)

(ID of a file upload) Your subscription cancellation policy, as shown to the customer.

When expanded, this is a L<Net::API::Stripe::File> object.

=head2 cancellation_policy_disclosure string

An explanation of how and when the customer was shown your refund policy prior to purchase.

=head2 cancellation_rebuttal string

A justification for why the customer’s subscription was not canceled.

=head2 customer_communication string (expandable)

(ID of a file upload) Any communication with the customer that you feel is relevant to your case. Examples include emails proving that the customer received the product or service, or demonstrating their use of or satisfaction with the product or service.

When expanded, this is a L<Net::API::Stripe::File> object.

=head2 customer_email_address string

The email address of the customer.

=head2 customer_name string

The name of the customer.

=head2 customer_purchase_ip string

The IP address that the customer used when making the purchase.

=head2 customer_signature string (expandable)

(ID of a file upload) A relevant document or contract showing the customer’s signature.

When expanded, this is a L<Net::API::Stripe::File> object.

=head2 duplicate_charge_documentation string (expandable)

(ID of a file upload) Documentation for the prior charge that can uniquely identify the charge, such as a receipt, shipping label, work order, etc. This document should be paired with a similar document from the disputed payment that proves the two payments are separate.

When expanded, this is a L<Net::API::Stripe::File> object.

=head2 duplicate_charge_explanation string

An explanation of the difference between the disputed charge versus the prior charge that appears to be a duplicate.

=head2 duplicate_charge_id string

The Stripe ID for the prior charge which appears to be a duplicate of the disputed charge.

=head2 product_description string

A description of the product or service that was sold.

=head2 receipt string (expandable)

(ID of a file upload) Any receipt or message sent to the customer notifying them of the charge.

When expanded, this is a L<Net::API::Stripe::File> object.

=head2 refund_policy string (expandable)

(ID of a file upload) Your refund policy, as shown to the customer.

When expanded, this is a L<Net::API::Stripe::File> object.

=head2 refund_policy_disclosure string

Documentation demonstrating that the customer was shown your refund policy prior to purchase.

=head2 refund_refusal_explanation string

A justification for why the customer is not entitled to a refund.

=head2 service_date string

The date on which the customer received or began receiving the purchased service, in a clear human-readable format.

=head2 service_documentation string (expandable)

(ID of a file upload) Documentation showing proof that a service was provided to the customer. This could include a copy of a signed contract, work order, or other form of written agreement.

When expanded, this is a L<Net::API::Stripe::File> object.

=head2 shipping_address string

The address to which a physical product was shipped. You should try to include as complete address information as possible.

=head2 shipping_carrier string

The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc. If multiple carriers were used for this purchase, please separate them with commas.

=head2 shipping_date string

The date on which a physical product began its route to the shipping address, in a clear human-readable format.

=head2 shipping_documentation string (expandable)

(ID of a file upload) Documentation showing proof that a product was shipped to the customer at the same address the customer provided to you. This could include a copy of the shipment receipt, shipping label, etc. It should show the customer’s full shipping address, if possible.

=head2 shipping_tracking_number string

The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.

=head2 uncategorized_file string (expandable)

(ID of a file upload) Any additional evidence or statements.

=head2 uncategorized_text string

Any additional evidence or statements.

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

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
