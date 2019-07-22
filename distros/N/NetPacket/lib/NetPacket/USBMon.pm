package NetPacket::USBMon;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Assemble and disassemble USB packets captured via Linux USBMon interface.
$NetPacket::USBMon::VERSION = '1.7.2';
use 5.10.0;
use strict;
use warnings;

use parent 'NetPacket';

our @EXPORT_OK = qw(
    USB_TYPE_SUBMISSION USB_TYPE_CALLBACK USB_TYPE_ERROR
    USB_XFER_TYPE_ISO USB_XFER_TYPE_INTR
    USB_XFER_TYPE_CONTROL USB_XFER_TYPE_BULK
    USB_FLAG_SETUP_IRRELEVANT USB_FLAG_SETUP_RELEVANT
    USB_FLAG_DATA_ERROR USB_FLAG_DATA_INCOMING
    USB_FLAG_DATA_OUTGOING USB_FLAG_DATA_PRESENT
    USB_TYPE_VENDOR
);

our %EXPORT_TAGS =(
    ALL         => \@EXPORT_OK,
    types       => [qw(USB_TYPE_SUBMISSION USB_TYPE_CALLBACK
                       USB_TYPE_ERROR)],
    xfer_types  => [qw(USB_XFER_TYPE_ISO USB_XFER_TYPE_INTR
                       USB_XFER_TYPE_CONTROL USB_XFER_TYPE_BULK)],
    setup_flags => [qw(USB_FLAG_SETUP_IRRELEVANT USB_FLAG_SETUP_RELEVANT)],
    data_flags  => [qw(USB_FLAG_DATA_ERROR USB_FLAG_DATA_INCOMING
                       USB_FLAG_DATA_OUTGOING USB_FLAG_DATA_PRESENT)],
    setup_types => [qw(USB_TYPE_VENDOR)],
);


use constant USB_TYPE_SUBMISSION        => 'S';
use constant USB_TYPE_CALLBACK          => 'C';
use constant USB_TYPE_ERROR             => 'E';

use constant USB_XFER_TYPE_ISO          => 0;
use constant USB_XFER_TYPE_INTR         => 1;
use constant USB_XFER_TYPE_CONTROL      => 2;
use constant USB_XFER_TYPE_BULK         => 3;

use constant USB_FLAG_SETUP_IRRELEVANT  => '-';
use constant USB_FLAG_SETUP_RELEVANT    => chr(0);

use constant USB_FLAG_DATA_ERROR        => 'E';
use constant USB_FLAG_DATA_INCOMING     => '<';
use constant USB_FLAG_DATA_OUTGOING     => '>';
use constant USB_FLAG_DATA_PRESENT      => chr(0);

use constant USB_TYPE_VENDOR            => 0x40;

sub decode
{
    my $class = shift;
    my $packet = shift;
    my $parent = shift;

    my($id, $type, $xfer_type, $epnum, $devnum, $busnum, $flag_setup,
        $flag_data, $ts_sec, $ts_usec, $status, $length, $len_cap,
        $s, $interval, $start_frame, $xfer_flags, $ndesc, $rest) =
        unpack('a8CCCCS<CCa8l<i<I<I<a8l<l<L<L<a*', $packet);

    # Try to grok quads. We may lose some address information with 32-bit
    # Perl parsing 64-bit captures, or timestamp after 2038. Still the best
    # we can do.
    eval {
      $id = unpack ('Q<', $id);
      $ts_sec = unpack ('Q<', $ts_sec);
    };
    if ($@) {
      ($id) = unpack ('L<L<', $id);
      ($ts_sec) = unpack ('L<L<', $ts_sec);
    }

    my $self = {
        _parent         => $parent,
        _frame          => $packet,

        id              => $id,
        type            => chr($type),
        xfer_type       => $xfer_type,
        ep              => {
            num         => ($epnum & 0x7f),
            dir         => ($epnum & 0x80 ? 'IN' : 'OUT'),
        },
        devnum          => $devnum,
        busnum          => $busnum,
        flag_setup      => chr($flag_setup),
        flag_data       => chr($flag_data),
        ts_sec          => $ts_sec,
        ts_usec         => $ts_usec,
        status          => $status,
        length          => $length,
        len_cap         => $len_cap,
        interval        => $interval,
        start_frame     => $start_frame,
        xfer_flags      => $xfer_flags,
        ndesc           => $ndesc,
    };

    # Setup
    if ($self->{flag_setup} ne USB_FLAG_SETUP_IRRELEVANT) {
        my $setup = {};
        my $rest;

       ($setup->{bmRequestType}, $setup->{bRequest}, $rest)
            = unpack('CCa*', $s);

        if ($setup->{bmRequestType} & USB_TYPE_VENDOR) {
           ($setup->{wValue}, $setup->{wIndex},
                $setup->{wLength}) = unpack('S<3', $rest);
        } else {
            # Unknown setup request;
            $setup->{data} = $rest;
        }

        $self->{setup} = $setup;
    }

    # Isochronous descriptors
    if ($self->{xfer_type} == USB_XFER_TYPE_ISO) {
        my $iso = {};
       ($iso->{error_count}, $iso->{numdesc}) = unpack('i<i<', $s);
        $self->{iso} = $iso;
    }

    # Data
    warn 'Payload length mismatch'
        if length($rest) ne $self->{len_cap};
    $self->{data} = $rest;

    return bless $self, $class;
}

