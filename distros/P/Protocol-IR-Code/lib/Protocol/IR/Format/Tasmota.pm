package Protocol::IR::Format::Tasmota;
use strict;
use warnings;

our $VERSION = '1.0';

use Protocol::IR::Code;

# Tasmota IR raw data support.
#
# decode() accepts the content of a Tasmota "RawData" field, either as the
# compact letter-compressed form ("+8570-4240+550-1580C-510+565-1565F-505Fh...")
# or as a plain comma-separated mark/space list ("926,844,958,..."). The
# timings are decoded to microsecond mark/space pairs, tried against every
# registered protocol, and the resulting Protocol::IR::Code keeps the raw timings so
# the signal can be re-exported losslessly.
#
# export() produces a Tasmota IRSend raw command:
#   IRSend <frequency>,<rawdata>
# with the compact form by default, or the comma list with style => 'comma'.

# --- compact format codec ----------------------------------------------
#
# Each new timing value gets the next letter (A-Z); a repeated value is
# written as that letter, uppercase for a HIGH (mark) signal and lowercase
# for a LOW (space) signal. Magnitudes are multiples of 5 microseconds.

sub _round5 {
    my ($v) = @_;
    return int(($v + 2.5) / 5) * 5;
}

# The Tasmota compact encoding assigns letters (A-Z) to the first 26 distinct
# timing magnitudes in order of first appearance. A repeated value is written
# as its letter, uppercase for a mark and lowercase for a space. Values beyond
# the 26-letter table are written numerically every time they occur.
sub _decode_compact {
    my ($text) = @_;
    my @values;
    my (%letter_for, %rev); # magnitude -> letter, letter -> magnitude
    my $count = 0;
    while ($text =~ /([+\-]\d+|[A-Za-z])/g) {
        my $tok = $1;
        if ($tok =~ /^([+\-])(\d+)$/) {
            my $mag = $2 + 0;
            if (!exists $letter_for{$mag} && $count < 26) {
                $letter_for{$mag} = chr(ord('A') + $count++);
                $rev{ $letter_for{$mag} } = $mag;
            }
            push @values, ($1 eq '+' ? 1 : -1) * $mag;
        } else {
            die "Tasmota compact format references undefined timing letter '$tok'\n"
                unless exists $rev{uc $tok};
            my $mag = $rev{uc $tok};
            push @values, ($tok =~ /^[A-Z]/ ? 1 : -1) * $mag;
        }
    }
    die "Tasmota compact format contains no timing data\n" unless @values;
    return \@values;
}

sub _encode_compact {
    my ($values) = @_;
    my @out;
    my %letter_for;
    my $next = 0;
    for my $v (@$values) {
        my $sign = ($v < 0) ? '-' : '+';
        my $mag  = _round5(abs($v));
        if (!exists $letter_for{$mag}) {
            if ($next < 26) {
                $letter_for{$mag} = chr(ord('A') + $next++);
            }
            push @out, $sign . $mag;
        } else {
            my $letter = $letter_for{$mag};
            $letter = uc($letter) if $sign eq '+';
            $letter = lc($letter) if $sign eq '-';
            push @out, $letter;
        }
    }
    return join '', @out;
}

# Normalize the various RawData forms into a flat list of signed timings,
# positive for marks and negative for spaces.
sub _to_signed_values {
    my ($input) = @_;
    die "No Tasmota RawData provided\n" unless defined $input;

    if (ref $input eq 'ARRAY') {
        my @values;
        for my $i (0 .. $#$input) {
            push @values, ($i % 2 == 0 ? 1 : -1) * ($input->[$i] + 0);
        }
        return \@values;
    }

    my $text = $input;
    $text =~ s/^\s+|\s+$//g;
    # Accept a full "IRSend <freq>,<rawdata>" command line as well.
    $text =~ s/^IRsend\s+\d+,//i;

    if ($text =~ /,/) {
        my @values;
        my $i = 0;
        for my $tok (split /,/, $text) {
            $tok =~ s/^\s+|\s+$//g;
            push @values, ($i++ % 2 == 0 ? 1 : -1) * ($tok + 0);
        }
        return \@values;
    }
    if ($text =~ /[A-Za-z+\-]/) {
        return _decode_compact($text);
    }
    die "Unrecognized Tasmota RawData input\n";
}

