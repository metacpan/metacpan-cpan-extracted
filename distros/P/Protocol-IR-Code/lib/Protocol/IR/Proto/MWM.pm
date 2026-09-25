package Protocol::IR::Proto::MWM;
use strict;
use warnings;

our $VERSION = '1.1';

use Math::BigInt;
use Protocol::IR::Code;

# MWM (Disney "Made With Magic" / Glow With The Show) protocol handler,
# ported from IRremoteESP8266's sendMWM/decodeMWM (ir_MWM.cpp) and validated
# against the Tasmota captures in samples/tasmota-capture.log.
#
# The signal is 2400 bps serial over a 38 kHz carrier: 1 start bit (mark),
# 8 data bits (space=1, mark=0, LSB-first), 1 stop bit (space), repeated per
# byte with no header, each logical bit one 417 µs tick (up to 9 ticks may
# merge into one measured run). Messages are 3-18 bytes (24-144 bits); the
# byte count is implied by the message body: state[0] carries a 4-bit payload
# length in the high nibble for command frames (0x9x/0xFx), and show commands
# open with the 0x55 0xAA signature. Because the decoded state bytes are
# exactly the transmitted bytes, Tasmota's "Data" field is the display form
# and no byte-order translation applies.
#
# Frames are up to 144 bits, beyond the native integer range, so the data
# word is carried as a Math::BigInt.

my $kTick         = 417;    # us per logical bit
my $kMaxWidth     = 9;      # maximum consecutive same-sign ticks per measured run
my $kDelta        = 150;    # +/- us width tolerance, matching IRrecv::match(delta)
my $kMaxGap       = 20000;  # us threshold for an inter-message space
my $kFooterGap    = 30000;  # us inter-command delay, kMWMMinGap
my $kMinSamples   = 6;      # kMWMMinSamples: shortest frame has 3 bytes, >= 2 samples each
my $kStateSizeMax = 55;     # IRremoteESP8266 state buffer cap
my $kMinBits      = 24;     # kMWMMinBits: 3 bytes
my $kMaxBits      = 144;    # (15 + 3) * 8: the 4-bit payload nibble caps a frame at 18 bytes

sub _parse_int {
    my ($val) = @_;
    return Math::BigInt->bzero() unless defined $val;
    return Math::BigInt->new($val) if ref $val;
    $val =~ s/^\s+|\s+$//g;
    return Math::BigInt->bzero() unless length $val;
    return Math::BigInt->from_hex($val) if $val =~ /^0x/i;
    return Math::BigInt->new($val);
}

# MWM is a serial protocol, not an IR on-air byte stream: there is no
# display/accumulated byte-order distinction, so the value is used as-is.
sub lsb_is_accumulated { 0 }

# A bundle is the accumulation of two or more length-declared MWM frames
# (typically a command A, its status companion B, and a repeat A' -- all three
# self-declare their own byte length in their leading byte, so the stream is
# walkable without any side information). Splits the value into one Code per
# frame. The first frame returned is the command/decode_raw frame A, which is
# what the structured Data field of a Tasmota MWM record normally carries;
# unbundle exists so a single structured hex tap can split a real A+B+A'
# capture into all three of its own frames.
sub unbundle {
    my ($class, $raw_val) = @_;
    my $val = _parse_int($raw_val);
    die "MWM data must be non-negative\n" if $val->is_neg;

    # Walk the value as a run of length-declared frames. 0x9x/0xFx leading
    # nibbles declare n+3 payload bytes (byte0's low nibble declaring the byte
    # count after the fixed 3-byte header). When the walk cannot land exactly
    # on the value end, the value is a single bare frame (24-bit show /
    # width-based values) and this returns the one Code built from the whole
    # value.
    my $hex = $val->as_hex;
    $hex =~ s/^0x//i;
    $hex = '0' x (6 - length($hex)) . $hex if length($hex) < 6;
    my @bytes = map { hex($_) } ($hex =~ /(..?)/g);
    my @frames;
    my $pos = 0;
    while ($pos < @bytes) {
        my $header   = $bytes[$pos];
        my $declared = ($header & 0x0f) + 3;
        last if $pos + $declared > @bytes;
        my $high = $header & 0xf0;
        last unless $high == 0x90 || $high == 0xf0;
        push @frames, [ @bytes[$pos .. $pos + $declared - 1] ];
        $pos += $declared;
    }
    if (@frames < 2 || $pos != @bytes) {
        # Single frame (or a non-length walk): the width-derived frame is the
        # same one decode_raw's fallback builds -- inline that law here so a
        # single frame never rings unbundle<->decode_raw.
        my $digits = $val->as_hex;
        $digits =~ s/^0x//i;
        my $bits = int((length($digits) + 1) / 2) * 8;
        $bits = $kMinBits if $bits < $kMinBits;
        return [ Protocol::IR::Code->new(
            protocol => 'MWM', bits => $bits, data => $val) ];
    }
    my @codes;
    for my $frame (@frames) {
        my $data = Math::BigInt->bzero();
        for my $b (@$frame) { $data = ($data << 8)->badd($b); }
        push @codes, Protocol::IR::Code->new(
            protocol => 'MWM',
            bits     => scalar(@$frame) * 8,
            data     => $data,
        );
    }
    return \@codes;
}

