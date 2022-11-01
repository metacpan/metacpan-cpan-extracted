##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Intent/TransferData.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Intent::TransferData;
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

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub destination { return( shift->_set_get_scalar_or_object( 'destination', 'Net::API::Stripe::Connect::Account', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Intent::TransferData - A Stripe TransferData Object

=head1 SYNOPSIS

    my $tf_data = $stripe->payment_intent->transfer_data({
        amount => 2000,
        destination => $connect_account_object,
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

The data with which to automatically create a Transfer when the payment is finalized. See the PaymentIntents use case for connected accounts for details.

This is instantiated by method B<transfer_data> in module L<Net::API::Stripe::Payment::Intent>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Payment::Intent::TransferData> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 amount integer

A positive integer representing how much to charge in the smallest currency unit (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency). The minimum amount is $0.50 US or equivalent in charge currency. The amount value supports up to eight digits (e.g., a value of 99999999 for a USD charge of $999,999.99).

=head2 destination string (expandable)

The account (if any) the payment will be attributed to for tax reporting, and where funds from the payment will be transferred to upon payment success.

When expanded, this is a L<Net::API::Stripe::Connect::Account> object.

=head1 API SAMPLE

    {
      "id": "pi_fake123456789",
      "object": "payment_intent",
      "amount": 1099,
      "amount_capturable": 0,
      "amount_received": 0,
      "application": null,
      "application_fee_amount": null,
      "canceled_at": null,
      "cancellation_reason": null,
      "capture_method": "automatic",
      "charges": {
        "object": "list",
        "data": [],
        "has_more": false,
        "url": "/v1/charges?payment_intent=pi_fake123456789"
      },
      "client_secret": "pi_fake123456789_secret_kfhksfhlajfl",
      "confirmation_method": "automatic",
      "created": 1556596976,
      "currency": "jpy",
      "customer": null,
      "description": null,
      "invoice": null,
      "last_payment_error": null,
      "livemode": false,
      "metadata": {},
      "next_action": null,
      "on_behalf_of": null,
      "payment_method": null,
      "payment_method_options": {},
      "payment_method_types": [
        "card"
      ],
      "receipt_email": null,
      "review": null,
      "setup_future_usage": null,
      "shipping": null,
      "statement_descriptor": null,
      "statement_descriptor_suffix": null,
      "status": "requires_payment_method",
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

L<https://stripe.com/docs/api/payment_intents/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

