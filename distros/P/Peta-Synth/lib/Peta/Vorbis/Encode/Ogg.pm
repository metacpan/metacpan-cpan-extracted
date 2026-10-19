package Peta::Vorbis::Encode::Ogg;
# ABSTRACT: Ogg pages around Vorbis packets

# Ogg pages around packets (RFC 3533): a header of 27 bytes ("OggS",
# version, flags, granule position, stream serial, page number, CRC, the
# number of segments), the segment table (each packet as segments of 255
# bytes and a last shorter one), the packets' bytes. The CRC is the
# CRC-32 of the polynomial 0x04C11DB7, not reflected, over the page with
# its own field zero.
#
# A page's granule position is that of the last packet finished on it
# (-1 when none is); for Vorbis, the number of samples decoded through it.

use v5.36;

our $VERSION = '0.2610180';

# The header type flags; and how full a page gets before it goes out.
use constant {
    CONTINUED  => 1,    # the page begins with the rest of a packet
    FIRST      => 2,    # the stream's first page
    LAST       => 4,    # its last
    PAGE_BYTES => 4096,
};

# The CRC of each byte value, for a byte at a time.
my @CRC;
for my $i (0 .. 255) {
    my $r = $i << 24;
    for (1 .. 8) {
        $r = $r & 0x80000000 ? ($r << 1) ^ 0x04C11DB7 : $r << 1;
        $r &= 0xFFFFFFFF;
    }
    $CRC[$i] = $r;
}

sub crc ($bytes) {
    my $crc = 0;
    for my $byte (unpack 'C*', $bytes) {
        $crc = (($crc << 8) & 0xFFFFFFFF) ^ $CRC[ (($crc >> 24) ^ $byte) & 0xFF ];
    }
    return $crc;
}

sub new ($class, $serial) {
    return bless {
        serial   => $serial,
        page     => 0,      # the next page's number
        segments => [],     # the lacing values of the page being made
        body     => '',     # and its bytes
        granule  => -1,     # its granule position
        first    => 1,      # whether it is the stream's first
    }, $class;
}

# A packet onto the page being made: its segments, and the granule position
# once it is finished. Returns the pages it filled; with $last, the stream's
# last page too, which ends with this packet.
sub packet ($self, $bytes, $granule, $last = 0) {
    my $out = '';
    my @lacing = ((255) x int(length($bytes) / 255), length($bytes) % 255);
    while (@lacing) {
        my $room = 255 - @{ $self->{segments} };
        if ($room == 0) { $out .= $self->_page(0); next }
        my @take = splice @lacing, 0, $room;
        my $len = 0;
        $len += $_ for @take;
        push @{ $self->{segments} }, @take;
        $self->{body} .= substr $bytes, 0, $len, '';
        $self->{granule} = $granule if !@lacing;    # the packet ends on this page
        $self->{continued_next} = @lacing ? 1 : 0;
    }
    if    ($last)                             { $out .= $self->_page(1) }
    elsif (length $self->{body} >= PAGE_BYTES) { $out .= $self->_page(0) }
    return $out;
}

# The page being made, out now (the headers end their pages).
sub flush ($self) {
    return '' if !@{ $self->{segments} };
    return $self->_page(0);
}

sub _page ($self, $last) {
    my $flags = ($self->{continuing} ? CONTINUED : 0)
              | ($self->{first}      ? FIRST     : 0)
              | ($last               ? LAST      : 0);
    my @segments = @{ $self->{segments} };

    my $page = join '',
        'OggS',
        pack('C C', 0, $flags),                        # version, flags
        pack('q<', $self->{granule}),
        pack('V V V', $self->{serial}, $self->{page}++, 0),    # the CRC, 0 while it is computed
        pack('C', scalar @segments),
        pack('C*', @segments),
        $self->{body};
    substr($page, 22, 4) = pack 'V', crc($page);

    $self->{continuing} = $self->{continued_next};
    $self->{continued_next} = 0;
    $self->{first} = 0;
    $self->{segments} = [];
    $self->{body} = '';
    $self->{granule} = -1;
    return $page;
}

# Bits packed as Vorbis packs them: from the least significant bit of each
# byte up.
package Peta::Vorbis::Encode::Bits {
    sub new ($class) { return bless { bytes => '', acc => 0, count => 0, bits => 0 }, $class }

    sub put ($self, $value, $width) {
        return if !$width;
        while ($width > 24) {    # wide values in two pieces
            $self->put($value & 0xFFFF, 16);
            $value >>= 16;
            $width -= 16;
        }
        $self->{acc} |= ($value & ((1 << $width) - 1)) << $self->{count};
        $self->{count} += $width;
        $self->{bits}  += $width;
        while ($self->{count} >= 8) {
            $self->{bytes} .= chr($self->{acc} & 0xFF);
            $self->{acc} >>= 8;
            $self->{count} -= 8;
        }
        return;
    }

    sub bits ($self) { return $self->{bits} }

    # Everything written, the last byte filled up with zeros.
    sub bytes ($self) {
        return $self->{bytes} if !$self->{count};
        return $self->{bytes} . chr($self->{acc} & 0xFF);
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Vorbis::Encode::Ogg - Ogg pages around Vorbis packets

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $ogg = Peta::Vorbis::Encode::Ogg->new($serial);
    print $fh $ogg->packet($header, 0), $ogg->flush;
    print $fh $ogg->packet($audio, $granule);
    print $fh $ogg->packet($audio, $granule, 1);    # the last, on the last page

=head1 DESCRIPTION

Ogg's framing (RFC 3533) around a logical stream of packets: the lacing
of each packet into segments, pages of up to 255 segments with their
granule positions, sequence numbers and CRCs. Peta::Vorbis::Encode::Bits,
beside it, packs the packets' bits, from the least significant, as Vorbis
I writes them.

=head1 METHODS

=head2 new

C<new($serial)>: a stream of that serial number, its first page to come.

=head2 packet

C<packet($bytes, $granule, $last = 0)>: a packet onto the page being
made, the granule position once it is finished; the pages it filled, and
with C<$last> the stream's last page too, which ends with it.

=head2 flush

The page being made, out now (the headers end their pages).

=head1 FUNCTIONS

=head2 crc

C<crc($bytes)>: Ogg's CRC-32 of a page.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
