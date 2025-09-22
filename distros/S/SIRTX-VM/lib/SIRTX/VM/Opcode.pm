# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for single SIRTX VM opcodes


package SIRTX::VM::Opcode;

use v5.16;
use strict;
use warnings;

use Carp;
use Scalar::Util qw(looks_like_number);

use parent 'Data::Identifier::Interface::Userdata';

our $VERSION = v0.06;

my %_die_raen = (code => 0, P => 7, codeX => 0, S => 2, T => 4+1, is_return => 1);

my %_raes_to_raen = (
    NONE    =>  0,
    NOENT   =>  2,
    NOSYS   =>  6,
    NOTSUP  =>  7,
    NOMEM   => 12,
    INVAL   => 13,
    FAULT   => 18,
    IO      => 19,
    NODATA  => 25,
    NOSPC   => 38,
    TYPEMM  => 39,
    RO      => 45,
    ILLSEQ  => 56,
    BADEXEC => 79,
    BADFH   => 83,
);

my @_simple_0 = ();
my @_simple_1 = (reg => 'P');
my @_simple_2 = (reg => 'P', reg => 'T');
my @_simple_3 = (reg => 'P', reg => 'S', reg => 'T');

my %_simple_opcodes = (
    noop            => [\@_simple_0 => {first => 0, second => 0, T => 0}],
    magic           => [\@_simple_0 => {first => 0, codeX => 0, S => 0, T => 4+3, extra => "VM\r\n\xc0\n"}],
    autodie         => [\@_simple_0 => {code => 0, P => 7, codeX => 0, S => 2, T => 4+0, is_autodie => 1}],
    data_start_marker   => [\@_simple_0 => {code => 0, P => 6, codeX => 0, S => 0, T => 0}],

    filesize        => [[int_half => 'extra[]'] => {code => 0, P => 1, codeX => 0, S => 0, T => 0+1}],
    section_pointer => [[int_half => 'extra[]'] => {code => 0, P => 1, codeX => 0, S => 1, T => 0+1}],
    minimum_handles => [[int_half => 'extra[]'] => {code => 0, P => 1, codeX => 0, S => 2, T => 0+1}],
    minimum_memory  => [[int_half => 'extra[]'] => {code => 0, P => 1, codeX => 0, S => 3, T => 0+1}],
    text_boundary   => [[int_half => 'extra[]'] => {code => 0, P => 1, codeX => 0, S => 4, T => 0+1}],
    load_boundary   => [[int_half => 'extra[]'] => {code => 0, P => 1, codeX => 0, S => 5, T => 0+1}],

    rjump           => [[int      => 'extra[]'] => {code => 0, P => 7, codeX => 0, S => 4, T => 0+1}],

    unref           => [\@_simple_1 => {code => 0, codeX => 1, S => 0, T => 0+0}],
    rewind          => [\@_simple_1 => {code => 0, codeX => 1, S => 1, T => 0+0}],
    die             => [\@_simple_1 => {code => 0, codeX => 1, S => 2, T => 4+0, is_return => 1}],
    exit            => [\@_simple_1 => {code => 0, codeX => 1, S => 3, T => 0+0, is_return => 1}],
    #jump            => {code => 0, codeX => 1, S => 4, T => 0+0},
    rcall           => [[int => 'extra[]'] => {code => 0, codeX => 1, S => 5, T => 0+1}],
    trcall          => [[int => 'extra[]'] => {code => 0, codeX => 1, S => 5, T => 4+1}],
    open_context    => [\@_simple_1 => {code => 1, codeX => 1, S => 7, T => 0+0}],

    replace         => [\@_simple_2 => {code => 0, codeX => 2, S => 0}],
    move            => [\@_simple_2 => {code => 0, codeX => 2, S => 1}],
    seek            => [\@_simple_2 => {code => 0, codeX => 2, S => 2}],
    tell            => [\@_simple_2 => {code => 0, codeX => 2, S => 3}],
    transfer        => [\@_simple_2 => {code => 0, codeX => 2, S => 4}],

    return          => [\@_simple_0 => {code => 0, P => 7, codeX => 0, S => 2, T => 0+0, is_return => 1},
                        \@_simple_1 => {code => 0,         codeX => 1, S => 2, T => 0+0, is_return => 1}],

    contents        => [\@_simple_2 => {code => 1, codeX => 2, S => 1}],
    die             => [['raen:' => 'extra[]'] => \%_die_raen],
    substr          => [[reg => 'P', reg => 'T', int => 'extra[]', int => 'extra[]'] => {code => 1, codeX => 2, S => (0+3)}],
    open_function   => [[reg => 'P', int_rel4 => 'extra[]'] => {code => 1, codeX => 1, S => 6, T => 0+1}],
    relations       => [[reg => 'P', reg => 'S', reg => 'T', undef => 'undef'] => {code => 4, codeX => 0},
                        [reg => 'P', undef => 'undef', reg => 'T', reg => 'S'] => {code => 4, codeX => 1}],
    metadata        => [\@_simple_3 => {code => 4, codeX => 2}],
    control         => [[reg => 'P', reg => 'T']                                => {code => 1, codeX => 2, S => 0+0},
                        [reg => 'P', 'sni:' => 'extra[]', reg => 'T']           => {code => 1, codeX => 2, S => 4+0},
                        [reg => 'P', 'sni:' => 'extra[]']                       => {code => 1, codeX => 1, S => 0, T => 0+1},
                        [reg => 'P', 'sni:' => 'extra[]', 'sni:' => 'extra[]']  => {code => 1, codeX => 1, S => 0, T => 0+2},
                        [reg => 'P', 'sni:' => 'extra[]', int => 'extra[]']     => {code => 1, codeX => 1, S => 0, T => 4+2},
                        [reg => 'P', reg => 'S', reg => 'T']                    => {code => 1, codeX => 3}],

    open            => [[reg => 'P', 'sni:' => 'extra[]']                                   => {code => 0, codeX => 1, S => 6, T => 0+1},
                        [reg => 'P', '"ns"' => 'undef', int => 'extra[]']                   => {code => 0, codeX => 1, S => 6, T => 4+1},
                        [reg => 'P', '"ns"' => 'undef', int => 'extra[]', int => 'extra[]'] => {code => 0, codeX => 1, S => 6, T => 4+2}],
    byte_transfer   => [[reg => 'P', reg => 'T', int => 'extra[]', autodie => 'false'] => {code => 1, codeX => 2, S => 4+2},
                        [reg => 'P', reg => 'T', int => 'extra[]', autodie => 'true']  => {code => 1, codeX => 2, S => 4+1}],
    call            => [[reg => 'P', reg => 'T', autodie => 'false'] => {code => 0, codeX => 2, S => 5},
                        [reg => 'P', reg => 'T', autodie => 'true']  => {code => 0, codeX => 2, S => 6}],
    jump            => [[int_rel4 => 'extra[]'] => {code => 0, P => 7, codeX => 0, S => 4, T => 0+1}],

    '.not_implemented'  => [\@_simple_0 => {%_die_raen, extra => [$_raes_to_raen{NOSYS}]}],
    '.bug'              => [\@_simple_0 => {%_die_raen, extra => [$_raes_to_raen{ILLSEQ}]}],
);
$_simple_opcodes{nop} = $_simple_opcodes{noop}; # alias

