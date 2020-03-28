##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Terminal/Reader.pm
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
## https://stripe.com/docs/api/terminal/readers/object
package Net::API::Stripe::Terminal::Reader;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub device_sw_version { shift->_set_get_scalar( 'device_sw_version', @_ ); }

sub device_type { shift->_set_get_scalar( 'device_type', @_ ); }

sub ip_address { shift->_set_get_scalar( 'ip_address', @_ ); }

sub label { shift->_set_get_scalar( 'label', @_ ); }

sub location { shift->_set_get_scalar( 'location', @_ ); }

sub serial_number { shift->_set_get_scalar( 'serial_number', @_ ); }

sub status { shift->_set_get_scalar( 'status', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Terminal::Reader - A Stripe Terminal Reader Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

A Reader represents a physical device for accepting payment details.

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

=item B<object> string, value is "terminal.reader"

String representing the object’s type. Objects of the same type share the same value.

=item B<device_sw_version> string

The current software version of the reader.

=item B<device_type> string

Type of reader, e.g., verifone_P400 or bbpos_chipper2x.

=item B<ip_address> string

The local IP address of the reader.

=item B<label> string

Custom label given to the reader for easier identification.

=item B<location> string

The location identifier of the reader.

=item B<serial_number> string

Serial number of the reader.

=item B<status> string

The networking status of the reader.

=back

=head1 API SAMPLE

	{
	  "id": "tmr_P400-123-456-789",
	  "object": "terminal.reader",
	  "device_sw_version": null,
	  "device_type": "verifone_P400",
	  "ip_address": "192.168.2.2",
	  "label": "Blue Rabbit",
	  "location": null,
	  "serial_number": "123-456-789",
	  "status": "online"
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

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