sub decode_raw {
    my ($class, $raw_val) = @_;
    my $val = _parse_int($raw_val);
    die "MWM data must be non-negative\n" if $val->is_neg;

    # A structured tap that ingested a whole A+B+A' bundle asks for a single
    # code: the bundle's first frame (A) is the command that decode_raw
    # returns for the record's Data field.
    my $bundled = $class->unbundle($val);
    return $bundled->[0] if @$bundled >= 2;

    # The frame length is implied by the value's own width, rounded up to a
    # whole number of bytes with the 3-byte protocol minimum.
    my $hex = $val->as_hex;
    $hex =~ s/^0x//i;
    my $bits = int((length($hex) + 1) / 2) * 8;
    $bits = $kMinBits if $bits < $kMinBits;

    return Protocol::IR::Code->new(
        protocol => 'MWM',
        bits     => $bits,
        data     => $val,
    );
}

sub decode_params {
    my ($class, %args) = @_;
    die "MWM requires a data value\n"
        unless defined $args{data} && "$args{data}" ne '';
    return $class->decode_raw($args{data});
}

# Match a measured width against `expected` within +/- kDelta us, mirroring
# IRrecv::match with zero tolerance and the kMWMDelta margin.
sub _match_width {
    my ($width, $expected) = @_;
    return $width >= $expected - $kDelta && $width <= $expected + $kDelta;
}

# Consume one logical level from the run-length rawbuf, expanding a measured
# width into up to kMaxWidth ticks of the same signal, exactly like
# IRrecv::getRClevel(kMWMTick, 0, 0, kMWMDelta, kMWMMaxWidth). Advances
# `state` (a { offset, used } cursor) as levels are consumed.
sub _get_rc_level {
    my ($rawbuf, $state) = @_;
    return 1 if $state->{offset} >= @$rawbuf;   # bare space past the end
    my $width = $rawbuf->[$state->{offset}];
    # rawbuf alternates mark/space from index 1, so odd indices are marks.
    my $val = ($state->{offset} % 2) ? 0 : 1;
    # A space wider than the max signal gap or the widest run is an
    # inter-message gap: read it as a bare space without consuming it.
    if ($val == 1 &&
        ($width > $kMaxGap - $kDelta || $width > $kMaxWidth * $kTick + $kDelta)) {
        return 1;
    }
    my $avail = 0;
    for my $a (reverse 1 .. $kMaxWidth) {
        if (_match_width($width, $a * $kTick)) { $avail = $a; last; }
    }
    return -1 unless $avail;    # the width matches no whole number of ticks
    $state->{used}++;
    if ($state->{used} >= $avail) {
        $state->{used} = 0;
        $state->{offset}++;
    }
    return $val;
}

