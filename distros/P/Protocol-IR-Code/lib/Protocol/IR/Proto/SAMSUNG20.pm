package Protocol::IR::Proto::SAMSUNG20;
use strict;
use warnings;

our $VERSION = '1.0';
use Protocol::IR::Code;

# Protocol::IR::Proto::SAMSUNG20 is the SAMSUNG20 protocol handler
# (20-bit), from the MakeHex Samsung20.irp and DecodeIR definitions:
#
#   {38.4k,564}<1,-1|1,-3>(8,-8,D:6,S:6,F:8,1,-44)
#
# A 20-bit frame carries a 6-bit device, a 6-bit subdevice, and an 8-bit
# function, transmitted LSB-first within each field behind a 4512/4512 us
# header (the same header Samsung's 32-bit protocol uses). The whole frame is
# sent once, so a capture is header + 20 bits + stop. IRDB uses it for Samsung
# air-conditioner handsets.

sub _parse_int {
    my ($val) = @_;
    return 0 unless defined $val;
    $val =~ s/^\s+|\s+$//g;
    return hex($val) if $val =~ /^0x/i;
    return $val + 0;
}

# True when the accumulated word (Tasmota DataLSB) is the form decode_raw
# reads; SAMSUNG20 has no display/accumulated distinction, so decode_byte_order
# is inherited from decode_raw.
sub lsb_is_accumulated { 1 }

# Pack device/subdevice/function into the transmitted 20-bit word. The
# default subdevice is 0 per Samsung20.irp (Default S=0), so a caller that
# omits it (subaddress -1) sends a zero field.
sub _encode_data {
    my ($addr, $subaddr, $cmd) = @_;
    return (($cmd & 0xFF) << 12) | (($subaddr & 0x3F) << 6) | ($addr & 0x3F);
}

sub decode_raw {
    my ($class, $raw_val) = @_;
    my $val = _parse_int($raw_val);

    return Protocol::IR::Code->new(
        protocol   => 'SAMSUNG20',
        bits       => 20,
        address    => $val & 0x3F,
        subaddress => ($val >> 6) & 0x3F,
        command    => ($val >> 12) & 0xFF,
        data       => $val,
    );
}

