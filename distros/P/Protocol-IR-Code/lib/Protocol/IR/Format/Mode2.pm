package Protocol::IR::Format::Mode2;
use strict;
use warnings;

our $VERSION = '1.1';

use Protocol::IR::Code;

# Mode2 pulse/space capture import and export, the native format of the LIRC
# `mode2` tool and the MQTT IR test rig's receiver topic ("hear back timings").
#
# A mode2 capture is one timing per line: "pulse 417" and "space 1251", in
# microseconds, strictly alternating. Consecutive messages are separated by an
# inter-message space far wider than any in-frame timing; the log splits on a
# space of 10000 µs or more (lirc's default gap), keeping the separator in the
# message so the final space is part of the decoded signal.
#
# decode() reads the whole capture, splits it into messages, decodes each
# through every registered protocol decoder, and returns one Protocol::IR::Code per
# message with its raw timings kept, so a re-export is lossless. Messages with
# no mark at all (the doubled-gap dead air between two separators) are dropped;
# signals no protocol recognizes are kept as UNKNOWN rather than discarded,
# because a capture is a record of what was on the air, not a filter.
#
# export() writes one message as alternating pulse/space lines, ensuring the
# message ends on a space wide enough (>= 10000 µs) that re-importing the file
# splits messages back at the same boundaries.

# lirc's default inter-message gap: any space this wide separates messages.
my $SPLIT = 10000;
# The gap written at the end of an exported message that does not already end
# on a wide space. Far above any in-frame timing and well past SPLIT.
my $EXPORT_GAP = 100000;

# Split a flat signed timing list into messages on spaces of SPLIT us or
# more, keeping the separator in the message that precedes it.
sub _split_messages {
    my ($flat) = @_;
    my (@msgs, @cur);
    for my $v (@$flat) {
        push @cur, $v;
        if ($v < 0 && -$v >= $SPLIT) {
            push @msgs, [@cur];
            @cur = ();
        }
    }
    push @msgs, [@cur] if @cur;
    return \@msgs;
}

# Decode one message's flat signed timings (positive marks, negative spaces)
# into a Protocol::IR::Code by trying every registered protocol decoder. The code keeps
# the raw timings so it re-exports losslessly; a signal no protocol recognizes
# is tagged UNKNOWN.
sub _decode_message {
    my ($values, $registry) = @_;
    my @pairs;
    for (my $i = 0; $i < @$values; $i += 2) {
        push @pairs, [abs($values->[$i]), abs($values->[$i + 1] // 0)];
    }

    my $code;
    for my $proto_class ($registry->get_protocols()) {
        next unless $proto_class->can('decode_timing');
        my $decoded = $proto_class->decode_timing(\@pairs);
        if (defined $decoded) { $code = $decoded; last; }
    }
    $code ||= Protocol::IR::Code->new(protocol => 'UNKNOWN');
    $code->timings($values);
    if ($code->protocol ne 'UNKNOWN' && defined $code->data) {
        $code->alias(Protocol::IR::Code::_data_hex($code->data));
    }
    return $code;
}

# Derive a flat signed timing list for a fresh Protocol::IR::Code by round-tripping
# through the registered protocol encoder's Pronto output.
sub _timings_from_code {
    my ($ir_code, $registry) = @_;
    my $pronto = $registry->export_code($ir_code, 'Pronto');
    $pronto =~ s/^\s+|\s+$//g;
    my @tokens = split /\s+/, $pronto;
    die "Cannot derive Mode2 timings from protocol encoder output\n"
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

sub decode {
    my ($class, $input, $registry) = @_;
    die "No Mode2 capture provided\n" unless defined $input;

    my $text = ref $input eq 'ARRAY' ? join("\n", @$input) : "$input";
    my @flat;
    for my $line (split /\r?\n/, $text) {
        next unless $line =~ /^\s*(pulse|space)\s+(\d+)/i;
        my $sign = (lc($1) eq 'pulse') ? 1 : -1;
        push @flat, $sign * ($2 + 0);
    }
    die "No Mode2 timings found\n" unless @flat;

    my @codes;
    for my $msg (@{ _split_messages(\@flat) }) {
        # The dead air between two separators (a doubled gap) has no mark.
        next unless grep { $_ > 0 } @$msg;
        push @codes, _decode_message($msg, $registry);
    }
    return \@codes;
}

sub export {
    my ($class, $ir_code, $registry) = @_;
    my $list = ref $ir_code eq 'ARRAY' ? $ir_code : [$ir_code];
    my @lines;
    for my $code (@$list) {
        my $timings = $code->timings;
        $timings ||= _timings_from_code($code, $registry);
        $timings = [ @$timings ];
        my $last = $timings->[-1];
        if ($last > 0) {
            # Ends on a mark: append an inter-message gap.
            push @$timings, -$EXPORT_GAP;
        } elsif (-$last < $SPLIT) {
            # Ends on a space too short to split on: widen it into the gap.
            $timings->[-1] = -$EXPORT_GAP;
        }
        for my $v (@$timings) {
            push @lines, sprintf("%s %d", ($v > 0 ? 'pulse' : 'space'), int(abs($v) + 0.5));
        }
    }
    return join("\n", @lines) . "\n";
}

1;

=encoding utf8

=head1 NAME

Protocol::IR::Format::Mode2 - LIRC mode2 pulse/space capture import and export

=head1 VERSION

version 1.1

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # Import a mode2 capture (pulse/space lines, one timing per line)
    my $capture = "pulse 4514\nspace 4514\npulse 549\nspace 1708\n...";
    my $codes = $converter->import_format('Mode2', $capture);

    # Re-export a code as mode2 lines
    my $text = $converter->export_code($codes->[0], 'Mode2');

=head1 DESCRIPTION

C<Protocol::IR::Format::Mode2> imports and exports the pulse/space capture
format of the LIRC C<mode2> tool (and the MQTT IR test rig's receiver topic):
one timing per line, C<pulse N> or C<space N>, in microseconds, strictly
alternating.

=over 4

=item Example capture (what C<mode2> puts on stdout)

    pulse 4514
    space 4514
    pulse 549
    space 1708
    pulse 549
    space 1647
    ...
    space 100000

=back

C<mode2> is part of LIRC (L<https://www.lirc.org/>).

C<decode> reads a whole capture, splits it into messages on spaces of
B<10000 µs> or more (lirc's default inter-message gap, keeping the separator
in the message that precedes it), decodes each message through every
registered protocol decoder, and returns one L<Protocol::IR::Code> per message.
Every code keeps its raw timings so a re-export is lossless. Messages with no
mark at all (dead air between two separators) are dropped; signals no
protocol recognizes are kept with protocol C<UNKNOWN> rather than discarded,
because a capture is a record of what was on the air. Codes that decode to a
known protocol get their C<alias> set to the signal's Data hex value.

C<export> writes one message per code as alternating pulse/space lines,
ensuring each message ends on a space wide enough (B<100000 µs>, or its
existing trailing space when already B<E<gt>= 10000 µs>) that re-importing
the output splits messages back at the same boundaries. When a code carries
no raw timings (e.g. one built with C<import_code>), they are derived by
round-tripping the code through the protocol encoder's Pronto output, so the
emitted timings match the other timing formats exactly.

=head1 METHODS

=head2 decode

    my $codes = $class->decode($input, $registry);

Parses a mode2 capture (a string, or an arrayref of lines) into a list of
L<Protocol::IR::Code> objects, one per message. Dies on empty input with no
timings.

=head2 export

    my $text = $class->export($ir_code, $registry);

Serializes one L<Protocol::IR::Code>, or an arrayref of them, into mode2
pulse/space lines.

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
