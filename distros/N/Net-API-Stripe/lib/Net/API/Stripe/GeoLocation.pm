##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/GeoLocation.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::GeoLocation;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.100.0';
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

    my $geo_loc = $stripe->fraud_review->ip_address_location({
		city => 'Tokyo',
		country => 'jp',
		latitude => '35.6935496',
		longitude => '139.7461204',
		region => undef,
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Information related to the location of the payment. Note that this information is an approximation and attempts to locate the nearest population center - it should not be used to determine a specific address.

This is used in L<Net::API::Stripe::Fraud::Review>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::GeoLocation> object.
It may also take an hash like arguments, that also are method of the same name.

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
	  "id": "prv_fake123456789",
	  "object": "review",
	  "billing_zip": null,
	  "charge": "ch_fake123456789",
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

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
