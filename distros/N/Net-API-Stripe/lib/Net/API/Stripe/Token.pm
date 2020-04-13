##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Token.pm
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
## https://stripe.com/docs/api/tokens/object
package Net::API::Stripe::Token;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub bank_account { shift->_set_get_object( 'bank_account', 'Net::API::Stripe::Payment::BankAccount', @_ ); }

sub card { shift->_set_get_object( 'card', 'Net::API::Stripe::Payment::Card', @_ ); }

sub client_ip { shift->_set_get_scalar( 'client_ip', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

## account, bank_account, card, person, or pii
sub type { shift->_set_get_scalar( 'type', @_ ); }

sub used { shift->_set_get_boolean( 'used', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Token - A Stripe Token Object

=head1 SYNOPSIS

    my $token = $stripe->token({
        card => $card_object,
        client_ip => '1.2.3.4',
        livemode => $stripe->false,
        type => 'card',
        used => $stripe->false,
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    0.1

=head1 DESCRIPTION

Tokenisation is the process Stripe uses to collect sensitive card or bank account details, or personally identifiable information (PII), directly from your customers in a secure manner. A token representing this information is returned to your server to use. You should use Stripe's recommended payments integrations (L<https://stripe.com/docs/payments>) to perform this process client-side. This ensures that no sensitive card data touches your server, and allows your integration to operate in a PCI-compliant way.

If you cannot use client-side tokenization, you can also create tokens using the API with either your publishable or secret API key. Keep in mind that if your integration uses this method, you are responsible for any PCI compliance that may be required, and you must keep your secret API key safe. Unlike with client-side tokenization, your customer's information is not sent directly to Stripe, so Stripe cannot determine how it is handled or stored.

Tokens cannot be stored or used more than once. To store card or bank account information for later use, you can create Customer objects (L<Net::API::Stripe::Customer> / L<https://stripe.com/docs/api#customers>) or Custom accounts (L<Net::API::Stripe::Connect::ExternalAccount::Bank> and L<Net::API::Stripe::Connect::ExternalAccount::Card> / L<https://stripe.com/docs/api#external_accounts>). Note that Radar (L<https://stripe.com/docs/radar>), Stripe's integrated solution for automatic fraud protection, supports only integrations that use client-side tokenization.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Token> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "token"

String representing the object’s type. Objects of the same type share the same value.

=item B<bank_account> hash

Hash describing the bank account.

This is a L<Net::API::Stripe::Payment::BankAccount> object.

=item B<card> hash

Hash describing the card used to make the charge.

This is a L<Net::API::Stripe::Payment::Card> object.

=item B<client_ip> string

IP address of the client that generated the token.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<type> string

Type of the token: account, bank_account, card, or pii.

=item B<used> boolean

Whether this token has already been used (tokens can be used only once).

=back

=head1 API SAMPLE

	{
	  "id": "tok_fake123456789",
	  "object": "token",
	  "card": {
		"id": "card_fake123456789",
		"object": "card",
		"address_city": null,
		"address_country": null,
		"address_line1": null,
		"address_line1_check": null,
		"address_line2": null,
		"address_state": null,
		"address_zip": null,
		"address_zip_check": null,
		"brand": "Visa",
		"country": "US",
		"cvc_check": null,
		"dynamic_last4": null,
		"exp_month": 8,
		"exp_year": 2020,
		"fingerprint": "x18XyLUPM6hub5xz",
		"funding": "credit",
		"last4": "4242",
		"metadata": {},
		"name": null,
		"tokenization_method": null
	  },
	  "client_ip": null,
	  "created": 1571314413,
	  "livemode": false,
	  "type": "card",
	  "used": false
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/tokens>, L<https://stripe.com/docs/payments/cards/collecting/web#create-token>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