1;

__END__

=pod

=head1 NAME

NetPacket::USBMon - Assemble and disassemble USB packets captured via Linux USBMon interface.

=head1 VERSION

version 1.7.2

=head1 SYNOPSIS

  use NetPacket::USBMon;

  $usb = NetPacket::USBMon->decode($raw_pkt);

=head1 DESCRIPTION

C<NetPacket::USBMon> is a L<NetPacket> decoder of USB packets captured via
Linux USBMon interface.

=head2 Methods

=over

=item C<NetPacket::USBMon-E<gt>decode([RAW PACKET])>

Decode a USB packet.

=back

=head2 Instance data

The instance data for the C<NetPacket::UDP> object consists of
the following fields.

=over

=item id

An in-kernel address of the USB Request Block (URB). Stays the same for the
transaction submission and completion.

Might be truncatted when reading a 64-bit capture with 32-bit file.

=item type

URB type. Character 'S', 'C' or 'E', for constants USB_TYPE_SUBMISSION,
USB_TYPE_CALLBACK or USB_TYPE_ERROR.

=item xfer_type

Transfer type. USB_XFER_TYPE_ISO, USB_XFER_TYPE_INTR, USB_XFER_TYPE_CONTROL
or USB_XFER_TYPE_BULK.

=item ep

Endpoint identification.

=over 8

=item num

Endpoint number.

=item dir

Transfer direction. "IN" or "OUT".

=back

=item devnum

Device address.

=item busnum

Bus number.

=item flag_setup

Indicates whether setup is present and makes sense.

=item flag_data

Indicates whether data is present and makes sense.

=item ts_sec

Timestamp seconds since epoch. Subject to truncation with 32-bit Perl,
which should be fine until 2038.

=item ts_usec

Timestamp microseconds.

=item status

URB status. Negative errno.

=item length

Length of data (submitted or actual).

=item len_cap

Delivered length

=item setup

Only present for packets with setup_flag turned on.
Some contents are dependent on actual request type.

=over 8

=item bmRequestType

=item bRequest

=item wValue

=item wIndex

=item wLength

=back

=item iso

Only present for isochronous transfers.

=over 8

=item error_count

=item numdesc

=back

=item interval

Isochronous packet response rate.

=item start_frame

Only applicable to isochronous transfers.

=item xfer_flags

A copy of URB's transfer_flags.

=item ndesc

Actual number of isochronous descriptors.

=item data

Packet payload.

=back

=head2 Exports

=over

=item default

none

=item exportable

USB_TYPE_SUBMISSION, USB_TYPE_CALLBACK, USB_TYPE_ERROR, USB_XFER_TYPE_ISO,
USB_XFER_TYPE_INTR, USB_XFER_TYPE_CONTROL, USB_XFER_TYPE_BULK,
USB_FLAG_SETUP_IRRELEVANT, USB_FLAG_SETUP_RELEVANT, USB_FLAG_DATA_ERROR,
USB_FLAG_DATA_INCOMING, USB_FLAG_DATA_OUTGOING, USB_FLAG_DATA_PRESENT,
USB_TYPE_VENDOR

=item tags

The following tags group together related exportable items.

=over

=item C<:types>

USB_TYPE_SUBMISSION, USB_TYPE_CALLBACK, USB_TYPE_ERROR

=item C<:xfer_types>

USB_XFER_TYPE_ISO, USB_XFER_TYPE_INTR, USB_XFER_TYPE_CONTROL, USB_XFER_TYPE_BULK

=item C<:setup_flags>

USB_FLAG_SETUP_IRRELEVANT, USB_FLAG_SETUP_RELEVANT

=item C<:data_flags>

USB_FLAG_DATA_ERROR, USB_FLAG_DATA_INCOMING, USB_FLAG_DATA_OUTGOING,
USB_FLAG_DATA_PRESENT

=item C<:setup_types>

USB_TYPE_VENDOR

=item C<:ALL>

All the above exportable items.

=back

=back

=head1 COPYRIGHT

Copyright (c) 2013 Lubomir Rintel.

This module is free software. You can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Lubomir Rintel E<lt>lkundrak@v3.skE<gt>

=cut
