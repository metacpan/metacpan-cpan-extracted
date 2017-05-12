use strict;
use warnings;

package Printer::ESCPOS::Connections::USB;

# PODNAME: Printer::ESCPOS::Connections::USB
# ABSTRACT: USB Connection Interface for L<Printer::ESCPOS>
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

use Device::USB;
use Time::HiRes qw(usleep);


has vendorId => (
    is       => 'ro',
    required => 1,
);


has productId => (
    is       => 'ro',
    required => 1,
);


has endPoint => (
    is       => 'ro',
    required => 1,
    default  => 0x01,
);


has timeout => (
    is       => 'ro',
    required => 1,
    default  => 1000,
);

has _connection => (
    is       => 'lazy',
    init_arg => undef,
);

sub _build__connection {
    my ($self) = @_;

    my $usb = Device::USB->new();
    my $device = $usb->find_device( $self->vendorId, $self->productId );

    if ( $device->get_driver_np(0) ) {
        $device->detach_kernel_driver_np();
    }
    $device->open();
    $device->reset();

    return $device;
}


sub read {
    my ( $self, $question, $bytes ) = @_;
    my $data;
    $bytes |= 1024;

    $self->_connection->bulk_write( $self->endPoint, $question,
        $self->timeout );
    $self->_connection->bulk_read( $self->endPoint, $data, $bytes,
        $self->timeout );

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

    my $n = 2**14;    # Size of each chunk in bytes
    @chunks = unpack "a$n" x ( ( length($buffer) / $n ) - 1 ) . "a*", $buffer;
    for my $chunk (@chunks) {
        $self->_connection->bulk_write( $self->endPoint, $chunk,
            $self->timeout );
        usleep(10000)
          ; # USB Port is sometimes annoying, it doesn't always tell you when it is ready to get the next chunk
    }
}

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Printer::ESCPOS::Connections::USB - USB Connection Interface for L<Printer::ESCPOS>

=head1 VERSION

version 1.006

=head1 SYNOPSIS

For using the printer in USB mode you will need to get a few details for your printer.

retrieve the I<vendorId> and I<productId> params using the lsusb command

     shantanu@shantanu-G41M-ES2L:~$ lsusb
     Bus 002 Device 002: ID 8087:8000 Intel Corp.
     Bus 002 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
     Bus 001 Device 002: ID 8087:8008 Intel Corp.
     Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
     Bus 004 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
     Bus 003 Device 020: ID 05e0:1200 Symbol Technologies Bar Code Scanner
     Bus 003 Device 005: ID 413c:2111 Dell Computer Corp.
     Bus 003 Device 004: ID 046d:c03e Logitech, Inc. Premium Optical Wheel Mouse (M-BT58)
     Bus 003 Device 009: ID 1cbe:0002 Luminary Micro Inc.
     Bus 003 Device 007: ID 0cf3:0036 Atheros Communications, Inc.
     Bus 003 Device 008: ID 1504:0006
     Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub

My printer shows up at the second to last line in the list.

     Bus 003 Device 008: ID 1504:0006

The I<vendorId> and I<productId> for my printer is 0x1504 and 0x0006 respectively

Now to get the I<endPoint> value for my printer I use this command:

     shantanu@shantanu-G41M-ES2L:~/test$ sudo lsusb -vvv -d 1504:0006 | grep bEndpointAddress | grep OUT
             bEndpointAddress     0x01  EP 1 OUT

The endpoint address is 0x01 which is the default for the module.

Now you have all the values you need for your printer to work in USB mode.

     $device = Printer::ESCPOS->new(
         driverType => 'USB',
         vendorId   => 0x1504,
         productId  => 0x0006,
         endPoint   => 0x01,   # There is no need to specify endPOint in
                               # this case as 0x01 is the default value
     );
     $device->printer->text("Blah Blah\n");
     $device->printer->print();

=head1 ATTRIBUTES

=head2 vendorId

USB Printers VendorId. use lsusb command to get this value

=head2 productId

USB Printers product Id. use lsusb command to get this value

=head2 endPoint

USB endPoint to write to.

=head2 timeout

Timeout for bulk write functions for the USB printer.

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
