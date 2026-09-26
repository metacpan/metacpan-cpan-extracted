package Protocol::IR::Proto::SAMSUNG36;
use strict;
use warnings;

our $VERSION = '1.2';
use Protocol::IR::Code;

# Protocol::IR::Proto::SAMSUNG36 is the SAMSUNG36 protocol handler (36-bit),
# ported from IRremoteESP8266 (Copyright David Conran et al., GPLv2,
# https://github.com/crankyoldgit/IRremoteESP8266, ir_Samsung.cpp
# sendSamsung36/decodeSamsung36).
#
# The 36-bit data word is transmitted in two blocks. Block #1 carries the top
# 16 bits (the address) behind a 4515/4438 µs header; block #2 carries the
# remaining 20 bits (the command) with no header. Each block is sent MSB-first
# with a 512 µs mark and a 1468 µs (1) / 490 µs (0) space, and each block ends
# with a 512 µs mark; block #1's footer is followed by a 4438 µs space and
# block #2's by the ~27 ms inter-message gap. The decoder reads both blocks
# MSB-first, so the stored data word is the same value the transmitter sent -
# what IRremoteESP8266 reports as `value`, the "Code" column of the sample
# tables. The "LSB" column is the same word read bit-for-bit in reverse.

my $BITS = 36;
my $ADDR_BITS = 16;          # block #1
my $CMD_BITS = $BITS - $ADDR_BITS;   # block #2 (20)
my $BLOCK1_SHIFT = 1 << $CMD_BITS;   # 2^20: block #1 value is data / this

sub _parse_int {
    my ($val) = @_;
    return 0 unless defined $val;
    $val =~ s/^\s+|\s+$//g;
    if ($val =~ /^0x/i) {
        # 36-bit hex strings exceed the 32-bit range that triggers Perl's
        # "portable" warning; the modules here handle them by design.
        no warnings 'portable';
        return hex($val);
    }
    return $val + 0;
}

# The 36-bit word is transmitted MSB-first as a whole, so Tasmota's "Data"
# field is itself the accumulated form decode_raw reads. Tasmota's "DataLSB"
# (the per-byte bit reversal of the low 32 bits) is a display artifact that
# cannot reconstruct the transmitted value, so Data is preferred.
sub lsb_is_accumulated { 0 }

# Reverse the full 36-bit value end to end (not per byte, as for
# NEC/JVC/SAMSUNG): the "LSB" column is the same word read bit-for-bit in
# reverse. Each `out * 2 + bit` step shifts earlier bits up, so feeding the
# original bits LSB-first builds the reversed word MSB-first.
sub _reverse_bits {
    my ($val, $bits) = @_;
    my $out = 0;
    for my $i (0 .. $bits - 1) {
        $out = $out * 2 + (($val >> $i) & 1);
    }
    return $out;
}

# Pack the 16-bit address (block #1) and the 20-bit command (block #2) into
# the transmitted 36-bit word.
sub _encode_data {
    my ($addr, $cmd) = @_;
    return (($addr & 0xFFFF) * $BLOCK1_SHIFT) + ($cmd & ($BLOCK1_SHIFT - 1));
}

# decode_raw expects the display form (the "Code" column / IRremoteESP8266
# `value`): the word read MSB-first, address in the top 16 bits.
sub decode_raw {
    my ($class, $raw_val) = @_;
    my $val = _parse_int($raw_val);

    return Protocol::IR::Code->new(
        protocol   => 'SAMSUNG36',
        bits       => $BITS,
        address    => int($val / $BLOCK1_SHIFT) & 0xFFFF,
        subaddress => -1,
        command    => $val % $BLOCK1_SHIFT,
        data       => $val,
    );
}

# The LSB form is the same word reversed end to end, so it has to be reversed
# (not per-byte, as for NEC/JVC/SAMSUNG) to reach the display form decode_raw
# reads.
sub decode_byte_order {
    my ($class, $raw_val, $lsb) = @_;
    my $val = _parse_int($raw_val);
    return $class->decode_raw($lsb ? _reverse_bits($val, $BITS) : $val);
}

