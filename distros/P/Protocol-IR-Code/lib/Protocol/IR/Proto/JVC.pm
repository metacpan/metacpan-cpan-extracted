package Protocol::IR::Proto::JVC;
use strict;
use warnings;

our $VERSION = '1.1';
use Protocol::IR::Code;

sub _parse_int {
    my ($val) = @_;
    return 0 unless defined $val;
    $val =~ s/^\s+|\s+$//g;
    return hex($val) if $val =~ /^0x/i;
    return $val + 0;
}

sub decode_params {
    my ($class, %args) = @_;
    my $addr = _parse_int($args{address} // $args{device} // 0);
    my $cmd  = _parse_int($args{command} // $args{function} // 0);

    my $data = (($addr & 0xFF) << 8) | ($cmd & 0xFF);

    return Protocol::IR::Code->new(
        protocol   => 'JVC',
        bits       => 16,
        address    => $addr,
        subaddress => -1,
        command    => $cmd,
        data       => $data,
    );
}

sub decode_raw {
    my ($class, $raw_val) = @_;
    my $val  = _parse_int($raw_val);
    my $addr = ($val >> 8) & 0xFF;
    my $cmd  = $val & 0xFF;

    return Protocol::IR::Code->new(
        protocol   => 'JVC',
        bits       => 16,
        address    => $addr,
        subaddress => -1,
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
# accumulated wire form (Tasmota Data, the "LSB" form the LIRC
# pre_data/post_data composition lands on) and the display form decode_raw
# reads (Tasmota DataLSB).
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

# lsb=true is the form decode_raw reads (Tasmota DataLSB);
# lsb=false is the accumulated wire form, reached from the display form by
# reversing the bits within each byte.
sub decode_byte_order {
    my ($class, $raw_val, $lsb) = @_;
    my $val = _parse_int($raw_val);
    return $class->decode_raw($lsb ? $val : _bit_reverse_bytes($val, 16));
}

# Decode microsecond timing pairs into Protocol::IR::Code
sub decode_timing {
    my ($class, $burst_pairs) = @_;
    return undef unless scalar(@$burst_pairs) >= 18; # Header + 16 bits + Stop

    my ($hdr_mark, $hdr_space) = @{$burst_pairs->[0]};

    # JVC Header Check: ~8400 µs mark, ~4200 µs space
    return undef unless ($hdr_mark >= 7000 && $hdr_mark <= 9800) &&
                        ($hdr_space >= 3200 && $hdr_space <= 5200);

    my @bytes = (0, 0);
    for my $i (0 .. 15) {
        my $pair = $burst_pairs->[$i + 1];
        my $space = $pair->[1];

        # Space ~1578 µs = 1, ~526 µs = 0
        my $bit = ($space > 1000) ? 1 : 0;
        my $byte_idx = int($i / 8);
        my $bit_idx  = $i % 8; # LSB-first

        $bytes[$byte_idx] |= ($bit << $bit_idx);
    }

    my ($addr, $cmd) = @bytes;
    my $data = ($addr << 8) | $cmd;

    # Stop bit: a short mark followed by the inter-frame gap (~17080 µs for
    # repeated frames, ~42000 µs for a lone frame). Single-frame captures may
    # end on a bare trailing mark with no space. This rejects signals whose
    # header overlaps JVC's but have a different frame structure.
    my ($stop_mark, $stop_space) = @{$burst_pairs->[17]};
    return undef unless $stop_mark >= 400 && $stop_mark <= 900 &&
                        ($stop_space == 0 || $stop_space >= 8000);

    return Protocol::IR::Code->new(
        protocol   => 'JVC',
        bits       => 16,
        address    => $addr,
        subaddress => -1,
        command    => $cmd,
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

    my @burst_pairs = (
        [$us_to_pulses->(8400), $us_to_pulses->(4200)]
    );

    my @bits;
    for my $i (0..7) { push @bits, ($code->address >> $i) & 1; }
    for my $i (0..7) { push @bits, ($code->command >> $i) & 1; }

    for my $bit (@bits) {
        push @burst_pairs, [
            $us_to_pulses->(526),
            $us_to_pulses->($bit ? 1578 : 526)
        ];
    }

    push @burst_pairs, [$us_to_pulses->(526), $us_to_pulses->(42000)];

    my $seq1_pairs = scalar @burst_pairs;

    my $header = sprintf("0000 %04X %04X 0000", $freq_word, $seq1_pairs);
    my @payload = map { sprintf("%04X %04X", $_->[0], $_->[1]) } @burst_pairs;

    return join(" ", $header, @payload);
}

1;

=encoding utf8

=head1 NAME

Protocol::IR::Proto::JVC - JVC protocol handler (16-bit)

=head1 VERSION

version 1.1

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # From a raw 16-bit value or from parameters
    my $code = $converter->import_code('JVC', '0x030C');
    my $code = $converter->import_code('JVC',
        { address => 3, command => 12 });

=head1 DESCRIPTION

The JVC protocol transmits a 16-bit frame at 38 kHz: an B<address> byte
followed by a B<command> byte, each sent LSB-first. The C<data> value has
the address in bits 8-15 and the command in bits 0-7, matching Tasmota's
C<Data> field. JVC has no subaddress; C<subaddress> is set to C<-1>.

Frame timing: B<8400 µs> header mark and B<4200 µs> header space; each bit
is a B<526 µs> mark followed by a space of B<526 µs> for 0 or B<1578 µs>
for 1; a B<526 µs> stop mark ends the frame. The inter-frame gap is about
B<17080 µs> for repeated frames or B<42000 µs> for a lone frame.

The C<decode_timing> decoder validates both the header and the stop bit, so
a capture from a protocol whose header overlaps JVC's but has a different
frame structure is rejected rather than misidentified.

=head1 METHODS

=head2 decode_raw

    my $code = $class->decode_raw('0x030C');

Builds an L<Protocol::IR::Code> from the raw 16-bit value.

=head2 decode_byte_order

    my $code = $class->decode_byte_order($raw, $lsb);

Decodes from either byte order: C<$lsb> true reads the accumulated (DataLSB)
form directly; false reads the display (Data) form, the per-byte bit reversal
of the accumulated word. JVC sends each byte LSB-first, so the accumulated
word is the one carried on the wire and by Tasmota's C<DataLSB>.

=head2 lsb_is_accumulated

    my $flag = $class->lsb_is_accumulated;

True (always, for JVC) when the accumulated byte order is what
C<decode_raw> reads, informing the Tasmota structured importer which of its
C<Data>/C<DataLSB> fields to prefer.

=head2 decode_params

    my $code = $class->decode_params(address => 3, command => 12);

Builds an L<Protocol::IR::Code> from discrete parameters. Accepts C<address> or
C<device>, and C<command> or C<function>.

=head2 decode_timing

    my $code = $class->decode_timing(\@burst_pairs_us);

Decodes an arrayref of microsecond C<[mark_us, space_us]> pairs. Returns an
L<Protocol::IR::Code> when the header, 16 data bits, and stop bit match the JVC
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