sub decode {
    my ($class, $input, $registry) = @_;
    die "No Tasmota RawData provided\n" unless defined $input;

    # A multi-line dump (a Tasmota console log of IRrecv lines, possibly
    # timestamp-prefixed) splits into one signal per line.
    return $class->decode_dump($input, $registry)
        if !ref $input && $input =~ /[\r\n]/;

    # A protocol-structured line ("Protocol = NEC, Bits = 32, Data = 0x...",
    # or the JSON form Tasmota publishes over MQTT) imports through the named
    # protocol rather than by timing decode, preferring DataLSB for the
    # per-byte LSB-first protocols exactly as the JS port does.
    if (!ref $input) {
        my ($proto, $data, $data_lsb) = _parse_structured($input);
        if (defined $proto) {
            my $code = $class->_import_structured($proto, $data, $data_lsb, $registry);
            if ($code) {
                $code->alias(_data_alias($code)) unless $code->alias;
                return [$code];
            }
            return [];
        }
    }

    my $values = _to_signed_values($input);

    my @flat = @$values;
    my @pairs;
    while (@flat) {
        my $mark  = shift @flat;
        my $space = shift @flat // 0;
        push @pairs, [abs($mark), abs($space)];
    }

    my $code;
    for my $proto_class ($registry->get_protocols()) {
        next unless $proto_class->can('decode_timing');
        my $decoded = $proto_class->decode_timing(\@pairs);
        if (defined $decoded) { $code = $decoded; last; }
    }
    $code ||= Protocol::IR::Code->new(protocol => 'UNKNOWN');
    $code->timings($values);
    $code->alias(_data_alias($code)) if $code->protocol ne 'UNKNOWN';

    return [$code];
}

# Parse a Tasmota IRrecv protocol-structured record, in either the console
# log form ("Protocol = NEC, Bits = 32, Data = 0x10EF00FF") or the JSON form
# Tasmota publishes ("Protocol":"NEC","Data":"0x10EF00FF","DataLSB":
# "0x08F700FF"). Returns the protocol name, the Data token, and the DataLSB
# token (or undef when absent), or an empty list when the line is not
# structured.
sub _parse_structured {
    my ($text) = @_;
    my ($proto) = $text =~ /\bProtocol"?\s*[=:]\s*"?([A-Za-z][A-Za-z0-9_-]*)"?/i
        or return ();
    my ($data)  = $text =~ /\bData"?\s*[=:]\s*"?((?:0[xX])?[0-9A-Fa-f]+)"?/i
        or return ();
    my ($data_lsb) = $text =~ /\bDataLSB"?\s*[=:]\s*"?((?:0[xX])?[0-9A-Fa-f]+)"?/i;
    return ($proto, $data, $data_lsb);
}

# Import a structured record's fields through the named protocol, mirroring
# the JS decodeRecord routing. Tasmota's "Data" is IRremoteESP8266's decoded
# value and "DataLSB" the per-byte bit reversal Tasmota computes from it; for
# the protocols that transmit each byte LSB-first (NEC, JVC, SAMSUNG) that
# reversal is the accumulated form decode_raw reads, so DataLSB wins, while
# for whole-word MSB-first protocols (SAMSUNG36) Data itself is the
# accumulated form. Returns undef for an unregistered protocol name.
sub _import_structured {
    my ($class, $proto, $data, $data_lsb, $registry) = @_;
    my $proto_class = $registry->get_protocol($proto);
    return undef unless $proto_class;

    my $lsb_is_accumulated = 1;
    $lsb_is_accumulated = $proto_class->lsb_is_accumulated
        if $proto_class->can('lsb_is_accumulated');

    if ($lsb_is_accumulated && defined $data_lsb) {
        return $registry->import_lsb($proto, $data_lsb);
    }
    return $registry->import_msb($proto, $data);
}

# The button-name substitute used when a capture has no known key name: the
# code's "Data" hex value, formatted like Tasmota's Data field (0x030C for a
# 16-bit JVC frame, 0x10EF00FF for a 32-bit NEC frame, the full word for the
# wide protocols). A wig built from these gets editable button names the
# user can correct after importing it in HAIR.
sub _data_alias {
    my ($code) = @_;
    return '' unless defined $code->data;
    return Protocol::IR::Code::_data_hex($code->data);
}

