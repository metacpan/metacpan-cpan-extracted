##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Transfer.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/transfers
package Net::API::Stripe::Connect::Transfer;
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

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub amount_reversed { return( shift->_set_get_number( 'amount_reversed', @_ ) ); }

sub balance_transaction { return( shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub destination { return( shift->_set_get_scalar_or_object( 'destination', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub destination_payment { return( shift->_set_get_scalar_or_object( 'destination_payment', 'Net::API::Stripe::Connect::Transfer', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub reversals { return( shift->_set_get_object( 'reversals', 'Net::API::Stripe::Connect::Transfer::Reversals', @_ ) ); }

sub reversed { return( shift->_set_get_boolean( 'reversed', @_ ) ); }

sub source_transaction { return( shift->_set_get_scalar_or_object( 'source_transaction', 'Net::API::Stripe::Charge', @_ ) ); }

## As reference in the example data here https://stripe.com/docs/api/balance/balance_object
sub source_type { return( shift->_set_get_scalar( 'source_type', @_ ) ); }

sub source_types { return( shift->_set_get_hash( 'source_types', @_ ) ); }

sub transfer_group { return( shift->_set_get_scalar( 'transfer_group', @_ ) ); }

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

    v0.100.0

=head1 DESCRIPTION

A Transfer object is created when you move funds between Stripe accounts as part of Connect.

Before April 6, 2017, transfers also represented movement of funds from a Stripe account to a card or bank account. This behavior has since been split out into a Payout object (L<Net::API::Stripe::Payout> / L<https://stripe.com/docs/api/transfers#payout_object>), with corresponding payout endpoints. For more information, read about the transfer/payout split (L<https://stripe.com/docs/transfer-payout-split>).

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Connect::Transfer> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "transfer"

String representing the object’s type. Objects of the same type share the same value.

=head2 amount integer

Amount in JPY to be transferred.

=head2 amount_reversed integer

Amount in JPY reversed (can be less than the amount attribute on the transfer if a partial reversal was issued).

=head2 balance_transaction string (expandable)

Balance transaction that describes the impact of this transfer on your account balance.

When expanded, this is a L<Net::API::Stripe::Balance::Transaction> object.

=head2 created timestamp

Time that this record of the transfer was first created.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users.

=head2 destination string (expandable)

ID of the Stripe account the transfer was sent to.

When expanded, this is a L<Net::API::Stripe::Connect::Account> object.

=head2 destination_payment string (expandable)

If the destination is a Stripe account, this will be the ID of the payment that the destination account received for the transfer.

When expanded, this is a L<Net::API::Stripe::Connect::Transfer> object.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

A set of key-value pairs that you can attach to a transfer object. It can be useful for storing additional information about the transfer in a structured format.

=head2 reversals list

A list of reversals that have been applied to the transfer.

This is a L<Net::API::Stripe::Connect::Transfer::Reversals> object.

=head2 reversed boolean

Whether the transfer has been fully reversed. If the transfer is only partially reversed, this attribute will still be false.

=head2 source_transaction string (expandable)

ID of the charge or payment that was used to fund the transfer. If null, the transfer was funded from the available balance.

When expanded, this is a L<Net::API::Stripe::Charge> object.

=head2 source_type string

The source balance this transfer came from. One of card or bank_account.

=head2 source_types hash

This is undocumented, but found in Stripe API response.

=head2 transfer_group string

A string that identifies this transaction as part of a group. See the Connect documentation for details.

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
