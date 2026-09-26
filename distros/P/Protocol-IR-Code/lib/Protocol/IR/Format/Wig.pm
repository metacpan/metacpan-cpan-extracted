package Protocol::IR::Format::Wig;
use strict;
use warnings;

our $VERSION = '1.2';

use JSON::PP;

use Protocol::IR::Code;
use Protocol::IR::Format::Pronto;
use Protocol::IR::Format::JSON;

use constant FORMAT_VERSION => 'hair-wig/3';

# wig is the portable IR code set format
# used by the HAIR Home Assistant integration
# (https://github.com/DAB-LABS/HAIR): one JSON file, one remote, raw
# Pronto hex as the payload.
#
# We emit hair-wig/3, the current recipe major: every signal carries
# an explicit ditto_count and bypass_protocol, plus an optional
# send_count when a code carries a repeat count other than the default
# single press. On import, signals are decoded fresh through the
# registered protocols (the file never carries decoded fields) and each
# signal's transmit recipe is kept on the resulting Protocol::IR::Code.

sub decode {
    my ($class, $input, $registry) = @_;
    die "No wig input provided\n" unless defined $input;

    my $text = _read_input($input);
    $text =~ s/^\x{FEFF}//; # Strip UTF-8 BOM if present

    my $data = eval { JSON::PP->new->utf8->decode($text) };
    die "Invalid wig JSON: $@\n" if $@;
    die "wig top level must be a JSON object\n" unless ref $data eq 'HASH';
    # A JSON IR database document (a "commands" list with raw Pronto hex
    # payloads, no hair-wig "format" field) carries the same signals a wig
    # does, so the wig entry point imports it interchangeably.
    if (!defined $data->{format} && (ref $data->{commands} eq 'ARRAY' || defined $data->{codeset})) {
        return Protocol::IR::Format::JSON->decode($input, $registry);
    }
    die "Unsupported wig format: " . ($data->{format} // '(missing)') . "\n"
        unless defined $data->{format} && $data->{format} =~ m{^hair-wig/([1-3])$};

    my @decoded_codes;
    for my $sig (@{ $data->{signals} || [] }) {
        next unless ref $sig eq 'HASH';
        next unless defined $sig->{pronto} && $sig->{pronto} ne '';

        my $code = eval { $registry->import_format('Pronto', $sig->{pronto}) };
        die "wig signal '" . ($sig->{alias} // '') . "' cannot be decoded: $@\n"
            if $@ || !defined $code;

        $code->alias($sig->{alias} // '');
        $code->ditto_count($sig->{ditto_count} // 0);
        $code->bypass_protocol($sig->{bypass_protocol} ? 1 : 0);
        # send_count (how many times the whole signal transmits per press) is
        # optional with a default of 1; preserve it so a wig -> wig or later
        # export round trip keeps it.
        $code->send_count($sig->{send_count}) if defined $sig->{send_count};
        push @decoded_codes, $code;
    }

    return \@decoded_codes;
}

# Generate a wig from one Protocol::IR::Code or an arrayref of them.
#
# Options:
#   name    - remote name (required by the format; default 'Untitled')
#   brand   - manufacturer name
#   model   - model string
#   kind    - device kind slug (tv, soundbar, ...)
#   notes   - free-form notes
#   origin  - provenance string; default marks this library as the converter
#   wig_id  - identity UUID (default: a freshly minted v4 UUID)
#   format  - format major to emit (default: hair-wig/3)
sub export {
    my ($class, $codes, $registry, %opts) = @_;
    $codes = [$codes] unless ref $codes eq 'ARRAY';

    my @signals;
    for my $code (@$codes) {
        my $pronto = $registry->export_code($code, 'Pronto');
        my %sig = (
            alias           => $code->alias,
            pronto          => $pronto,
            ditto_count     => $code->ditto_count // 0,
            bypass_protocol => $code->bypass_protocol ? JSON::PP::true : JSON::PP::false,
        );
        # send_count is optional with a default of 1, so only a repeat count
        # that differs from the default is written (the canonical forms leave
        # it out); a code with no recorded repeat (send_count 0) also omits
        # it, keeping existing exports byte-stable.
        $sig{send_count} = $code->send_count if $code->send_count >= 2;
        push @signals, \%sig;
    }

    my %wig = (
        format  => $opts{format} // FORMAT_VERSION,
        name    => $opts{name}   // 'Untitled',
        wig_id  => $opts{wig_id} // _new_uuid(),
        origin  => $opts{origin} // 'converted by Protocol::IR::Converter',
        signals => \@signals,
    );
    for my $key (qw(brand model kind notes)) {
        $wig{$key} = $opts{$key} if defined $opts{$key};
    }

    my $json = JSON::PP->new->utf8->canonical->space_after->indent(4);
    return $json->encode(\%wig) . "\n";
}

# Treat $input as file content when it looks like multi-line data,
# otherwise as a path to a file (falling back to treating it as a
# single-line JSON string).
sub _read_input {
    my ($input) = @_;
    return $input if $input =~ /[\r\n]/;

    if (-e $input) {
        open my $fh, '<', $input or die "Cannot open wig file '$input': $!\n";
        local $/;
        my $text = <$fh>;
        close $fh;
        return $text;
    }
    return $input;
}

# A random UUID v4: eight groups of hex in the 8-4-4-4-12 layout, with
# the version and variant bits set.
sub _new_uuid {
    my @bytes = map { sprintf('%02x', int(rand(256))) } 1 .. 16;
    my $hex = join '', @bytes;
    substr($hex, 12, 1, '4');
    substr($hex, 16, 1, sprintf('%x', 0x8 | (hex(substr($hex, 16, 1)) & 0x3)));
    return join '-',
        substr($hex, 0, 8),
        substr($hex, 8, 4),
        substr($hex, 12, 4),
        substr($hex, 16, 4),
        substr($hex, 20, 12);
}

1;

=head1 NAME

Protocol::IR::Format::Wig - HAIR wig JSON import and export

=head1 VERSION

version 1.2

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();
    my @codes = @{ $converter->import_format('CSV', 'remote.csv') };

    # Export Protocol::IR::Code objects to a HAIR hair-wig/3 JSON document
    my $wig = $converter->export_codes('wig', \@codes,
        name  => 'Tigersecu DVR',
        brand => 'Tigersecu',
        model => 'TS-1080',
        kind  => 'dvr',
        notes => 'Converted from the IRDB sample set',
    );

    # Import a wig (file path or JSON string) back into Protocol::IR::Code objects
    my $imported = $converter->import_format('wig', 'remote.wig.json');
    for my $code (@$imported) {
        print $code->alias . " (" . $code->protocol . ")\n";
    }

=head1 DESCRIPTION

wig is the portable IR code set format used by
the HAIR Home Assistant integration
(L<https://github.com/DAB-LABS/HAIR>): one JSON file, one remote, raw
Pronto hex as the payload.

C<Protocol::IR::Format::Wig> emits C<hair-wig/3>, the current recipe major: every
signal carries an explicit C<ditto_count> and C<bypass_protocol>, plus an optional
C<send_count> (how many times the whole signal transmits per press) when a code
carries a repeat count other than the default. On import,
signals are decoded fresh through the registered protocols (the file never
carries decoded fields), and each signal's transmit recipe is kept on the
resulting L<Protocol::IR::Code>. Formats C<hair-wig/1> through C<hair-wig/3> are
accepted on import.

=over 4

=item Example C<hair-wig/3> document (a NEC signal)

    {
      "format": "hair-wig/3",
      "name": "Samsung TV",
      "brand": "Samsung",
      "origin": "converted from IRDB",
      "signals": [
        {
          "alias": "",
          "bypass_protocol": false,
          "ditto_count": 0,
          "pronto": "0000 006D 0022 0000 0157 00AC 0015 0015 ..."
        }
      ],
      "wig_id": "d50a492e-a604-4c32-8bcb-aa542da06023"
    }

=back

=head1 METHODS

=head2 export

    my $json = $class->export($codes, $registry, %opts);

Serializes one L<Protocol::IR::Code> or an arrayref of them into a C<hair-wig/3> JSON
document. Options:

=over 4

=item * C<name> -- remote name (required by the format; default
C<'Untitled'>)

=item * C<brand>, C<model>, C<kind>, C<notes> -- optional remote metadata

=item * C<origin> -- provenance string; defaults to
C<'converted by Protocol::IR::Converter'>

=item * C<wig_id> -- identity UUID (default: a freshly minted v4 UUID)

=item * C<format> -- format major to emit (default: C<hair-wig/3>)

=back

=head2 decode

    my $codes = $class->decode($input, $registry);

Parses a wig file path or JSON string and returns an arrayref of L<Protocol::IR::Code>
objects. C<alias>, C<ditto_count>, C<bypass_protocol>, and C<send_count> when
present are preserved on each code. Dies if the JSON is invalid, the format
is unsupported, or a signal's Pronto payload cannot be decoded.

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
