##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Charge/Outcome.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Charge::Outcome;
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

sub network_status { return( shift->_set_get_scalar( 'network_status', @_ ) ); }

sub reason { return( shift->_set_get_scalar( 'reason', @_ ) ); }

sub risk_level { return( shift->_set_get_scalar( 'risk_level', @_ ) ); }

sub risk_score { return( shift->_set_get_scalar( 'risk_score', @_ ) ); }

sub rule { return( shift->_set_get_scalar( 'rule', @_ ) ); }

sub seller_message { return( shift->_set_get_scalar( 'seller_message', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Charge::Outcome - A Stripe Charge Outcome Object

=head1 SYNOPSIS

    my $outcome = $stripe->charge->outcome({
        network_status  => 'approved_by_network',
        reason          => undef,
        risk_level      => 'normal',
        risk_score      => 0,
        rule            => undef,
        seller_message  => undef,
        type            => 'authorized',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Details about whether the payment was accepted, and why. See understanding declines for details.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Charge::Outcome> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 network_status string

Possible values are approved_by_network, declined_by_network, not_sent_to_network, and reversed_after_approval. The value reversed_after_approval indicates the payment was blocked by Stripe after bank authorization, and may temporarily appear as “pending” on a cardholder’s statement.

=head2 reason string

An enumerated value providing a more detailed explanation of the outcome’s type. Charges blocked by Radar’s default block rule have the value highest_risk_level. Charges placed in review by Radar’s default review rule have the value elevated_risk_level. Charges authorized, blocked, or placed in review by custom rules have the value rule. See understanding declines for more details.

=head2 risk_level string

Stripe’s evaluation of the riskiness of the payment. Possible values for evaluated payments are normal, elevated, highest. For non-card payments, and card-based payments predating the public assignment of risk levels, this field will have the value not_assessed. In the event of an error in the evaluation, this field will have the value unknown.

=head2 risk_score integer

Stripe’s evaluation of the riskiness of the payment. Possible values for evaluated payments are between 0 and 100. For non-card payments, card-based payments predating the public assignment of risk scores, or in the event of an error during evaluation, this field will not be present. This field is only available with Radar for Fraud Teams.

=head2 rule string (expandable)

The ID of the Radar rule that matched the payment, if applicable.

=head2 seller_message string

A human-readable description of the outcome type and reason, designed for you (the recipient of the payment), not your customer.

=head2 type string

Possible values are authorized, manual_review, issuer_declined, blocked, and invalid. See understanding declines and Radar reviews for details.

=head1 API SAMPLE

        {
          "id": "ch_fake123456789",
          "object": "charge",
          "amount": 100,
          "amount_refunded": 0,
          "application": null,
          "application_fee": null,
          "application_fee_amount": null,
          "balance_transaction": "txn_fake123456789",
          "billing_details": {
            "address": {
              "city": null,
              "country": null,
              "line1": null,
              "line2": null,
              "postal_code": null,
              "state": null
            },
            "email": null,
            "name": null,
            "phone": null
          },
          "captured": false,
          "created": 1571176460,
          "currency": "jpy",
          "customer": null,
          "description": "My First Test Charge (created for API docs)",
          "dispute": null,
          "failure_code": null,
          "failure_message": null,
          "fraud_details": {},
          "invoice": null,
          "livemode": false,
          "metadata": {},
          "on_behalf_of": null,
          "order": null,
          "outcome": null,
          "paid": true,
          "payment_intent": null,
          "payment_method": "card_fake123456789",
          "payment_method_details": {
            "card": {
              "brand": "visa",
              "checks": {
                "address_line1_check": null,
                "address_postal_code_check": null,
                "cvc_check": null
              },
              "country": "US",
              "exp_month": 4,
              "exp_year": 2024,
              "fingerprint": "fake123456789",
              "funding": "credit",
              "installments": null,
              "last4": "4242",
              "network": "visa",
              "three_d_secure": null,
              "wallet": null
            },
            "type": "card"
          },
          "receipt_email": null,
          "receipt_number": null,
          "receipt_url": "https://pay.stripe.com/receipts/acct_fake123456789/ch_fake123456789/rcpt_fake123456789",
          "refunded": false,
          "refunds": {
            "object": "list",
            "data": [],
            "has_more": false,
            "url": "/v1/charges/ch_fake123456789/refunds"
          },
          "review": null,
          "shipping": null,
          "source_transfer": null,
          "statement_descriptor": null,
          "statement_descriptor_suffix": null,
          "status": "succeeded",
          "transfer_data": null,
          "transfer_group": null
        }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/charges/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
