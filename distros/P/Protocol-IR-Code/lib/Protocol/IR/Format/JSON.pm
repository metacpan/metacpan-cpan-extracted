package Protocol::IR::Format::JSON;
use strict;
use warnings;

our $VERSION = '1.2';

use JSON::PP;
use File::Spec;
use File::Basename qw(dirname);

use Protocol::IR::Code;
use Protocol::IR::Format::Pronto;

# Import for a proprietary JSON IR database dump.  One command-set document
# is a "commands" list; each command is:
#
#   {
#     "keycode":   "G:JVCO1 16 Bit:(Start)(0xF0D6)():3",
#     "name":      "PowerToggle",
#     "protocol":  "JVCO1 16 Bit",
#     "pronto":    "0000 006D ..."
#   }
#
# The payload is raw Pronto hex, exactly as a wig carries, so these documents
# import to the same code list a wig would.  A *device* document in the same
# dump carries no commands of its own, only a "codeset" path to the re-usable
# command set shared by every device with those commands; the path is
# relative to the dump root, so it is resolved by walking up from the device
# file's own directory.  The wig importer auto-detects both shapes, so the two
# formats interchange freely at the converter entry point.  Import-only: the
# "keycode"/"protocol" strings are the dump's own opaque naming, so this
# format is never exported.

sub decode {
    my ($class, $input, $registry) = @_;
    die "No JSON input provided\n" unless defined $input;

    my ($text, $path) = _read_input($input);
    my $data = _decode_json($text);

    # A device document: follow its pointer to the shared command set.
    if (ref $data->{commands} ne 'ARRAY' && defined $data->{codeset}) {
        my $set = _find_codeset($data->{codeset}, $path);
        die "Cannot find the code set '$data->{codeset}'\n" unless defined $set;
        $data = _decode_json(_read_input($set));
    }

    die "JSON requires a commands list\n"
        unless ref($data->{commands}) eq 'ARRAY' && @{ $data->{commands} };

    my @decoded_codes;
    for my $cmd (@{ $data->{commands} }) {
        die "JSON command must be an object\n" unless ref $cmd eq 'HASH';
        # A command may carry no Pronto payload (nothing was ever captured
        # for it); nothing to convert, so skip rather than fail the import.
        next unless defined $cmd->{pronto} && $cmd->{pronto} ne '';
        die "JSON command is missing its name\n"
            unless defined $cmd->{name} && $cmd->{name} ne '';

        my $code = eval { $registry->import_format('Pronto', $cmd->{pronto}) };
        die "JSON command '" . $cmd->{name} . "' cannot be decoded: $@\n"
            if $@ || !defined $code;

        $code->alias($cmd->{name});
        $code->send_count(_repeat_hint($cmd));
        push @decoded_codes, $code;
    }

    return \@decoded_codes;
}

# How many times one press of a command transmits.  A keycode ends with a
# repeat hint after its last colon -- e.g. "G:JVC 16 Bit:(Start)(0xC004)():3"
# -- which is a property of the command rather than of its waveform.  Most
# commands hint the same value, but it does vary (1, 4, 33 and 0 all occur),
# so it is read per command.  0 means the keycode carries no usable hint, so
# the code keeps the single-press default.
sub _repeat_hint {
    my ($cmd) = @_;
    my ($hint) = defined $cmd->{keycode}
        ? $cmd->{keycode} =~ /:(\d{1,3})$/
        : ();
    return $hint && $hint >= 1 ? $hint : 0;
}

sub _decode_json {
    my ($text) = @_;
    $text =~ s/^\x{FEFF}//; # Strip UTF-8 BOM if present
    my $data = eval { JSON::PP->new->utf8->decode($text) };
    die "Invalid JSON: $@\n" if $@;
    die "JSON top level must be a JSON object\n" unless ref $data eq 'HASH';
    return $data;
}

# A device document names its code set relative to the dump root, not to the
# device file, so try each directory from the device file upwards.
sub _find_codeset {
    my ($rel, $base) = @_;
    return undef unless defined $rel;
    return $rel if -f $rel; # already relative to the current directory
    return undef unless defined $base;

    my $dir = dirname($base);
    while (1) {
        my $path = File::Spec->catfile($dir, $rel);
        return $path if -f $path;
        last if $dir eq File::Spec->rootdir;
        my $up = dirname($dir);
        last if $up eq $dir;
        $dir = $up;
    }
    return undef;
}

# Treat $input as file content when it looks like multi-line data, otherwise
# as a path to a file (falling back to treating it as a single-line JSON
# string).  Returns the text and, when the input was read from a file, the
# path it came from.
sub _read_input {
    my ($input) = @_;
    return ($input, undef) if $input =~ /[\r\n]/;

    if (-f $input) {
        open my $fh, '<', $input or die "Cannot open JSON file '$input': $!\n";
        local $/;
        my $text = <$fh>;
        close $fh;
        return ($text, $input);
    }
    return ($input, undef);
}

1;

=head1 NAME

Protocol::IR::Format::JSON - proprietary JSON IR database dump import

=head1 VERSION

version 1.2

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # Import a command-set document (file path or JSON string)
    my $codes = $converter->import_format('JSON', 'codeset.json');
    for my $code (@$codes) {
        print $code->alias . " (" . $code->protocol . ")\n";
    }

    # Import a device document, which points at its command set
    my $device = $converter->import_format('JSON', 'devices/JVC/EM40NF5.json');

    # The wig entry point accepts the same documents interchangeably
    my $also = $converter->import_format('wig', 'codeset.json');

=head1 DESCRIPTION

C<Protocol::IR::Format::JSON> imports the JSON documents of a proprietary IR
database dump.  A command-set document is a C<commands> list, each entry
carrying a C<name> and a raw C<pronto> Pronto hex payload plus opaque
C<keycode>/C<protocol> strings.  A device document instead carries a
C<codeset> path pointing at the re-usable command set that every device with
those commands shares; the path is relative to the dump root, so it is
resolved by walking up from the device file's own directory.  Either way the
payloads are the Pronto hex a wig carries, so the imported codes are
identical to what C<import_format('wig', ...)> would produce, and the wig
importer accepts these shapes automatically.  Commands with no Pronto payload
are skipped rather than failing the import.  Dies with a concrete reason if
the JSON is malformed, a command is missing its name, or a payload cannot be
decoded.

Import-only: the C<keycode>/C<protocol> strings are the dump's own naming, so
the format is never exported.

=head1 METHODS

=head2 decode

    my $codes = $class->decode($input, $registry);

Parses a file path or JSON string and returns an arrayref of
L<Protocol::IR::Code> objects, one per command with a Pronto payload, with
C<alias> set from the command C<name> and C<send_count> set from the repeat
hint the keycode carries after its last colon.

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
