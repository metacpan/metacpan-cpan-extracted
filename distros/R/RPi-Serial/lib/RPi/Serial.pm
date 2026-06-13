package RPi::Serial;

use strict;
use warnings;


our $VERSION = '3.02';

require XSLoader;
XSLoader::load('RPi::Serial', $VERSION);

sub new {
    my ($class, $device, $baud) = @_;

    my $self = bless {
        rx_data     => '',
        rx_started  => 0,
        rx_ended    => 0,
    }, $class;

    $self->fd(tty_open($device, $baud));

    return $self;
}
sub close {
    tty_close($_[0]->fd);
}
sub crc {
    my ($self, $data) = @_;
    return crc16($data, length($data));
}
sub avail {
    return tty_available($_[0]->fd);
}
sub fd {
    my $self = shift;
    $self->{fd} = shift if @_;
    return $self->{fd};
}
sub flush {
    tty_flush($_[0]->fd);
}
sub putc {
    tty_putc($_[0]->fd, $_[1]);
}
sub puts {
    tty_puts($_[0]->fd, $_[1]);
}
sub getc {
    return tty_getc($_[0]->fd);
}
sub gets {
    # Returns the exact bytes read (binary-safe); may be shorter than the
    # requested count if the port's read timeout elapsed first.
    return tty_gets($_[0]->fd, $_[1]);
}
sub write {
    my ($self, $byte) = @_;
    if (! defined $byte){
        die "write() requires a byte of data sent in\n";
    }
    $self->putc(pack("C", $byte));
}
sub rx {
    my ($self, $start, $end) = @_;

    my $c = chr $self->getc; # getc() returns the ord() val on a char* perl-wise

    if ($c ne $start && ! $self->{rx_started}){
        $self->_rx_reset();
        return;
    }

    if ($c eq $start){
        $self->{rx_started} = 1;
        return;
    }

    if ($c eq $end){
        $self->{rx_ended} = 1;
    }

    if ($self->{rx_started} && ! $self->{rx_ended}){
        $self->{rx_data} .= $c;
    }

    if ($self->{rx_started} && $self->{rx_ended}){

        my $l_crc = $self->_local_crc($self->{rx_data});
        my $r_crc = $self->_remote_crc($self->{rx_data});

        if ($r_crc == $l_crc){
            my $rx_data = $self->{rx_data};
            $self->_rx_reset;
            return $rx_data;
        }
        else {
            warn "\ncompiled data '$self->{rx_data}' has mismatching CRC\n\n";
            $self->_rx_reset;
            return;
        }
    }
}
sub tx {
    my ($self, $data, $tx_start, $tx_end) = @_;

    my $crc = $self->crc($data);
    my $crc_msb = $crc >> 8;
    my $crc_lsb = $crc & 0xFF;

    my $tx = $tx_start . $data . $tx_end;

    for (split //, $tx){
        $self->write($_);
    }

    $self->write($crc_msb);
    $self->write($crc_lsb);
}

sub DESTROY {
    tty_close($_[0]->fd);
}

