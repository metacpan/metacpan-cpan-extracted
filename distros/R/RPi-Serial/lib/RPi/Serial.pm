package RPi::Serial;

use 5.006;
use strict;
use warnings;

use parent 'WiringPi::API';

our $VERSION = '2.3603';

sub new {
    my ($class, $device, $baud) = @_;
    my $self = bless {}, $class;
    $self->fd($self->serial_open($device, $baud));
    return $self;
}
sub close {
    $_[0]->serial_close($_[0]->fd);
}
sub avail {
    return $_[0]->serial_data_avail($_[0]->fd);
}
sub fd {
    my $self = shift;
    $self->{fd} = shift if @_;
    return $self->{fd};
}
sub flush {
    $_[0]->serial_flush($_[0]->fd);
}
sub putc {
    $_[0]->serial_put_char($_[0]->fd, $_[1]);
}
sub puts {
    $_[0]->serial_puts($_[0]->fd, $_[1]);
}
sub getc {
    return $_[0]->serial_get_char($_[0]->fd);
}
sub gets {
    return $_[0]->serial_gets($_[0]->fd, $_[1]);
}
sub DESTROY {
    $_[0]->serial_close($_[0]->fd);
}
sub __placeholder {} # vim folds
1;

=head1 NAME

RPi::Serial - Basic read/write interface to a serial port

=head1 SYNOPSIS

    use RPi::Serial;

    my $dev  = "/dev/ttyAMA0";
    my $baud = 115200;
    
    my $ser = RPi::Serial->new($dev, $baud);

    $ser->putc(5);
    $ser->puts("hello, world!");

    my $char = $ser->getc;

    my $num_bytes = 12;
    my $str  = $ser->gets($num_bytes);

    $ser->flush;

    my $bytes_available = $ser->avail;

    $ser->close;

=head1 DESCRIPTION

Provides basic read and write functionality on the Raspberry Pi's GPIO serial
interface (GPIO pins 14 and 15).

=head1 WARNING

In order to use GPIO pins 14 and 15 as a serial interface on the Raspberry Pi,
you need to disable the built-in Bluetooth adaptor. This distribution will not
operate correctly without this being done.

To disable Bluetooth on the Pi, edit the C</boot/config.txt>, and add the
following line:

    dtoverlay=pi3-disable-bt-overlay

Save the file, then reboot the Pi.

=head1 METHODS

=head2 new($device, $baud);

Opens the specified serial port at the specified baud rate, and returns a new
L<RPi::Serial> object.

Parameters:

    $device

Mandatory, String: The serial device to open (eg: C<"/dev/ttyAMA0">.

    $baud

Mandatory, Integer: A valud baud rate to use.

=head2 close

Closes an already open serial device.

=head2 avail

Returns the number of bytes waiting to be read if any.

=head2 flush

Flush any data currently in the serial buffer.

=head2 fd

Returns the C<ioctl> file descriptor for the current serial object.

=head2 getc

Retrieve a single character from the serial port.

=head2 gets($num_bytes)

Read a specified number of bytes into a string.

Parameters:

    $num_bytes

Mandatory, Integer; The number of bytes to read. If this number is larger than
what is available to be read, a 10 second timeout will briefly hand your
application.

=head2 putc($char)

Writes a single character to the serial device.

Parameters:

    $char

Mandatory, Unsigned Char: The character to write to the port.

=head2 puts($string)

Write a character string to the serial device.

Parameters:

    $string

Mandatory, String: Whatever you want to write to the serial line.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
