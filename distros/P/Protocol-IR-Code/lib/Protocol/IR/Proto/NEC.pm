package Protocol::IR::Proto::NEC;
use strict;
use warnings;

our $VERSION = '1.1';
use Protocol::IR::Code;

# Protocol::IR::Proto::NEC is the base class for the whole NEC protocol family.
# The single-frame formats differ only along two independent axes, both
# taken from the MakeHex IRP files IRDB builds on (nec1.irp, nec2.irp,
# NECx1.irp, NECx2.irp):
#
#   header        NEC1/NEC2 use the full 9024/4512 µs preamble
#                 (Prefix=16,-8); NECx1/NECx2 use the half header
#                 4512/4512 µs (Prefix=8,-8, see _half_header).
#   subaddress    NEC1/NEC2 expect the subaddress byte to be the one's
#                 complement of the address (Default S=~D); NECx1/NECx2 use
#                 it as the low byte of a real 16-bit address (Default S=D),
#                 so it is never normalized to -1.
#
# NEC2 and NECx2 are timing-identical to NEC1 and NECx1 respectively for a
# single frame; the "2" variants only repeat the *entire* 32-bit frame
# instead of a short header+gap ditto frame, which is invisible to the
# single-frame decoders here. Their protocol name is preserved so repeat
# behavior survives conversion (see the individual subclass PODs).

# The protocol name this class decodes into / encodes as. Subclasses
# override this (NEC2, NECX1, NECX2).
sub _protocol_name { 'NEC' }

# True for the half-header (4512/4512 µs) NECx1/NECx2 framing; false for
# the full-header (9024/4512 µs) NEC1/NEC2 framing.
sub _half_header { 0 }

# True when an omitted subaddress means the one's complement of the address
# (Default S=~D, stored as -1); false when it means "copy the address"
# (Default S=D, stored as a real byte).
sub _inverted_subaddress_default { 1 }

# True when a raw subaddress byte equal to ~address is normalized to -1.
# NEC1/NEC2 treat that byte as redundant; NECx1/NECx2 keep it as part of the
# 16-bit address.
sub _normalize_subaddress { 1 }

sub _parse_int {
    my ($val) = @_;
    return 0 unless defined $val;
    $val =~ s/^\s+|\s+$//g;
    return hex($val) if $val =~ /^0x/i;
    return $val + 0;
}

sub decode_raw {
    my ($class, $raw_val) = @_;
    my $val = _parse_int($raw_val);

    my $addr    = ($val >> 24) & 0xFF;
    my $subaddr = ($val >> 16) & 0xFF;
    my $cmd     = ($val >> 8)  & 0xFF;

    if ($class->_normalize_subaddress && $subaddr == ((~$addr) & 0xFF)) {
        $subaddr = -1;
    }

    return Protocol::IR::Code->new(
        protocol   => $class->_protocol_name,
        bits       => 32,
        address    => $addr,
        subaddress => $subaddr,
        command    => $cmd,
        data       => $val,
    );
}

# True when the value decode_raw reads (Tasmota DataLSB) is the accumulated
# per-byte LSB-first wire form; the display form (Tasmota Data) is its
# per-byte bit reversal.
sub lsb_is_accumulated { 1 }

# Reverse the bits within each byte of a $bits-bit value, keeping the byte
# order. Each frame byte is sent LSB-first, so this maps between the
# accumulated value a receiver collects (Tasmota DataLSB, the "LSB" form the
# LIRC pre_data/post_data composition lands on) and the display form decode_raw
# reads. Arithmetic shifts rather than the 32-bit bitwise ops, so wide words
# survive whole.
sub _bit_reverse_bytes {
    my ($val, $bits) = @_;
    my $out = 0;
    for my $i (0 .. $bits - 1) {
        my $byte = int($i / 8);
        my $bit  = $i % 8;
        my $src  = 8 * $byte + (7 - $bit);
        $out |= (($val >> $src) & 1) << $i;
    }
    return $out;
}

