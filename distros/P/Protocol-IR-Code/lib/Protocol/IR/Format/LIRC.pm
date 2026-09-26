package Protocol::IR::Format::LIRC;
use strict;
use warnings;

our $VERSION = '1.2';

use Protocol::IR::Code;

# LIRC remote definition format (.lircd.conf) importer and exporter.
#
# The LIRC format describes IR remotes in two encoding modes:
#
#   Protocol-based (SPACE_ENC): A remote header defines timing parameters
#   (header, one, zero, pre_data, post_data), and the codes section maps
#   button names to hex values. The signal is reconstructed from the
#   protocol rules.
#
#   Raw codes (RAW_CODES): Direct pulse/space microsecond values for
#   each button.
#
# This module handles both import modes and can export protocol-based
# LIRC files for known protocols.

# --- LIRC timing templates for known protocols ---------------------------
#
# Each template defines the standard LIRC timing parameters for a protocol.
# The template is used for export; import reads whatever the file specifies.

my %LIRC_TEMPLATES = (
    NEC => {
        bits           => 32,
        flags          => 'SPACE_ENC|CONST_LENGTH',
        header         => [9000, 4500],
        one            => [560, 1690],
        zero           => [560, 560],
        ptrail         => 560,
        repeat         => [9000, 2250],
        pre_data_bits  => 0,
        pre_data       => 0,
        post_data_bits => 0,
        post_data      => 0,
        gap            => 108000,
        toggle_bit_mask => 0,
        min_repeat     => 1,
    },
    SAMSUNG => {
        bits           => 32,
        flags          => 'SPACE_ENC|CONST_LENGTH',
        header         => [4500, 4500],
        one            => [560, 1690],
        zero           => [560, 560],
        ptrail         => 560,
        repeat         => [4500, 1690],
        pre_data_bits  => 0,
        pre_data       => 0,
        post_data_bits => 0,
        post_data      => 0,
        gap            => 108000,
        toggle_bit_mask => 0,
        min_repeat     => 1,
    },
    JVC => {
        bits           => 16,
        flags          => 'SPACE_ENC|CONST_LENGTH',
        header         => [8440, 4220],
        one            => [526, 1276],
        zero           => [526, 526],
        ptrail         => 526,
        repeat         => [8440, 2110],
        pre_data_bits  => 0,
        pre_data       => 0,
        post_data_bits => 0,
        post_data      => 0,
        gap            => 108000,
        toggle_bit_mask => 0,
        min_repeat     => 1,
    },
);

# --- Import (decode) -----------------------------------------------------

sub decode {
    my ($class, $input, $registry) = @_;
    die "No LIRC input provided\n" unless defined $input;

    my $text = _read_input($input);
    die "LIRC input is empty\n" unless $text =~ /\S/;

    # Split into remote blocks
    my @remotes = _parse_remotes($text);
    die "No 'begin remote' blocks found in LIRC input\n" unless @remotes;

    my @codes;
    for my $remote (@remotes) {
        my $remote_name = $remote->{name} // 'unknown';
        my $flags = $remote->{flags} // '';
        my $is_raw = ($flags =~ /RAW_CODES/i);

        if ($is_raw) {
            push @codes, _decode_raw_codes($remote, $registry);
        } else {
            push @codes, _decode_protocol_codes($remote, $registry);
        }
    }

    return \@codes;
}

