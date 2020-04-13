##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Transfer.pm
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
## https://stripe.com/docs/api/transfers
package Net::API::Stripe::Connect::Transfer;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub amount_reversed { shift->_set_get_number( 'amount_reversed', @_ ); }

sub balance_transaction { shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub description { shift->_set_get_scalar( 'description', @_ ); }

sub destination { shift->_set_get_scalar_or_object( 'destination', 'Net::API::Stripe::Connect::Account', @_ ); }

sub destination_payment { shift->_set_get_scalar_or_object( 'destination_payment', 'Net::API::Stripe::Connect::Transfer', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub reversals { shift->_set_get_object( 'reversals', 'Net::API::Stripe::Connect::Transfer::Reversals', @_ ); }

sub reversed { shift->_set_get_boolean( 'reversed', @_ ); }

sub source_transaction { shift->_set_get_scalar_or_object( 'source_transaction', 'Net::API::Stripe::Charge', @_ ); }

## As reference in the example data here https://stripe.com/docs/api/balance/balance_object
sub source_type { shift->_set_get_scalar( 'source_type', @_ ); }

sub source_types { shift->_set_get_hash( 'source_types', @_ ); }

sub transfer_group { shift->_set_get_scalar( 'transfer_group', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Transfer - A Stripe Account-to-Account Transfer Object

=head1 SYNOPSIS

    my $trans = $stripe->transfer({
        amount => 2000,
        currency => 'jpy',
        description => 'Campaign contribution payment',
        destination => $account_object,
        metadata => { transaction_id => 123 },
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    0.1

=head1 DESCRIPTION

A Transfer object is created when you move funds between Stripe accounts as part of Connect.

Before April 6, 2017, transfers also represented movement of funds from a Stripe account to a card or bank account. This behavior has since been split out into a Payout object (L<Net::API::Stripe::Payout> / L<https://stripe.com/docs/api/transfers#payout_object>), with corresponding payout endpoints. For more information, read about the transfer/payout split (L<https://stripe.com/docs/transfer-payout-split>).

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::Transfer> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "transfer"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> integer

Amount in JPY to be transferred.

=item B<amount_reversed> integer

Amount in JPY reversed (can be less than the amount attribute on the transfer if a partial reversal was issued).

=item B<balance_transaction> string (expandable)

Balance transaction that describes the impact of this transfer on your account balance.

When expanded, this is a L<Net::API::Stripe::Balance::Transaction> object.

=item B<created> timestamp

Time that this record of the transfer was first created.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<description> string

An arbitrary string attached to the object. Often useful for displaying to users.

=item B<destination> string (expandable)

ID of the Stripe account the transfer was sent to.

When expanded, this is a L<Net::API::Stripe::Connect::Account> object.

=item B<destination_payment> string (expandable)

If the destination is a Stripe account, this will be the ID of the payment that the destination account received for the transfer.

When expanded, this is a L<Net::API::Stripe::Connect::Transfer> object.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

A set of key-value pairs that you can attach to a transfer object. It can be useful for storing additional information about the transfer in a structured format.

=item B<reversals> list

A list of reversals that have been applied to the transfer.

This is a L<Net::API::Stripe::Connect::Transfer::Reversals> object.

=item B<reversed> boolean

Whether the transfer has been fully reversed. If the transfer is only partially reversed, this attribute will still be false.

=item B<source_transaction> string (expandable)

ID of the charge or payment that was used to fund the transfer. If null, the transfer was funded from the available balance.

When expanded, this is a L<Net::API::Stripe::Charge> object.

=item B<source_type> string

The source balance this transfer came from. One of card or bank_account.

=item B<source_types> hash

This is undocumented, but found in Stripe API response.

=item B<transfer_group> string

A string that identifies this transaction as part of a group. See the Connect documentation for details.

=back

=head1 API SAMPLE

	{
	"id": "tr_fake123456789",
	"object": "transfer",
	"amount": 1100,
	"amount_reversed": 0,
	"balance_transaction": "txn_fake123456789",
	"created": 1571197172,
	"currency": "jpy",
	"description": null,
	"destination": "acct_fake123456789",
	"destination_payment": "py_fake123456789",
	"livemode": false,
	"metadata": {},
	"reversals": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/transfers/tr_fake123456789/reversals"
	},
	"reversed": false,
	"source_transaction": null,
	"source_type": "card",
	"transfer_group": null
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2017-04-06

Splits the Transfer object into Payout and Transfer. The Payout object represents money moving from a Stripe account to an external account (bank or debit card). The Transfer object now only represents money moving between Stripe accounts on a Connect platform. For more details, see L<https://stripe.com/docs/transfer-payout-split>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/transfers>, L<https://stripe.com/docs/connect/charges-transfers>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
