##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Issuing/Card.pm
## Version v0.200.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/issuing/cards/object
package Net::API::Stripe::Issuing::Card;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.200.0';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub authorization_controls { shift->_set_get_object( 'authorization_controls', 'Net::API::Stripe::Issuing::Card::AuthorizationsControl', @_ ); }

sub brand { shift->_set_get_scalar( 'brand', @_ ); }

sub cardholder { shift->_set_get_object( 'cardholder', 'Net::API::Stripe::Issuing::Card::Holder', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub exp_month { shift->_set_get_scalar( 'exp_month', @_ ); }

sub exp_year { shift->_set_get_scalar( 'exp_year', @_ ); }

sub last4 { shift->_set_get_scalar( 'last4', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub name { shift->_set_get_scalar( 'name', @_ ); }

sub pin { return( shift->_set_get_hash_as_object( 'pin', 'Net::API::Stripe::Issuing::Card::PinInfo', @_ ) ); }

sub replacement_for { return( shift->_set_get_scalar_or_object( 'replacement_for', 'Net::API::Stripe::Issuing::Card', @_ ) ); }

sub replacement_reason { return( shift->_set_get_scalar( 'replacement_reason', @_ ) ); }

sub shipping { shift->_set_get_object( 'shipping', 'Net::API::Stripe::Shipping', @_ ); }

sub spending_controls
{
	return( shift->_set_get_class( 'spending_controls',
	{
	allowed_categories => { type => 'array' },
	blocked_categories => { type => 'array' },
	spending_limits => 
        {
        type => 'class', definition =>
            {
            amount => { type => 'number' },
            categories => { type => 'array' },
            interval => { type => 'scalar' },
            }
	    },
	spending_limits_currency => { type => 'scalar' },
	}, @_ ) );
}

sub status { shift->_set_get_scalar( 'status', @_ ); }

sub type { shift->_set_get_scalar( 'type', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::Card - A Stripe Issued Card Object

=head1 SYNOPSIS

    my $card = $stripe->card({
        authorization_controls => $authorization_controls_objet,
        brand => 'visa',
        cardholder => $cardholder_object,
        currency => 'jpy',
        exp_month => 12,
        exp_year => 2030,
        last4 => 123,
        metadata => { transaction_id => 123 },
        name => 'John Doe',
        replacement_for => $card_object,
        replacement_reason => 'loss',
        shipping => $address_object,
        status => 'active',
        type => 'physical',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.200.0

=head1 DESCRIPTION

You can create physical or virtual cards that are issued to cardholders.

This Module bears some resemblance with L<Net::API::Stripe::Connect::ExternalAccount::Card>, but is quite different, so it stands on its own.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Issuing::Card> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "issuing.card"

String representing the object’s type. Objects of the same type share the same value.

=item B<authorization_controls> hash

Spending rules that give you some control over how your cards can be used. Refer to L<Stripe's authorizations documentation|https://stripe.com/docs/issuing/purchases/authorizations> for more details.

This is a L<Net::API::Stripe::Issuing::Card::AuthorizationsControl> object.

=item B<brand> string

The brand of the card.

=item B<cardholder> hash

The Cardholder object to which the card belongs.

This is a L<Net::API::Stripe::Issuing::Card::Holder> object.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<exp_month> integer

The expiration month of the card.

=item B<exp_year> integer

The expiration year of the card.

=item B<last4> string

The last 4 digits of the card number.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<name> string

The name of the cardholder, printed on the card.

=item B<pin> hash

Metadata about the PIN on the card.

This is a virtual L<Net::API::Stripe::Issuing::Card::PinInfo> object.

It contains the following property:

=over 8

=item I<status> string

The status of the pin. One of blocked or active.

=back

=item B<replacement_for> string (expandable)

The card this card replaces, if any. When expanded, this is a L<Net::API::Stripe::Issuing::Card> object.

=item B<replacement_reason> string

Why the card that this card replaces (if any) needed to be replaced. One of damage, expiration, loss, or theft.

=item B<shipping> hash

Where and how the card will be shipped.

This is a L<Net::API::Stripe::Shipping> object.

=item B<spending_controls> hash

This is a hash whose properties are accessible as a dynamic class methods

=over 8

=item I<amount> positive integer

Maximum amount allowed to spend per time interval.

=item I<categories> array

Array of strings containing categories on which to apply the spending limit. Leave this blank to limit all charges.

=item I<interval> enum

The time interval or event with which to apply this spending limit towards.

=over 12

=item I<per_authorization>

A maximum amount for each authorization.

=item I<daily>

A maximum within a day. A day start at midnight UTC.

=item I<weekly>

A maximum within a week. The first day of a week is Monday.

=item I<monthly>

A maximum within a month. Starts on the first of that month.

=item I<yearly>

A maximum amount within a year. Starts January 1st.

=item I<all_time>

A maximum amount for all transactions.

=back

=item I<spending_limits_currency> currency

Currency for the amounts within spending_limits. Locked to the currency of the card.

=back

=item B<status> string

One of active, inactive, canceled, lost, or stolen.

=item B<type> string

One of virtual or physical.

=back

=head1 API SAMPLE

	{
	  "id": "ic_fake123456789",
	  "object": "issuing.card",
	  "authorization_controls": {
		"allowed_categories": null,
		"blocked_categories": null,
		"currency": "usd",
		"max_amount": 10000,
		"max_approvals": 1,
		"spending_limits": [],
		"spending_limits_currency": null
	  },
	  "brand": "Visa",
	  "cardholder": {
		"id": "ich_fake123456789",
		"object": "issuing.cardholder",
		"authorization_controls": {
		  "allowed_categories": [],
		  "blocked_categories": [],
		  "spending_limits": [],
		  "spending_limits_currency": null
		},
		"billing": {
		  "address": {
			"city": "Beverly Hills",
			"country": "US",
			"line1": "123 Fake St",
			"line2": "Apt 3",
			"postal_code": "90210",
			"state": "CA"
		  },
		  "name": "Jenny Rosen"
		},
		"company": null,
		"created": 1540111055,
		"email": "jenny@example.com",
		"individual": null,
		"is_default": false,
		"livemode": false,
		"metadata": {},
		"name": "Jenny Rosen",
		"phone_number": "+18008675309",
		"requirements": {
		  "disabled_reason": null,
		  "past_due": []
		},
		"status": "active",
		"type": "individual"
	  },
	  "created": 1571480456,
	  "currency": "usd",
	  "exp_month": 8,
	  "exp_year": 2020,
	  "last4": "4242",
	  "livemode": false,
	  "metadata": {},
	  "name": "Jenny Rosen",
	  "pin": null,
	  "replacement_for": null,
	  "replacement_reason": null,
	  "shipping": null,
	  "status": "active",
	  "type": "physical"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head2 v0.2

Added method L</"spending_controls"> that was added on Stripe api.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/issuing/cards>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
