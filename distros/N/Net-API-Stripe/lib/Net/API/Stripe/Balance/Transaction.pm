##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Balance/Transaction.pm
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
## https://stripe.com/docs/api/balance/balance_transaction
package Net::API::Stripe::Balance::Transaction;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub available_on { shift->_set_get_datetime( 'available_on', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub description { shift->_set_get_scalar( 'description', @_ ); }

sub exchange_rate { shift->_set_get_number( 'exchange_rate', @_ ); }

sub fee { shift->_set_get_number( 'fee', @_ ); }

## Array of Net::API::Stripe::Balance::Transaction::FeeDetails
sub fee_details { shift->_set_get_object_array( 'fee_details', 'Net::API::Stripe::Balance::Transaction::FeeDetails', @_ ); }

sub net { shift->_set_get_number( 'net', @_ ); }

sub source { shift->_set_get_scalar_or_object_variant( 'source', @_ ); }

sub sourced_transfers { return( shift->_set_get_object( 'sourced_transfers', 'Net::API::Stripe::List', @_ ) ); }

sub status { shift->_set_get_scalar( 'status', @_ ); }

sub type { shift->_set_get_scalar( 'type', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Balance::Transaction - The Balance Transaction object

=head1 SYNOPSIS

    my $bt = $stripe->balance_transactions({
        amount => 2000,
        # or we could also use a unix timestamp
        available_on => '2019-08-15',
        currency => 'jpy',
        description => 'Customer account credit',
        fee_details => Net::API::Stripe::Balance::Transaction::FeeDetails->new({
			amount => 40,
			currency => 'eur',
			description => 'Some transaction',
			type => 'application_fee',
		}),
		net => 1960,
		status => 'available',
		type => 'application_fee',
    }) || die( $stripe->error );

=head1 VERSION

    0.1

=head1 DESCRIPTION

Balance transactions represent funds moving through your Stripe account. They're created for every type of transaction that comes into or flows out of your Stripe account balance.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Balance::Transaction> object

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "balance_transaction"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> integer

Gross amount of the transaction, in JPY.

=item B<available_on> timestamp

The date the transaction’s net funds will become available in the Stripe balance.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency (L<https://stripe.com/docs/currencies>).

=item B<description> string

An arbitrary string attached to the object. Often useful for displaying to users.

=item B<exchange_rate> decimal

fee integer

Fees (in JPY) paid for this transaction.

=item B<fee_details> array of L<Net::API::Stripe::Balance::Transaction::FeeDetails> objects

Detailed breakdown of fees (in JPY) paid for this transaction.

=over 8

=item B<amount> integer

Amount of the fee, in cents.

=item B<application> string

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<description> string

An arbitrary string attached to the object. Often useful for displaying to users.

=item B<type> string

Type of the fee, one of: application_fee, stripe_fee or tax.

=back

=item B<net> integer

Net amount of the transaction, in JPY.

=item B<source> string (expandable)

The Stripe object to which this transaction is related.

For example, a charge object. This is managed with L<Net::API::Stripe::Generic/"_set_get_scalar_or_object_variant"> method. It will check if this is a hash, array or string, and will find out the proper associated class by peeking into the data.

=item B<sourced_transfers> array

This is a list of object, but according to Stripe and its support, it is deprecated.

The "sourced_transfers parameters used to include any charges or ACH payments to which the balance transfer relates and provide a link back to the 'source' of the balance transaction."

See L<https://stripe.com/docs/upgrades#2017-01-27>

=item B<status> string

If the transaction’s net funds are available in the Stripe balance yet. Either available or pending.

=item B<type> string

Transaction type:

=over 8

=item I<adjustment>

=item I<advance>

=item I<advance_funding>

=item I<application_fee>

=item I<application_fee_refund>

=item I<charge>

=item I<connect_collection_transfer>

=item I<issuing_authorization_hold>

=item I<issuing_authorization_release>

=item I<issuing_transaction>

=item I<payment>

=item I<payment_failure_refund>

=item I<payment_refund>

=item I<payout>

=item I<payout_cancel>

=item I<payout_failure>

=item I<refund>

=item I<refund_failure>

=item I<reserve_transaction>

=item I<reserved_funds>

=item I<stripe_fee>

=item I<stripe_fx_fee>

=item I<tax_fee>

=item I<topup>

=item I<topup_reversal>

=item I<transfer>

=item I<transfer_cancel>

=item I<transfer_failure>

=item I<transfer_refund>

=back

=back

=head1 API SAMPLE

	{
	  "id": "txn_1FTlZvCeyNCl6fY2qIteNrPe",
	  "object": "balance_transaction",
	  "amount": 8000,
	  "available_on": 1571443200,
	  "created": 1571128827,
	  "currency": "jpy",
	  "description": "Invoice 409CD54-0039",
	  "exchange_rate": null,
	  "fee": 288,
	  "fee_details": [
		{
		  "amount": 288,
		  "application": null,
		  "currency": "jpy",
		  "description": "Stripe processing fees",
		  "type": "stripe_fee"
		}
	  ],
	  "net": 7712,
	  "source": "ch_1FTlZvCeyNCl6fY2YAZ8thLx",
	  "status": "pending",
	  "type": "charge"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/balance_transactions>, L<https://stripe.com/docs/reports/balance-transaction-types>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