# Parse all 'begin remote' ... 'end remote' blocks from the text.
# Uses a line-by-line state machine to avoid regex backtracking issues.
sub _parse_remotes {
    my ($text) = @_;
    my @remotes;
    my %remote;
    my $state = 'idle';  # idle | remote | codes | raw_codes

    my @lines = split /\n/, $text;
    for my $line (@lines) {
        my $raw = $line;
        $line =~ s/^\s+|\s+$//g;

        # Skip blank lines and comments
        next if $line eq '' || $line =~ /^#/;

        if ($state eq 'idle') {
            if ($line =~ /^begin\s+remote$/i) {
                %remote = ();
                $state = 'remote';
            }
        }
        elsif ($state eq 'remote') {
            if ($line =~ /^end\s+remote$/i) {
                push @remotes, { %remote } if $remote{name};
                %remote = ();
                $state = 'idle';
            }
            elsif ($line =~ /^begin\s+codes$/i) {
                $state = 'codes';
                $remote{codes} = [];
            }
            elsif ($line =~ /^begin\s+raw_codes$/i) {
                $state = 'raw_codes';
                $remote{raw_codes} = [];
            }
            else {
                my ($key, $val) = split /\s+/, $line, 2;
                next unless defined $key && defined $val;
                $val =~ s/\s+$//;

                if ($key eq 'name') {
                    $remote{name} = $val;
                } elsif ($key eq 'bits') {
                    $remote{bits} = $val + 0;
                } elsif ($key eq 'flags') {
                    $remote{flags} = $val;
                } elsif ($key eq 'eps') {
                    $remote{eps} = $val + 0;
                } elsif ($key eq 'aeps') {
                    $remote{aeps} = $val + 0;
                } elsif ($key eq 'header') {
                    my @v = split /\s+/, $val;
                    $remote{header} = [@v[0,1]];
                } elsif ($key eq 'one') {
                    my @v = split /\s+/, $val;
                    $remote{one} = [@v[0,1]];
                } elsif ($key eq 'zero') {
                    my @v = split /\s+/, $val;
                    $remote{zero} = [@v[0,1]];
                } elsif ($key eq 'ptrail') {
                    $remote{ptrail} = $val + 0;
                } elsif ($key eq 'repeat') {
                    my @v = split /\s+/, $val;
                    $remote{repeat} = [@v[0,1]];
                } elsif ($key eq 'pre_data_bits') {
                    $remote{pre_data_bits} = $val + 0;
                } elsif ($key eq 'pre_data') {
                    $remote{pre_data} = hex($val) if $val =~ /^0x/i;
                    $remote{pre_data} = $val + 0 if $val =~ /^\d+$/;
                } elsif ($key eq 'post_data_bits') {
                    $remote{post_data_bits} = $val + 0;
                } elsif ($key eq 'post_data') {
                    $remote{post_data} = hex($val) if $val =~ /^0x/i;
                    $remote{post_data} = $val + 0 if $val =~ /^\d+$/;
                } elsif ($key eq 'gap') {
                    $remote{gap} = $val + 0;
                } elsif ($key eq 'toggle_bit_mask') {
                    $remote{toggle_bit_mask} = hex($val) if $val =~ /^0x/i;
                    $remote{toggle_bit_mask} = $val + 0 if $val =~ /^\d+$/;
                } elsif ($key eq 'min_repeat') {
                    $remote{min_repeat} = $val + 0;
                } elsif ($key eq 'frequency') {
                    $remote{frequency} = $val + 0;
                }
            }
        }
        elsif ($state eq 'codes') {
            if ($line =~ /^end\s+codes$/i) {
                $state = 'remote';
            }
            else {
                # Strip inline comments before matching
                (my $clean = $line) =~ s/\s*#.*$//;
                if ($clean =~ /^(\S+)\s+(0[xX][0-9A-Fa-f]+|\d+)\s*$/) {
                    push @{$remote{codes}}, [$1, $2];
                }
            }
        }
        elsif ($state eq 'raw_codes') {
            if ($line =~ /^end\s+raw_codes$/i) {
                $state = 'remote';
            }
            elsif ($line =~ /^name\s+(\S+)/) {
                push @{$remote{raw_codes}}, [$1, []];
            }
            elsif ($line =~ /^[\d\s]+$/ && @{$remote{raw_codes}}) {
                my @vals = split /\s+/, $line;
                push @{$remote{raw_codes}[-1][1]}, @vals;
            }
        }
    }

    return @remotes;
}

