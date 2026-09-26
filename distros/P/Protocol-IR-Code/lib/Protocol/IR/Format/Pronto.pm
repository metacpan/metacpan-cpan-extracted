package Protocol::IR::Format::Pronto;
use strict;
use warnings;

our $VERSION = '1.2';

sub export {
    my ($class, $ir_code, $registry) = @_;

    # A code decoded from Pronto Hex carries its original hex verbatim (see
    # decode), so re-emitting it needs no protocol encoder and round-trips
    # byte-identically. Only codes built from decoded fields (import_code,
    # CSV) are encoded here.
    return $ir_code->pronto if defined $ir_code->pronto;

    my $proto_name = $ir_code->protocol;
    my $plugin     = $registry->get_protocol($proto_name);

    die "No protocol encoder registered for: $proto_name\n" unless $plugin;
    return $plugin->to_pronto($ir_code);
}

# Renamed from 'import' to 'decode' to avoid Perl's module import hook
sub decode {
    my ($class, $pronto_str, $registry) = @_;

    die "No Pronto Hex string provided\n" unless defined $pronto_str;

    # Clean whitespace and split hex tokens
    $pronto_str =~ s/^\s+|\s+$//g;
    my @tokens = split(/\s+/, $pronto_str);

    die "Invalid Pronto Hex string (too short)\n" if scalar(@tokens) < 4;

    my $raw_format = hex($tokens[0]);
    die "Only raw Pronto Hex format (0000) is supported\n" unless $raw_format == 0;

    my $freq_word  = hex($tokens[1]);
    my $seq1_pairs = hex($tokens[2]);
    my $seq2_pairs = hex($tokens[3]);

    # Calculate carrier frequency and period in microseconds
    my $carrier_hz = ($freq_word > 0) ? int(1000000.0 / ($freq_word * 0.241246)) : 38000;
    my $period_us  = 1000000.0 / $carrier_hz;

    my @burst_pairs_us;
    my $pair_count = $seq1_pairs + $seq2_pairs;

    for (my $i = 0; $i < $pair_count; $i++) {
        my $idx = 4 + ($i * 2);
        last if $idx + 1 >= scalar(@tokens);

        my $mark_cycles  = hex($tokens[$idx]);
        my $space_cycles = hex($tokens[$idx + 1]);

        push @burst_pairs_us, [
            $mark_cycles * $period_us,
            $space_cycles * $period_us
        ];
    }

    # Keep the capture so any re-export is lossless: the quantized mark/space
    # waveform (for the timing formats) and the original hex verbatim (for a
    # Pronto re-export or a Pronto-passthrough container such as wig), exactly
    # as the other timing formats (Tasmota, mode2, LIRC) already do.
    my @timings;
    for my $pair (@burst_pairs_us) {
        push @timings, int($pair->[0]), -int($pair->[1]);
    }

    # Iterate over registered protocols (in registration order) to decode
    # the timing array
    for my $proto_class ($registry->get_protocols()) {
        if ($proto_class->can('decode_timing')) {
            my $code = $proto_class->decode_timing(\@burst_pairs_us);
            if (defined $code) {
                $code->timings(\@timings);
                $code->pronto($pronto_str);
                return $code;
            }
        }
    }

    # No registered protocol matched. A payload with real timing data is
    # still valid raw Pronto Hex, so keep it as an opaque UNKNOWN code rather
    # than failing: container conversions that just move Pronto hex (e.g.
    # JSON dump to wig) must not depend on naming the protocol. A truncated
    # or empty payload is malformed, not merely unknown, and still dies.
    die "Unable to decode Pronto Hex string into a known protocol\n"
        unless @burst_pairs_us;

    return Protocol::IR::Code->new(
        protocol        => 'UNKNOWN',
        bypass_protocol => 1,
        timings         => \@timings,
        pronto          => $pronto_str,
    );
}

1;

=head1 NAME

