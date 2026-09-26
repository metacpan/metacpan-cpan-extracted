package Protocol::IR::Proto::SAMSUNG;
use strict;
use warnings;

our $VERSION = '1.2';
use Protocol::IR::Code;

# Timing and bit ordering follow IRremoteESP8266 (Copyright David Conran et al.,
# GPLv2, https://github.com/crankyoldgit/IRremoteESP8266):
#   kSamsungHdrMark/Space = 8 * 560 µs, kSamsungBitMark = 560 µs,
#   kSamsungOneSpace = 3 * 560 µs, kSamsungZeroSpace = 560 µs, 32 bits.
# The 32-bit value is transmitted with the most significant byte first and
# each byte LSB-first within, so the value collected from a capture (and
# stored in ->data) matches Tasmota's DataLSB field. The customer (address)
# and command bytes are bit-reversed on the wire.

sub _parse_int {
    my ($val) = @_;
    return 0 unless defined $val;
    $val =~ s/^\s+|\s+$//g;
    return hex($val) if $val =~ /^0x/i;
    return $val + 0;
}

sub _reverse_bits {
    my ($val) = @_;
    my $out = 0;
    for my $i (0 .. 7) {
        $out |= (($val >> $i) & 1) << (7 - $i);
    }
    return $out;
}

# Reverse the bits within each of the four bytes of a 32-bit value.
sub _byte_reverse {
    my ($val) = @_;
    my $out = 0;
    for my $i (0 .. 31) {
        my $byte = int($i / 8);
        my $bit  = $i % 8;
        my $src  = 8 * $byte + (7 - $bit);
        $out |= (($val >> $src) & 1) << $i;
    }
    return $out;
}

# Pack customer (address) + command into the transmitted 32-bit value.
sub _encode_data {
    my ($addr, $cmd) = @_;
    my $rev_customer = _reverse_bits($addr & 0xFF);
    my $rev_command  = _reverse_bits($cmd & 0xFF);
    return (($rev_command ^ 0xFF) |
            ($rev_command << 8) |
            ($rev_customer << 16) |
            ($rev_customer << 24));
}

sub decode_raw {
    my ($class, $raw_val) = @_;
    my $val = _parse_int($raw_val);
    return $class->decode_params(
        address => ($val >> 16) & 0xFF,
        command => ($val >> 8)  & 0xFF,
    );
}

# True when the value decode_raw reads (Tasmota DataLSB) is the accumulated
# per-byte LSB-first wire form; the display form (Tasmota Data) is its
# per-byte bit reversal.
sub lsb_is_accumulated { 1 }

# lsb=true is the accumulated wire form (Tasmota DataLSB), which must be
# per-byte bit-reversed to reach the display form decode_raw reads (Tasmota
# Data, the hex LIRC and IRDB carry); lsb=false is that display form as-is.
# SAMSUNG's polarity is the reverse of NEC/JVC because the P-data displayed
# hexes (0xE0E040BF) are already the display form, not decode_raw's input.
sub decode_byte_order {
    my ($class, $raw_val, $lsb) = @_;
    my $val = _parse_int($raw_val);
    return $class->decode_raw($lsb ? _byte_reverse($val) : $val);
}

