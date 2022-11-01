##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Terminal/Location.pm
## Version v0.101.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/terminal/locations
package Net::API::Stripe::Terminal::Location;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.101.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub address { return( shift->_set_get_object( 'address', 'Net::API::Stripe::Address', @_ ) ); }

sub configuration_overrides { return( shift->_set_get_scalar( 'configuration_overrides', @_ ) ); }

sub display_name { return( shift->_set_get_scalar( 'display_name', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Terminal::Location - A Strip Terminal Reader Location Object

=head1 SYNOPSIS

    my $loc = $stripe->location({
        address => $address_object,
        display_name => 'Tokyo central',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

A Location represents a grouping of readers.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Terminal::Location> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "terminal.location"

String representing the object’s type. Objects of the same type share the same value.

=head2 address hash

The full address of the location.

This is a L<Net::API::Stripe::Address> object.

=head2 configuration_overrides string

The ID of a configuration that will be used to customize all readers in this location.

=head2 display_name string

The display name of the location.

=head2 livemode boolean

Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.

=head2 metadata hash

Set of [key-value pairs](/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head1 API SAMPLE

    {
      "id": "tml_fake123456789",
      "object": "terminal.location",
      "address": {
        "city": "Anytown",
        "country": "US",
        "line1": "1234 Main street",
        "line2": null,
        "postal_code": "123456",
        "state": null
      },
      "display_name": "My First Store"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/terminal/locations>, L<https://stripe.com/docs/terminal/readers/fleet-management#create>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
