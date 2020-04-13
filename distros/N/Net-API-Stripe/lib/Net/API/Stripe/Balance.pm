##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Balance.pm
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
## https://stripe.com/docs/api/balance/balance_object
package Net::API::Stripe::Balance;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub object { shift->_set_get_scalar( 'object', @_ ); }

## Array of Net::API::Stripe::Connect::Transfer
sub available { shift->_set_get_object_array( 'available', 'Net::API::Stripe::Connect::Transfer', @_ ); }

## Array of Net::API::Stripe::Balance::ConnectReserved
sub connect_reserved { shift->_set_get_object_array( 'connect_reserved', 'Net::API::Stripe::Balance::ConnectReserved', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

## Array of Net::API::Stripe::Balance::Pending
sub pending { shift->_set_get_object_array( 'pending', 'Net::API::Stripe::Balance::Pending', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Balance - The Balance object

=head1 SYNOPSIS

	my $object = $stripe->balances( 'retrieve' ) || die( $stripe->error );

=head1 VERSION

    0.1

=head1 DESCRIPTION

This is an object representing your Stripe balance. You can retrieve it to see the balance currently on your Stripe account.

You can also retrieve the balance history, which contains a list of transactions (L<https://stripe.com/docs/reporting/balance-transaction-types>) that contributed to the balance (charges, payouts, and so forth).

The available and pending amounts for each currency are broken down further by payment source types.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Balance> object.

=back

=head1 METHODS

=over 4

=item B<object> string, value is "balance"

String representing the object’s type. Objects of the same type share the same value.

=item B<available> array of C<Net::API::Stripe::Connect::Transfer>

Funds that are available to be transferred or paid out, whether automatically by Stripe or explicitly via the Transfers API or Payouts API. The available balance for each currency and payment type can be found in the source_types property.

Currently this is an array of C<Net::API::Stripe::Connect::Transfer>, but I am considering revising that in light of the documentation of the Stripe API.

=over 8

=item B<amount> integer

Balance amount.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<source_types> hash

Breakdown of balance by source types.

=over 12

=item I<bank_account> integer

Amount for bank account.

=item I<card> integer

Amount for card.

=back

=back

=item B<connect_reserved> array of C<Net::API::Stripe::Balance::ConnectReserved> objects.

Funds held due to negative balances on connected Custom accounts. The connect reserve balance for each currency and payment type can be found in the source_types property.

=over 8

=item B<amount> integer

Balance amount.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<source_types> hash

Breakdown of balance by source types.

=back

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<pending> array of C<Net::API::Stripe::Balance::Pending> objects.

Funds that are not yet available in the balance, due to the 7-day rolling pay cycle. The pending balance for each currency, and for each payment type, can be found in the source_types property.

=over 8

=item B<amount> integer

Balance amount.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<source_types> hash

Breakdown of balance by source types.

=back

=back

=head1 API SAMPLE

	{
	  "object": "balance",
	  "available": [
		{
		  "amount": 0,
		  "currency": "jpy",
		  "source_types": {
			"card": 0
		  }
		}
	  ],
	  "connect_reserved": [
		{
		  "amount": 0,
		  "currency": "jpy"
		}
	  ],
	  "livemode": false,
	  "pending": [
		{
		  "amount": 7712,
		  "currency": "jpy",
		  "source_types": {
			"card": 7712
		  }
		}
	  ]
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://stripe.com/docs/api/balance>, L<https://stripe.com/docs/connect/account-balances>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