my %_synthetic = (
    open            => [
        [reg => 1, undef     => 'undef'] => ['unref', \1],
        [reg => 1, '"false"' => 'undef'] => ['open', \1, 'sni:189'],
        [reg => 1, '"true"'  => 'undef'] => ['open', \1, 'sni:190'],
    ],
    add             => [['"out"' => 'undef', reg => 1, reg => 2] => ['control', \1, 'sni:81', \2]],
    sub             => [['"out"' => 'undef', reg => 1, reg => 2] => ['control', \1, 'sni:82', \2]],
    div             => [['"out"' => 'undef', reg => 1, reg => 2] => ['control', \1, 'sni:83', \2]],
    mod             => [['"out"' => 'undef', reg => 1, reg => 2] => ['control', \1, 'sni:84', \2]],
    jump            => [[reg => 1] => ['seek', 'program_text', \1]],
    return          => [[undef => 'undef'] => ['return']],
    control         => [[any => 1, any => 2, any => 3, '"arg"' => 'undef'] => ['control', \1, \2, \3]],
    push            => [[reg => 1, reg => 2] => ['control', \1, 'sni:180', \2]],
    pop             => [
        ['"out"'   => 1, reg => 2] => ['control', \2, 'sni:181'],
        ['"undef"' => 1, reg => 2] => ['control', \2, 'sni:181'], # alias
    ],
    setvalue        => [[reg => 1, reg => 2, '"arg"' => 3] => ['control', \1, 'sni:102', \2, \3]],
    getvalue        => [['"out"' => 1, reg => 2, reg => 3] => ['control', \2, 'sni:101', \3]],
);


