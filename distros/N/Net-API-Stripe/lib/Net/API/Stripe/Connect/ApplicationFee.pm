##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/ApplicationFee.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/application_fees
package Net::API::Stripe::Connect::ApplicationFee;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub account { shift->_set_get_scalar_or_object( 'account', 'Net::API::Stripe::Connect::Account', @_ ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub amount_refunded { shift->_set_get_number( 'amount_refunded', @_ ); }

sub application { shift->_set_get_scalar_or_object( 'application', 'Net::API::Stripe::Connect::Account', @_ ); }

sub balance_transaction { shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ); }

sub charge { shift->_set_get_scalar_or_object( 'charge', 'Net::API::Stripe::Charge', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub originating_transaction { shift->_set_get_scalar_or_object( 'originating_transaction', 'Net::API::Stripe::Charge', @_ ); }

sub refunded { shift->_set_get_boolean( 'refunded', @_ ); }

sub refunds { shift->_set_get_object( 'refunds', 'Net::API::Stripe::Connect::ApplicationFee::Refunds', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::ApplicationFee - A Stripe Application Fee Object

=head1 SYNOPSIS

    my $app_fee = $stripe->application_fee({
        account => $account_object,
        amount => 2000,
        balance_transaction => $balance_transaction_object,
        currency => 'jpy',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

When you collect a transaction fee on top of a charge made for your user (using Connect L<https://stripe.com/docs/connect>), an Application Fee object is created in your account. You can list, retrieve, and refund application fees.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::ApplicationFee> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "application_fee"

String representing the object’s type. Objects of the same type share the same value.

=item B<account> string (expandable)

ID of the Stripe account this fee was taken from. When expanded, this is a L<Net::API::Stripe::Connect::Account> object.

=item B<amount> integer

Amount earned, in JPY.

=item B<amount_refunded> positive integer or zero

Amount in JPY refunded (can be less than the amount attribute on the fee if a partial refund was issued)

=item B<application> string (expandable) "application"

ID of the Connect application that earned the fee. When expanded, this is a L<Net::API::Stripe::Connect::Account> object.

=item B<balance_transaction> string (expandable)

Balance transaction that describes the impact of this collected application fee on your account balance (not including refunds).

When expanded, this is a L<Net::API::Stripe::Balance::Transaction> object.

=item B<charge> string (expandable)

ID of the charge that the application fee was taken from. When expanded, this is a L<Net::API::Stripe::Charge> object.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

This is a C<DateTime> object.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<originating_transaction> string (expandable) charge or transfer

ID of the corresponding charge on the platform account, if this fee was the result of a charge using the destination parameter.

When expanded, this is a L<Net::API::Stripe::Charge> object.

=item B<refunded> boolean

Whether the fee has been fully refunded. If the fee is only partially refunded, this attribute will still be false.

=item B<refunds> list

A list of refunds that have been applied to the fee.

This is a L<Net::API::Stripe::Connect::ApplicationFee::Refunds> object.

=back

=head1 API SAMPLE

	{
	  "id": "fee_fake123456789",
	  "object": "application_fee",
	  "account": "acct_fake123456789",
	  "amount": 100,
	  "amount_refunded": 0,
	  "application": "ca_fake123456789",
	  "balance_transaction": "txn_fake123456789",
	  "charge": "ch_fake123456789",
	  "created": 1571480455,
	  "currency": "jpy",
	  "livemode": false,
	  "originating_transaction": null,
	  "refunded": false,
	  "refunds": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/application_fees/fee_fake123456789/refunds"
	  }
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/application_fees>, L<https://stripe.com/docs/connect/direct-charges#collecting-fees>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