sub _local_crc {
    return $_[0]->crc($_[1]);
}
sub _remote_crc {
    my ($self) = @_;

    while ($self->avail < 2){} # loop until we have two bytes to make up the CRC

    my $crc_msb = $self->getc;
    my $crc_lsb = $self->getc;

    my $crc = ($crc_msb << 8) | $crc_lsb;

    return if $crc_msb == -1 || $crc_lsb == -1;
    return $crc;
}
sub _rx_reset {
    my ($self) = @_;
    $self->{rx_started} = 0;
    $self->{rx_ended} = 0;
    $self->{rx_data} = '';
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

    # Write a single char

    $ser->putc(5);

    # Write a string

    $ser->puts("hello, world!");

    # Write a single byte by its integer value (0-255)

    $ser->write(65);
    my $char = $ser->getc;

    # Get a string

    my $num_bytes = 12;
    my $str  = $ser->gets($num_bytes);

    # Send a CRC-framed payload between start/end delimiters

    $ser->tx("payload", "<", ">");

    # Receive a CRC-framed payload (call in a loop until it returns the data)

    my $frame = $ser->rx("<", ">");

    my $crc = $ser->crc($str);

    $ser->flush;

    my $bytes_available = $ser->avail;

    $ser->close;

=head1 DESCRIPTION

Provides basic read and write functionality of a UART serial interface

=head1 WARNING

If using on a Raspberry Pi platform, the procedure to enable GPIO pins 14 (TXD)
and 15 (RXD) as a serial interface differs by board. On B<all> boards, first
free the port from the kernel console: in C<raspi-config>, under C<Interface
Options -E<gt> Serial Port>, answer B<no> to the login shell and B<yes> to the
serial hardware.

=head2 Raspberry Pi 3 / 4 (and Zero W)

The on-board Bluetooth modem is wired to the primary PL011 UART, leaving GPIO
14/15 on the inferior, baud-unstable mini-UART (C</dev/ttyS0>). To move the good
UART onto the header pins you must disable Bluetooth. Edit
C</boot/firmware/config.txt> (C</boot/config.txt> on releases before Bookworm)
and add:

    enable_uart=1
    dtoverlay=disable-bt

With that overlay the header serial port becomes C</dev/ttyAMA0>.

=head2 Raspberry Pi 5

Bluetooth has its B<own dedicated UART> and is B<not> shared with the GPIO 14/15
pins, so there is nothing to disable. Just enable the header UART in
C</boot/firmware/config.txt>:

    enable_uart=1

The header serial port is C</dev/ttyAMA0>. (Note that on the Pi 5
C</dev/serial0> maps to the separate 3-pin debug-UART connector, B<not> the
header pins.)

Save the file, then reboot the Pi.

=head1 METHODS

=head2 new($device, $baud);

Opens the specified serial port at the specified baud rate, and returns a new
L<RPi::Serial> object.

Parameters:

    $device

Mandatory, String: The serial device to open (eg: C<"/dev/ttyAMA0">).

    $baud

Mandatory, Integer: A valid baud rate to use.

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

Read up to a specified number of bytes and return them as a string.

The read blocks only until the port's configured read timeout (the C<VTIME>
value set when the port was opened) elapses, so the returned string may be
B<shorter> than C<$num_bytes> if fewer bytes arrived in time (or the device
closed). The result is binary-safe: embedded C<NUL> bytes and trailing
whitespace are preserved exactly as received.

Parameters:

    $num_bytes

Mandatory, Integer; The maximum number of bytes to read. If this number is
larger than what is available, the call returns the bytes received before the
read timeout elapsed (possibly an empty string).

Returns: A string of the bytes actually read. Croaks on a read error.

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

=head2 crc($string)

Calculate and return a CRC-16 checksum. Uses local B<crc16.c> application to
generate the CRC.

Parameters:

    $string

Mandatory, String: The string to perform the checksum on.

=head2 write($byte)

Writes a single byte to the serial device. The byte is packed into an unsigned
char before being sent, making this a convenience wrapper around L</putc($char)>
that accepts an integer value rather than a character.

Parameters:

    $byte

Mandatory, Unsigned Integer (0-255): The byte value to write to the port.
Croaks if not supplied.

=head2 rx($start, $end)

Reads a single character from the serial port and assembles framed data across
successive calls. A frame begins when the C<$start> delimiter is received and
ends when the C<$end> delimiter is received, at which point the two trailing
CRC-16 bytes are read and validated against the assembled payload.

Call this repeatedly (eg: in a loop). Until a complete, CRC-valid frame has been
received it returns C<undef>; characters seen before the C<$start> delimiter are
discarded.

Parameters:

    $start

Mandatory, Char: The single character that marks the beginning of a frame.

    $end

Mandatory, Char: The single character that marks the end of a frame.

Returns: The assembled payload string once a full frame with a matching CRC has
been received, or C<undef> otherwise. Warns and discards the frame if the
received CRC does not match the locally computed one.

=head2 tx($data, $tx_start, $tx_end)

Transmits a frame of data. The C<$data> is wrapped between the C<$tx_start> and
C<$tx_end> delimiters and written to the port, followed by the two bytes (most
significant first) of the CRC-16 checksum calculated over C<$data>.

Parameters:

    $data

Mandatory, String: The payload to transmit.

    $tx_start

Mandatory, Char: The single character to send before the payload.

    $tx_end

Mandatory, Char: The single character to send after the payload.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
