package Protocol::IR::Proto::NEC48;
use strict;
use warnings;

our $VERSION = '1.1';
use Protocol::IR::Code;

# Protocol::IR::Proto::NEC48 is the base class for the 48-bit NEC family
# (48-NEC1/48-NEC2), from the DecodeIR definitions:
#
#   48-NEC1: {38.0k,564}<1,-1|1,-3>(16,-8,D:8,S:8,F:8,~F:8,E:8,~E:8,1,^108m,(16,-4,1,^108m)*)
#   48-NEC2: {38.0k,564}<1,-1|1,-3>(16,-8,D:8,S:8,F:8,~F:8,E:8,~E:8,1,^108m)+
#
# A single frame carries all six bytes (D, S, F, ~F, E, ~E) behind a
# 9024/4512 µs header; the trailing '+'/'*' repeats that whole frame, which is
# invisible to the single-frame decoders here. Like the 32-bit NEC family, the
# '2' variant only differs in repeat structure, so its name is preserved only
# so repeat behavior survives conversion. The trailing E byte is not part of
# the IRDB CSV rows, so it defaults to 0 when a code is built from
# device/subdevice/function parameters.

# The protocol name this class decodes into / encodes as. The subclass
# NEC482 overrides this for the '2' variant.
sub _protocol_name { '48-NEC1' }

# True when the accumulated word (Tasmota DataLSB) is the form decode_raw
# reads and decode_byte_order reverses per byte to reach the display form.
sub lsb_is_accumulated { 1 }

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

# Reverse the bits within each byte of a $bits-bit value, keeping the byte
# order. Each frame byte is sent LSB-first, so this maps between the
# accumulated value a receiver collects (Tasmota DataLSB) and the display form
# (Tasmota Data). Arithmetic shifts rather than the 32-bit bitwise ops, so
# 48-bit words survive whole.
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

# Pack address/subaddress/command/ext into the transmitted 48-bit value. The
# E byte is an extended function field, not part of the IRDB rows; it is sent
# cleared unless a code roundtripping through Pronto carries one.
sub _encode_data {
    my ($addr, $subaddr, $cmd, $ext) = @_;
    my $d = $addr & 0xFF;
    my $s = $subaddr & 0xFF;
    my $f = $cmd & 0xFF;
    my $e = $ext & 0xFF;
    return ($d << 40) | ($s << 32) | ($f << 24) |
           (((~$f) & 0xFF) << 16) | ($e << 8) | ((~$e) & 0xFF);
}

