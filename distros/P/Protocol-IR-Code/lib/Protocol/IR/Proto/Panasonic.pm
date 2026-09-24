package Protocol::IR::Proto::Panasonic;
use strict;
use warnings;

our $VERSION = '1.0';
use Protocol::IR::Code;

=pod

=head1 NAME

Protocol::IR::Proto::Panasonic - Panasonic (Kaseikyo) protocol handler

=head1 VERSION

Version 1.0

=head1 DESCRIPTION

The Panasonic protocol handler (48-bit, Kaseikyo family, OEM code 0x40/0x04),
from the DecodeIR definition:

  {36k,432}<1,-1|1,-3>(8,-4,M:8,ID:8,D:8,S:8,F:8,(D^S^F):8,1,-173)+

Six bytes are transmitted in order (Mfg_hi=0x40, Mfg_lo=0x04, device,
subdevice, function, checksum) behind a 3456/1728 us header.  The frame is
structured identically to JVC-48 (Kaseikyo family) with different OEM codes.
Each byte is sent MSB-first on the wire, so the value a receiver accumulates
(Tasmota's DataLSB) has per-byte bit-reversed OEM and device/function bytes.
The address and command fields follow the IRDB convention: they store the
bit-reversed wire byte (e.g. wire device 0x01 -> address 128 = 0x80), which
is the accumulated form the decoder naturally produces.  The checksum byte is
device^subdevice^function in the IRDB (accumulated) convention.

=cut

sub _parse_int {
    my ($val) = @_;
    return 0 unless defined $val;
    $val =~ s/^\s+|\s+$//g;
    if ($val =~ /^0x/i) {
        no warnings 'portable';
        return hex($val);
    }
    return $val + 0;
}

# Reverse the bits within each byte of a 48-bit value, keeping the byte order.
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

# Reverse the bits within a single byte.
sub _reverse_byte {
    my ($val) = @_;
    my $out = 0;
    for my $i (0 .. 7) {
        $out |= (($val >> $i) & 1) << (7 - $i);
    }
    return $out;
}

# Panasonic manufacturer codes (wire form): 0x40, 0x04.
# The accumulated (bit-reversed) forms used in the data field are 0x02, 0x20.
use constant MFG_HI     => 0x40;
use constant MFG_LO     => 0x04;
use constant MFG_HI_ACC => 0x02;  # reverseBits(0x40)
use constant MFG_LO_ACC => 0x20;  # reverseBits(0x04)
use constant BITS       => 48;

sub lsb_is_accumulated { 1 }

# Pack device/subdevice/function into the transmitted 48-bit accumulated
# value, computing the checksum byte per the D^S^F rule.  The address and
# command follow the IRDB convention (bit-reversed wire bytes), so the OEM
# bytes must also be reversed to match the accumulated form.
sub _encode_data {
    my ($addr, $subaddr, $cmd) = @_;
    my $a = $addr & 0xFF;
    my $s = $subaddr & 0xFF;
    my $f = $cmd & 0xFF;
    return (MFG_HI_ACC << 40) | (MFG_LO_ACC << 32) | ($a << 24) |
           ($s << 16) | ($f << 8) | ($a ^ $s ^ $f);
}

sub decode_raw {
    my ($class, $raw_val) = @_;
    my $val = _parse_int($raw_val);

    # decodeRaw expects the display form (Tasmota Data): the frame bytes are
    # bit-reversed on the wire, so each byte in the display form must be
    # reversed to reach the accumulated / IRDB convention for address and command.
    my $addr = _reverse_byte(($val >> 24) & 0xFF);
    my $sub  = _reverse_byte(($val >> 16) & 0xFF);
    my $cmd  = _reverse_byte(($val >> 8) & 0xFF);

    # Re-pack the canonical accumulated word via _encode_data rather than
    # storing the display word as-is, so the DataLSB import and the Data
    # import land on the same data value (matching the other protocols and
    # the JS port, where decode_raw routes through decode_params).
    return Protocol::IR::Code->new(
        protocol   => 'PANASONIC',
        bits       => BITS,
        address    => $addr,
        subaddress => $sub,
        command    => $cmd,
        data       => _encode_data($addr, $sub, $cmd),
    );
}

# lsb=true is the accumulated form (Tasmota DataLSB);
# lsb=false is the display form, reached by reversing the bits within each
# byte (the frame bytes are each sent MSB-first on the wire).
sub decode_byte_order {
    my ($class, $raw_val, $lsb) = @_;
    my $val = _parse_int($raw_val);
    return $class->decode_raw($lsb ? _bit_reverse_bytes($val, 48) : $val);
}

sub decode_params {
    my ($class, %args) = @_;
    my $addr        = _parse_int($args{address} // $args{device} // 0) & 0xFF;
    my $subaddr_arg = _parse_int($args{subaddress} // $args{subdevice} // -1);
    my $cmd         = _parse_int($args{command} // $args{function} // 0) & 0xFF;

    my $subaddr = ($subaddr_arg == -1) ? 0 : $subaddr_arg & 0xFF;

    return Protocol::IR::Code->new(
        protocol   => 'PANASONIC',
        bits       => BITS,
        address    => $addr,
        subaddress => $subaddr_arg,
        command    => $cmd,
        data       => _encode_data($addr, $subaddr, $cmd),
    );
}

sub decode_timing {
    my ($class, $burst_pairs) = @_;
    return undef unless scalar(@$burst_pairs) >= 50; # Header + 48 bits + Stop

    my ($hdr_mark, $hdr_space) = @{$burst_pairs->[0]};

    # Panasonic Header Check: ~3456us mark, ~1728us space (8/-4 of 432us).
    return undef unless ($hdr_mark >= 2800 && $hdr_mark <= 4100) &&
                        ($hdr_space >= 1300 && $hdr_space <= 2100);

    my @bytes = (0, 0, 0, 0, 0, 0);
    for my $i (0 .. 47) {
        my $pair  = $burst_pairs->[$i + 1];
        my $space = $pair->[1];

        # Space ~1296us = 1, ~432us = 0
        my $bit = ($space > 800) ? 1 : 0;
        my $byte_idx = int($i / 8);
        my $bit_idx  = $i % 8; # LSB-first

        $bytes[$byte_idx] |= ($bit << $bit_idx);
    }

    # Stop bit: a short mark followed by the long trailing space. A
    # capture may end on a bare trailing mark with no space.
    my ($stop_mark, $stop_space) = @{$burst_pairs->[49]};
    return undef unless ($stop_mark >= 300 && $stop_mark <= 700) &&
                        ($stop_space == 0 || $stop_space >= 4000);

    my ($b0, $b1, $b2, $b3, $b4, $b5) = @bytes;

    # Validate Panasonic manufacturer code (0x40, 0x04). Frames with other
    # OEM bytes belong to a different Kaseikyo-family protocol (e.g. JVC-48
    # with OEM 3/1).  Compare against the accumulated (bit-reversed) forms
    # because the bytes here were collected LSB-first from the wire.
    return undef unless $b0 == MFG_HI_ACC && $b1 == MFG_LO_ACC;

    # Validate checksum: device ^ subdevice ^ function
    return undef unless $b5 == ($b2 ^ $b3 ^ $b4);

    my $data = ($b0 << 40) | ($b1 << 32) | ($b2 << 24) |
               ($b3 << 16) | ($b4 << 8) | $b5;

    return Protocol::IR::Code->new(
        protocol   => 'PANASONIC',
        bits       => BITS,
        address    => $b2,
        subaddress => $b3,
        command    => $b4,
        data       => $data,
    );
}

sub to_pronto {
    my ($class, $code) = @_;
    my $carrier_hz = 36000;

    my $freq_word  = int(sprintf("%.0f", 1000000.0 / ($carrier_hz * 0.241246)));
    my $period_us  = $freq_word * 0.241246;
    my $us_to_pulses = sub { int(sprintf("%.0f", $_[0] / $period_us)) };

    my $addr    = $code->address & 0xFF;
    my $subaddr = ($code->subaddress != -1) ? ($code->subaddress & 0xFF) : 0;
    my $cmd     = $code->command & 0xFF;

    # The value is transmitted with the most significant byte first and each
    # byte MSB-first within. The wire bytes are the MSB display form
    # (Tasmota's Data field), which is the per-byte bit reversal of the
    # collected value.
    my $data = _encode_data($addr, $subaddr, $cmd);
    my $msb_val = _bit_reverse_bytes($data, 48);

    my @bits;
    for my $i (reverse 0 .. 47) {
        push @bits, ($msb_val >> $i) & 1;
    }

    my @burst_pairs = (
        [$us_to_pulses->(3456), $us_to_pulses->(1728)]
    );

    for my $bit (@bits) {
        push @burst_pairs, [
            $us_to_pulses->(432),
            $us_to_pulses->($bit ? 1296 : 432)
        ];
    }

    # The trailing mark and long inter-frame space.
    push @burst_pairs, [$us_to_pulses->(432), $us_to_pulses->(40000)];

    my $seq1_pairs = scalar @burst_pairs;
    my $header = sprintf("0000 %04X %04X 0000", $freq_word, $seq1_pairs);
    my @payload = map { sprintf("%04X %04X", $_->[0], $_->[1]) } @burst_pairs;

    return join(" ", $header, @payload);
}

1;
