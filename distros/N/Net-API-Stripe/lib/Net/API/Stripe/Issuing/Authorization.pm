##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Issuing/Authorization.pm
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
## https://stripe.com/docs/api/issuing/authorizations/object
package Net::API::Stripe::Issuing::Authorization;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub approved { shift->_set_get_boolean( 'approved', @_ ); }

sub authorization_method { shift->_set_get_scalar( 'authorization_method', @_ ); }

sub authorized_amount { shift->_set_get_number( 'authorized_amount', @_ ); }

sub authorized_currency { shift->_set_get_scalar( 'authorized_currency', @_ ); }

sub balance_transactions { shift->_set_get_object_array( 'balance_transactions', 'Net::API::Stripe::Balance::Transaction', @_ ); }

sub card { shift->_set_get_object( 'card', 'Net::API::Stripe::Issuing::Card', @_ ); }

sub cardholder { shift->_set_get_scalar_or_object( 'cardholder', 'Net::API::Stripe::Issuing::Card::Holder', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub held_amount { shift->_set_get_number( 'held_amount', @_ ); }

sub held_currency { shift->_set_get_number( 'held_currency', @_ ); }

sub is_held_amount_controllable { shift->_set_get_boolean( 'is_held_amount_controllable', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub merchant_data { shift->_set_get_object( 'merchant_data', 'Net::API::Stripe::Issuing::MerchantData', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub pending_authorized_amount { shift->_set_get_number( 'pending_authorized_amount', @_ ); }

sub pending_held_amount { shift->_set_get_number( 'pending_held_amount', @_ ); }

sub request_history { shift->_set_get_object_array( 'request_history', 'Net::API::Stripe::Issuing::Authorization::RequestHistory', @_ ); }

sub status { shift->_set_get_scalar( 'status', @_ ); }

sub transactions { shift->_set_get_object_array( 'transactions', 'Net::API::Stripe::Issuing::Authorization::Transaction', @_ ); }

sub verification_data { shift->_set_get_object( 'verification_data', 'Net::API::Stripe::Issuing::Authorization::VerificationData', @_ ); }

sub wallet_provider { return( shift->_set_get_scalar( 'wallet_provider', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::Authorization - A Stripe Issued Authorization Object

=head1 SYNOPSIS

    my $auth = $stripe->authorization({
        approved => $stripe->true,
        authorization_method => 'online',
        authorized_amount => 2000,
        authorized_currency => 'jpy',
        balance_transactions => 
        [
            {
			amount => 2000,
			authorization => $authorization_object,
			card => $card_object,
			cardholder => $cardholder_object,
			currency => 'jpy',
			merchant_amount => 2000,
			merchant_currency => 'jpy',
			merchant_data => $merchant_data_object,
			metadata => { transaction_id => 123 },
			type => 'capture',
			},
        ],
        card => $card_object,
        cardholder => $cardholder_object,
        created => '2020-04-12T04:07:30',
        held_amount => 2000,
        held_currency => 'jpy',
        is_held_amount_controllable => $stripe->true,
        merchant_data => $merchant_data_object,
        metadata => { transaction_id => 123 },
        pending_authorized_amount => 2000,
        pending_held_amount => 2000,
        request_history => [ $request_history_obj1, $request_history_obj2 ],
        status => 'pending',
        transactions => [ $transactions_obj1, $transactions_obj2, $transactions_obj3 ],
        verification_data => $verification_data_object,
        wallet_provider => undef,
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    0.1

=head1 DESCRIPTION

When an issued card is used to make a purchase, an Issuing Authorization object is created. Authorisations (L<https://stripe.com/docs/issuing/authorizations>) must be approved for the purchase to be completed successfully.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Issuing::Authorization> object.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "issuing.authorization"

String representing the object’s type. Objects of the same type share the same value.

=item B<approved> boolean

Whether the authorization has been approved.

=item B<authorization_method> string

How the card details were provided. One of chip, contactless, keyed_in, online, or swipe.

=item B<authorized_amount> integer

The amount that has been authorized. This will be 0 when the object is created, and increase after it has been approved.

=item B<authorized_currency> currency

The currency that was presented to the cardholder for the authorization. Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<balance_transactions> array, contains: balance_transaction object

This is an array of C<Net::API::Stripe::Balance::Transaction> objects.

=item B<card> hash

This is a C<Net::API::Stripe::Issuing::Card> object.

=item B<cardholder> string (expandable)

The cardholder to whom this authorization belongs.

When expanded, this is a C<Net::API::Stripe::Issuing::Card::Holder> object.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<held_amount> integer

The amount the authorization is expected to be in held_currency. When Stripe holds funds from you, this is the amount reserved for the authorization. This will be 0 when the object is created, and increase after it has been approved. For multi-currency transactions, held_amount can be used to determine the expected exchange rate.

=item B<held_currency> currency

The currency of the held amount. This will always be the card currency.

=item B<is_held_amount_controllable> boolean

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<merchant_data> hash

This is a C<Net::API::Stripe::Issuing::MerchantData> object.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<pending_authorized_amount> integer

The amount the user is requesting to be authorized. This field will only be non-zero during an issuing.authorization.request webhook.

=item B<pending_held_amount> integer

The additional amount Stripe will hold if the authorization is approved. This field will only be non-zero during an issuing.authorization.request webhook.

=item B<request_history> array of hashes

This is an array of C<Net::API::Stripe::Issuing::Authorization::RequestHistory> objects.

=item B<status> string

One of pending, reversed, or closed.

=item B<transactions> array of hashes

This is an array of C<Net::API::Stripe::Issuing::Authorization::Transaction> objects.

=item B<verification_data> hash

This is a C<Net::API::Stripe::Issuing::Authorization::VerificationData> object.

=item B<wallet_provider> string

What, if any, digital wallet was used for this authorization. One of apple_pay, google_pay, or samsung_pay.

=back

=head1 API SAMPLE

	{
	  "id": "iauth_fake123456789",
	  "object": "issuing.authorization",
	  "approved": true,
	  "authorization_method": "online",
	  "authorized_amount": 500,
	  "authorized_currency": "usd",
	  "balance_transactions": [],
	  "card": null,
	  "cardholder": null,
	  "created": 1540642827,
	  "held_amount": 0,
	  "held_currency": "usd",
	  "is_held_amount_controllable": false,
	  "livemode": false,
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
	  "pending_authorized_amount": 0,
	  "pending_held_amount": 0,
	  "request_history": [],
	  "status": "reversed",
	  "transactions": [
		{
		  "id": "ipi_fake123456789",
		  "object": "issuing.transaction",
		  "amount": -100,
		  "authorization": "iauth_fake123456789",
		  "balance_transaction": null,
		  "card": "ic_fake123456789",
		  "cardholder": null,
		  "created": 1540642827,
		  "currency": "usd",
		  "dispute": null,
		  "livemode": false,
		  "merchant_amount": null,
		  "merchant_currency": null,
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
		},
		{
		  "id": "ipi_fake123456789",
		  "object": "issuing.transaction",
		  "amount": -100,
		  "authorization": "iauth_fake123456789",
		  "balance_transaction": null,
		  "card": "ic_fake123456789",
		  "cardholder": null,
		  "created": 1540642827,
		  "currency": "usd",
		  "dispute": null,
		  "livemode": false,
		  "merchant_amount": null,
		  "merchant_currency": null,
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
	  ],
	  "verification_data": {
		"address_line1_check": "not_provided",
		"address_zip_check": "match",
		"authentication": "none",
		"cvc_check": "match"
	  },
	  "wallet_provider": null
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/issuing/authorizations>, L<https://stripe.com/docs/issuing/authorizations>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