# lsb=true is the form decode_raw reads (Tasmota DataLSB, the display hex);
# lsb=false is the accumulated wire form (Tasmota Data), reached from the
# display form by reversing the bits within each byte.
sub decode_byte_order {
    my ($class, $raw_val, $lsb) = @_;
    my $val = _parse_int($raw_val);
    return $class->decode_raw($lsb ? $val : _bit_reverse_bytes($val, 32));
}

sub decode_params {
    my ($class, %args) = @_;
    my $addr    = _parse_int($args{address} // $args{device} // 0);
    my $subaddr = _parse_int($args{subaddress} // $args{subdevice} // -1);
    my $cmd     = _parse_int($args{command} // $args{function} // 0);

    my ($real_subaddr, $stored_subaddr);
    if ($subaddr == -1) {
        # Omitted subaddress: derive it from the address per the IRP
        # "Default S=..." rule of this variant.
        if ($class->_inverted_subaddress_default) {
            $real_subaddr  = (~$addr) & 0xFF;
            $stored_subaddr = -1; # redundant byte, normalized away
        } else {
            $real_subaddr  = $addr & 0xFF;
            $stored_subaddr = $addr & 0xFF;
        }
    } else {
        $real_subaddr  = $subaddr & 0xFF;
        $stored_subaddr = $subaddr;
    }

    my $inv_cmd = (~$cmd) & 0xFF;

    my $data = (($addr & 0xFF) << 24) |
               (($real_subaddr) << 16) |
               (($cmd & 0xFF) << 8) |
               ($inv_cmd);

    return Protocol::IR::Code->new(
        protocol   => $class->_protocol_name,
        bits       => 32,
        address    => $addr,
        subaddress => $stored_subaddr,
        command    => $cmd,
        data       => $data,
    );
}

# Decode microsecond timing pairs into Protocol::IR::Code
sub decode_timing {
    my ($class, $burst_pairs) = @_;
    return undef unless scalar(@$burst_pairs) >= 34; # Header + 32 bits + Stop

    my ($hdr_mark, $hdr_space) = @{$burst_pairs->[0]};

    if ($class->_half_header) {
        # NECx1/NECx2 Header Check: ~4500 µs mark, ~4500 µs space
        return undef unless ($hdr_mark >= 3800 && $hdr_mark <= 5200) &&
                            ($hdr_space >= 3800 && $hdr_space <= 5200);
    } else {
        # NEC1/NEC2 Header Check: ~9000 µs mark, ~4500 µs space
        return undef unless ($hdr_mark >= 7500 && $hdr_mark <= 10500) &&
                            ($hdr_space >= 3500 && $hdr_space <= 5500);
    }

    my @bytes = (0, 0, 0, 0);
    for my $i (0 .. 31) {
        my $pair = $burst_pairs->[$i + 1];
        my $space = $pair->[1];

        # Space ~1687 µs = 1, ~562 µs = 0
        my $bit = ($space > 1100) ? 1 : 0;
        my $byte_idx = int($i / 8);
        my $bit_idx  = $i % 8; # LSB-first

        $bytes[$byte_idx] |= ($bit << $bit_idx);
    }

    my ($addr, $subaddr_raw, $cmd, $inv_cmd) = @bytes;

    # Stop bit: a short mark (~562 µs) followed by the long inter-message
    # space (~40000 µs, or the shorter repeat gap). This distinguishes NEC
    # frames from multi-frame captures of other protocols whose header
    # overlaps NEC's (e.g. JVC).
    my ($stop_mark, $stop_space) = @{$burst_pairs->[33]};
    return undef unless ($stop_mark >= 400 && $stop_mark <= 900) &&
                        ($stop_space >= 3000);

    my $subaddr = ($class->_normalize_subaddress &&
                   $subaddr_raw == ((~$addr) & 0xFF)) ? -1 : $subaddr_raw;
    my $data = ($addr << 24) | ($subaddr_raw << 16) | ($cmd << 8) | $inv_cmd;

    return Protocol::IR::Code->new(
        protocol   => $class->_protocol_name,
        bits       => 32,
        address    => $addr,
        subaddress => $subaddr,
        command    => $cmd,
        data       => $data,
    );
}

sub to_pronto {
    my ($class, $code) = @_;
    my $carrier_hz = 38000;

    # The Pronto frequency word is the carrier period in 0.241246 µs units,
    # rounded to an integer. Pronto parsers decode pulses using that rounded
    # word (freq_word * 0.241246), and MakeHex converts IRP timings to
    # pulses the same way, so build the pulse conversion period from it.
    # Using the exact 38 kHz period instead would make every pulse count
    # drift by +/-1 from the reference.
    my $freq_word  = int(sprintf("%.0f", 1000000.0 / ($carrier_hz * 0.241246)));
    my $period_us  = $freq_word * 0.241246;

    my $us_to_pulses = sub { int(sprintf("%.0f", $_[0] / $period_us)) };

    my $addr    = $code->address & 0xFF;
    # A code that reached to_pronto normally carries a real subaddress for
    # the NECx variants, but fall back to the IRP "Default S=..." rule if
    # it is still the -1 sentinel.
    my $subaddr = ($code->subaddress != -1)
        ? ($code->subaddress & 0xFF)
        : ($class->_inverted_subaddress_default
            ? ((~$addr) & 0xFF)
            : ($addr & 0xFF));
    my $cmd     = $code->command & 0xFF;
    my $inv_cmd = (~$cmd) & 0xFF;

    my @bytes = ($addr, $subaddr, $cmd, $inv_cmd);
    my @bits;
    for my $b (@bytes) {
        for my $i (0..7) { push @bits, ($b >> $i) & 1; }
    }

    my ($hdr_mark_us, $hdr_space_us) = $class->_half_header
        ? (4512, 4512)   # NECx1/NECx2: Prefix=8,-8  (8*564, 8*564)
        : (9024, 4512);  # NEC1/NEC2:   Prefix=16,-8 (16*564, 8*564)

    my @burst_pairs = (
        [$us_to_pulses->($hdr_mark_us), $us_to_pulses->($hdr_space_us)]
    );

    for my $bit (@bits) {
        push @burst_pairs, [
            $us_to_pulses->(562.5),
            $us_to_pulses->($bit ? 1687.5 : 562.5)
        ];
    }

    # Suffix=1,-78: a 564 µs stop mark and the inter-message space
    # (78*564 = ~44 ms), matching the MakeHex reference output.
    push @burst_pairs, [$us_to_pulses->(564), $us_to_pulses->(43992)];

    my $seq1_pairs = scalar @burst_pairs;

    my $header = sprintf("0000 %04X %04X 0000", $freq_word, $seq1_pairs);
    my @payload = map { sprintf("%04X %04X", $_->[0], $_->[1]) } @burst_pairs;

    return join(" ", $header, @payload);
}

1;

=encoding utf8

=head1 NAME

Protocol::IR::Proto::NEC - NEC protocol handler (32-bit) and NEC-family base class

=head1 VERSION

version 1.1

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # From a raw 32-bit value or from parameters
    my $code = $converter->import_code('NEC', '0x10EF00FF');
    my $code = $converter->import_code('NEC',
        { address => 16, command => 0 });

=head1 DESCRIPTION

The NEC protocol family transmits 32-bit frames at 38 kHz. Each frame is
four bytes -- B<address> (device), B<subaddress>, B<command>, and the
command's one's complement -- sent LSB-first, preceded by a header and
followed by a stop mark. The C<data> value matches Tasmota's C<Data> field:
B<address> in bits 24-31, B<subaddress> in bits 16-23, B<command> in
bits 8-15, and the inverted command in bits 0-7.

IRDB (via the MakeHex IRP files) distinguishes four single-frame formats:

=over 4

=item * C<NEC1> (this class) -- full 9000/4500 µs header, subaddress is the
one's complement of the address (Default S=~D), short header+gap repeat.

=item * C<NEC2> (L<Protocol::IR::Proto::NEC2>) -- identical single-frame timing to
NEC1; only the repeat differs (it re-transmits the whole frame).

=item * C<NECx1> (L<Protocol::IR::Proto::NECX1>) -- half 4500/4500 µs header,
subaddress is the low byte of a real 16-bit address (Default S=D), short
repeat.

=item * C<NECx2> (L<Protocol::IR::Proto::NECX2>) -- identical single-frame timing
to NECx1; whole-frame repeat.

=back

C<Protocol::IR::Proto::NEC> implements the shared machinery and doubles as the
base class; the variants only override the header, the subaddress rule, and
their protocol name. For a single frame NEC1 and NEC2 are timing-identical
and so are NECx1 and NECx2, so a timing decode cannot tell the "1" and "2"
forms apart -- the repeat structure is a property of the code's protocol
name, not of any single frame.

When the subaddress equals the one's complement of the address (the normal
case for standard NEC frames), C<subaddress> is normalized to C<-1> on the
resulting L<Protocol::IR::Code>. NECx1/NECx2 never normalize: their subaddress byte
is a real part of the 16-bit address.

Frame timing: header mark/space of B<9024/4512 µs> (NEC1/NEC2, the IRP
B<Prefix=16,-8> at a 564 µs time base) or B<4512/4512 µs> (NECx1/NECx2,
B<Prefix=8,-8>); each bit is a B<562.5 µs> mark followed by a space of
B<562.5 µs> for 0 or B<1687.5 µs> for 1. A B<564 µs> stop mark and the
inter-message space of B<~44 ms> (IRP B<Suffix=1,-78>) end the frame,
matching the MakeHex reference output for these IRPs.

The C<decode_timing> decoder validates both the header and the stop bit, so
a capture from an overlapping protocol (e.g. JVC, whose frame structure
starts with a similar header) is rejected rather than misidentified.

=head1 METHODS

=head2 decode_raw

    my $code = $class->decode_raw('0x10EF00FF');

Builds an L<Protocol::IR::Code> from the raw 32-bit value.

=head2 decode_byte_order

    my $code = $class->decode_byte_order($raw, $lsb);

Decodes from either byte order: C<$lsb> true reads the accumulated (DataLSB)
form directly; false reads the display (Data) form, the per-byte bit reversal
of the accumulated word (the Tasmota C<Data> field and the IRDB C<Code>
column). NEC sends each byte LSB-first, so the accumulated word is the one
carried on the wire and by Tasmota's C<DataLSB>.

=head2 lsb_is_accumulated

    my $flag = $class->lsb_is_accumulated;

True (always, for NEC) when the accumulated byte order is what
C<decode_raw> reads, informing the Tasmota structured importer which of its
C<Data>/C<DataLSB> fields to prefer.

=head2 decode_params

    my $code = $class->decode_params(address => 16, command => 0);

Builds an L<Protocol::IR::Code> from discrete parameters. Accepts C<address> or
C<device>, C<subaddress> or C<subdevice>, and C<command> or C<function>.

=head2 decode_timing

    my $code = $class->decode_timing(\@burst_pairs_us);

Decodes an arrayref of microsecond C<[mark_us, space_us]> pairs. Returns an
L<Protocol::IR::Code> when the header, 32 data bits, and stop bit match the NEC
timing signature, otherwise C<undef>.

=head2 to_pronto

    my $pronto = $class->to_pronto($ir_code);

Encodes an L<Protocol::IR::Code> object as a Pronto Hex string at 38 kHz.

=head1 SUPPORT

Source code: L<https://github.com/bwarden/perl-protocol-ir>

Bug reports and feature requests: L<https://github.com/bwarden/perl-protocol-ir/issues>

=head1 AUTHOR

Brett T. Warden <bwarden@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Brett T. Warden

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License version 2.1 as
published by the Free Software Foundation.
