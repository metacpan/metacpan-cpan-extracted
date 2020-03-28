##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Refund.pm
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
## https://stripe.com/docs/api/refunds
package Net::API::Stripe::Refund;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub balance_transaction { shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ); }

sub charge { shift->_set_get_scalar_or_object( 'charge', 'Net::API::Stripe::Charge', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub failure_balance_transaction { shift->_set_get_scalar_or_object( 'failure_balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ); }

sub failure_reason { shift->_set_get_scalar( 'failure_reason', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub reason { shift->_set_get_scalar( 'reason', @_ ); }

sub receipt_number { shift->_set_get_scalar( 'receipt_number', @_ ); }

sub source_transfer_reversal { shift->_set_get_scalar_or_object( 'source_transfer_reversal', 'Net::API::Stripe::Connect::Transfer::Reversal', @_ ); }

sub status { shift->_set_get_scalar( 'status', @_ ); }

sub transfer_reversal { shift->_set_get_scalar_or_object( 'transfer_reversal', 'Net::API::Stripe::Connect::Transfer::Reversal', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Refund - A Stripe Refund Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

Refund objects allow you to refund a charge that has previously been created but not yet refunded. Funds will be refunded to the credit or debit card that was originally charged.

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

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "refund"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> integer

Amount, in JPY.

=item B<balance_transaction> string (expandable)

Balance transaction that describes the impact on your account balance.

When expanded, this is a C<Net::API::Stripe::Balance::Transaction> object.

=item B<charge> string (expandable)

ID of the charge that was refunded. When expanded, this is a C<Net::API::Stripe::Charge> object.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch. This is a C<DateTime> object.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<description> string

An arbitrary string attached to the object. Often useful for displaying to users. (Available on non-card refunds only)

=item B<failure_balance_transaction> string (expandable)

If the refund failed, this balance transaction describes the adjustment made on your account balance that reverses the initial balance transaction. This is a C<Net::API::Stripe::Balance::Transaction>

=item B<failure_reason> string

If the refund failed, the reason for refund failure if known. Possible values are lost_or_stolen_card, expired_or_canceled_card, or unknown.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<reason> string

Reason for the refund. If set, possible values are duplicate, fraudulent, and requested_by_customer.

=item B<receipt_number> string

This is the transaction number that appears on email receipts sent for this refund.

=item B<source_transfer_reversal> string (expandable)

The transfer reversal that is associated with the refund. Only present if the charge came from another Stripe account. See the Connect documentation for details. This is a C<Net::API::Stripe::Connect::Transfer::Reversal>

=item B<status> string

Status of the refund. For credit card refunds, this can be pending, succeeded, or failed. For other types of refunds, it can be pending, succeeded, failed, or canceled. Refer to our refunds documentation for more details.

=item B<transfer_reversal> string (expandable)

If the accompanying transfer was reversed, the transfer reversal object. Only applicable if the charge was created using the destination parameter. This is a C<Net::API::Stripe::Connect::Transfer::Reversal> object.

=back

=head1 API SAMPLE

	{
	  "id": "re_1DQFAzCeyNCl6fY2Ntw9eath",
	  "object": "refund",
	  "amount": 30200,
	  "balance_transaction": "txn_1DQFAzCeyNCl6fY2VBP8MxtZ",
	  "charge": "ch_1DQFAHCeyNCl6fY2ugNKel6w",
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

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
