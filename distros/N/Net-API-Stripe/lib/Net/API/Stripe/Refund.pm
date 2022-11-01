##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Refund.pm
## Version v0.101.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/refunds
package Net::API::Stripe::Refund;
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

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub balance_transaction { return( shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

sub charge { return( shift->_set_get_scalar_or_object( 'charge', 'Net::API::Stripe::Charge', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub failure_balance_transaction { return( shift->_set_get_scalar_or_object( 'failure_balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

sub failure_reason { return( shift->_set_get_scalar( 'failure_reason', @_ ) ); }

sub instructions_email { return( shift->_set_get_scalar( 'instructions_email', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub next_action { return( shift->_set_get_class( 'next_action',
{
  display_details => {
    definition => {
      email_sent => {
                      definition => {
                        email_sent_at => { type => "datetime" },
                        email_sent_to => { type => "scalar" },
                      },
                      type => "class",
                    },
      expires_at => { type => "datetime" },
    },
    type => "class",
  },
  type => { type => "scalar" },
}, @_ ) ); }

sub payment_intent { return( shift->_set_get_scalar_or_object( 'payment_intent', 'Net::API::Stripe::PaymentIntent', @_ ) ); }

sub reason { return( shift->_set_get_scalar( 'reason', @_ ) ); }

sub receipt_number { return( shift->_set_get_scalar( 'receipt_number', @_ ) ); }

sub source_transfer_reversal { return( shift->_set_get_scalar_or_object( 'source_transfer_reversal', 'Net::API::Stripe::Connect::Transfer::Reversal', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub transfer_reversal { return( shift->_set_get_scalar_or_object( 'transfer_reversal', 'Net::API::Stripe::Connect::Transfer::Reversal', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Refund - A Stripe Refund Object

=head1 SYNOPSIS

    my $refund = $stripe->refund({
        amount => 2000,
        charge => $charge_object,
        currency => 'jpy',
        description => 'Cancelled service order',
        metadata => { transaction_id => 123, customer_id => 456 },
        reason => 'requested_by_customer',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

Refund objects allow you to refund a charge that has previously been created but not yet refunded. Funds will be refunded to the credit or debit card that was originally charged.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Refund> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "refund"

String representing the object’s type. Objects of the same type share the same value.

=head2 amount integer

Amount, in JPY.

=head2 balance_transaction string (expandable)

Balance transaction that describes the impact on your account balance.

When expanded, this is a L<Net::API::Stripe::Balance::Transaction> object.

=head2 charge string (expandable)

ID of the charge that was refunded. When expanded, this is a L<Net::API::Stripe::Charge> object.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch. This is a C<DateTime> object.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users. (Available on non-card refunds only)

=head2 failure_balance_transaction string (expandable)

If the refund failed, this balance transaction describes the adjustment made on your account balance that reverses the initial balance transaction. This is a L<Net::API::Stripe::Balance::Transaction>

=head2 failure_reason string

If the refund failed, the reason for refund failure if known. Possible values are lost_or_stolen_card, expired_or_canceled_card, or unknown.

=head2 instructions_email string

Email to which refund instructions, if required, are sent to.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 next_action hash

If the refund has a status of C<requires_action>, this property will describe what the refund needs in order to continue processing.

It has the following properties:

=over 4

=item C<display_details> hash

Contains the refund details.

=over 8

=item C<email_sent> hash

Contains information about the email sent to the customer.

=over 12

=item C<email_sent_at> timestamp

The timestamp when the email was sent.

=item C<email_sent_to> string

The recipient's email address.


=back

=item C<expires_at> timestamp

The expiry timestamp.


=back

=item C<type> string

Type of the next action to perform.

=back

=head2 payment_intent expandable

ID of the PaymentIntent that was refunded.

When expanded this is an L<Net::API::Stripe::PaymentIntent> object.

=head2 reason string

Reason for the refund. If set, possible values are duplicate, fraudulent, and requested_by_customer.

=head2 receipt_number string

This is the transaction number that appears on email receipts sent for this refund.

=head2 source_transfer_reversal string (expandable)

The transfer reversal that is associated with the refund. Only present if the charge came from another Stripe account. See the Connect documentation for details. This is a L<Net::API::Stripe::Connect::Transfer::Reversal>

=head2 status string

Status of the refund. For credit card refunds, this can be pending, succeeded, or failed. For other types of refunds, it can be pending, succeeded, failed, or canceled. Refer to L<Stripe refunds documentation|https://stripe.com/docs/refunds#failed-refunds> for more details.

=head2 transfer_reversal string (expandable)

If the accompanying transfer was reversed, the transfer reversal object. Only applicable if the charge was created using the destination parameter. This is a L<Net::API::Stripe::Connect::Transfer::Reversal> object.

=head1 API SAMPLE

    {
      "id": "re_fake123456789",
      "object": "refund",
      "amount": 30200,
      "balance_transaction": "txn_fake123456789",
      "charge": "ch_fake123456789",
      "created": 1540736617,
      "currency": "jpy",
      "metadata": {},
      "reason": null,
      "receipt_number": null,
      "source_transfer_reversal": null,
      "status": "succeeded",
      "transfer_reversal": null
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/refunds>, L<https://stripe.com/docs/refunds>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
