package Protocol::IR::Proto::JVC48;
use strict;
use warnings;

our $VERSION = '1.1';
use Protocol::IR::Code;

# Protocol::IR::Proto::JVC48 is the JVC-48 protocol handler (48-bit,
# Kaseikyo family OEM code 3/1), from the DecodeIR definition:
#
#   {37k,432}<1,-1|1,-3>(8,-4,3:8,1:8,D:8,S:8,F:8,(D^S^F):8,1,-173)+
#
# Six bytes are transmitted in order (OEM1=3, OEM2=1, device, subdevice,
# function, checksum) behind a 3456/1728 µs header. Each byte is sent
# LSB-first, so the value a receiver accumulates is the first byte in the
# most significant position (Tasmota's DataLSB). The checksum byte is
# device^subdevice^function, the same rule the Panasonic member of the
# Kaseikyo family uses. A single frame carries all six bytes; the trailing
# '+' repeats that whole frame, invisible to the single-frame decoder here.

sub _parse_int {
    my ($val) = @_;
    return 0 unless defined $val;
    $val =~ s/^\s+|\s+$//g;
    if ($val =~ /^0x/i) {
        # 48-bit hex strings exceed the 32-bit range that triggers Perl's
        # "portable" warning; the modules here handle them by design.
        no warnings 'portable';
        return hex($val);
    }
    return $val + 0;
}

# Reverse the bits within each byte of a 48-bit value, keeping the byte
# order (see Protocol::IR::Proto::NEC48::_bit_reverse_bytes).
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

# Pack device/subdevice/function into the transmitted 48-bit value,
# computing the checksum byte per the D^S^F rule.
sub _encode_data {
    my ($addr, $subaddr, $cmd) = @_;
    my $a = $addr & 0xFF;
    my $s = $subaddr & 0xFF;
    my $f = $cmd & 0xFF;
    return (3 << 40) | (1 << 32) | ($a << 24) | ($s << 16) |
           ($f << 8) | ($a ^ $s ^ $f);
}

# True when the accumulated word (Tasmota DataLSB) is the form decode_raw
# reads; the display form (Tasmota Data) is its per-byte bit reversal.
sub lsb_is_accumulated { 1 }

sub decode_raw {
    my ($class, $raw_val) = @_;
    my $val = _parse_int($raw_val);

    return Protocol::IR::Code->new(
        protocol   => 'JVC-48',
        bits       => 48,
        address    => ($val >> 24) & 0xFF,
        subaddress => ($val >> 16) & 0xFF,
        command    => ($val >> 8) & 0xFF,
        data       => $val,
    );
}

# lsb=true is the accumulated form decode_raw reads (Tasmota DataLSB);
# lsb=false is the display form, reached by reversing the bits within each
# byte (the frame bytes are each sent LSB-first).
sub decode_byte_order {
    my ($class, $raw_val, $lsb) = @_;
    my $val = _parse_int($raw_val);
    return $class->decode_raw($lsb ? $val : _bit_reverse_bytes($val, 48));
}