sub decode_params {
    my ($class, %args) = @_;
    my $addr        = _parse_int($args{address} // $args{device} // 0) & 0x3F;
    my $subaddr_arg = _parse_int($args{subaddress} // $args{subdevice} // -1);
    my $cmd         = _parse_int($args{command} // $args{function} // 0) & 0xFF;

    # Default S=0: a missing subdevice sends a zero field; the stored
    # subaddress stays -1.
    my $subaddr = ($subaddr_arg == -1) ? 0 : $subaddr_arg & 0x3F;

    return Protocol::IR::Code->new(
        protocol   => 'SAMSUNG20',
        bits       => 20,
        address    => $addr,
        subaddress => $subaddr_arg,
        command    => $cmd,
        data       => _encode_data($addr, $subaddr, $cmd),
    );
}

# Decode microsecond timing pairs into Protocol::IR::Code
sub decode_timing {
    my ($class, $burst_pairs) = @_;
    return undef unless scalar(@$burst_pairs) >= 22; # Header + 20 bits + Stop

    my ($hdr_mark, $hdr_space) = @{$burst_pairs->[0]};

    # SAMSUNG20 Header Check: ~4512us mark, ~4512us space
    return undef unless ($hdr_mark >= 3800 && $hdr_mark <= 5200) &&
                        ($hdr_space >= 3800 && $hdr_space <= 5200);

    my $value = 0;
    for my $i (0 .. 19) {
        my $pair  = $burst_pairs->[$i + 1];
        my $space = $pair->[1];

        # Space ~1692us = 1, ~564us = 0
        my $bit = ($space > 1100) ? 1 : 0;
        $value |= ($bit << $i); # LSB-first
    }

    # Stop bit: a short mark followed by the ~25ms inter-frame space. A
    # capture may end on a bare trailing mark with no space.
    my ($stop_mark, $stop_space) = @{$burst_pairs->[21]};
    return undef unless ($stop_mark >= 400 && $stop_mark <= 900) &&
                        ($stop_space == 0 || $stop_space >= 3000);

    return Protocol::IR::Code->new(
        protocol   => 'SAMSUNG20',
        bits       => 20,
        address    => $value & 0x3F,
        subaddress => ($value >> 6) & 0x3F,
        command    => ($value >> 12) & 0xFF,
        data       => $value,
    );
}

sub to_pronto {
    my ($class, $code) = @_;
    my $carrier_hz = 38400;

    # Build the pulse conversion period from the rounded Pronto frequency
    # word, as MakeHex and Pronto parsers do (see Protocol::IR::Proto::NEC).
    my $freq_word  = int(sprintf("%.0f", 1000000.0 / ($carrier_hz * 0.241246)));
    my $period_us  = $freq_word * 0.241246;

    my $us_to_pulses = sub { int(sprintf("%.0f", $_[0] / $period_us)) };

    my $addr    = $code->address & 0x3F;
    my $subaddr = ($code->subaddress != -1) ? ($code->subaddress & 0x3F) : 0;
    my $cmd     = $code->command & 0xFF;

    my $data = _encode_data($addr, $subaddr, $cmd);

    my @bits;
    for my $i (0 .. 19) { push @bits, ($data >> $i) & 1; } # LSB-first

    my @burst_pairs = (
        [$us_to_pulses->(4512), $us_to_pulses->(4512)]
    );

    for my $bit (@bits) {
        push @burst_pairs, [
            $us_to_pulses->(564),
            $us_to_pulses->($bit ? 1692 : 564)
        ];
    }

    # The trailing mark and ~25ms inter-frame space (1,-44 of 564us).
    push @burst_pairs, [$us_to_pulses->(564), $us_to_pulses->(24816)];

    my $seq1_pairs = scalar @burst_pairs;

    my $header = sprintf("0000 %04X %04X 0000", $freq_word, $seq1_pairs);
    my @payload = map { sprintf("%04X %04X", $_->[0], $_->[1]) } @burst_pairs;

    return join(" ", $header, @payload);
}

1;

=head1 NAME

Protocol::IR::Proto::SAMSUNG20 - SAMSUNG20 protocol handler (20-bit AC)

=head1 VERSION

version 1.0

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # From a raw 20-bit value or from parameters
    my $code = $converter->import_code('SAMSUNG20', '0x27201');
    my $code = $converter->import_code('SAMSUNG20',
        { address => 1, subaddress => 8, command => 39 });

=head1 DESCRIPTION

The C<SAMSUNG20> protocol transmits 20-bit frames at B<38.4 kHz>: a 6-bit
B<device>, a 6-bit B<subdevice>, and an 8-bit B<function>, transmitted
LSB-first within each field behind a B<4512/4512 us> header (the same header
Samsung's 32-bit protocol uses). The whole frame is sent once, so a capture
is header + 20 bits + stop. IRDB uses it for Samsung air-conditioner
handsets.

The C<data> value matches Tasmota's C<DataLSB> field: the B<function> in
bits 12-19, B<subdevice> in bits 6-11, and B<device> in bits 0-5. There is no
display/accumulated byte-order distinction for a 20-bit word.

A missing subdevice (C<-1>) sends a zero field per the IRP "Default S=0"
rule; the stored C<subaddress> stays C<-1>.

=head1 METHODS

=head2 decode_raw

    my $code = $class->decode_raw('0x27201');

Builds an L<Protocol::IR::Code> from the raw 20-bit value.

=head2 decode_params

    my $code = $class->decode_params(address => 1, subaddress => 8, command => 39);

Builds an L<Protocol::IR::Code> from discrete parameters. Accepts C<address> or
C<device>, C<subaddress> or C<subdevice>, and C<command> or C<function>.

=head2 decode_timing

    my $code = $class->decode_timing(\@burst_pairs_us);

Decodes an arrayref of microsecond C<[mark_us, space_us]> pairs. Returns an
L<Protocol::IR::Code> when the header, 20 data bits, and stop bit match the
SAMSUNG20 timing signature, otherwise C<undef>.

=head2 to_pronto

    my $pronto = $class->to_pronto($ir_code);

Encodes an L<Protocol::IR::Code> object as a Pronto Hex string at 38.4 kHz.

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
