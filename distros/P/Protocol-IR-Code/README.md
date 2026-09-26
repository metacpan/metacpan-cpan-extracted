# NAME

Protocol::IR::Code - Intermediate representation of an IR remote control code

# VERSION

version 1.2

# SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();
    my $code = $converter->import_code('NEC', '0x10EF00FF');

    print $code->protocol;    # NEC
    print $code->address;     # 16
    print $code->command;     # 0

    my $hash = $code->to_irsend;   # Tasmota IRSend JSON payload

# DESCRIPTION

`Protocol::IR::Code` is the unified intermediate representation used throughout the
Protocol::IR::Code distribution. Every protocol handler decodes into an `Protocol::IR::Code`
object and every format exports from one, so a signal can be moved between
protocols and formats without loss of information.

The object is compatible with Tasmota's `IRSend` JSON payload structure:
[to\_irsend](#to_irsend) returns a hash with `Protocol`, `Bits`, and
`Data` keys. The `data` value is expressed so that it matches Tasmota's
`Data` field for the protocol.

# ATTRIBUTES

All attributes are read-write accessors, e.g. `$code->alias('POWER')`.
They are created by the [Protocol::IR::Converter](https://metacpan.org/pod/Protocol%3A%3AIR%3A%3AConverter) registry and the protocol/format
handlers; you normally do not construct `Protocol::IR::Code` objects directly.

- protocol

    Protocol name (e.g. `NEC`), or `UNKNOWN` for undecoded timing data.

- bits

    Number of data bits in the frame.

- address

    Primary address (device) byte.

- subaddress

    Secondary address byte, or `-1` when the protocol has none (JVC, SAMSUNG)
    or when it equals the one's complement of the address (standard NEC frames).

- command

    Command (function) byte.

- data

    The raw transmitted value. Bit order matches the protocol's `Data` field
    in Tasmota (see the individual protocol modules).

- alias

    A human-readable button name, carried by CSV and wig round trips.

- ditto\_count

    Number of repeat ("ditto") frames a wig should send after the first.

- send\_count

    How many times the whole signal transmits per press (the wig's `send_count`,
    the repeat hint a JSON dump's keycode carries).  Zero means the source carried
    no repeat count, so a wig export omits `send_count` and the default single
    press is assumed.

- bypass\_protocol

    Flag marking that a wig should bypass protocol-aware repeat behavior.

- timings

    The raw waveform as a flat list of signed microsecond durations, alternating
    mark (positive) and space (negative), exactly as captured: `[+9185, -4490,
    \+650, -500, ...]`. It is set whenever a signal enters through a timing
    format -- Tasmota `RawData`, a mode2 capture, LIRC `raw_codes`, or any
    Pronto Hex string -- so the capture can be re-exported losslessly to any
    timing format. `undef` for codes built from decoded fields.

    The values are quantized to the source format's grid: Pronto durations are
    integer carrier cycles times the period derived from the frequency word
    (about 26.3 µs at 38 kHz), Tasmota compact timings are multiples of 5 µs, and
    mode2/LIRC carry integer microseconds as measured. Protocol encoders emit
    Pronto quantized to their nominal carrier, so a signal decoded from Pronto
    re-encodes to the same pulse counts.

- pronto

    The verbatim Pronto Hex string the code was decoded from, when any, kept so
    the code re-exports byte-identically through any Pronto output or
    Pronto-passthrough container format (wig, a JSON dump) without
    re-quantizing. On a signal no registered protocol recognizes (protocol
    `UNKNOWN`, `bypass_protocol` set) this is alongside `timings`. `undef`
    for codes built from decoded fields.

    `timings` and `pronto` are kept together on a decoded code because the two
    format families each need their own lossless view: `timings` feeds the
    microsecond timing formats (Tasmota, mode2, LIRC), `pronto` the hex container
    formats (wig, a JSON dump, a Pronto re-export). Deriving either from the
    other would re-quantize and could change silent fractions.

# METHODS

## to\_irsend

    my $hash = $code->to_irsend;

Returns a hashref with `Protocol`, `Bits`, and (when known) `Data` keys,
matching the structure of a Tasmota `IRSend` JSON payload.

# FUNCTIONS

## reverse\_byte

    my $reversed = Protocol::IR::Code::reverse_byte(0xE0);  # returns 0x07

Reverses the bits within an 8-bit byte.  Used by
["as\_necx2\_params" in Protocol::IR::Proto::SAMSUNG](https://metacpan.org/pod/Protocol%3A%3AIR%3A%3AProto%3A%3ASAMSUNG#as_necx2_params) and
["as\_samsung\_params" in Protocol::IR::Proto::NECX2](https://metacpan.org/pod/Protocol%3A%3AIR%3A%3AProto%3A%3ANECX2#as_samsung_params) for cross-protocol
conversion between SAMSUNG and NECX2, where the Samsung address/command
bytes are the bit-reversal of the NECX2 device/function bytes.

This is an exported package function (not a method), callable as
`Protocol::IR::Code::reverse_byte($val)`.

# SUPPORT

Source code: [https://github.com/bwarden/perl-protocol-ir](https://github.com/bwarden/perl-protocol-ir)

Bug reports and feature requests: [https://github.com/bwarden/perl-protocol-ir/issues](https://github.com/bwarden/perl-protocol-ir/issues)

# RELATED PROJECTS

[Protocol::IR::Code](https://metacpan.org/pod/Protocol%3A%3AIR%3A%3ACode) trades formats with the IR ecosystem rather than
reinventing it:

- LIRC -- [remote definitions](https://www.lirc.org/), and the [mode2](https://metacpan.org/pod/Protocol%3A%3AIR%3A%3AFormat%3A%3AMode2) capture tool
- Tasmota -- [IR send/receive and RawData](https://tasmota.github.io/docs/Tasmota-IR/), built on [IRremoteESP8266](https://github.com/crankyoldgit/IRremoteESP8266)
- IRDB -- [the community button/CSV database](https://github.com/probonopd/irdb)
- HAIR -- [the Home Assistant IR integration and wig format](https://github.com/DAB-LABS/HAIR)
- IR Scrutinizer -- [Pronto Hex format glossary](http://www.harctoolbox.org/Glossary.html)

# AUTHOR

Brett T. Warden <bwarden@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (c) 2026 Brett T. Warden

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License version 2.1 as
published by the Free Software Foundation.

# TRADEMARK NOTICE

This project exists solely to enable interoperability with independently
purchased hardware. It is an independent community project: it is not
supplied by, authorized by, affiliated with, or endorsed by The Walt Disney
Company or any other rights holder. "Made With Magic", "Glow With The Show",
and all related names and marks are trademarks of their respective owners,
referenced here only to identify interoperable functionality.
