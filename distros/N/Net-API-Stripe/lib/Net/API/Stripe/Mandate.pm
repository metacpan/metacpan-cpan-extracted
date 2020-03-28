##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Mandate.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/12/25
## Modified 2019/12/25
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Mandate;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub customer_acceptance
{
	return( shift->_set_get_class( 'customer_acceptance', 
		{
		accepted_at => { type => 'datetime' },
		offline => { type => 'hash_as_object' },
		online => { type => 'hash_as_object' },
		type => { type => 'scalar' },
		}, @_ )
	);
}

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub multi_use { return( shift->_set_get_hash( 'multi_use', @_ ) ); }

sub payment_method { return( shift->_set_get_scalar_or_object( 'payment_method', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub payment_method_details
{
	return( shift->_set_get_class( 'payment_method_details', 
		{
		card => { type => 'hash' },
		sepa_debit => { type => 'hash' },
		type => { type => 'scalar' },
		}, @_ )
	);
}

sub single_use
{
	return( shift->_set_get_class( 'single_use', 
		{
		amount => { type => 'number' },
		currency => { type => 'scalar' },
		}, @_ )
	);
}

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Mandate - A Stripe Mandate Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

A Mandate is a record of the permission a customer has given you to debit their payment method.

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

=item B<object> string, value is "mandate"

String representing the object’s type. Objects of the same type share the same value.

=item B<customer_acceptance> hash

Details about the customer’s acceptance of the mandate.

=over 8

=item I<accepted_at> timestamp

The time at which the customer accepted the Mandate.

=item I<offline> hash

If this is a Mandate accepted offline, this hash contains details about the offline acceptance.

=item I<online> hash

If this is a Mandate accepted online, this hash contains details about the online acceptance.

=item I<type> string

The type of customer acceptance information included with the Mandate. One of online or offline.

=back

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<multi_use> hash

If this is a multi_use mandate, this hash contains details about the mandate.

=item B< payment_method> string expandable

ID of the payment method associated with this mandate.

=item B<payment_method_details> hash

Additional mandate information specific to the payment method type.

=over 8

=item I<card> hash

If this mandate is associated with a card payment method, this hash contains mandate information specific to the card payment method.

=item I<sepa_debit> hash

If this mandate is associated with a sepa_debit payment method, this hash contains mandate information specific to the sepa_debit payment method.

=item I<type> string

The type of the payment method associated with this mandate. An additional hash is included on payment_method_details with a name matching this value. It contains mandate information specific to the payment method.

=back

=item B<single_use> hash

If this is a single_use mandate, this hash contains details about the mandate.

=over 8

=item I<amount> integer

On a single use mandate, the amount of the payment.

=item I<currency> currency

On a single use mandate, the currency of the payment.

=back

=item B<status> string

The status of the Mandate, one of active, inactive, or pending. The Mandate can be used to initiate a payment only if status=active.

=item B<type> string

The type of the mandate, one of multi_use or single_use

=back

=head1 API SAMPLE

	{
	  "id": "mandate_123456789",
	  "object": "mandate",
	  "customer_acceptance": {
		"accepted_at": 123456789,
		"online": {
		  "ip_address": "127.0.0.0",
		  "user_agent": "device"
		},
		"type": "online"
	  },
	  "livemode": false,
	  "multi_use": {},
	  "payment_method": "pm_123456789",
	  "payment_method_details": {
		"sepa_debit": {
		  "reference": "123456789",
		  "url": ""
		},
		"type": "sepa_debit"
	  },
	  "status": "active",
	  "type": "multi_use"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>, L<https://stripe.com/docs/api/mandates/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