sub new {
    my ($pkg, %opts) = @_;
    my $self = bless({}, $pkg);

    foreach my $key (qw(first second code codeX ST P S T size is_return is_autodie)) {
        my $val = delete $opts{$key} // next;
        unless (looks_like_number($val)) {
            croak 'Invalid argument: '.$key.' is not a number';
        }
        $self->{$key} = int($val);
    }

    $self->{extra} = delete $opts{extra};

    # TODO: Implement more checks here.

    croak 'Stray options passed' if scalar keys %opts;

    return $self;
}


sub from_template {
    my ($pkg, %opts) = @_;
    my $parts   = delete $opts{parts};
    my $asm     = delete $opts{assembler};
    my $size    = delete $opts{size};
    my $line    = delete $opts{line};
    my $out     = delete $opts{out};
    my $autodie = delete $opts{autodie};
    my ($cmd, @args) = @{$parts};

    croak 'Stray options passed' if scalar keys %opts;

    if (defined(my $entry = $_synthetic{$cmd})) {
        outer:
        for (my $i = 0; $i < scalar(@{$entry}); $i += 2) {
            my @argmap = @{$entry->[$i]};
            my %updates;

            next unless (scalar(@args)*2) == scalar(@argmap);

            for (my $j = 0; ($j*2) < scalar(@argmap); $j++) {
                my $type = $argmap[$j*2 + 0];
                my $dst  = $argmap[$j*2 + 1];
                my $val  = $args[$j];

                if ($val =~ /^raes:(.+)$/) {
                    if (defined(my $raen = $_raes_to_raen{uc($1)})) {
                        $val = 'raen:'.$raen;
                    }
                }

                if ($type =~ /^".+"$/) {
                    next outer if $val ne $asm->_parse_string($type);
                } elsif ($type eq 'any') {
                    # no-op
                } else {
                    next outer if $asm->_get_value_type($val) ne $type;
                }

                if ($dst eq 'undef') {
                    # ignore this value
                } else {
                    $updates{$dst} = $val;
                }
            }

            ($cmd, @args) = map {ref ? $updates{${$_}} : $_} @{$entry->[$i+1]};
        }
    }

    if (defined(my $entry = $_simple_opcodes{$cmd})) {
        outer:
        for (my $i = 0; $i < scalar(@{$entry}); $i += 2) {
            my @argmap = @{$entry->[$i]};
            my %updates;
            my $last_data;
            my $reset_autodie;

            if (scalar(@argmap) >= 2 && $argmap[-2] eq 'autodie') {
                next unless ((scalar(@args) + 1)*2) == scalar(@argmap);
            } else {
                next unless ((scalar(@args) + 0)*2) == scalar(@argmap);
            }

            for (my $j = 0; ($j*2) < scalar(@argmap); $j++) {
                my $type = $argmap[$j*2 + 0];
                my $dst  = $argmap[$j*2 + 1];
                my $val  = $args[$j];
                my $data;
                my $mods = '';

                if ($type =~ s/_(.+)$//) {
                    $mods = $1;
                }

                if ($type ne 'autodie' && $val =~ /^raes:(.+)$/) {
                    if (defined(my $raen = $_raes_to_raen{uc($1)})) {
                        $val = 'raen:'.$raen;
                    }
                }

                if ($type =~ /^".+"$/) {
                    next outer if $val ne $asm->_parse_string($type);
                } elsif ($type eq 'autodie') {
                    next outer if !defined($autodie);
                } else {
                    next outer if $asm->_get_value_type($val) ne $type;
                }

                if ($type eq 'reg') {
                    $data = $asm->_force_mapped($val);
                } elsif ($type eq 'int') {
                    if ($mods eq 'rel4') {
                        my $org = $out->tell + 4;
                        $data = $asm->_parse_int($val, $org) - $org;
                        if ($data & 1) {
                            croak sprintf('Bad offset: line %s: offset %i', $line, $data);
                        }
                        $data /= 2;
                    } elsif ($mods eq 'half') {
                        $data = $asm->_parse_int($val, $last_data);
                        if ($data & 1) {
                            croak sprintf('Bad value: line %s: value %i', $line, $data);
                        }
                        $data /= 2;
                    } else {
                        $data = $asm->_parse_int($val, $last_data);
                    }
                } elsif ($type =~ /^[a-z]+:$/) {
                    (undef, $data) = $asm->_parse_id($val);
                } elsif ($type eq 'undef') {
                    $data = undef;
                } elsif ($type =~ /^".+"$/) {
                    $data = $val;
                } elsif ($type eq 'autodie') {
                    $reset_autodie = $asm->_parse_bool($dst);
                    next outer if (${$autodie} xor $reset_autodie);
                    next;
                } else {
                    croak 'BUG: Unsupported type: '.$type;
                    next outer;
                }

                if ($dst eq 'extra[]') {
                    push(@{$updates{extra} //= []}, $data);
                } elsif ($dst eq 'undef') {
                    # ignore this value
                } else {
                    $updates{$dst} = $data;
                }

                $last_data = $data;
            }

            ${$autodie} = undef if defined($autodie) && $reset_autodie;
            return $pkg->new(%{$entry->[$i+1]}, %updates, size => $size);
        }
    }

    if ($cmd eq 'compare' && scalar(@args) >= 3 && $args[0] eq 'out') {
        my @flags = @args[3..$#args];
        my $flags = 0;

        foreach my $flag (@flags) {
            if ($flag eq 'with') {
                # no-op
            } elsif ($flag eq 'icase') {
                $flags |= 0x0001;
            } elsif ($flag eq 'asciz') {
                $flags |= 0x0008;
            } elsif ($flag eq 'nulls_distinct') {
                $flags |= 0x0080;
            } elsif ($flag eq 'nulls_equal') {
                $flags |= 0x0040;
            } elsif ($flag eq 'nulls_first') {
                $flags |= 0x0010;
            } elsif ($flag eq 'nulls_last') {
                $flags |= 0x0020;
            } elsif ($flag eq 'prefix') {
                $flags |= 0x0002;
            } elsif ($flag eq 'suffix') {
                $flags |= 0x0004;
            } elsif ($flag eq 'seekback_end') {
                $flags |= 0x0400;
            } elsif ($flag eq 'seekback_start') {
                $flags |= 0x0200;
            } elsif ($flag eq 'subject') {
                $flags |= 0x0100;
            } else {
                croak sprintf('Unsupported compare flag: line %s: flag %s', $line, $flag);
            }
        }

        return $pkg->new(code => 3, P => $asm->_force_mapped($args[1]), codeX => 2, S => 0, T => $asm->_force_mapped($args[2]), extra => [$flags]);
    } elsif ($cmd eq 'open' && scalar(@args) == 2 && $asm->_get_value_type($args[0]) eq 'reg' && $asm->_get_value_type($args[1]) eq 'int') {
        my $num = $asm->_parse_int($args[1]);
        if (($num >= 0 && $num <= 7) && (!defined($size) || $size != 4)) {
            return $pkg->new(code => 0, P => $asm->_force_mapped($args[0]), codeX => 2, S => 7, T => $num);
        } else {
            return $pkg->new(code => 0, P => $asm->_force_mapped($args[0]), codeX => 1, S => 7, T => 0+1, extra => [$num]);
        }
    } elsif ($cmd eq 'open' && scalar(@args) == 2 && $asm->_get_value_type($args[0]) eq 'reg' && $asm->_get_value_type($args[1]) =~ /:$/) {
        my ($type, $num) = $asm->_parse_id($args[1]);
        my $sni = $asm->_type_to_sni($type);
        return $pkg->new(code => 0, P => $asm->_force_mapped($args[0]), codeX => 1, S => 6, T => 0+2, extra => [$sni, $num], size => $size);
    } elsif ($cmd eq 'jump' && scalar(@args) >= 3 && $asm->_get_value_type($args[0]) eq 'int' && ($args[1] eq 'if' || $args[1] eq 'unless')) {
        my $org = $out->tell + 4;
        my $extra = $asm->_parse_int($args[0], $org) - $org;
        my @cond = @args[2..$#args];
        my $P = 0;
        my $S = 0;
        my $T = 0;

        if ($extra & 1) {
            croak sprintf('Bad offset: line %s: offset %i', $line, $extra);
        }
        $extra /= 2;

        if ($args[1] eq 'if') {
            # no-op
        } elsif ($args[1] eq 'unless') {
            $P |= 0x1;
        }

        while (scalar(@cond) >= 3) {
            my $reg = shift(@cond);
            my $op  = shift(@cond);
            my $val = shift(@cond);

            croak sprintf('Unsupported jump syntax: line %s: register %s', $line, $reg) unless $reg eq 'out';

            if ($op eq 'is') {
                if ($val eq 'valid') {
                    $S |= 0x1;
                } elsif ($val eq 'true') {
                    $S |= 0x2;
                } elsif ($val eq 'notfine' || $val eq 'bad' || $val eq 'dog' || $val eq 'hotdog') {
                    $S |= 0x4;
                } else {
                    croak sprintf('Unsupported jump syntax: line %s: is-value %s', $line, $val);
                }
            } elsif (($op eq '<' && $val eq '0') || ($op eq '<=' && $val eq '-1')) {
                $T |= 0x1;
            } elsif ($op eq '==' && $val eq '0') {
                $T |= 0x2;
            } elsif (($op eq '>' && $val eq '0') || ($op eq '>=' && $val =~ /^\+?1$/)) {
                $T |= 0x4;
            } else {
                croak sprintf('Unsupported jump syntax: line %s: operator/value %s %s', $line, $op, $val);
            }

            shift(@cond) if scalar(@cond) && $cond[0] eq 'or';
        }

        if (scalar @cond) {
            croak sprintf('Unsupported jump syntax: line %s: condition %s', $opts{line}, join(' ', @cond));
        }

        return $pkg->new(code => 3, P => $P, codeX => 0, S => $S, T => $T, extra => [$extra]);
    } elsif ($cmd eq 'noop' && scalar(@args) == 1 && $asm->_get_value_type($args[0]) eq 'string') {
        my $string = $asm->_parse_string($args[0]);
        my $l = length($string);

        if ($l > 6 || ($l & 1)) {
            croak sprintf('Unsupported noop with data of invalid length: line %s: length %u', $line, $l);
        }

        return $pkg->new(first => 0, codeX => 0, S => 0, T => ($l/2), extra => $string);
    }

    croak 'Unsupported template';
}


sub write {
    my ($self, $out, @opts) = @_;
    my $required;
    my $size;

    croak 'Stray options passed' if scalar @opts;

    $required = $self->required_size;

    if (defined $self->{size}) {
        $size = $self->{size};
    } else {
        $size = $required;
    }

    if ($required > $size) {
        croak sprintf('Opcode does not fit in allocated size: required %u, have %u', $required, $size);
    } elsif ($required < $size) {
        my $diff = $size - $required;
        croak 'Opcode padding alignment error' if $diff & 1;
        print $out chr(0) x $diff;
    }

    print $out chr($self->{first}), chr($self->{second});

    if (ref $self->{extra}) {
        print $out pack('n*', @{$self->{extra}});
    } elsif (defined $self->{extra}) {
        $self->{extra} .= chr(0) if length($self->{extra}) & 1;
        print $out $self->{extra};
    }
}


sub required_alignment {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return 2;
}


sub new_alignment {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return 2;
}


sub required_size {
    my ($self, @opts) = @_;
    my $required;

    croak 'Stray options passed' if scalar @opts;

    $self->{first}  //= ($self->{code}  << 3) | $self->{P};
    $self->{ST}     //= ($self->{S}     << 3) | $self->{T} unless defined $self->{second};
    $self->{second} //= ($self->{codeX} << 6) | $self->{ST};

    $required = 2;
    if (ref $self->{extra}) {
        $required += 2 * scalar(@{$self->{extra}});
    } elsif (defined $self->{extra}) {
        my $l = length($self->{extra});
        $l++ if $l & 1;
        $required += $l;
    }

    return $required;
}


sub is_return {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{is_return};
}


sub is_autodie {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{is_autodie};
}

# ---- Private helpers ----

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::VM::Opcode - module for single SIRTX VM opcodes

=head1 VERSION

version v0.06

=head1 SYNOPSIS

    use SIRTX::VM::Opcode;

    my SIRTX::VM::Opcode $opcode = SIRTX::VM::Opcode->new(...);

    $opcode->write($out);

This package inherits from L<Data::Identifier::Interface::Userdata>.

=head1 METHODS

=head2 new

    my SIRTX::VM::Opcode $opcode = SIRTX::VM::Opcode->new(%opts);

Creates a new opcode object.

The following options are supported. Which values are required depend on the other values.

=over

=item C<first>

The first byte of the opcode.

=item C<second>

The second byte of the opcode.

=item C<code>

The C<code> value of the opcode.

=item C<codeX>

The C<codeX> value of the opcode.

=item C<ST>

The combined C<S> and C<T> values of the opcode.

=item C<P>

The C<P> value of the opcode.

=item C<S>

The C<S> value of the opcode.

=item C<T>

The C<T> value of the opcode.

=item C<extra>

The extra data to be added to the opcode. This might be an array of 16 bit values or a (even sized) bytestring.

=item C<size>

The space (in bytes) for the opcode to fill. This may be used in multi-pass translation.

=back

=head2 from_template

    my SIRTX::VM::Opcode $opcode = SIRTX::VM::Opcode->from_template(...);

(experimental)

Try to create an opcode from a template

=head2 write

    $opcode->write($fh);

Writes the opcode to C<$fh>. The handle must be correctly aligned.

See also:
L</required_alignment>.

=head2 required_alignment

    my $alignment = $opcode->required_alignment;

Returns the required alignment (in bytes) for the opcode.

=head2 new_alignment

    my $alignment = $opcode->new_alignment;

Returns the new alignment after the opcode has been written (considering L</required_alignment> was adhered).

=head2 required_size

    my $size = $opcode->required_size;

Returns the size of the opcode (in bytes).

=head2 is_return

    my $is_return = $opcode->is_return;

Returns a true value for opcodes that are some kind of return (e.g. return, die, or exit).

=head2 is_autodie

    my $is_autodie = $opcode->is_autodie;

Returns a true value for opcodes that are some kind of autodie (autodie, those that implement it).

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
