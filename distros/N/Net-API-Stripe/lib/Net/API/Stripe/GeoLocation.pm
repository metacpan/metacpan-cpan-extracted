##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/GeoLocation.pm
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
package Net::API::Stripe::GeoLocation;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub city { return( shift->_set_get_scalar( 'city', @_ ) ); }

sub country { return( shift->_set_get_scalar( 'country', @_ ) ); }

sub latitude { return( shift->_set_get_number( 'latitude', @_ ) ); }

sub longitude { return( shift->_set_get_number( 'longitude', @_ ) ); }

sub region { return( shift->_set_get_scalar( 'region', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::GeoLocation - A Stripe Geo Location Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

Information related to the location of the payment. Note that this information is an approximation and attempts to locate the nearest population center - it should not be used to determine a specific address.

This is used in C<Net::API::Stripe::Fraud::Review>

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

=item B<city> string

The city where the payment originated.

=item B<country> string

Two-letter ISO code representing the country where the payment originated.

=item B<latitude> decimal

The geographic latitude where the payment originated.

=item B<longitude> decimal

The geographic longitude where the payment originated.

=item B<region> string

The state/county/province/region where the payment originated.

=back

=head1 API SAMPLE

	{
	  "id": "prv_1FVF3MCeyNCl6fY27Q3RLQ4n",
	  "object": "review",
	  "billing_zip": null,
	  "charge": "ch_1AaRjGCeyNCl6fY2v83S8nXJ",
	  "closed_reason": null,
	  "created": 1571480456,
	  "ip_address": null,
	  "ip_address_location": null,
	  "livemode": false,
	  "open": true,
	  "opened_reason": "rule",
	  "reason": "rule",
	  "session": null
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/radar/reviews/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
