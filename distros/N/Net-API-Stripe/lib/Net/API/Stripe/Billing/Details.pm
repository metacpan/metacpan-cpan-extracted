##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Details.pm
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
## https://stripe.com/docs/api/charges/object
package Net::API::Stripe::Billing::Details;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub address { shift->_set_get_object( 'address', 'Net::API::Stripe::Address', @_ ); }

sub email { shift->_set_get_scalar( 'email', @_ ); }

sub name { shift->_set_get_scalar( 'name', @_ ); }

sub phone { shift->_set_get_scalar( 'phone', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Details - An interface to Stripe API

=head1 SYNOPSIS

    my $billing_details = $stripe->charge->billing_details({
    	address => $stripe->address({
    		line1 => '1-2-3 Kudan-Manami, Chiyoda-ku',
    		line2 => 'Big Bldg, 12F',
    		city => 'Tokyo',
    		postal_code => '123-4567',
    		country => 'jp',
    	}),
    	email => 'john.doe@example.com',
    	name => 'John Doe',
    	phone => '+81-90-1234-5678',
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

This is created by method B<billing_details> L<Net::API::Stripe::Charge> or by method B<billing_details> in L<Net::API::Stripe::Payment::Method> and capture the billing details

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Billing::Details> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<address> hash

Billing address.

This is a L<Net::API::Stripe::Address> object.

=item B<email> string

Email address.

=item B<name> string

Full name.

=item B<phone> string

Billing phone number (including extension).

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
		"fingerprint": "xksmmnsnmhfjskhjh",
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

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

