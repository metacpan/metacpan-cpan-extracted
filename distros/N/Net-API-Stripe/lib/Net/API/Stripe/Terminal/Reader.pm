##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Terminal/Reader.pm
## Version v0.101.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/terminal/readers/object
package Net::API::Stripe::Terminal::Reader;
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

sub action { return( shift->_set_get_object( 'action', 'Net::API::Stripe::Payout', @_ ) ); }

sub device_sw_version { return( shift->_set_get_scalar( 'device_sw_version', @_ ) ); }

sub device_type { return( shift->_set_get_scalar( 'device_type', @_ ) ); }

sub ip_address { return( shift->_set_get_scalar( 'ip_address', @_ ) ); }

sub label { return( shift->_set_get_scalar( 'label', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub location { return( shift->_set_get_scalar( 'location', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub registration_code { return( shift->_set_get_scalar( 'registration_code', @_ ) ); }

sub serial_number { return( shift->_set_get_scalar( 'serial_number', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Terminal::Reader - A Stripe Terminal Reader Object

=head1 SYNOPSIS

    my $reader = $stripe->reader({
        device_sw_version => '1.0.2',
        device_type => 'verifone_P400',
        ip_address => '1.2.3.4',
        label => 'Blue Rabbit',
        # Anywhere
        location => undef,
        registration_code => 'puppies-plug-could',
        serial_number => '123-456-789',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

A Reader represents a physical device for accepting payment details.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Terminal::Reader> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "terminal.reader"

String representing the object’s type. Objects of the same type share the same value.

=head2 action object

The most recent action performed by the reader.

This is a L<Net::API::Stripe::Payout> object.

=head2 device_sw_version string

The current software version of the reader.

=head2 device_type string

Type of reader, e.g., verifone_P400 or bbpos_chipper2x.

=head2 ip_address string

The local IP address of the reader.

=head2 label string

Custom label given to the reader for easier identification. If no label is specified, the registration code will be used.

=head2 livemode boolean

Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.

=head2 location string

The location to assign the reader to. If no location is specified, the reader will be assigned to the account’s default location.

=head2 metadata hash

Set of L<key-value pairs|https://stripe.com/docs/api/metadata> that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 serial_number string

Serial number of the reader.

=head2 status string

The networking status of the reader.

=head1 API SAMPLE

    {
      "id": "tmr_P400-123-456-789",
      "object": "terminal.reader",
      "device_sw_version": null,
      "device_type": "verifone_P400",
      "ip_address": "192.168.2.2",
      "label": "Blue Rabbit",
      "livemode": false,
      "location": "tml_1234",
      "metadata": {},
      "serial_number": "123-456-789",
      "status": "online",
      "registration_code": "puppies-plug-could"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/terminal/readers>, L<https://stripe.com/docs/terminal/readers/connecting>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
