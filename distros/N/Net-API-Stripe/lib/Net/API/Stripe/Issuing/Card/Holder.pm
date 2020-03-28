##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Issuing/Card/Holder.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/issuing/cardholders/object
package Net::API::Stripe::Issuing::Card::Holder;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub authorization_controls { return( shift->_set_get_object( 'authorization_controls', 'Net::API::Stripe::Issuing::Card::AuthorizationsControl', @_ ) ); }

sub billing { shift->_set_get_object( 'billing', 'Net::API::Stripe::Billing::Details', @_ ); }

sub company { return( shift->_set_get_object( 'company', 'Net::API::Stripe::Connect::Account::Company', @_ ) ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub email { shift->_set_get_scalar( 'email', @_ ); }

sub individual { return( shift->_set_get_object( 'individual', 'Net::API::Stripe::Connect::Person', @_ ) ); }

sub is_default { return( shift->_set_get_boolean( 'is_default', @_ ) ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub name { shift->_set_get_scalar( 'name', @_ ); }

sub phone_number { shift->_set_get_scalar( 'phone_number', @_ ); }

sub requirements { return( shift->_set_get_object( 'requirements', 'Net::API::Stripe::Connect::Account::Requirements', @_ ) ); }

sub status { shift->_set_get_scalar( 'status', @_ ); }

sub type { shift->_set_get_scalar( 'type', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::Card::Holder - A Stripe Card Holder Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

An Issuing Cardholder object represents an individual or business entity who is issued (L<https://stripe.com/docs/issuing>) cards.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new C<Net::API::Stripe> objects.
It may also take an hash like arguments, that also are method of the same name.

=over 8

=item I<verbose>

Toggles verbose mode on/off

=item I<debug>

Toggles debug mode on/off

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "issuing.cardholder"

String representing the object’s type. Objects of the same type share the same value.

=item B<authorization_controls> hash

This is a C<Net::API::Stripe::Issuing::Card::AuthorizationsControl> object.

=item B<billing> hash

The cardholder’s billing address.

This is a C<Net::API::Stripe::Billing::Details> object.

=item B<company> hash preview feature

Additional information about a business_entity cardholder.

This is a C<Net::API::Stripe::Connect::Account::Company> object.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

This is a C<DateTime> object.

=item B<email> string

The cardholder’s email address.

=item B<individual> hash preview feature

Additional information about an individual cardholder.

This is a C<Net::API::Stripe::Connect::Person> object.

=item B<is_default> boolean

Whether or not this cardholder is the default cardholder.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<name> string

The cardholder’s name. This will be printed on cards issued to them.

=item B<phone_number> string

The cardholder’s phone number.

=item B<requirements> hash

Information about verification requirements for the cardholder, including what information needs to be collected.

This is a C<Net::API::Stripe::Connect::Account::Requirements> object.

=item B<status> string

One of active, inactive, or blocked.

=item B<type> string

One of individual or business_entity.

=back

=head1 API SAMPLE

	{
	  "id": "ich_1DNcRHCeyNCl6fY2Epuwa9n9",
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
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/issuing/cardholders>, L<https://stripe.com/docs/issuing/cards#create-cardholder>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
