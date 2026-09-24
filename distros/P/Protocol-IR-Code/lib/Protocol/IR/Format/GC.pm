package Protocol::IR::Format::GC;
use strict;
use warnings;

our $VERSION = '1.0';

use JSON::PP;

use Protocol::IR::Code;
use Protocol::IR::Format::Pronto;

# Global Cache IR database JSON import, the Perl sibling of the type-script
# GCIR/GlobalCache importer.  Global Cache hardware ("iTach", "GC-100" line)
# exports its IR code database as one JSON document per remote with a
# "commands" list; each command is:
#
#   {
#     "keycode": "G:Memorex 32 Bit:()(0xC100E01F)():3",
#     "name": "AmFmToggle",
#     "pronto": "0000 006D ...",
#     "protocol": "Memorex 32 Bit"
#   }
#
# The signal payload is raw Pronto hex, exactly as a HAIR wig carries, so a
# GC export imports to the same code list a wig would.  The repeat count --
# how many times the whole code replays on transmission -- is recorded as the
# trailing ":N" segment of the keycode (the ":3" above) and, in some exports,
# as an explicit per-command "repeats" field; it lands on the code's
# send_count so a wig export carries it as send_count.  The wig importer
# auto-detects this shape, so the two formats interchange freely at the
# converter entry point.  Import-only: the opaque "keycode"/"protocol"
# strings are Global Cache's own naming, so this format is never exported.

sub decode {
    my ($class, $input, $registry) = @_;
    die "No GC input provided\n" unless defined $input;

    my $text = _read_input($input);
    $text =~ s/^\x{FEFF}//; # Strip UTF-8 BOM if present

    my $data = eval { JSON::PP->new->utf8->decode($text) };
    die "Invalid GC JSON: $@\n" if $@;
    die "GC top level must be a JSON object\n" unless ref $data eq 'HASH';
    die "GC requires a commands list\n"
        unless ref($data->{commands}) eq 'ARRAY' && @{ $data->{commands} };

    my @decoded_codes;
    for my $cmd (@{ $data->{commands} }) {
        die "GC command must be an object\n" unless ref $cmd eq 'HASH';
        # A compact export may list commands without a Pronto payload (no
        # signal captured for them); nothing to convert, so skip rather than
        # fail the whole import.
        next unless defined $cmd->{pronto} && $cmd->{pronto} ne '';
        die "GC command is missing its name\n"
            unless defined $cmd->{name} && $cmd->{name} ne '';

        my $code = eval { $registry->import_format('Pronto', $cmd->{pronto}) };
        die "GC command '" . $cmd->{name} . "' cannot be decoded: $@\n"
            if $@ || !defined $code;

        $code->alias($cmd->{name});
        $code->send_count(_repeat_count($cmd));
        push @decoded_codes, $code;
    }

    return \@decoded_codes;
}

# The repeat count of a GC command: how many times the whole code replays
# upon transmission.  A raw IR database export records it two ways -- a
# per-command "repeats" integer in some exports, and always as the trailing
# ":N" segment of the keycode (e.g. "G:Eufy 40 Bit:()(0x68A0000008)():3").
# 0 means no count was recorded, which the wig exporter reads as the default
# single press.
sub _repeat_count {
    my ($cmd) = @_;
    my $r = $cmd->{repeats};
    if (defined $r && $r =~ /^\d+$/ && $r >= 1) {
        return $r;
    }
    my ($tail) = defined $cmd->{keycode} ? $cmd->{keycode} =~ /:(\d{1,3})$/ : ();
    return $tail && $tail >= 1 ? $tail : 0;
}

# Treat $input as file content when it looks like multi-line data,
# otherwise as a path to a file (falling back to treating it as a
# single-line JSON string).
sub _read_input {
    my ($input) = @_;
    return $input if $input =~ /[\r\n]/;

    if (-e $input) {
        open my $fh, '<', $input or die "Cannot open GC file '$input': $!\n";
        local $/;
        my $text = <$fh>;
        close $fh;
        return $text;
    }
    return $input;
}

1;

=head1 NAME

Protocol::IR::Format::GC - Global Cache IR database JSON import

=head1 VERSION

version 1.0

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # Import a Global Cache IR database export (file path or JSON string)
    my $codes = $converter->import_format('GCIR', 'gc-ir.json');
    for my $code (@$codes) {
        print $code->alias . " (" . $code->protocol . ")\n";
    }

    # The wig entry point accepts the same export interchangeably
    my $also = $converter->import_format('wig', 'gc-ir.json');

=head1 DESCRIPTION

C<Protocol::IR::Format::GC> imports a Global Cache IR database JSON document
(a C<commands> list, each entry carrying a C<name> and a raw C<pronto> Pronto
hex payload, plus opaque C<keycode>/C<protocol> strings).  The payload is the
same Pronto hex a HAIR wig carries, so the imported codes are identical to
what C<import_format('wig', ...)> would produce, and the wig importer accepts
this shape automatically.  Commands that carry no Pronto payload (a compact
export may list buttons it never captured a signal for) are skipped rather
than failing the import.  Dies with a concrete reason if the JSON is
malformed, a command is missing its name, or a payload cannot be decoded.

Import-only: the C<keycode>/C<protocol> strings are Global Cache's own
naming, so the format is never exported.

=head1 METHODS

=head2 decode

    my $codes = $class->decode($input, $registry);

Parses a GC file path or JSON string and returns an arrayref of
L<Protocol::IR::Code> objects, one per command with a Pronto payload,
C<alias> set from the command C<name> and C<send_count> set from the
command's repeat count (the C<repeats> field, falling back to the trailing
C<:N> of the keycode).

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

=cut