sub decode_params {
    my ($class, %args) = @_;
    my $addr = _parse_int($args{address} // $args{device} // 0);
    my $cmd  = _parse_int($args{command} // $args{function} // 0);

    return Protocol::IR::Code->new(
        protocol   => 'SAMSUNG36',
        bits       => $BITS,
        address    => $addr,
        subaddress => -1,
        command    => $cmd,
        data       => _encode_data($addr, $cmd),
    );
}

# Decode microsecond timing pairs into Protocol::IR::Code. Frame layout:
#   [header 4515/4438] [16 addr bits] [mark/4438] [20 cmd bits] [mark/26880]
# so 1 + 16 + 1 + 20 + 1 = 39 burst pairs. A capture may end on a bare
# trailing mark, in which case the final space reads as 0.
sub decode_timing {
    my ($class, $burst_pairs) = @_;
    return undef unless scalar(@$burst_pairs) >= 39;

    my ($hdr_mark, $hdr_space) = @{$burst_pairs->[0]};
    return undef unless ($hdr_mark >= 3800 && $hdr_mark <= 5200) &&
                        ($hdr_space >= 3800 && $hdr_space <= 5200);

    my $block1 = 0;
    for my $i (0 .. $ADDR_BITS - 1) {
        my $space = $burst_pairs->[$i + 1]->[1];
        # Space ~1468 µs = 1, ~490 µs = 0
        $block1 = $block1 * 2 + (($space > 1000) ? 1 : 0);
    }

    # Mid-block footer: a 512 µs mark and the 4438 µs space separating the
    # two blocks.
    my ($mid_mark, $mid_space) = @{$burst_pairs->[$ADDR_BITS + 1]};
    return undef unless ($mid_mark >= 400 && $mid_mark <= 900) &&
                        ($mid_space >= 3800 && $mid_space <= 5200);

    my $block2 = 0;
    for my $i (0 .. $CMD_BITS - 1) {
        my $space = $burst_pairs->[$i + $ADDR_BITS + 2]->[1];
        $block2 = $block2 * 2 + (($space > 1000) ? 1 : 0);
    }

    # Stop bit: a short mark followed by the ~27ms inter-message gap. A
    # capture may end on a bare trailing mark with no space.
    my ($stop_mark, $stop_space) = @{$burst_pairs->[$ADDR_BITS + $CMD_BITS + 2]};
    return undef unless ($stop_mark >= 400 && $stop_mark <= 900) &&
                        ($stop_space == 0 || $stop_space >= 8000);

    my $data = ($block1 * $BLOCK1_SHIFT) + $block2;

    return Protocol::IR::Code->new(
        protocol   => 'SAMSUNG36',
        bits       => $BITS,
        address    => $block1,
        subaddress => -1,
        command    => $block2,
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

    my $data   = _encode_data($code->address, $code->command);
    my $block1 = int($data / $BLOCK1_SHIFT) & 0xFFFF;
    my $block2 = $data % $BLOCK1_SHIFT;

    my @burst_pairs = (
        [$us_to_pulses->(4515), $us_to_pulses->(4438)]
    );

    for (my $i = $ADDR_BITS - 1; $i >= 0; $i--) {
        my $bit = ($block1 >> $i) & 1;
        push @burst_pairs, [
            $us_to_pulses->(512),
            $us_to_pulses->($bit ? 1468 : 490)
        ];
    }

    push @burst_pairs, [$us_to_pulses->(512), $us_to_pulses->(4438)];

    for (my $i = $CMD_BITS - 1; $i >= 0; $i--) {
        my $bit = ($block2 >> $i) & 1;
        push @burst_pairs, [
            $us_to_pulses->(512),
            $us_to_pulses->($bit ? 1468 : 490)
        ];
    }

    # The trailing mark and ~27ms inter-message gap.
    push @burst_pairs, [$us_to_pulses->(512), $us_to_pulses->(26880)];

    my $seq1_pairs = scalar @burst_pairs;

    my $header = sprintf("0000 %04X %04X 0000", $freq_word, $seq1_pairs);
    my @payload = map { sprintf("%04X %04X", $_->[0], $_->[1]) } @burst_pairs;

    return join(" ", $header, @payload);
}

1;

=encoding utf8

=head1 NAME

Protocol::IR::Proto::SAMSUNG36 - SAMSUNG36 protocol handler (36-bit)

=head1 VERSION

version 1.2

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # From a raw 36-bit value or from parameters
    my $code = $converter->import_code('SAMSUNG36', '0x7004F023E3');
    my $code = $converter->import_code('SAMSUNG36',
        { address => 0x7004, command => 0xF023E });

=head1 DESCRIPTION

The C<SAMSUNG36> protocol transmits 36-bit frames at B<38 kHz> in two
blocks: block #1 carries the top 16 bits (the B<address>) behind a
B<4515/4438 µs> header, and block #2 carries the remaining 20 bits (the
B<command>) with no header. Each block is sent B<MSB-first> with a 512 µs
mark and a 1468 µs (1) / 490 µs (0) space, and each block ends with a 512 µs
mark; block #1's footer is followed by a 4438 µs space and block #2's by the
~27 ms inter-message gap. The whole frame is sent once.

Because the word is transmitted MSB-first as a whole, the stored C<data> is
the same value the transmitter sent -- what IRremoteESP8266 reports as
C<value>, the "Code" column of the sample tables. The "LSB" column is the
same word read bit-for-bit in reverse; see C<decode_byte_order>. SAMSUNG36
has no subaddress; C<subaddress> is set to C<-1>.

Timing and bit ordering follow IRremoteESP8266 (David Conran et al., GPLv2,
L<https://github.com/crankyoldgit/IRremoteESP8266>): C<kSamsung36HdrMark>/
C<kSamsung36HdrSpace>, C<kSamsung36BitMark>, C<kSamsung36OneSpace>, and
C<kSamsung36ZeroSpace>.

=head1 METHODS

=head2 decode_raw

    my $code = $class->decode_raw('0x7004F023E3');

Builds an L<Protocol::IR::Code> from the raw 36-bit display value.

=head2 decode_byte_order

    my $code = $class->decode_byte_order($raw, $lsb);

Decodes from either byte order: C<$lsb> true reads the whole word reversed
end to end (the "LSB" column), false reads the display form (the "Code"
column) directly.

=head2 decode_params

    my $code = $class->decode_params(address => 0x7004, command => 0xF023E);

Builds an L<Protocol::IR::Code> from discrete parameters. Accepts C<address> or
C<device>, and C<command> or C<function>.

=head2 decode_timing

    my $code = $class->decode_timing(\@burst_pairs_us);

Decodes an arrayref of microsecond C<[mark_us, space_us]> pairs. Returns an
L<Protocol::IR::Code> when the header, 39 burst pairs, both block footers,
and the stop bit match the SAMSUNG36 timing signature, otherwise C<undef>.

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
