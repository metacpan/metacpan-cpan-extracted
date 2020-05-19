##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/TopUp.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/topups
package Net::API::Stripe::Connect::TopUp;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub balance_transaction { shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub description { shift->_set_get_scalar( 'description', @_ ); }

sub expected_availability_date { shift->_set_get_datetime( 'expected_availability_date', @_ ); }

sub failure_code { shift->_set_get_scalar( 'failure_code', @_ ); }

sub failure_message { shift->_set_get_scalar( 'failure_message', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub source { shift->_set_get_object( 'source', 'Net::API::Stripe::Payment::Source', @_ ); }

sub statement_descriptor { shift->_set_get_scalar( 'statement_descriptor', @_ ); }

sub status { shift->_set_get_scalar( 'status', @_ ); }

## Does not seem to be documented in the Stripe API, although it showed up in its response json
sub transfer_group { shift->_set_get_scalar( 'transfer_group', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::TopUp - An Stripe Top-up Object

=head1 SYNOPSIS

    my $topup = $stripe->topup({
        amount => 2000,
        currency => 'usd',
        description => 'Adding fund for Q2 2020',
        metadata => { transaction_id => 123 },
        source => $source_object,
        statement_descriptor => 'Fund transfer to Stripe for Q2 2020',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

To top up your Stripe balance, you create a top-up object. You can retrieve individual top-ups, as well as list all top-ups. Top-ups are identified by a unique, random ID.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::TopUp> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "topup"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> integer

Amount transferred.

=item B<balance_transaction> string (expandable)

ID of the balance transaction that describes the impact of this top-up on your account balance. May not be specified depending on status of top-up.

When expanded, this is a L<Net::API::Stripe::Balance::Transaction> object.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<currency> string

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<description> string

An arbitrary string attached to the object. Often useful for displaying to users.

=item B<expected_availability_date> integer

Date the funds are expected to arrive in your Stripe account for payouts. This factors in delays like weekends or bank holidays. May not be specified depending on status of top-up.

=item B<failure_code> string

Error code explaining reason for top-up failure if available (see the errors section for a list of codes).

=item B<failure_message> string

Message to user further explaining reason for top-up failure if available.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<source> hash, source object

For most Stripe users, the source of every top-up is a bank account. This hash is then the source object describing that bank account.

This is a L<Net::API::Stripe::Payment::Source> object.

=item B<statement_descriptor> string

Extra information about a top-up. This will appear on your source’s bank statement. It must contain at least one letter.

=item B<status> string

The status of the top-up is either canceled, failed, pending, reversed, or succeeded.
transfer_group string

A string that identifies this top-up as part of a group.

=item B<transfer_group>

Undocumented in Stripe API, but found in its response json data. See example API sample below.

=back

=head1 API SAMPLE

	{
	  "id": "tu_fake123456789",
	  "object": "topup",
	  "amount": 1000,
	  "balance_transaction": null,
	  "created": 123456789,
	  "currency": "jpy",
	  "description": "Top-up description",
	  "expected_availability_date": 123456789,
	  "failure_code": null,
	  "failure_message": null,
	  "livemode": false,
	  "metadata": {
		"order_id": "12345678"
	  },
	  "source": {
		"id": "src_fake123456789",
		"object": "source",
		"ach_debit": {
		  "country": "US",
		  "type": "individual",
		  "routing_number": "110000000",
		  "bank_name": "STRIPE TEST BANK",
		  "fingerprint": "5Wh4KBcfDrz5IOnx",
		  "last4": "6789"
		},
		"amount": null,
		"client_secret": "src_client_secret_fake123456789",
		"created": 1571480456,
		"currency": "jpy",
		"flow": "code_verification",
		"livemode": false,
		"metadata": {},
		"owner": {
		  "address": null,
		  "email": "jenny.rosen@example.com",
		  "name": "Jenny Rosen",
		  "phone": null,
		  "verified_address": null,
		  "verified_email": null,
		  "verified_name": null,
		  "verified_phone": null
		},
		"statement_descriptor": null,
		"status": "pending",
		"type": "ach_debit",
		"usage": "reusable"
	  },
	  "statement_descriptor": null,
	  "status": "pending",
	  "transfer_group": null
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/topups>, L<https://stripe.com/docs/connect/top-ups>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
