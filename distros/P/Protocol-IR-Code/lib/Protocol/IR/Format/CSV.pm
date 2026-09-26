package Protocol::IR::Format::CSV;
use strict;
use warnings;

our $VERSION = '1.2';

# Parse a single CSV line with full RFC-style quoting: a field wrapped in
# double quotes may hold commas, quotes, and newlines, with a literal quote
# written as a doubled "" exactly as the reference TypeScript parser accepts
# (the web-ir-remote-tools port emits such files). Unquoted fields are
# trimmed of surrounding whitespace, again matching the TS port so the two
# agree on every file. A hand-rolled parser stays because IRDB files are not
# strict RFC 4180 - header fields can be tab-joined, rows arrive headerless,
# and quoted values may carry leading/trailing whitespace the strict library
# parsers reject - and Text::CSV_XS would add a compiled dependency for a
# format that mostly does not need it.
sub _parse_csv_line {
    my ($line) = @_;
    return () unless defined $line;
    $line =~ s/[\r\n]+$//;
    my @fields;
    my ($field, $in_quotes, $quoted) = ('', 0, 0);
    for (my $i = 0; $i < length $line; $i++) {
        my $c = substr($line, $i, 1);
        if ($in_quotes) {
            if ($c eq '"') {
                if (substr($line, $i + 1, 1) eq '"') {
                    $field .= '"';
                    $i++;
                } else {
                    $in_quotes = 0;
                }
            } else {
                $field .= $c;
            }
        } elsif ($c eq '"' && $field eq '') {
            $in_quotes = 1;
            $quoted = 1;
        } elsif ($c eq ',') {
            push @fields, _field_value($field, $quoted);
            $field = '';
            $quoted = 0;
        } else {
            $field .= $c;
        }
    }
    push @fields, _field_value($field, $quoted);
    return @fields;
}

# Quoted fields keep their bytes verbatim; unquoted fields are trimmed to
# match the TypeScript parser's String.trim().
sub _field_value {
    my ($value, $quoted) = @_;
    return $value if $quoted;
    $value =~ s/^\s+|\s+$//g;
    return $value;
}

# Normalize protocol aliases commonly found in IRDB.
#
# IRDB labels its NEC-family rows NEC, NEC1, nec, nec1 (all the standard
# NEC1 framing), NEC2 (whole-frame repeat), and NECx1/NECx2 (the extended,
# half-header 16-bit-address variants). Anything else is returned
# unchanged, so unknown protocols still reach the registry and are skipped
# as unregistered rather than being silently remapped.
sub _normalize_protocol {
    my ($proto) = @_;
    return '' unless defined $proto;
    $proto =~ s/^\s+|\s+$//g;
    $proto = uc $proto;

    return 'NEC'   if $proto =~ /^NEC1?$/;
    return 'NEC2'  if $proto eq 'NEC2';
    return 'NECX1' if $proto eq 'NECX1';
    return 'NECX2' if $proto eq 'NECX2';
    return 'JVC'   if $proto eq 'JVC';
    return $proto;
}

sub decode {
    my ($class, $input, $registry) = @_;
    die "No CSV input provided\n" unless defined $input;

    my @lines;
    if ($input !~ /[\r\n]/ && -e $input) {
        open my $fh, '<', $input or die "Cannot open CSV file '$input': $!\n";
        @lines = <$fh>;
        close $fh;
    } else {
        @lines = split(/\r?\n/, $input);
    }

    # Filter empty lines
    @lines = grep { /\S/ } @lines;
    die "CSV input is empty\n" unless @lines;

    # Parse header row
    my @headers = map { lc($_) } _parse_csv_line(shift @lines);
    $headers[0] =~ s/^\x{FEFF}//; # Strip UTF-8 BOM if present

    # Map column headers
    my %col_map;
    for my $i (0 .. $#headers) {
        my $h = $headers[$i];
        $h =~ s/^\s+|\s+$//g;

        if ($h =~ /^(functionname|function_name|key|alias|label|name)$/) {
            $col_map{alias} = $i;
        } elsif ($h =~ /^(protocol|proto)$/) {
            $col_map{protocol} = $i;
        } elsif ($h =~ /^(device|address|addr|dev)$/) {
            $col_map{device} = $i;
        } elsif ($h =~ /^(subdevice|subaddress|subaddr|subdev)$/) {
            $col_map{subdevice} = $i;
        } elsif ($h =~ /^(function|command|cmd|code)$/ && !defined $col_map{alias}) {
            $col_map{command} = $i;
        } elsif ($h =~ /^(function|command|cmd|code)$/) {
            $col_map{command} //= $i;
        } elsif ($h =~ /^(data|hex|raw)$/) {
            $col_map{data} = $i;
        }
    }

    my @decoded_codes;

    for my $line (@lines) {
        my @fields = _parse_csv_line($line);
        next unless @fields;

        my $proto_raw = defined $col_map{protocol}  ? $fields[$col_map{protocol}]  : '';
        my $proto     = _normalize_protocol($proto_raw);
        next unless $proto;

        my $alias     = defined $col_map{alias}     ? $fields[$col_map{alias}]     : 'UNKNOWN';
        my $device    = defined $col_map{device}    ? $fields[$col_map{device}]    : undef;
        my $subdevice = defined $col_map{subdevice} ? $fields[$col_map{subdevice}] : undef;
        my $command   = defined $col_map{command}   ? $fields[$col_map{command}]   : undef;
        my $data      = defined $col_map{data}      ? $fields[$col_map{data}]      : undef;

        my $ir_code;
        eval {
            if (defined $data && $data ne '') {
                $ir_code = $registry->import_code($proto, $data);
            } elsif (defined $device && defined $command) {
                $ir_code = $registry->import_code($proto, {
                    device    => $device,
                    subdevice => $subdevice // -1,
                    command   => $command,
                });
            }
        };
        # Rows with an unregistered protocol or an unparseable value are
        # skipped (as documented in the POD), not fatal: real IRDB files
        # routinely mix protocols this distribution does not handle.
        next if $@;

        if ($ir_code) {
            $ir_code->alias($alias);
            push @decoded_codes, $ir_code;
        }
    }

    return \@decoded_codes;
}