# Decode protocol-based codes from a remote block.
sub _decode_protocol_codes {
    my ($remote, $registry) = @_;
    my @codes;

    my $remote_name = $remote->{name} // 'unknown';
    my $bits = $remote->{bits} // 0;
    my $pre_data_bits = $remote->{pre_data_bits} // 0;
    my $pre_data = $remote->{pre_data} // 0;
    my $post_data_bits = $remote->{post_data_bits} // 0;
    my $post_data = $remote->{post_data} // 0;

    # LIRC SPACE_ENC remotes store each transmitted word (pre_data, post_data,
    # and the code value) in the wire's accumulated byte order, whose per-byte
    # LSB-first reading the decode_byte_order reduction below unwraps. A remote
    # flagged REVERSE stores each word bit-mirrored within its own declared
    # width instead -- the same signal, written backwards. Restoring the wire
    # order first makes both encodings converge on one code: Vizio VX37L
    # (REVERSE, pre_data 0xFB04 + Power 0xF708) and LCD_TV (no REVERSE,
    # pre_data 0x20DF + Power 0x10EF) are the same NEC signal, the second
    # being the 16-bit mirror of the first.
    my $had_pre_post = ($pre_data_bits > 0 || $post_data_bits > 0);
    my $reversed = $had_pre_post && ($remote->{flags} // '') =~ /(?:^|\|)REVERSE(?:\||$)/i;

    # Try to infer protocol from timing parameters
    my $proto = _infer_protocol($remote);

    for my $pair (@{ $remote->{codes} || [] }) {
        my ($button_name, $hex_val) = @$pair;
        my $value = hex($hex_val);

        # Mask to the declared bit width — LIRC files sometimes represent
        # 16-bit values as 48-bit hex (zero-padded), but only the low
        # bits matter.
        if ($bits > 0 && $bits < 64) {
            my $mask = (1 << $bits) - 1;
            $value &= $mask;
        }

        # Construct the full data word from pre_data, value, post_data. A
        # REVERSE remote stores each word bit-mirrored, so mirror it back to
        # the wire's accumulated order before combining; the decode_byte_order
        # reduction below then unwraps the per-byte LSB-first reading for both
        # encodings alike.
        my $full_data = $reversed ? _mirror_word($value, $bits) : $value;
        if ($pre_data_bits > 0) {
            my $pre = $reversed ? _mirror_word($pre_data, $pre_data_bits) : $pre_data;
            $full_data = ($pre << $bits) | $full_data;
        }
        if ($post_data_bits > 0) {
            my $post = $reversed ? _mirror_word($post_data, $post_data_bits) : $post_data;
            $full_data = ($full_data << $post_data_bits) | $post;
        }

        my $code;
        my $proto_class = $proto ? $registry->get_protocol($proto) : undef;
        if ($proto_class) {
            # A code composed from pre_data/post_data carries the wire's
            # accumulated byte order (e.g. NEC 0xC10000FF from pre_data 0xC100
            # and a 16-bit value 0x00FF) and must be reduced to the display
            # form via decode_byte_order (as the JS port and the rm-sg20 case
            # do) to land on the real address/subaddress/command instead of
            # treating the accumulated bytes as the fields. A plain
            # codes-section value is already in its final form, so it keeps
            # the raw decode_raw path.
            if ($had_pre_post && $proto_class->can('decode_byte_order')) {
                $code = $proto_class->decode_byte_order($full_data, 0);
            } elsif ($proto_class->can('decode_raw')) {
                $code = $proto_class->decode_raw($full_data);
            }
        }
        unless ($code) {
            $code = Protocol::IR::Code->new(
                protocol => $proto // 'UNKNOWN',
                bits     => $bits + $pre_data_bits + $post_data_bits,
                data     => $full_data,
            );
        }

        $code->alias($button_name);
        push @codes, $code;
    }

    return @codes;
}

# Decode raw codes from a remote block.
sub _decode_raw_codes {
    my ($remote, $registry) = @_;
    my @codes;

    for my $pair (@{ $remote->{raw_codes} || [] }) {
        my ($button_name, $values) = @$pair;

        # Convert alternating pulse/space values to pairs
        my @flat = @$values;
        my @pairs;
        while (@flat) {
            my $mark  = shift @flat;
            my $space = shift @flat // 0;
            push @pairs, [$mark, $space];
        }

        # Try timing-based decode through registered protocols
        my $code;
        for my $proto_class ($registry->get_protocols()) {
            next unless $proto_class->can('decode_timing');
            my $decoded = $proto_class->decode_timing(\@pairs);
            if (defined $decoded) {
                $code = $decoded;
                last;
            }
        }

        $code ||= Protocol::IR::Code->new(protocol => 'UNKNOWN');

        # Store raw timings for lossless re-export
        my @timings;
        for my $i (0 .. $#$values) {
            push @timings, ($i % 2 == 0 ? 1 : -1) * $values->[$i];
        }
        $code->timings(\@timings);
        $code->alias($button_name);

        push @codes, $code;
    }

    return @codes;
}

# Try to infer the protocol name from the remote's timing parameters.
sub _infer_protocol {
    my ($remote) = @_;
    my $header = $remote->{header} || [];
    my $one    = $remote->{one}    || [];
    my $zero   = $remote->{zero}   || [];

    # NEC: ~9000/4500 header, ~560/1690 one-bit
    return 'NEC' if @$header == 2 && $header->[0] >= 8500 && $header->[0] <= 10000
        && $header->[1] >= 3500 && $header->[1] <= 5500
        && @$one == 2 && $one->[0] >= 400 && $one->[0] <= 700
        && $one->[1] >= 1560 && $one->[1] <= 2000
        && @$zero == 2 && $zero->[0] >= 400 && $zero->[0] <= 700
        && $zero->[1] >= 300 && $zero->[1] <= 800;

    return 'SAMSUNG' if @$header == 2 && $header->[0] >= 3500 && $header->[0] <= 5500
        && $header->[1] >= 3500 && $header->[1] <= 5500
        && @$one == 2 && $one->[0] >= 400 && $one->[0] <= 700
        && $one->[1] >= 1400 && $one->[1] <= 2000
        && @$zero == 2 && $zero->[0] >= 400 && $zero->[0] <= 700
        && $zero->[1] >= 300 && $zero->[1] <= 800;

    # JVC: ~8440/4220 header, ~526/1276 one-bit (wider tolerance for variants)
    return 'JVC' if @$header == 2 && $header->[0] >= 7000 && $header->[0] <= 10000
        && $header->[1] >= 3000 && $header->[1] <= 5500
        && @$one == 2 && $one->[0] >= 400 && $one->[0] <= 700
        && $one->[1] >= 1000 && $one->[1] <= 1560
        && @$zero == 2 && $zero->[0] >= 400 && $zero->[0] <= 700
        && $zero->[1] >= 300 && $zero->[1] <= 800;

    return undef;
}

# Format a value as hex padded to the given bit width.
sub _data_hex_for_bits {
    my ($val, $bits) = @_;
    my $bytes = int(($bits + 7) / 8);
    my $hex = uc sprintf("%X", $val);
    my $pad = $bytes * 2;
    $hex = ('0' x ($pad - length($hex))) . $hex if length($hex) < $pad;
    return '0x' . $hex;
}

# --- Export --------------------------------------------------------------

sub export {
    my ($class, $codes, $registry, %opts) = @_;
    $codes = [$codes] unless ref $codes eq 'ARRAY';
    die "No codes to export\n" unless @$codes;

    my $remote_name = $opts{name} // 'exported';
    my $output = '';

    # Group codes by protocol for multi-button remotes
    my %by_proto;
    for my $code (@$codes) {
        my $proto = $code->protocol // 'UNKNOWN';
        push @{ $by_proto{$proto} }, $code;
    }

    for my $proto (sort keys %by_proto) {
        my $proto_codes = $by_proto{$proto};
        my $template = $LIRC_TEMPLATES{uc $proto};

        if ($template) {
            $output .= _export_protocol_remote($remote_name, $template, $proto_codes, $registry);
        } else {
            # Fall back to raw codes for unknown protocols
            $output .= _export_raw_remote($remote_name, $proto_codes, $registry);
        }
    }

    return $output;
}

sub _export_protocol_remote {
    my ($remote_name, $template, $codes, $registry) = @_;
    my $out = '';

    $out .= "begin remote\n\n";
    $out .= "  name  $remote_name\n";
    $out .= sprintf("  bits            %d\n", $template->{bits});
    $out .= "  flags           $template->{flags}\n";
    $out .= "  eps             30\n";
    $out .= "  aeps            100\n\n";
    $out .= sprintf("  header          %d  %d\n", @{ $template->{header} });
    $out .= sprintf("  one             %d  %d\n", @{ $template->{one} });
    $out .= sprintf("  zero            %d  %d\n", @{ $template->{zero} });
    $out .= sprintf("  ptrail          %d\n", $template->{ptrail});
    $out .= sprintf("  repeat          %d  %d\n", @{ $template->{repeat} });

    if ($template->{pre_data_bits} && $template->{pre_data_bits} > 0) {
        $out .= sprintf("  pre_data_bits   %d\n", $template->{pre_data_bits});
        $out .= sprintf("  pre_data        0x%X\n", $template->{pre_data});
    }
    if ($template->{post_data_bits} && $template->{post_data_bits} > 0) {
        $out .= sprintf("  post_data_bits  %d\n", $template->{post_data_bits});
        $out .= sprintf("  post_data       0x%X\n", $template->{post_data});
    }

    $out .= sprintf("  gap             %d\n", $template->{gap});
    $out .= sprintf("  toggle_bit_mask 0x%X\n", $template->{toggle_bit_mask});
    $out .= sprintf("  min_repeat      %d\n", $template->{min_repeat} // 1);

    $out .= "\n      begin codes\n";
    for my $code (@$codes) {
        my $name = ($code->alias // '') =~ /\S/ ? $code->alias : 'UNKNOWN';
        my $val = _lirc_code_value($code, $template, $registry);
        $out .= sprintf("          %-20s %s\n", $name, $val);
    }
    $out .= "      end codes\n\n";
    $out .= "end remote\n\n";

    return $out;
}

sub _export_raw_remote {
    my ($remote_name, $codes, $registry) = @_;
    my $out = '';

    $out .= "begin remote\n\n";
    $out .= "  name  $remote_name\n";
    $out .= "  flags RAW_CODES|CONST_LENGTH\n";
    $out .= "  eps            25\n";
    $out .= "  aeps          100\n\n";
    $out .= "  ptrail          0\n";
    $out .= "  repeat     0     0\n";
    $out .= "  gap    100000\n\n";
    $out .= "      begin raw_codes\n\n";

    for my $code (@$codes) {
        my $name = ($code->alias // '') =~ /\S/ ? $code->alias : 'UNKNOWN';
        my $timings = $code->timings;

        if ($timings && @$timings) {
            # Use the stored timings
            $out .= "          name $name\n";
            my @vals = map { int(abs($_) + 0.5) } @$timings;
            # Format in groups of 8
            while (@vals) {
                my @chunk = splice(@vals, 0, 8);
                $out .= "              " . join("  ", @chunk) . "\n";
            }
            $out .= "\n";
        } else {
            # Try to generate timings via Pronto round-trip
            my $pronto;
            eval { $pronto = $registry->export_code($code, 'Pronto'); 1 };
            next unless $pronto && $pronto !~ /^0000 0000/;

            my $pronto_code;
            eval { $pronto_code = $registry->import_format('Pronto', $pronto); 1 };
            next unless $pronto_code && $pronto_code->timings;

            $timings = $pronto_code->timings;
            $out .= "          name $name\n";
            my @vals = map { int(abs($_) + 0.5) } @$timings;
            while (@vals) {
                my @chunk = splice(@vals, 0, 8);
                $out .= "              " . join("  ", @chunk) . "\n";
            }
            $out .= "\n";
        }
    }

    $out .= "      end raw_codes\n\n";
    $out .= "end remote\n\n";

    return $out;
}

# Extract the button value for a protocol-based LIRC code.
#
# A code's stored data may be the accumulated wire form (e.g. SAMSUNG
# 0x070702FD) rather than the display form LIRC carries (0xE0E040BF). Mirror
# the JS exporter: probe decode_raw with the stored data and, when the decoded
# value comes back different, the stored data is accumulated and must be
# per-byte bit-reversed to the display form.
sub _lirc_code_value {
    my ($code, $template, $registry) = @_;
    my $data = $code->data;
    return '0x00' unless defined $data;

    my $bits = $template->{bits} // 32;
    my $mask = (1 << $bits) - 1;

    my $raw = $data;
    if ($registry && $code->protocol && $registry->can('get_protocol')) {
        my $proto_class = $registry->get_protocol($code->protocol);
        if ($proto_class && $proto_class->can('decode_raw')) {
            my $probe = eval { $proto_class->decode_raw($data) };
            if ($probe && defined $probe->data && $probe->data != $data) {
                $raw = _reverse_bytes($data, $bits);
            }
        }
    }

    my $val = ref $raw && $raw->can('band') ? $raw->band($mask)->numify : $raw & $mask;

    return sprintf("0x%X", $val);
}

# Reverse the bits within each byte of a $bits-bit value, keeping the byte
# order (the inverse of the accumulated-to-display mapping).
sub _reverse_bytes {
    my ($val, $bits) = @_;
    my $out = 0;
    for my $i (0 .. $bits - 1) {
        my $byte = int($i / 8);
        my $bit  = $i % 8;
        my $src  = 8 * $byte + (7 - $bit);
        $out |= (($val >> $src) & 1) << $i;
    }
    return $out;
}

# Mirror the $width significant bits of $word (bit $i <-> bit $width-1-$i),
# the mapping LIRC's REVERSE flag applies to each transmitted word.
sub _mirror_word {
    my ($word, $width) = @_;
    return $word if $width <= 0;
    my $out = 0;
    for my $i (0 .. $width - 1) {
        $out |= (($word >> $i) & 1) << ($width - 1 - $i);
    }
    return $out;
}

sub _read_input {
    my ($input) = @_;
    # Only try file I/O if the input looks like a file path (no newlines)
    if (!ref $input && $input !~ /\n/ && -e $input && !-d $input) {
        open my $fh, '<:raw', $input or die "Cannot open '$input': $!\n";
        local $/;
        my $text = <$fh>;
        close $fh;
        return $text;
    }
    return $input;
}

1;

=encoding utf8

=head1 NAME

Protocol::IR::Format::LIRC - LIRC remote definition format (.lircd.conf) import and export

=head1 VERSION

version 1.2

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # Import a LIRC remote definition
    my $codes = $converter->import_format('LIRC', $lirc_text);
    for my $code (@$codes) {
        print $code->alias, ": ", $code->protocol, "\n";
    }

    # Export a code as a LIRC remote definition
    my $lirc = $converter->export_code($code, 'LIRC',
        name => 'My Remote');

=head1 DESCRIPTION

C<Protocol::IR::Format::LIRC> imports and exports LIRC remote definition
files (C<.lircd.conf>).  The LIRC format is the de facto standard for
sharing IR remote control definitions across the LIRC ecosystem
(L<https://www.lirc.org/>).

=over 4

=item Example C<.lircd.conf> (NEC transmission with timing template)

    begin remote

      name  Samsung_TV
      bits           16
      flags SPACE_ENC|CONST_LENGTH
      eps            30
      aeps           100

      header         4500  4500
      one            550   1650
      zero           550   550
      gap            107000

          begin codes
              KEY_POWER 0xE0E040BF
          end codes

    end remote

=back

=head2 Import modes

C<decode> handles two LIRC encoding modes:

=over 4

=item * Protocol-based (C<SPACE_ENC>): The remote header defines timing
parameters (C<header>, C<one>, C<zero>, C<pre_data>, C<post_data>), and
the C<codes> section maps button names to hex values.  The module infers
the protocol from the timing parameters and decodes through the
registered protocol handler.

=item * Raw codes (C<RAW_CODES>): The C<raw_codes> section contains
explicit pulse/space microsecond values for each button.  These are
decoded through the registered protocol timing decoders, with raw
timings preserved for lossless re-export.

=back

=head2 Export

C<export> produces a LIRC remote definition with timing parameters
matched to the code's protocol.  Known protocols (NEC, Samsung, JVC)
get protocol-based output with correct timing templates.  Unknown
protocols fall back to raw codes derived from the stored timings or
a Pronto hex round-trip.

Options:

=over 4

=item * C<name> -- remote name (default: C<'exported'>)

=back

=head1 METHODS

=head2 decode

    my $codes = $class->decode($input, $registry);

Parses a LIRC remote definition and returns an arrayref of
L<Protocol::IR::Code> objects.

=head2 export

    my $lirc = $class->export($codes, $registry, %opts);

Serializes one or more L<Protocol::IR::Code> objects into a LIRC remote
definition string.

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