sub decode_params {
    my ($class, %args) = @_;
    my $addr = _parse_int($args{address} // $args{device} // 0) & 0xFF;
    my $cmd  = _parse_int($args{command} // $args{function} // 0) & 0xFF;

    return Protocol::IR::Code->new(
        protocol   => 'SAMSUNG',
        bits       => 32,
        address    => $addr,
        subaddress => -1,
        command    => $cmd,
        data       => _encode_data($addr, $cmd),
    );
}

# Decode microsecond timing pairs into Protocol::IR::Code
sub decode_timing {
    my ($class, $burst_pairs) = @_;
    return undef unless scalar(@$burst_pairs) >= 34; # Header + 32 bits + Stop

    my ($hdr_mark, $hdr_space) = @{$burst_pairs->[0]};

    # SAMSUNG Header Check: ~4500 µs mark, ~4500 µs space
    return undef unless ($hdr_mark >= 3800 && $hdr_mark <= 5200) &&
                        ($hdr_space >= 3800 && $hdr_space <= 5200);

    my @bytes = (0, 0, 0, 0);
    for my $i (0 .. 31) {
        my $space = $burst_pairs->[$i + 1]->[1];

        # Space ~1680 µs = 1, ~560 µs = 0
        my $bit = ($space > 1000) ? 1 : 0;
        my $byte_idx = int($i / 8);
        my $bit_idx  = $i % 8; # LSB-first

        $bytes[$byte_idx] |= ($bit << $bit_idx);
    }

    # Stop bit: a short mark followed by the long trailing space
    my ($stop_mark, $stop_space) = @{$burst_pairs->[33]};
    return undef unless ($stop_mark >= 350 && $stop_mark <= 900) &&
                        ($stop_space >= 3000);

    # Samsung sends the address byte twice and the command byte followed by
    # its one's complement, so the frame bytes read back as addr, addr, cmd,
    # ~cmd. Enforce that structure (matching IRremoteESP8266's strict
    # decodeSAMSUNG compliance checks) so half-header NECx frames, which
    # share the 4480/4480 µs header and per-byte LSB-first bit timing but
    # carry a real subaddress byte instead of a repeated address, are not
    # mislabelled as SAMSUNG. The reference decoder reports those as UNKNOWN.
    return undef unless $bytes[0] == $bytes[1] &&
                        $bytes[2] == (($bytes[3] ^ 0xFF) & 0xFF);

    # Value is transmitted LSB-first per byte, so the first received byte is
    # the most significant byte of the value (matching Tasmota's DataLSB).
    my $data = ($bytes[0] << 24) | ($bytes[1] << 16) |
               ($bytes[2] << 8)  | $bytes[3];

    return Protocol::IR::Code->new(
        protocol   => 'SAMSUNG',
        bits       => 32,
        address    => _reverse_bits(($data >> 24) & 0xFF),
        subaddress => -1,
        command    => _reverse_bits(($data >> 8) & 0xFF),
        data       => $data,
    );
}

# Convert a SAMSUNG code to its NECx2 equivalent parameters.
# Samsung address/command are the bit-reversal of the NECx2 device/subdevice
# and command bytes respectively, because Samsung transmits the same wire
# bitstream as NECX2 but labels the fields differently:
#   SAMSUNG addr 0xE0  ==  NECx2 device   7   (reverse_byte(0xE0) = 0x07)
#   SAMSUNG cmd  0x40  ==  NECx2 function 2   (reverse_byte(0x40) = 0x02)
# Returns a hashref suitable for import_code('NECX2', \%params).
#
# NOTE: IRDB labels these Samsung TV codes as NECX2 with the Samsung-native
# address and command values (device=7 is the Samsung addr 0xE0; function=2
# is the Samsung cmd 0x40).  The data word is the same (0x070702FD), and
# import_code('NECX2', {device=>7, subdevice=>7, command=>2}) reproduces
# it.  This method therefore returns the IRDB-compatible values (the
# bit-reversed form), not the raw Samsung values.
sub as_necx2_params {
    my ($self, $code) = @_;
    my $device   = Protocol::IR::Code::reverse_byte($code->address & 0xFF);
    my $function = Protocol::IR::Code::reverse_byte($code->command & 0xFF);
    return {
        device    => $device,
        subdevice => $device,
        command   => $function,
    };
}

sub to_pronto {
    my ($class, $code) = @_;
    my $carrier_hz = 38000;

    # Build the pulse conversion period from the rounded Pronto frequency
    # word, as MakeHex and Pronto parsers do (see Protocol::IR::Proto::NEC).
    my $freq_word  = int(sprintf("%.0f", 1000000.0 / ($carrier_hz * 0.241246)));
    my $period_us  = $freq_word * 0.241246;

    my $us_to_pulses = sub { int(sprintf("%.0f", $_[0] / $period_us)) };

    my $data = _encode_data($code->address, $code->command);

    # The value is transmitted with the most significant byte first and each
    # byte LSB-first within. The wire bytes are the MSB display form (Tasmota's
    # Data field), which is the per-byte bit reversal of the collected value.
    my $msb_val = _byte_reverse($data);

    my @burst_pairs = (
        [$us_to_pulses->(4480), $us_to_pulses->(4480)]
    );

    for (my $i = 31; $i >= 0; $i--) {
        my $bit = ($msb_val >> $i) & 1;
        push @burst_pairs, [
            $us_to_pulses->(560),
            $us_to_pulses->($bit ? 1680 : 560)
        ];
    }

    push @burst_pairs, [$us_to_pulses->(560), $us_to_pulses->(30000)];

    my $seq1_pairs = scalar @burst_pairs;

    my $header = sprintf("0000 %04X %04X 0000", $freq_word, $seq1_pairs);
    my @payload = map { sprintf("%04X %04X", $_->[0], $_->[1]) } @burst_pairs;

    return join(" ", $header, @payload);
}

1;

=encoding utf8

=head1 NAME

Protocol::IR::Proto::SAMSUNG - SAMSUNG protocol handler (32-bit)

=head1 VERSION

version 1.2

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # From a raw value (MSB display form) or from parameters
    my $code = $converter->import_code('SAMSUNG', '0xE0E09966');
    my $code = $converter->import_code('SAMSUNG',
        { address => 0xE0, command => 0x99 });

=head1 DESCRIPTION

The SAMSUNG protocol transmits a 32-bit frame at 38 kHz: a customer
(address) byte, its one's complement, a command byte, and the command's
one's complement. The 32-bit value is transmitted with the most significant
byte first and each byte LSB-first within, so the value collected from a
capture (and stored in C<data>) matches Tasmota's C<DataLSB> field; the
C<data> value exposed for a raw import is the MSB display form (Tasmota's
C<Data> field). The customer and command bytes are bit-reversed on the wire
relative to their logical values. SAMSUNG has no subaddress;
C<subaddress> is set to C<-1>.

Frame timing: B<4480 µs> header mark and B<4480 µs> header space; each bit
is a B<560 µs> mark followed by a space of B<560 µs> for 0 or B<1680 µs>
for 1; a B<560 µs> stop mark ends the frame.

Timing and bit ordering follow IRremoteESP8266 (David Conran et al., GPLv2,
L<https://github.com/crankyoldgit/IRremoteESP8266>): C<kSamsungHdrMark>/
C<kSamsungHdrSpace> = 8 * 560 µs, C<kSamsungBitMark> = 560 µs,
C<kSamsungOneSpace> = 3 * 560 µs, C<kSamsungZeroSpace> = 560 µs, 32 bits.

=head1 METHODS

=head2 decode_raw

    my $code = $class->decode_raw('0xE0E09966');

Builds an L<Protocol::IR::Code> from the raw 32-bit value.

=head2 decode_byte_order

    my $code = $class->decode_byte_order($raw, $lsb);

Decodes from either byte order: C<$lsb> true reads the accumulated (DataLSB)
form; false reads the display (Data) form, and reverses the bytes to reach it.
Samsung is the opposite of NEC's polarity: C<decode_raw> reads the display
form directly (its C<data> field carries the accumulated word), so C<$lsb>
false needs no reversal and true reverses once.

=head2 lsb_is_accumulated

    my $flag = $class->lsb_is_accumulated;

True (always, for SAMSUNG) when the accumulated byte order is what
C<decode_raw> reads, informing the Tasmota structured importer which of its
C<Data>/C<DataLSB> fields to prefer.

=head2 decode_params

    my $code = $class->decode_params(address => 0xE0, command => 0x99);

Builds an L<Protocol::IR::Code> from discrete parameters. Accepts C<address> or
C<device>, and C<command> or C<function>.

=head2 decode_timing

    my $code = $class->decode_timing(\@burst_pairs_us);

Decodes an arrayref of microsecond C<[mark_us, space_us]> pairs. Returns an
L<Protocol::IR::Code> when the header, 32 data bits, and stop bit match the SAMSUNG
timing signature, otherwise C<undef>.

=head2 to_pronto

    my $pronto = $class->to_pronto($ir_code);

Encodes an L<Protocol::IR::Code> object as a Pronto Hex string at 38 kHz.

=head2 as_necx2_params

    my $params = $class->as_necx2_params($code);

Converts a SAMSUNG code to its L<Protocol::IR::Proto::NECX2> equivalent
parameter hashref.  The Samsung address and command are bit-reversed to
produce the NECX2 device and function values respectively.  The subaddress
is set equal to the device (Samsung's address-repeated convention mapped
to NECX2's C<Default S=D>).

The returned hashref is suitable for
C<< $converter->import_code('NECX2', $params) >>.

Example:

    # Samsung TV POWER: address=0xE0, command=0x40
    #   -> NECX2 device=7, subdevice=7, function=2
    my $necx2_params = Protocol::IR::Proto::SAMSUNG->as_necx2_params($code);

This is used by L<Protocol::IR::Converter/cross_protocol> and is also
available for direct use when building IRDB lookup tables.

=head1 CROSS-PROTOCOL MAPPING

The SAMSUNG protocol shares identical timing with L<Protocol::IR::Proto::NECX2>:
both use a B<4500/4500 µs> half header, B<560/1680 µs> bit timing, 32 bits,
per-byte LSB-first.  The two protocols differ only in field naming:

=over 4

=item SAMSUNG sends C<addr, addr, cmd, ~cmd> on the wire.

=item NECX2 sends C<device, subdevice, function, ~function>.

=back

Because Samsung's address byte is repeated while NECX2 carries a real
subaddress byte, the two cannot always be converted.  However, when the
NECX2 subaddress equals the device byte (the common case for Samsung TV
codes in IRDB), the Samsung address is the bit-reversal of the NECX2
device byte, and likewise for the command/function byte.

IRDB labels its Samsung TV entries as NECX2 with the Samsung address and
command values in the device and function columns (e.g. Samsung TV POWER
is C<NECx2,7,7,2>: device 7 is the bit-reversal of address 0xE0, function
2 is the bit-reversal of command 0x40).

Use L<Protocol::IR::Converter/cross_protocol> to convert between the two
automatically, or call C<as_necx2_params> directly for IRDB lookups.

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