# Serialize decoded codes as canonical IRDB rows. Only addressable,
# registered-protocol codes can be represented: a code whose protocol is
# unknown has nothing to key a row on, so it is skipped (the same set the
# importer drops). Each row carries the decoded fields the importer turns
# back into a code, so CSV -> Code -> CSV is lossless for addressable
# codes; the aliased device/subdevice/function columns cannot express every
# raw word of every protocol (e.g. Samsung20), which is inherent to IRDB's
# keyed schema, not to this export.
sub export {
    my ($class, $codes, $registry, %opts) = @_;
    $codes = [$codes] unless ref $codes eq 'ARRAY';

    my @lines = ('functionname,protocol,device,subdevice,function');
    for my $code (@$codes) {
        my $protocol = $code->protocol // 'UNKNOWN';
        next if $protocol eq 'UNKNOWN';

        my $alias = (defined $code->alias && $code->alias =~ /\S/) ? $code->alias : 'UNKNOWN';
        if ($alias =~ /[",\n\r]/) {
            $alias =~ s/"/""/g;
            $alias = qq{"$alias"};
        }

        push @lines, join(',',
            $alias,
            $protocol,
            $code->address    // 0,
            $code->subaddress // -1,
            $code->command    // 0,
        );
    }
    return join("\n", @lines) . "\n";
}

1;

=head1 NAME

Protocol::IR::Format::CSV - IRDB CSV importer and exporter

=head1 VERSION

version 1.2

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # Parse an IRDB-style CSV string
    my $csv = "functionname,protocol,device,subdevice,function\n"
            . "KEY_POWER,NEC1,4,0,8\n";
    my $codes = $converter->import_format('CSV', $csv);

    for my $code (@$codes) {
        print $code->alias . "\n";
        print $converter->export_code($code, 'Pronto') . "\n";
    }

    # Or load from a file path
    my $codes = $converter->import_format('CSV', 'remote.csv');

=head1 DESCRIPTION

C<Protocol::IR::Format::CSV> imports and exports IRDB-style CSV button listings as
L<Protocol::IR::Code> objects. It accepts either a CSV string or the path to a CSV file.

=over 4

=item Example IRDB CSV (Samsung TV, NECx2 variant)

    functionname,protocol,device,subdevice,function
    POWER,NECx2,7,7,2
    1,NECx2,7,7,4
    2,NECx2,7,7,5

=back

This is the delimited Remotec ZXT-120 style CSV used by the IRDB project
(L<https://github.com/probonopd/irdb>).

Column headers are detected automatically. Recognized header aliases:

=over 4

=item * C<functionname>, C<function_name>, C<key>, C<alias>, C<label>,
C<name> -- button name (stored on the C<alias> accessor)

=item * C<protocol>, C<proto> -- protocol name

=item * C<device>, C<address>, C<addr>, C<dev> -- device (address)

=item * C<subdevice>, C<subaddress>, C<subaddr>, C<subdev> -- subdevice

=item * C<function>, C<command>, C<cmd>, C<code> -- command

=item * C<data>, C<hex>, C<raw> -- a raw value for the protocol

=back

A row is decoded either from a raw C<data> value or, when no C<data> column
is present, from the C<device>/C<subdevice>/C<command> columns. Protocol
aliases such as C<NEC1> and C<nec> are normalized to C<NEC>; the IRDB
NEC-family variants C<NEC2>, C<NECx1>, and C<NECx2> are kept as-is, so the
variant identity survives the conversion. Each decoded code gets its
C<alias> set from the button name column.

=head1 METHODS

=head2 decode

    my $codes = $class->decode($input, $registry);

Parses a CSV string or file and returns an arrayref of L<Protocol::IR::Code> objects.
Rows with an unregistered or unrecognized protocol are skipped.

=head2 export

    my $csv = $class->export($codes, $registry);

Serializes a L<Protocol::IR::Code> or an arrayref of codes as canonical IRDB
CSV: a C<functionname,protocol,device,subdevice,function> header followed by
one row per code. A code with no addressable decoded fields (an C<UNKNOWN>
protocol) is skipped. Button names are quoted - with embedded quotes doubled -
when they contain a comma, double quote, or newline. Round-tripping through
C<decode> reproduces the decoded fields.

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