sub decode_raw {
    my ($class, $raw_val) = @_;
    my $val = _parse_int($raw_val);

    return Protocol::IR::Code->new(
        protocol   => $class->_protocol_name,
        bits       => 48,
        address    => ($val >> 40) & 0xFF,
        subaddress => ($val >> 32) & 0xFF,
        command    => ($val >> 24) & 0xFF,
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
    my $addr    = _parse_int($args{address} // $args{device} // 0) & 0xFF;
    my $subaddr = _parse_int($args{subaddress} // $args{subdevice} // -1) & 0xFF;
    my $cmd     = _parse_int($args{command} // $args{function} // 0) & 0xFF;

    # The E byte is not part of the IRDB rows; send it cleared.
    return Protocol::IR::Code->new(
        protocol   => $class->_protocol_name,
        bits       => 48,
        address    => $addr,
        subaddress => $subaddr,
        command    => $cmd,
        data       => _encode_data($addr, $subaddr, $cmd, 0),
    );
}

# Decode microsecond timing pairs into Protocol::IR::Code
sub decode_timing {
    my ($class, $burst_pairs) = @_;
    return undef unless scalar(@$burst_pairs) >= 50; # Header + 48 bits + Stop

    my ($hdr_mark, $hdr_space) = @{$burst_pairs->[0]};

    # NEC Header Check: ~9000 µs mark, ~4500 µs space
    return undef unless ($hdr_mark >= 7500 && $hdr_mark <= 10500) &&
                        ($hdr_space >= 3500 && $hdr_space <= 5500);

    my @bytes = (0, 0, 0, 0, 0, 0);
    for my $i (0 .. 47) {
        my $pair  = $burst_pairs->[$i + 1];
        my $space = $pair->[1];

        # Space ~1690 µs = 1, ~560 µs = 0
        my $bit = ($space > 1100) ? 1 : 0;
        my $byte_idx = int($i / 8);
        my $bit_idx  = $i % 8; # LSB-first

        $bytes[$byte_idx] |= ($bit << $bit_idx);
    }

    # Stop bit: a short mark followed by the ~108ms inter-frame space. A
    # capture may end on a bare trailing mark with no space.
    my ($stop_mark, $stop_space) = @{$burst_pairs->[49]};
    return undef unless ($stop_mark >= 400 && $stop_mark <= 900) &&
                        ($stop_space == 0 || $stop_space >= 3000);

    my ($b0, $b1, $b2, $b3, $b4, $b5) = @bytes;
    my $data = ($b0 << 40) | ($b1 << 32) | ($b2 << 24) |
               ($b3 << 16) | ($b4 << 8) | $b5;

    return Protocol::IR::Code->new(
        protocol   => $class->_protocol_name,
        bits       => 48,
        address    => $b0,
        subaddress => $b1,
        command    => $b2,
        data       => $data,
    );
}

sub to_pronto {
    my ($class, $code) = @_;
    my $carrier_hz = 38000;

    # Build the pulse conversion period from the rounded Pronto frequency
    # word, as MakeHex and Pronto parsers do (see Protocol::IR::Proto::NEC).
    my $freq_word  = int(sprintf("%.0f", 1000000.0 / ($carrier_hz * 0.241246)));
    my $period_us  = $freq_word * 0.241246;

    my $us_to_pulses = sub { int(sprintf("%.0f", $_[0] / $period_us)) };

    my $addr    = $code->address & 0xFF;
    my $subaddr = ($code->subaddress != -1) ? ($code->subaddress & 0xFF) : 0;
    my $cmd     = $code->command & 0xFF;
    # The E byte rides along in the data word for roundtrip fidelity; rebuild
    # it (cleared for codes built from IRDB rows).
    my $e = defined $code->data ? (($code->data >> 8) & 0xFF) : 0;

    my @bytes = ($addr, $subaddr, $cmd, (~$cmd) & 0xFF, $e, (~$e) & 0xFF);
    my @bits;
    for my $b (@bytes) {
        for my $i (0..7) { push @bits, ($b >> $i) & 1; }
    }

    my @burst_pairs = (
        [$us_to_pulses->(9000), $us_to_pulses->(4500)]
    );

    for my $bit (@bits) {
        push @burst_pairs, [
            $us_to_pulses->(560),
            $us_to_pulses->($bit ? 1690 : 560)
        ];
    }

    # Suffix: a 560 µs stop mark and the ~108ms inter-frame space
    # (^108m of the IRP).
    push @burst_pairs, [$us_to_pulses->(560), $us_to_pulses->(108000)];

    my $seq1_pairs = scalar @burst_pairs;

    my $header = sprintf("0000 %04X %04X 0000", $freq_word, $seq1_pairs);
    my @payload = map { sprintf("%04X %04X", $_->[0], $_->[1]) } @burst_pairs;

    return join(" ", $header, @payload);
}

1;

=encoding utf8

=head1 NAME

Protocol::IR::Proto::NEC48 - 48-NEC1 protocol handler (48-bit NEC family base)

=head1 VERSION

version 1.1

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # From a raw 48-bit value or from parameters
    my $code = $converter->import_code('48-NEC1', '0x4DB2DE2100FF');
    my $code = $converter->import_code('48-NEC1',
        { address => 77, subaddress => 178, command => 222 });

=head1 DESCRIPTION

The 48-bit NEC family transmits 48-bit frames at 38 kHz: six bytes --
B<address> (device), B<subaddress>, B<command>, the command's one's
complement, an extended B<E> byte, and E's one's complement -- each sent
LSB-first, preceded by a B<9024/4512 µs> header and followed by a stop mark.
A single frame carries all six bytes; the repeat is a whole-frame
retransmission invisible to the single-frame decoders here.

The C<data> value matches Tasmota's C<DataLSB> field: B<address> in bits
40-47, B<subaddress> in bits 32-39, B<command> in bits 24-31, its complement
in bits 16-23, C<E> in bits 8-15, and E's complement in bits 0-7. The
display form (Tasmota C<Data>) is the per-byte bit reversal; see
C<decode_byte_order>.

IRDB distinguishes two single-frame formats, like the 32-bit NEC family:

=over 4

=item * C<48-NEC1> (this class) -- short header+gap repeat.

=item * C<48-NEC2> (L<Protocol::IR::Proto::NEC482>) -- identical single-frame
timing; only the repeat differs (it re-transmits the whole frame).

=back

The C<E> byte is not part of the IRDB CSV rows, so codes built from
device/subdevice/function parameters send it cleared.

When a subaddress is omitted (C<-1>), it is masked to C<0xFF> exactly as the
type-script sibling does; IRDB rows always carry an explicit subdevice.

=head1 METHODS

=head2 decode_raw

    my $code = $class->decode_raw('0x4DB2DE2100FF');

Builds an L<Protocol::IR::Code> from the raw 48-bit accumulated value.

=head2 decode_byte_order

    my $code = $class->decode_byte_order($raw, $lsb);

Decodes from either byte order: C<$lsb> true reads the accumulated
(DataLSB) form, false reads the display (Data) form reached by reversing the
bits within each byte.

=head2 decode_params

    my $code = $class->decode_params(address => 77, subaddress => 178, command => 222);

Builds an L<Protocol::IR::Code> from discrete parameters. Accepts C<address> or
C<device>, C<subaddress> or C<subdevice>, and C<command> or C<function>.

=head2 decode_timing

    my $code = $class->decode_timing(\@burst_pairs_us);

Decodes an arrayref of microsecond C<[mark_us, space_us]> pairs. Returns an
L<Protocol::IR::Code> when the header, 48 data bits, and stop bit match the
48-bit NEC timing signature, otherwise C<undef>.

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