# Split a Tasmota console dump into its individual signals and decode each.
#
# A dump is one or more IRrecv lines, each either protocol-structured
# ("Protocol = NEC, Bits = 32, Data = 0x...") or raw timing data
# ("RawData = +...-..." compact, or "RawData = 9,9,..." comma), plus
# "IRsend <freq>,<rawdata>" command lines; each line is one signal.
# Timestamps and other log noise are ignored. Signals that fail to decode
# to a registered protocol -- an unsupported protocol name, or raw data
# that matches no protocol -- are dropped. Every decoded signal gets a
# data-hex alias (see _data_alias) so a wig built from the result has
# editable button names.
sub decode_dump {
    my ($class, $input, $registry) = @_;
    die "No Tasmota dump provided\n" unless defined $input;

    my $text = ref $input eq 'ARRAY' ? join("\n", @$input) : $input;
    my @codes;
    for my $line (split /\r?\n/, $text) {
        $line =~ s/^\s+|\s+$//g;
        next unless $line;

        my $signal;
        if ($line =~ /\bProtocol\s*[=:]/i) {
            $signal = $line;
        } elsif ($line =~ /\bRawData\s*=\s*(.+)$/i) {
            $signal = $1;
        } elsif ($line =~ /^IRsend\b/i) {
            $signal = $line;
        } else {
            next;
        }

        my $code;
        eval { $code = $class->decode($signal, $registry)->[0]; 1 }
            or next;
        next unless $code && $code->protocol ne 'UNKNOWN';
        # A structured MWM record's Data field can carry a whole A+B+A' bundle
        # (a "capture"), which Tasmota logged as one value -- unwrap it through
        # the protocol's optional unbundle capability so every frame of the
        # bundle is yielded as its own code.
        if ($code->protocol eq 'MWM') {
            my $proto_class = $registry->get_protocol('MWM');
            my $bundled = $proto_class && $proto_class->can('unbundle')
                ? $proto_class->unbundle($code->data)
                : [];
            if (@$bundled >= 2) { push @codes, @$bundled; next; }
        }
        push @codes, $code;
    }
    return \@codes;
}