sub decode_params {
    my ($class, %args) = @_;
    my $addr       = _parse_int($args{address} // $args{device} // 0) & 0xFF;
    my $subaddr_arg = _parse_int($args{subaddress} // $args{subdevice} // -1);
    my $cmd        = _parse_int($args{command} // $args{function} // 0) & 0xFF;

    # A missing subdevice sends a zero field (there is no Default S rule);
    # the stored subaddress stays -1.
    my $subaddr = ($subaddr_arg == -1) ? 0 : $subaddr_arg & 0xFF;

    return Protocol::IR::Code->new(
        protocol   => 'JVC-48',
        bits       => 48,
        address    => $addr,
        subaddress => $subaddr_arg,
        command    => $cmd,
        data       => _encode_data($addr, $subaddr, $cmd),
    );
}

# Decode microsecond timing pairs into Protocol::IR::Code
sub decode_timing {
    my ($class, $burst_pairs) = @_;
    return undef unless scalar(@$burst_pairs) >= 50; # Header + 48 bits + Stop

    my ($hdr_mark, $hdr_space) = @{$burst_pairs->[0]};

    # JVC-48 Header Check: ~3456 µs mark, ~1728 µs space (8/-4 of 432 µs)
    return undef unless ($hdr_mark >= 2800 && $hdr_mark <= 4100) &&
                        ($hdr_space >= 1300 && $hdr_space <= 2100);

    my @bytes = (0, 0, 0, 0, 0, 0);
    for my $i (0 .. 47) {
        my $pair  = $burst_pairs->[$i + 1];
        my $space = $pair->[1];

        # Space ~1296 µs = 1, ~432 µs = 0
        my $bit = ($space > 800) ? 1 : 0;
        my $byte_idx = int($i / 8);
        my $bit_idx  = $i % 8; # LSB-first

        $bytes[$byte_idx] |= ($bit << $bit_idx);
    }

    # Stop bit: a short mark followed by the ~74ms inter-frame space. A
    # capture may end on a bare trailing mark with no space.
    my ($stop_mark, $stop_space) = @{$burst_pairs->[49]};
    return undef unless ($stop_mark >= 300 && $stop_mark <= 700) &&
                        ($stop_space == 0 || $stop_space >= 4000);

    my ($b0, $b1, $b2, $b3, $b4, $b5) = @bytes;
    my $data = ($b0 << 40) | ($b1 << 32) | ($b2 << 24) |
               ($b3 << 16) | ($b4 << 8) | $b5;

    return Protocol::IR::Code->new(
        protocol   => 'JVC-48',
        bits       => 48,
        address    => $b2,
        subaddress => $b3,
        command    => $b4,
        data       => $data,
    );
}

sub to_pronto {
    my ($class, $code) = @_;
    my $carrier_hz = 37000;

    # Build the pulse conversion period from the rounded Pronto frequency
    # word, as MakeHex and Pronto parsers do (see Protocol::IR::Proto::NEC).
    my $freq_word  = int(sprintf("%.0f", 1000000.0 / ($carrier_hz * 0.241246)));
    my $period_us  = $freq_word * 0.241246;

    my $us_to_pulses = sub { int(sprintf("%.0f", $_[0] / $period_us)) };

    my $addr    = $code->address & 0xFF;
    my $subaddr = ($code->subaddress != -1) ? ($code->subaddress & 0xFF) : 0;
    my $cmd     = $code->command & 0xFF;

    my @bytes = (3, 1, $addr, $subaddr, $cmd, $addr ^ $subaddr ^ $cmd);
    my @bits;
    for my $b (@bytes) {
        for my $i (0..7) { push @bits, ($b >> $i) & 1; }
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

    # The trailing mark and ~74ms gap (1,-173 of 432 µs).
    push @burst_pairs, [$us_to_pulses->(432), $us_to_pulses->(74736)];

    my $seq1_pairs = scalar @burst_pairs;

    my $header = sprintf("0000 %04X %04X 0000", $freq_word, $seq1_pairs);
    my @payload = map { sprintf("%04X %04X", $_->[0], $_->[1]) } @burst_pairs;

    return join(" ", $header, @payload);
}

1;

=encoding utf8

=head1 NAME

Protocol::IR::Proto::JVC48 - JVC-48 protocol handler (48-bit Kaseikyo, OEM 3/1)

=head1 VERSION

version 1.1

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # From a raw 48-bit value or from parameters
    my $code = $converter->import_code('JVC-48', '0x030122210300');
    my $code = $converter->import_code('JVC-48',
        { address => 34, subaddress => 33, command => 3 });

=head1 DESCRIPTION

The C<JVC-48> protocol transmits 48-bit frames at B<37 kHz>: six bytes --
OEM code B<3>, OEM code B<1>, B<device>, B<subdevice>, B<function>, and a
checksum -- each sent LSB-first, preceded by a B<3456/1728 µs> header and
followed by a stop mark. A single frame carries all six bytes; the repeat is
a whole-frame retransmission invisible to the single-frame decoder here. The
checksum byte is B<device ^ subdevice ^ function>, the same rule the
Panasonic member of the Kaseikyo family uses. JVC-48 has no subaddress
semantics of its own; a missing subdevice sends a zero field.

The C<data> value matches Tasmota's C<DataLSB> field: B<OEM1> in bits 40-47,
B<OEM2> in bits 32-39, B<device> in bits 24-31, B<subdevice> in bits 16-23,
B<function> in bits 8-15, and the checksum in bits 0-7. The display form
(Tasmota C<Data>) is the per-byte bit reversal; see C<decode_byte_order>.

=head1 METHODS

=head2 decode_raw

    my $code = $class->decode_raw('0x030122210300');

Builds an L<Protocol::IR::Code> from the raw 48-bit accumulated value.

=head2 decode_byte_order

    my $code = $class->decode_byte_order($raw, $lsb);

Decodes from either byte order: C<$lsb> true reads the accumulated
(DataLSB) form, false reads the display (Data) form reached by reversing the
bits within each byte.

=head2 decode_params

    my $code = $class->decode_params(address => 34, subaddress => 33, command => 3);

Builds an L<Protocol::IR::Code> from discrete parameters. Accepts C<address> or
C<device>, C<subaddress> or C<subdevice>, and C<command> or C<function>.

=head2 decode_timing

    my $code = $class->decode_timing(\@burst_pairs_us);

Decodes an arrayref of microsecond C<[mark_us, space_us]> pairs. Returns an
L<Protocol::IR::Code> when the header, 48 data bits, and stop bit match the
JVC-48 timing signature, otherwise C<undef>.

=head2 to_pronto

    my $pronto = $class->to_pronto($ir_code);

Encodes an L<Protocol::IR::Code> object as a Pronto Hex string at 37 kHz.

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