# Decode a rawbuf of absolute timings into the transmitted state bytes.
# Mirrors IRrecv::decodeMWM with strict matching (Tasmota's decoder is
# non-strict and additionally accepts frames whose trailing bytes exceed the
# payload length; the strict length check keeps a truncated capture from
# silently decoding on its own). A capture whose final byte's stop space
# merged into the omitted footer is back-filled and accepted only when the
# result is length- and checksum-consistent. Returns undef when the signal is
# not a well-formed MWM message.
sub _decode_mwm {
    my ($rawbuf) = @_;
    # kMWMMinSamples: a message is >= 3 bytes and a byte has >= 2 samples, so a
    # run-length buffer of 6 entries or fewer cannot hold a full byte.
    return undef if @$rawbuf <= $kMinSamples;

    my $state = { offset => 1, used => 0 };
    my @state_bytes;
    my $data = Math::BigInt->bzero();
    my ($frame_bits, $data_bits, $done) = (0, 0, 0);

    while ($state->{offset} < @$rawbuf && $data_bits < 8 * $kStateSizeMax && !$done) {
        my $level = _get_rc_level($rawbuf, $state);
        last if $level < 0;
        my $slot = $frame_bits % 10;
        if ($slot == 0) {
            $done = 1 if $level != 0;   # start bit must be mark
        } elsif ($slot == 9) {
            return undef if $level != 1;    # stop bit must be space
            # $data_bits is the count of completed data bits, a multiple of 8 here.
            $state_bytes[int($data_bits / 8) - 1] = $data->copy->band(0xFF)->numify;
            $data = Math::BigInt->bzero();
        } else {
            # Data bit, LSB-first, space = 1: data = (data + (space?256:0)) >> 1
            $data->badd(($level == 1) ? 256 : 0);
            $data->brsft(1);
            $data_bits++;
        }
        $frame_bits++;
    }

    # The message body implies its own length. Command frames carry a payload
    # byte count in the high nibble of bytes[0]; show commands always open with
    # 0x55 0xAA. The show-command signature is rejected only when BOTH first
    # bytes differ from 0x55 0xAA (a 0x550808 show command, say, differs only
    # in the second byte). Returns the frame when length-consistent, else undef.
    my $validate = sub {
        my ($bytes) = @_;
        my $nb   = scalar @$bytes;
        my $nbit = $nb * 8;
        return undef if $nbit < $kMinBits || $nbit > $kMaxBits || !$nb;
        my $payload = 0;
        my $b0 = $bytes->[0] // 0;
        if (($b0 & 0xf0) == 0x90 || ($b0 & 0xf0) == 0xf0) {
            $payload = $b0 & 0x0f;
        } elsif ($b0 != 0x55 && ($bytes->[1] // 0) != 0xaa) {
            return undef;
        }
        return undef if $nbit < ($payload + 3) * 8;
        return undef if $payload && $nbit > ($payload + 3) * 8;
        return { bytes => $bytes, bits => $nbit };
    };

    # A complete, naturally-consistent frame stands on its own -- e.g. a 3-byte
    # 55 08 08 show capture whose trailing interference must not be folded into
    # a fabricated extra byte.
    my $natural = $validate->(\@state_bytes);
    return $natural if $natural;

    # Footerless capture: Tasmota omits the ~30 ms inter-command gap, so the
    # final byte's stop space (and any trailing 1-bits) ride invisibly inside
    # it and the signal can end mid-byte with only the stop bit missing. Only
    # when the natural decode came up short, back-fill the remaining
    # space-valued levels and commit the byte -- and accept the result only if
    # the checksum confirms the reconstructed trailing byte.
    if (!$done && $frame_bits % 10 != 0) {
        while ($frame_bits % 10 != 0) {
            if ($frame_bits % 10 == 9) {    # stop bit position
                push @state_bytes, $data->copy->band(0xFF)->numify;
                $data = Math::BigInt->bzero();
                $frame_bits++;
                last;
            }
            # data bit, space = 1
            $data->brsft(1);
            $data->badd(0x80);
            $frame_bits++;
        }
        my $rec = $validate->(\@state_bytes);
        if ($rec && $state_bytes[-1] == _crc8(@state_bytes[0 .. $#state_bytes - 1])) {
            return $rec;
        }
    }

    return undef;
}

# CRC-8 (poly 0x8c, MSB-first, init 0), the byte 0 of a 0x9x/0xFx command
# frame. Mirrors crc8 in the python-mwm library.
sub _crc8 {
    my (@bytes) = @_;
    my $crc = 0;
    for my $b (@bytes) {
        $crc ^= $b;
        for (1 .. 8) { $crc = ($crc & 1) ? (($crc >> 1) ^ 0x8c) : ($crc >> 1) }
    }
    return $crc & 0xff;
}

sub decode_timing {
    my ($class, $burst_pairs) = @_;
    # Flatten the pairs into the run-length rawbuf IRrecv feeds decodeMWM:
    # index 0 is the leading gap, then alternating mark/space.
    my @rawbuf = (0);
    for my $pair (@$burst_pairs) {
        push @rawbuf, $pair->[0], $pair->[1];
    }
    my $decoded = _decode_mwm(\@rawbuf);
    return undef unless $decoded;

    my $value = Math::BigInt->bzero();
    for my $b (@{ $decoded->{bytes} }) {
        $value->blsft(8);
        $value->badd($b);
    }

    return Protocol::IR::Code->new(
        protocol => 'MWM',
        bits     => $decoded->{bits},
        data     => $value,
    );
}

# Encode the frame: per byte a 417 µs start mark, the 8 data bits LSB-first
# (space = 1) and a 417 µs stop space, then the 30000 µs inter-command gap.
# Consecutive same-sign ticks merge into a single measured run.
sub to_pronto {
    my ($class, $code) = @_;
    my $carrier_hz = 38000;

    # Pronto frequency word and pulse conversion, mirroring NEC::to_pronto.
    my $freq_word  = int(sprintf("%.0f", 1000000.0 / ($carrier_hz * 0.241246)));
    my $period_us  = $freq_word * 0.241246;
    my $us_to_pulses = sub { int(sprintf("%.0f", $_[0] / $period_us)) };

    my $nbytes = int(($code->bits || $kMinBits) / 8);
    $nbytes = 3 if $nbytes < 3;
    my $val = $code->data;
    $val = Math::BigInt->bzero() unless defined $val;
    $val = Math::BigInt->new($val) unless ref $val && $val->isa('Math::BigInt');

    my @bytes;
    my $tmp = $val->copy();
    for (1 .. $nbytes) {
        push @bytes, $tmp->copy->band(0xFF)->numify;
        $tmp = $tmp->brsft(8);
    }
    @bytes = reverse @bytes;    # most significant byte first

    my @flat;
    for my $b (@bytes) {
        push @flat, $kTick;     # start bit (mark)
        for my $i (0 .. 7) {    # space = 1, mark = 0, LSB-first
            push @flat, (($b >> $i) & 1) ? -$kTick : $kTick;
        }
        push @flat, -$kTick;    # stop bit (space)
    }
    push @flat, -$kFooterGap;

    my @merged;
    for my $v (@flat) {
        if (@merged && (($merged[-1] > 0) == ($v > 0))) {
            $merged[-1] += $v;
        } else {
            push @merged, $v;
        }
    }

    my @pairs;
    for (my $i = 0; $i < @merged; $i += 2) {
        push @pairs, [abs($merged[$i]), abs($merged[$i + 1] // 0)];
    }

    my $header = sprintf("0000 %04X %04X 0000", $freq_word, scalar(@pairs));
    my @payload = map {
        sprintf("%04X %04X", $us_to_pulses->($_->[0]), $us_to_pulses->($_->[1]))
    } @pairs;

    return join(" ", $header, @payload);
}

1;

=encoding utf8

=head1 NAME

Protocol::IR::Proto::MWM - MWM protocol handler (Disney "Made With Magic")

=head1 VERSION

version 1.1

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # From a raw display-form value
    my $code = $converter->import_code('MWM', '0x550808');

    # From a data parameter (required)
    my $code = $converter->import_code('MWM', { data => '0x550808' });

=head1 DESCRIPTION

The MWM protocol ("Made With Magic", used by Disney light-up products such
as Glow With The Show) is 2400 bps serial over a 38 kHz carrier, with no
header. Each byte is a B<417 µs> start mark, B<8 data bits> (space = 1,
mark = 0, LSB-first), and a B<417 µs> stop space; up to 9 same-sign bits may
merge into one measured run. Messages are B<3 to 18 bytes> (24-144 bits) and
the byte count is implied by the message body: command frames carry a 4-bit
payload length in the high nibble of the first byte (B<0x9x>/B<0xFx>), while
show commands open with the B<0x55 0xAA> signature.

Because the decoded state bytes are exactly the transmitted bytes, the
C<data> value is the display form and matches Tasmota's C<Data> field; no
byte-order translation applies. Frames can reach 144 bits, which exceeds the
native integer range, so C<data> is always a L<Math::BigInt> for this
protocol.

The C<decode_timing> decoder is strict: it validates the start/stop bits of
every byte and enforces the payload-length check, so a genuinely truncated
capture is rejected rather than silently misdecoded. A capture whose final
byte's stop space merged into the omitted Tasmota footer is back-filled and
accepted only when the reconstructed trailing byte passes the checksum.

=head1 METHODS

=head2 decode_raw

    my $code = $class->decode_raw('0x550808');

Builds an L<Protocol::IR::Code> from the raw display-form value. The frame
length is implied by the value's width, rounded up to a whole number of
bytes with the 3-byte protocol minimum.

=head2 decode_params

    my $code = $class->decode_params(data => '0x550808');

Builds an L<Protocol::IR::Code> from a single required C<data> parameter.
Dies without one.

=head2 decode_timing

    my $code = $class->decode_timing(\@burst_pairs_us);

Decodes an arrayref of microsecond C<[mark_us, space_us]> pairs. Returns an
L<Protocol::IR::Code> when the frame is a well-formed MWM message (valid
start/stop bits, implied byte count, 24-144 bits), otherwise C<undef>.

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