Protocol::IR::Format::Pronto - Raw Pronto Hex encoder and decoder

=head1 VERSION

version 1.2

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();
    my $code = $converter->import_code('NEC', '0x10EF00FF');

    # Encode an Protocol::IR::Code object as Pronto Hex
    my $pronto = $converter->export_code($code, 'Pronto');

    # Decode Pronto Hex back into an Protocol::IR::Code
    my $decoded = $converter->import_format('Pronto', $pronto);

=head1 DESCRIPTION

C<Protocol::IR::Format::Pronto> encodes L<Protocol::IR::Code> objects into Pronto Hex strings
and decodes Pronto Hex back into L<Protocol::IR::Code> objects. Only the I<raw> form
(header C<0000>) is supported.

=over 4

=item Example Pronto Hex (a 32-bit NEC transmission)

    0000 006D 0022 0000 0157 00AC 0015 0015 0015 0015 0015 0015 0015 0015 \
    0015 0040 0015 0015 0015 0015 0015 0015 0015 0040 0015 0040 0015 0040 \
    0015 0040 0015 0015 0015 0040 0015 0040 0015 0040 0015 0015 0015 0015 \
    0015 0015 0015 0015 0015 0015 0015 0015 0015 0015 0015 0015 0015 0040 \
    0015 0040 0015 0040 0015 0040 0015 0040 0015 0040 0015 0040 0015 0040 \
    0015 0689

The fields are the raw-format marker (C<0000>), the carrier frequency word
(C<006D>), the burst-pair counts for the one-time and repeat sequences
(C<0022 0000>), then that many mark/space pulse-count pairs, the final value
being the trailing stop bit. See the IR Scrutinizer glossary for the full
field layout (L<http://www.harctoolbox.org/Glossary.html>).

=back

The carrier frequency word is stored in the frequency field and converted
to a period in microseconds: the pulse count stored for each mark/space is
the duration in carrier cycles, so the actual duration depends on the
transmitter's carrier frequency. Protocol encoders emit frequency words for
their nominal carrier (typically 38 kHz) and pulse counts quantized to that
carrier, so the decoded microsecond timings round-trip cleanly.

Because decoding works from the microsecond timing signature (see
L<Protocol::IR::Converter/"DECODING VERSUS GENERATING TIMINGS">), a Pronto string is
only recognized if it matches a registered protocol. Whether or not it does,
the decoded L<Protocol::IR::Code> keeps the exact capture -- the quantized
C<timings> and the hex stashed verbatim in C<pronto> -- so C<export> (and any
Pronto-passthrough container such as wig or the JSON dump importer)
round-trips the string byte-identically. A well-formed string with real
timing data that no protocol recognizes is not an error: it decodes to an
opaque C<UNKNOWN> code (C<bypass_protocol> set) so container conversions
that move Pronto hex can still complete. Truncated or empty payloads are
still rejected.

=over 4

=item * C<pronto> is set on every Pronto decode, so C<export> re-emits the
original string rather than re-quantizing through the protocol encoder.

=item * C<timings> is set on every Pronto decode, so the same microsecond
waveform feeds the other timing formats (Tasmota, mode2, LIRC) losslessly.

=back

=head1 METHODS

=head2 export

    my $pronto = $class->export($ir_code, $registry);

Converts a single L<Protocol::IR::Code> object into a Pronto Hex string.
When the code was itself decoded from Pronto Hex, its stashed C<pronto>
string is re-emitted verbatim. Otherwise the registered protocol handler for
the code's protocol encodes it from its decoded fields (L<to_pronto>).

=head2 decode

    my $code = $class->decode($pronto_str, $registry);

Parses a Pronto Hex string into microsecond mark/space pairs and tries each
registered protocol's C<decode_timing> in registration order. Returns the
first matching L<Protocol::IR::Code>, or dies if the string cannot be decoded.

C<decode> is named C<decode> rather than C<import> to avoid clashing with
Perl's module import hook.

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