sub export {
    my ($class, $ir_code, $registry, %opts) = @_;
    if (ref $ir_code eq 'ARRAY') {
        die "Tasmota IRSend can only export a single signal\n" unless @$ir_code;
        $ir_code = $ir_code->[0];
    }

    my $style = lc($opts{style} // 'compact');
    die "Unsupported Tasmota export style: $style\n"
        unless $style eq 'compact' || $style eq 'comma';

    my $timings = $ir_code->timings;
    $timings ||= _timings_from_code($ir_code, $registry);

    my $freq = defined $opts{frequency} ? $opts{frequency} + 0 : 0;
    my $data;
    if ($style eq 'compact') {
        $data = _encode_compact($timings);
    } else {
        $data = join(',', map { int(abs($_) + 0.5) } @$timings);
    }
    return "IRSend $freq,$data";
}

# Derive a flat signed timing list for a fresh Protocol::IR::Code by round-tripping
# through the registered protocol encoder's Pronto output.
sub _timings_from_code {
    my ($ir_code, $registry) = @_;
    my $pronto = $registry->export_code($ir_code, 'Pronto');
    $pronto =~ s/^\s+|\s+$//g;
    my @tokens = split /\s+/, $pronto;
    die "Cannot derive Tasmota timings from protocol encoder output\n"
        if scalar(@tokens) < 4;

    my $freq_word = hex($tokens[1]);
    my $carrier   = ($freq_word > 0) ? int(1000000.0 / ($freq_word * 0.241246)) : 38000;
    my $period    = 1000000.0 / $carrier;

    my $pair_count = hex($tokens[2]) + hex($tokens[3]);
    my @flat;
    for (my $i = 0; $i < $pair_count; $i++) {
        my $idx   = 4 + ($i * 2);
        my $mark  = hex($tokens[$idx])     * $period;
        my $space = hex($tokens[$idx + 1]) * $period;
        push @flat, int($mark + 0.5), -int($space + 0.5);
    }
    return \@flat;
}

1;

=head1 NAME

Protocol::IR::Format::Tasmota - Tasmota RawData import and IRSend export

=head1 VERSION

version 1.0

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # Decode a Tasmota IR log capture (compact letter-coded RawData)
    my $capture = "+9185-4490+650-500+655dE-1630C-505+630-525Ed...";
    my $code = $converter->import_format('Tasmota', $capture)->[0];
    print $code->protocol;   # NEC
    print $code->data;       # Tasmota DataLSB value

    # Re-export as a Tasmota IRSend command (comma style with carrier)
    my $irsend = $converter->export_code($code, 'Tasmota',
        style => 'comma', frequency => 38000);
    # IRSend 38000,9185,4490,650,...

    # Compact letter-coded style is the default
    my $compact = $converter->export_code($code, 'Tasmota');
    # IRSend 0,+9185-4490+650-500+655dE-...

=head1 DESCRIPTION

C<Protocol::IR::Format::Tasmota> imports Tasmota "RawData" IR captures and exports
Tasmota C<IRSend> commands.

=head2 Decode input forms

C<decode> accepts the content of a Tasmota C<RawData> field in any of these
forms:

=over 4

=item * The compact letter-compressed form
(C<+8570-4240+550-1580C-510+565-1565F-505Fh...>). Each new timing magnitude
gets the next letter (C<A>-C<Z>) in order of first appearance; a repeated
value is written as its letter, uppercase for a mark and lowercase for a
space. Magnitudes are multiples of 5 microseconds. Values beyond the 26
letter table are written numerically every time they occur.

=item * A plain comma-separated mark/space list (C<926,844,958,...>).

=item * A full C<IRSend E<lt>freqE<gt>,E<lt>rawdataE<gt>> command line.

=item * An arrayref of integer timings, alternating mark, space, mark, ...

=item * A protocol-structured IRrecv line
(C<IRrecv: Protocol = NEC, Bits = 32, Data = 0x10EF00FF>), possibly with a
timestamp prefix. The line imports through the named protocol rather than
by timing decode.

=back

The timings are decoded to microsecond mark/space pairs and tried against
every registered protocol. The resulting L<Protocol::IR::Code> keeps the raw timings
on the C<timings> accessor so the signal can be re-exported losslessly,
even when no protocol matches (the code's protocol is then C<UNKNOWN>).

A protocol-structured line and a raw-data signal that decodes to a known
protocol get their C<alias> set to the signal's Data hex value (e.g.
C<0x10EF00FF>, width-matched to the protocol's bit count), so a wig built
from them carries editable button names.

=head2 Decoding a full console dump

C<decode> treats input containing newlines as a Tasmota console dump and
splits it into one signal per line. Each line may be protocol-structured,
a C<RawData> line (compact or comma form), or an C<IRsend> command line;
timestamps and other log noise are ignored. Lines that fail to decode to a
registered protocol are dropped. C<decode_dump> performs the same split
explicitly.

=head2 Export forms

C<export> produces a Tasmota C<IRSend> command:

    IRSend <frequency>,<rawdata>

The C<rawdata> is the compact letter-coded form by default, or the
comma-separated mark/space list with C<style =E<gt> 'comma'>. When the code
was decoded from Tasmota data its original timings are reused; otherwise
they are derived by round-tripping the code through the protocol encoder's
Pronto output, so the emitted timings match the other timing formats
exactly.

=head1 METHODS

=head2 decode

    my $codes = $class->decode($input, $registry);

Returns an arrayref containing one L<Protocol::IR::Code> per captured signal. A
single Tasmota RawData string or protocol-structured line yields a single
code; multi-line input is split into one code per signal (see
L</"Decoding a full console dump">).

=head2 decode_dump

    my $codes = $class->decode_dump($dump_text, $registry);

Splits a Tasmota console dump (any mix of protocol-structured, C<RawData>,
and C<IRsend> lines) into one L<Protocol::IR::Code> per decodable signal. Lines that
do not decode to a registered protocol are dropped; every returned code
carries a Data-hex alias.

=head2 export

    my $cmd = $class->export($ir_code, $registry, %opts);

Serializes an L<Protocol::IR::Code> (or a single-element arrayref) into an C<IRSend>
command. Options:

=over 4

=item * C<style> -- C<'compact'> (default) or C<'comma'>.

=item * C<frequency> -- carrier frequency in Hz to embed in the command
(default C<0>).

=back

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
