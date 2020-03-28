##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Issuing/Transaction.pm
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
## https://stripe.com/docs/api/issuing/transactions
package Net::API::Stripe::Issuing::Transaction;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub authorization { shift->_set_get_scalar_or_object( 'authorization', 'Net::API::Stripe::Issuing::Authorization', @_ ); }

sub balance_transaction { shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ); }

sub card { shift->_set_get_scalar_or_object( 'card', 'Net::API::Stripe::Payment::Card', @_ ); }

sub cardholder { shift->_set_get_scalar_or_object( 'cardholder', 'Net::API::Stripe::Issuing::Card::Holder', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub dispute { shift->_set_get_scalar_or_object( 'dispute', 'Net::API::Stripe::Issuing::Dispute', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub merchant_amount { return( shift->_set_get_number( 'merchant_amount', @_ ) ); }

sub merchant_currency { return( shift->_set_get_scalar( 'merchant_currency', @_ ) ); }

sub merchant_data { shift->_set_get_object( 'merchant_data', 'Net::API::Stripe::Issuing::MerchantData', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub type { shift->_set_get_scalar( 'type', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::Transaction - A Stripe Issuing Transaction Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

Any use of an issued card (L<https://stripe.com/docs/issuing>) that results in funds entering or leaving your Stripe account, such as a completed purchase or refund, is represented by an Issuing Transaction object.

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

=item B<object> string, value is "issuing.transaction"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> integer

=item B<authorization> string (expandable)

The Authorization object that led to this transaction.

When expanded, this is a C<Net::API::Stripe::Issuing::Authorization> object.

=item B<balance_transaction> string (expandable)

When expanded, this is a C<Net::API::Stripe::Balance::Transaction> object.

=item B<card> string (expandable)

The card used to make this transaction.

When expanded, this is a C<Net::API::Stripe::Payment::Card> object.

=item B<cardholder> string (expandable)

The cardholder to whom this transaction belongs.

When expanded, this is a C<Net::API::Stripe::Issuing::Card::Holder> object.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<dispute> string (expandable)

When expanded, this is a C<Net::API::Stripe::Issuing::Dispute> object.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<merchant_amount> integer

=item B<merchant_currency> currency

=item B<merchant_data> hash

More information about the user involved in the transaction.

This is a C<Net::API::Stripe::Issuing::MerchantData> object.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<type> string

One of capture, refund, cash_withdrawal, refund_reversal, dispute, or dispute_loss.

=back

=head1 API SAMPLE

	{
	  "id": "ipi_1FVF3MCeyNCl6fY2IcWlQov3",
	  "object": "issuing.transaction",
	  "amount": -100,
	  "authorization": "iauth_1DPqmFCeyNCl6fY2fOG90330",
	  "balance_transaction": null,
	  "card": "ic_1FVF3MCeyNCl6fY2UUvnxdw6",
	  "cardholder": null,
	  "created": 1571480456,
	  "currency": "usd",
	  "dispute": null,
	  "livemode": false,
	  "merchant_amount": -100,
	  "merchant_currency": "usd",
	  "merchant_data": {
		"category": "taxicabs_limousines",
		"city": "San Francisco",
		"country": "US",
		"name": "Rocket Rides",
		"network_id": "1234567890",
		"postal_code": "94107",
		"state": "CA",
		"url": null
	  },
	  "metadata": {},
	  "type": "capture"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/issuing/transactions>, L<https://stripe.com/docs/issuing/transactions>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
