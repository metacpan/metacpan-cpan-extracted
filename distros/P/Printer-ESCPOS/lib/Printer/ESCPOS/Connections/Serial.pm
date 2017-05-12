use strict;
use warnings;

package Printer::ESCPOS::Connections::Serial;

# PODNAME: Printer::ESCPOS::Connections::Serial
# ABSTRACT: Serial Connection Interface for L<Printer::ESCPOS> (supports status commands)
#
# This file is part of Printer-ESCPOS
#
# This software is copyright (c) 2017 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '1.006'; # VERSION

# Dependencies

use 5.010;
use Moo;
with 'Printer::ESCPOS::Roles::Connection';

use Device::SerialPort;
use Time::HiRes qw(usleep);


has deviceFilePath => ( is => 'ro', );


has baudrate => (
    is      => 'ro',
    default => 38400,
);


has readConstTime => (
    is      => 'ro',
    default => 150,
);


has serialOverUSB => (
    is      => 'rw',
    default => '0',
);

has _connection => (
    is       => 'lazy',
    init_arg => undef,
);

sub _build__connection {
    my ($self) = @_;

    my $printer = new Device::SerialPort( $self->deviceFilePath )
      || die "Can't open Port: $!\n";
    $printer->baudrate( $self->baudrate );
    $printer->read_const_time( $self->readConstTime )
      ;    # 1 second per unfulfilled "read" call
    $printer->read_char_time(0);    # don't wait for each character

    return $printer;
}


sub read {
    my ( $self, $question, $bytes ) = @_;
    $bytes |= 1024;

    $self->_connection->write($question);
    my ( $count, $data ) = $self->_connection->read($bytes);

    return $data;
}


sub print {
    my ( $self, $raw ) = @_;
    my @chunks;

    my $buffer = $self->_buffer;
    if ( defined $raw ) {
        $buffer = $raw;
    }
    else {
        $self->_buffer('');
    }

    my $n = 8;    # Size of each chunk in bytes
    $n = 64 if ( $self->serialOverUSB );

    @chunks = unpack "a$n" x ( ( length($buffer) / $n ) - 1 ) . "a*", $buffer;
    for my $chunk (@chunks) {
        $self->_connection->write($chunk);
        if ( $self->serialOverUSB ) {
            $self->_connection->read();
        }
        else {
            usleep(10000)
              ; # Serial Port is annoying, it doesn't tell you when it is ready to get the next chunk
        }
    }
}

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Printer::ESCPOS::Connections::Serial - Serial Connection Interface for L<Printer::ESCPOS> (supports status commands)

=head1 VERSION

version 1.006

=head1 ATTRIBUTES

=head2 deviceFilePath

This variable contains the path for the printer device file like '/dev/ttyS0' when connected as a serial device on
UNIX-like systems. For Windows this will be the serial port name like 'COM1', 'COM2' etc. This must be passed in the
constructor. I haven't tested this on windows, so if you are able to use serial port successfully on windows, drop me a
email to let me know that I got it right :)

=head2 baudrate

When used as a local serial device you can set the baudrate of the printer too. Default (38400) will usually work, but
not always.This param may be specified when creating printer object to make sure it works properly.

$printer = Printer::Thermal->new(deviceFilePath => '/dev/ttyACM0', baudrate => 9600);

=head2 readConstTime

Seconds per unfulfilled read call, default 150

=head2 serialOverUSB

Set this value to 1 if you are connecting your printer using the USB Cable but it shows up as a serial device

=head1 METHODS

=head2 read

Read Data from the printer

=head2 print

Sends buffer data to the printer.

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org> L<https://www.shantanubhadoria.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
