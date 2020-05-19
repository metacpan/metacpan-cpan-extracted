##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payout.pm
## Version v0.100.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/payouts
package Net::API::Stripe::Payout;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub arrival_date { shift->_set_get_datetime( 'arrival_date', @_ ); }

sub automatic { shift->_set_get_boolean( 'automatic', @_ ); }

sub balance_transaction { shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub description { shift->_set_get_scalar( 'description', @_ ); }

sub destination { shift->_set_get_scalar_or_object( 'destination', 'Net::API::Stripe::Connect::Account', @_ ); }

sub failure_balance_transaction { shift->_set_get_scalar_or_object( 'failure_balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ); }

sub failure_code { shift->_set_get_scalar( 'failure_code', @_ ); }

sub failure_message { shift->_set_get_scalar( 'failure_message', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub method { shift->_set_get_scalar( 'method', @_ ); }

sub source_type { shift->_set_get_scalar( 'source_type', @_ ); }

sub statement_descriptor { shift->_set_get_scalar( 'statement_descriptor', @_ ); }

sub status { shift->_set_get_scalar( 'status', @_ ); }

sub type { shift->_set_get_scalar( 'type', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payout - A Stripe Payout Object

=head1 SYNOPSIS

    my $payout = $stripe->payout({
        amount => 2000,
        arrival_date => '2020-04-12',
        automatic => $stripe->true,
        currency => 'jpy',
        description => 'Customer payout',
        destination => $connect_account_object,
        livemode => $stripe->false,
        metadata => { transaction_id => 123, customer_id => 456 },
        method => 'standard',
        statement_descriptor => 'Fund raised payout',
        status => 'pending',
        type => 'bank_account',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

A Payout object is created when you receive funds from Stripe, or when you initiate a payout to either a bank account or debit card of a connected Stripe account (L<https://stripe.com/docs/connect/payouts>). You can retrieve individual payouts, as well as list all payouts. Payouts are made on varying schedules, depending on your country and industry.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Payout> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "payout"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> integer

Amount (in JPY) to be transferred to your bank account or debit card.

=item B<arrival_date> timestamp

Date the payout is expected to arrive in the bank. This factors in delays like weekends or bank holidays.

=item B<automatic> boolean

Returns true if the payout was created by an automated payout schedule (L<https://stripe.com/docs/payouts#payout-schedule>), and false if it was requested manually (L<https://stripe.com/docs/payouts#manual-payouts>).

=item B<balance_transaction> string (expandable)

ID of the balance transaction that describes the impact of this payout on your account balance. This is a string or a L<Net::API::Stripe::Balance::Transaction> object.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<currency> currency

Three-letter ISO currency code (L<https://www.iso.org/iso-4217-currency-codes.html>), in lowercase. Must be a supported currency (L<https://stripe.com/docs/currencies>).

=item B<description> string

An arbitrary string attached to the object. Often useful for displaying to users.

=item B<destination> string expandable card or bank account

ID of the bank account or card the payout was sent to. This is a string or a L<Net::API::Stripe::Connect::Account> object.

=item B<failure_balance_transaction> string (expandable)

If the payout failed or was canceled, this will be the ID of the balance transaction that reversed the initial balance transaction, and puts the funds from the failed payout back in your balance. Alternatively it can also be the L<Net::API::Stripe::Balance::Transaction> object if it was expanded.

=item B<failure_code> string

Error code explaining reason for payout failure if available. See Types of payout failures (L<https://stripe.com/docs/api#payout_failures>) for a list of failure codes.

=item B<failure_message> string

Message to user further explaining reason for payout failure if available.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<method> string

The method used to send this payout, which can be standard or instant. instant is only supported for payouts to debit cards. (See Instant payouts for marketplaces for more information: L<https://stripe.com/blog/instant-payouts-for-marketplaces>)

=item B<source_type> string

The source balance this payout came from. One of card or bank_account.

=item B<statement_descriptor> string

Extra information about a payout to be displayed on the user’s bank statement.

=item B<status> string

Current status of the payout (paid, pending, in_transit, canceled or failed). A payout will be pending until it is submitted to the bank, at which point it becomes in_transit. It will then change to paid if the transaction goes through. If it does not go through successfully, its status will change to failed or canceled.

=item B<type> string

Can be bank_account or card.

=back

=head1 API SAMPLE

	{
	  "id": "po_fake123456789",
	  "object": "payout",
	  "amount": 7712,
	  "arrival_date": 1568851200,
	  "automatic": true,
	  "balance_transaction": "txn_fake123456789",
	  "created": 1568682616,
	  "currency": "jpy",
	  "description": "STRIPE PAYOUT",
	  "destination": "ba_fake123456789",
	  "failure_balance_transaction": null,
	  "failure_code": null,
	  "failure_message": null,
	  "livemode": false,
	  "metadata": {},
	  "method": "standard",
	  "source_type": "card",
	  "statement_descriptor": null,
	  "status": "paid",
	  "type": "bank_account"
	}

=head1 HISTORY

=head2 v0.100.0

Initial version

=head1 STRIPE HISTORY

=head2 2017-04-06

Splits the Transfer object into Payout and Transfer. The Payout object represents money moving from a Stripe account to an external account (bank or debit card). The Transfer object now only represents money moving between Stripe accounts on a Connect platform. For more details, see L<https://stripe.com/docs/transfer-payout-split>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/payouts>,
L<https://stripe.com/docs/payouts>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
