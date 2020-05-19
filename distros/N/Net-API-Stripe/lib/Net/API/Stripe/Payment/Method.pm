##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Method.pm
## Version v0.1.1
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/payment_methods
package Net::API::Stripe::Payment::Method;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.1.1';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub au_becs_debit { return( shift->_set_get_hash( 'three_d_secure', @_ ) ); }

sub billing_details { return( shift->_set_get_object( 'billing_details', 'Net::API::Stripe::Billing::Details', @_ ) ); }

sub card { return( shift->_set_get_object( 'card', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub card_present { return( shift->_set_get_hash( 'card_present', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

## Expandable so either we get an id or we get the underlying object
sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub fpx { return( shift->_set_get_hash( 'fpx', @_ ) ); }

sub ideal { return( shift->_set_get_hash( 'ideal', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

# sub sepa_debit { return( shift->_set_get_hash( 'sepa_debit', @_ ) ); }
sub sepa_debit
{
	return( shift->_set_get_class( 'sepa_debit',
	{
	bank_code => { type => 'scalar' },
	branch_code => { type => 'scalar' },
	country => { type => 'scalar' },
	fingerprint => { type => 'scalar' },
	last4 => { type => 'scalar' },
	}, @_ ) );
}

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Method - A Stripe Payment Method Object

=head1 SYNOPSIS

    my $pm = $stripe->payment_method({
        billing_details => $billing_details_object,
        card => $card_object,
        metadata => { transaction_id => 123, customer_id => 456 },
        type => 'card',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

PaymentMethod objects represent your customer's payment instruments. They can be used with PaymentIntents (L<https://stripe.com/docs/payments/payment-intents>) to collect payments or saved to Customer objects to store instrument details for future payments.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Payment::Method> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "payment_method"

String representing the object’s type. Objects of the same type share the same value.

=item B<au_becs_debit>

If this is an au_becs_debit PaymentMethod, this hash contains details about the bank account.

=over 8

=item I<bsb_number> string

Six-digit number identifying bank and branch associated with this bank account.

=item I<fingerprint> string

Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.

=item I<last4> string

Last four digits of the bank account number.

=back

=item B<billing_details> hash

Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.

This is a L<Net::API::Stripe::Billing::Details> object.

=item B<card> hash

If this is a card PaymentMethod, this hash contains details about the card.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object.

=item B<card_present> hash

If this is an card_present PaymentMethod, this hash contains details about the Card Present payment method.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<customer> string (expandable)

The ID of the Customer to which this PaymentMethod is saved. This will not be set when the PaymentMethod has not been saved to a Customer.

=item B<fpx> hash

If this is an fpx PaymentMethod, this hash contains details about the FPX payment method.

=over 8

=item I<bank> string

The customer’s bank, if provided. Can be one of affin_bank, alliance_bank, ambank, bank_islam, bank_muamalat, bank_rakyat, bsn, cimb, hong_leong_bank, hsbc, kfh, maybank2u, ocbc, public_bank, rhb, standard_chartered, uob, deutsche_bank, maybank2e, or pb_enterprise.

=back

=item B<ideal> hash

If this is an ideal PaymentMethod, this hash contains details about the iDEAL payment method.

=over 8

=item I<bank> string

The customer’s bank, if provided. Can be one of abn_amro, asn_bank, bunq, handelsbanken, ing, knab, moneyou, rabobank, regiobank, sns_bank, triodos_bank, or van_lanschot.

=item I<bic> string

The Bank Identifier Code of the customer’s bank, if the bank was provided.

=back

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<sepa_debit> hash

If this is a sepa_debit PaymentMethod, this hash contains details about the SEPA debit bank account.

=over 8

=item I<bank_code> string

Bank code of bank associated with the bank account.

=item I<branch_code> string

Branch code of bank associated with the bank account.

=item I<country> string

Two-letter ISO code representing the country the bank account is located in.

=item I<fingerprint> string

Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.

=item I<last4> string

Last four characters of the IBAN.

=back

=item B<type> string

The type of the PaymentMethod. An additional hash is included on the PaymentMethod with a name matching this value. It contains additional information specific to the PaymentMethod type.

Possible enum values: card, fpx, ideal, sepa_debit

=back

=head1 API SAMPLE

	{
	  "id": "pm_123456789",
	  "object": "payment_method",
	  "billing_details": {
		"address": {
		  "city": "Anytown",
		  "country": "US",
		  "line1": "1234 Main street",
		  "line2": null,
		  "postal_code": "123456",
		  "state": null
		},
		"email": "jenny@example.com",
		"name": null,
		"phone": "+15555555555"
	  },
	  "card": {
		"brand": "visa",
		"checks": {
		  "address_line1_check": null,
		  "address_postal_code_check": null,
		  "cvc_check": null
		},
		"country": "US",
		"exp_month": 8,
		"exp_year": 2020,
		"fingerprint": "kabvjbjcnbmbcmn",
		"funding": "credit",
		"generated_from": null,
		"last4": "4242",
		"three_d_secure_usage": {
		  "supported": true
		},
		"wallet": null
	  },
	  "created": 123456789,
	  "customer": null,
	  "livemode": false,
	  "metadata": {
		"order_id": "123456789"
	  },
	  "type": "card"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2019-12-24

Added properties B<ideal> and B<sepa_debit>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/payment_methods>, L<https://stripe.com/docs/payments/payment-methods>, L<https://stripe.com/docs/payments/cards/reusing-cards>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
