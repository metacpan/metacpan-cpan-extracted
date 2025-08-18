# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for assembling SIRTX VM code


package SIRTX::VM::Assembler;

use v5.16;
use strict;
use warnings;

use Carp;
use Encode ();
use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);

use String::Super;

use SIRTX::VM::RegisterFile;
use SIRTX::VM::Opcode;

use parent 'Data::Identifier::Interface::Userdata';

our $VERSION = v0.02;

my %_escapes = (
    '\\' => '\\',
    '0' => chr(0x00),
    'n' => chr(0x0A),
    'r' => chr(0x0D),
    't' => chr(0x09),
    'e' => chr(0x1B),
);
my %_type_to_sni = (
    sni     =>  10,
    sid     => 115,
    raen    => 116,
    chat0w  => 118,
    asciicp => 122,
);
my %_sni_to_type = map {$_type_to_sni{$_} => $_} keys %_type_to_sni;

my %_header_ids = (
    init    => 1,
    header  => 2,
    rodata  => 3,
    text    => 4,
    trailer => 5,
);

my @_section_order = qw(header init text rodata trailer);
my @_section_text  = qw(header init text);
my @_section_load  = (@_section_text, qw(rodata));

my %_synthetic = (
    mul             => [['"out"' => 'undef', reg => 1, '"arg"' => 'undef'] => ['user*' => 2] => [
                            ['open', \2, 0],
                            ['control', \2, 'sni:81', \1],
                        ],
                        ['"out"' => 'undef', reg => 1, reg => 2] => ['arg' => 3] => [
                            ['replace', \3, \2],
                            ['mul', 'out', \1, \3],
                        ],
                        ['"out"' => 'undef', reg => 1, int => 2] => ['arg' => 3] => [
                            ['open', \3, \2],
                            ['mul', 'out', \1, \3],
                        ]],
    contents        => [[reg => 1, int => 2] => ['user*' => 3] => [
                            ['open_function*', \3, \2],
                            ['contents*', \1, \3],
                        ],
                        [reg => 1, id => 2] => ['user*' => 3] => [
                            ['open*', \3, \2],
                            ['contents*', \1, \3],
                        ]],
    call            => [[reg => 1, int => 2] => ['user*' => 3] => [
                            ['open_function*', \3, \2],
                            ['call*', \1, \3]
                        ],
                        [reg => 1, id => 2] => ['user*' => 3] => [
                            ['open*', \3, \2],
                            ['call*', \1, \3],
                        ],
                        [[qw(reg int id)] => 1] => ['user*' => 2] => [
                            ['open_context*', \2],
                            ['call*', \2, \1],
                        ]],
    transfer        => [[reg => 1, string => 2] => ['user*' => 3] => [
                            ['open', \3, \2],
                            ['transfer', \1, \3],
                        ]],
    control         => [[reg => 1, [qw(reg sni:)] => 2, string => 3] => ['user*' => 4] => [
                            ['open', \4, \3],
                            ['control', \1, \2, \4],
                        ]],
    '.autosectionstart' => [['"header"' => 1] => [] => [
                            ['.section', \1, '"VM\\r\\n\\xc0\\n"'],
                            ['filesize', 'size$out$'],
                            ['text_boundary', 'end$boundary$text'],
                            ['load_boundary', 'end$boundary$load'],
                            (map {['section_pointer', 'section$'.$_.'//section$header']} @_section_order),
                        ],
                        ['"rodata"' => 1] => [] => [
                            ['.section', \1],
                            ['.rodata'], # INTERNAL COMMAND, NOT FOR DOCS!
                            ['.align', 2],
                        ],
                        [any => 1] => [] => [
                            ['.section', \1]
                        ]],
    '.autosection'  => [[any => 1] => [] => [
                            ['.autosectionstart', \1],
                            ['.endsection']
                        ]],
);

my %_section_order_bad;

{
    my @got;
    foreach my $section (reverse @_section_order) {
        $_section_order_bad{$section} = {map {$_ => 1} @got};
        push(@got, $section);
    }
}


sub new {
    my ($pkg, %opts) = @_;
    my $self = bless({
            alive               => 1,
            alignment           => 1024,
            aliases             => {},
            current             => {},
            rf                  => SIRTX::VM::RegisterFile->new,
            regmap_last_used_c  => 0,
            regmap_last_used    => {},
            regmap_mapped       => {},
            sections            => {},
            pushback            => [],
            settings    => {
                synthetic_auto_unref    => 1,
                regmap_auto             => undef,
            },
            rodata              => String::Super->new,
            alias_rodata_idx    => {},
        }, $pkg);

    {
        my $fh = delete $opts{in};
        croak 'No input given' unless defined $fh;

        unless (ref $fh) {
            open(my $x, '<', $fh) or die $!;
            $fh = $x;
        }

        $fh->binmode;
        $fh->binmode(':utf8');
        $self->{in} = $fh;
    }

    {
        my $fh = delete $opts{out};
        croak 'No output given' unless defined $fh;

        unless (ref $fh) {
            open(my $x, '>', $fh) or die $!;
            $fh = $x;
        }

        $fh->binmode;
        $self->{out} = $fh;
    }

    croak 'Stray options passed' if scalar keys %opts;

    return $self;
}


sub run {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    $self->_save_position('out$');
    $self->_proc_input($self->{in});

    eval {
        my $size;
        $self->{out}->seek(0, SEEK_END);
        $size = $self->{out}->tell;
        if ($size & 1) {
            carp sprintf('WARNING: Final file size is %u bytes, this is a odd number', $size);
        }
        $self->_save_endposition('out$');
    };

    {
        my $boundary = 0;

        foreach my $section (@_section_text) {
            my $s = $self->{aliases}{'end$inner$section$'.$section} // next;
            $boundary = $s->[-1] if $boundary < $s->[-1];
        }

        if ($boundary & 1) {
            if (defined($self->{aliases}{'size$out$'}) && $self->{aliases}{'size$out$'}[-1] > $boundary) {
                $boundary++;
            } else {
                croak sprintf('Error: Text boundary has odd size and output size is invalid/too low');
            }
        }

        push(@{$self->{aliases}{'boundary$text'} //= []}, 0);
        push(@{$self->{aliases}{'end$boundary$text'} //= []}, $boundary);
    }

    {
        my $boundary = 0;

        foreach my $section (@_section_load) {
            my $s = $self->{aliases}{'end$inner$section$'.$section} // next;
            $boundary = $s->[-1] if $boundary < $s->[-1];
        }

        if ($boundary & 1) {
            if (defined($self->{aliases}{'size$out$'}) && $self->{aliases}{'size$out$'}[-1] > $boundary) {
                $boundary++;
            } else {
                croak sprintf('Error: Load boundary has odd size and output size is invalid/too low');
            }
        }

        push(@{$self->{aliases}{'boundary$load'} //= []}, 0);
        push(@{$self->{aliases}{'end$boundary$load'} //= []}, $boundary);
    }

    {
        my $pushback = $self->{pushback};

        $self->{pushback} = []; # reset

        foreach my $entry (@{$pushback}) {
            $self->{out}->seek($entry->{pos}, SEEK_SET);
            $self->_proc_parts($entry->{parts}, $entry->{opts}, undef, 1);
        }
    }

    if (scalar(@{$self->{pushback}})) {
        foreach my $entry (@{$self->{pushback}}) {
            carp sprintf('Warning: Still active pushback from line %u', $entry->{opts}{line});
        }

        croak sprintf('Error: There are still %u open pushbacks', scalar(@{$self->{pushback}}));
    }
}


sub dump {
    my ($self, $dumpfilename, @opts) = @_;
    my $aliases = $self->{aliases};
    my $rf = $self->{rf};
    my $dumpfh;

    croak 'Stray options passed' if scalar @opts;

    if (ref($dumpfilename)) {
        $dumpfh = $dumpfilename;
    } else {
        $dumpfh = $self->_open_file($dumpfilename, '>');
    }
    $dumpfh->binmode;
    $dumpfh->binmode(':utf8');

    say $dumpfh '; Settings:';
    foreach my $key (sort keys %{$self->{settings}}) {
        printf $dumpfh ";   %-32s -> %s\n", $key, $self->{settings}{$key} // '<undef>';
    }

    say $dumpfh '';
    say $dumpfh '; Register map:';
    foreach my $reg ($rf->expand('r*')) {
        printf $dumpfh ";   %-32s -> %s\n", $reg, scalar(eval {$rf->get_physical_by_name($reg)->name}) // '<?>';
    }

    say $dumpfh '';
    say $dumpfh '; Register attributes:';
    foreach my $reg ($rf->expand('r*', 'user*', 'system*')) {
        my $physical = $rf->get_physical_by_name($reg)->physical;
        my $temperature = $rf->register_temperature($reg);
        my $owner = $rf->register_owner($reg);
        printf $dumpfh ";   %-32s -> %2u: %8s %8s %8u\n", $reg, $physical, $temperature, $owner, $self->{regmap_last_used}{$physical} // 0;
    }

    say $dumpfh '';
    say $dumpfh '; Aliases:';
    foreach my $key (sort keys %{$aliases}) {
        printf $dumpfh ";   %-32s = %s\n", $key, join(', ', @{$aliases->{$key}});
    }
}
# ---- Private helpers ----
sub _open_file {
    my ($self, $filename, $mode) = @_;
    $mode //= '<';
    open(my $fh, $mode, $filename) or die $!;
    return $fh;
}

sub _alive {
    my ($self) = @_;
    return $self->{alive};
}

sub _quit {
    my ($self) = @_;
    delete $self->{alive};
}

sub _align {
    my ($self, $req, $warn) = @_;
    if ($self->{alignment} % $req) {
        my $pos = $self->{out}->tell;
        my $error = $pos % $req;
        if ($error) {
            $warn //= 0;
            if ($warn > 1) {
                croak sprintf('Fatal alignment missmatch would need to skip %u bytes', $req - $error);
            } elsif ($warn) {
                carp sprintf('Alignment missmatch, auto skipping %u bytes', $req - $error);
            }
            $self->{out}->seek($req - $error, SEEK_CUR);
            $self->{alignment} = $req;
        }
    }
}

sub _set_alignment {
    my ($self, $value) = @_;
    $self->{alignment} = $value;
}

sub _save_position {
    my ($self, $name) = @_;
    push(@{$self->{aliases}{$name} //= []}, $self->{out}->tell);
}
sub _save_endposition {
    my ($self, $name) = @_;
    push(@{$self->{aliases}{'end$' .$name} //= []}, $self->{out}->tell);
    push(@{$self->{aliases}{'size$'.$name} //= []}, $self->{aliases}{'end$'.$name}->[-1] - $self->{aliases}{$name}->[-1]) if defined $self->{aliases}{$name};
}

sub _write_opcode {
    my ($self, $opcode) = @_;
    $self->_align($opcode->required_alignment, 1);
    $opcode->write($self->{out});
    $self->_set_alignment($opcode->new_alignment);
}

sub _reg_map {
    my ($self, $loc, $phy) = @_;
    my $rf = $self->{rf};
    $loc = $rf->get_logical_by_name($loc);
    $phy = $rf->get_physical_by_name($phy);
    $rf->map($loc, $phy);
    return ($loc, $phy);
}
sub _reg_map_and_write {
    my ($self, @args) = @_;
    my ($loc, $phy) = $self->_reg_map(@args);
    $self->_write_opcode(SIRTX::VM::Opcode->new(code => 0, codeX => 3, P => $loc, ST => $phy->physical));
}

sub _force_mapped {
    my ($self, $register) = @_;
    my $regmap_last_used = $self->{regmap_last_used};
    my $rf = $self->{rf};
    my $loc = eval {$rf->get_logical_by_name($register)};
    my $inc = 5;

    unless (defined $loc) {
        if ($self->{settings}{regmap_auto}) {
            # Try to auto-map a register.
            my $regmap_mapped = $self->{regmap_mapped};
            my ($reg) = sort {($regmap_last_used->{$a} // 0) <=> ($regmap_last_used->{$b} // 0)} map {$_->physical} map {$rf->get_physical_by_name($_)} grep {$rf->register_owner($_) eq SIRTX::VM::Register::OWNER_YOURS()} grep {!$regmap_mapped->{$_}} $rf->expand('r*');

            croak 'No suitable register found for auto mapping, did you set enough registers with .yours?' unless defined $reg;

            $loc = $rf->get_logical_by_physical($reg);
            $regmap_mapped->{'r'.$loc} = 1;
            $self->_reg_map_and_write('r'.$loc, $register);
        }

        croak 'Cannot map register: '.$register unless defined $loc;
    }

    {
        my $physical = $rf->get_logical($loc)->physical;
        $regmap_last_used->{$physical} = $self->{regmap_last_used_c} + $inc;
        $self->{regmap_last_used_c} += 5;
    }
    return $loc;
}

sub _reg_alloc_phy {
    my ($self, @names) = @_;
    my $regmap_mapped = $self->{regmap_mapped};
    my $rf = $self->{rf};
    my ($reg) = grep {$rf->register_owner($_) eq SIRTX::VM::Register::OWNER_YOURS()} grep {!$regmap_mapped->{$_}} $rf->expand(@names);

    croak 'No suitable physical register found for auto mapping, did you set enough registers with .yours?' unless defined $reg;

    $regmap_mapped->{$reg} = 1;

    return $reg;
}

sub _autostring_allocate {
    my ($self, $str) = @_;
    state $autostring = 0;
    my $key = sprintf('autostring$%u', $autostring++);

    $self->{alias_rodata_idx}{$key} = $self->{rodata}->add_blob($str);
    push(@{$self->{aliases}{'size$'.$key} //= []}, length($str));

    return $key;
}

sub _pushback {
    my ($self, %opts) = @_;
    push(@{$self->{pushback}}, \%opts);
}

sub _proc_input {
    my ($self, $in) = @_;

    while ($self->_alive && defined(my $line = <$in>)) {
        my @parts;
        my %opts;
        my $autodie;

        $line =~ s/\r?\n$//;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        $line =~ s/^(?:;|\/\/|#).*$//;
        $line =~ s/\s+/ /g;

        next if $line eq '';

        while (length($line)) {
            if ($line =~ s/^("[^"]*")//) {
                push(@parts, $1);
            } elsif ($line =~ /^(?:;|\/\/|#)/) {
                # this is a comment, so just leave the rest alone
                last;
            } elsif ($line =~ s/^([^\s,=]+)//) {
                push(@parts, $1);
            } else {
                croak 'Bad line: '.$in->input_line_number;
            }

            $line =~ s/^\s*[,=]\s*//;
            $line =~ s/^\s+//;
        }

        next unless scalar @parts;

        $autodie = undef;
        if ($parts[0] =~ s/([\?\!])$//) {
            if ($1 eq '!') {
                $autodie = 1;
            }
        }

        %opts = (line => $in->input_line_number);

        $self->{regmap_mapped} = {};
        $self->_proc_parts(\@parts, \%opts, \$autodie);
    }
}

sub _proc_parts {
    my ($self, $parts, $opts, $autodie, $allow_alts) = @_;
    my $out = $self->{out};
    my ($cmd, @args) = @{$parts};
    my $was_return;
    my $opcode;

    $autodie //= do { \my $x };

    if ($cmd ne '.pushname' && $cmd ne '.popname') {
        foreach my $part (@{$parts}) {
            my @alts;

            next unless $part =~ /^[a-z0-9]*\$/;

            @alts = split(m#//#, $part);

            if ($allow_alts) {
                foreach my $alt (@alts) {
                    if (defined $self->{aliases}{$alt}) {
                        $part = $self->{aliases}{$alt}[-1];
                        last;
                    }
                }
            } else {
                $part = $self->{aliases}{$alts[0]}[-1] if defined $self->{aliases}{$alts[0]};
            }
        }
    }

    if ($cmd eq '.quit' && scalar(@args) == 0) {
        $self->_quit;
    } elsif ($cmd eq '.pushname' && !(scalar(@args) & 1)) {
        for (my $i = 0; $i < scalar(@args); $i += 2) {
            my $key   = $args[$i + 0];
            my $value = $args[$i + 1];

            if ($key !~ /^\$[0-9a-zA-Z_]+/) {
                croak sprintf('Bad key name: line %s: key %s', $opts->{line}, $key);
            }
            push(@{$self->{aliases}{$key} //= []}, $value);
        }
    } elsif ($cmd eq '.popname') {
        foreach my $key (@args) {
            unless (defined $self->{aliases}{$key}) {
                croak sprintf('Bad/unknown key name: line %s: key %s', $opts->{line}, $key);
            }

            pop(@{$self->{aliases}{$key}});
            delete $self->{aliases}{$key} unless scalar @{$self->{aliases}{$key}};
        }
    } elsif ($cmd eq '.utf8') {
        foreach my $str (@args) {
            print $out $self->_parse_string($str);
        }
        $self->_set_alignment(1);
    } elsif ($cmd eq '.byte') {
        my $last;
        foreach my $str (@args) {
            my $c = $self->_parse_int($str, $last);
            print $out pack('C', $c);
            $last = $c;
        }
        $self->_set_alignment(1);
    } elsif ($cmd eq '.string' && scalar(@args) >= 2) {
        my $key = 'string$'.$args[0];
        my $catted = '';
        foreach my $str (@args[1..$#args]) {
            $catted .= $self->_parse_string($str);
        }
        $self->{alias_rodata_idx}{$key} = $self->{rodata}->add_blob($catted);
        push(@{$self->{aliases}{'size$'.$key} //= []}, length($catted));
    } elsif ($cmd eq 'open' && scalar(@args) == 2 && $self->_get_value_type($args[0]) eq 'reg' && $self->_get_value_type($args[1]) eq 'string') {
        my $key = $self->_autostring_allocate($self->_parse_string($args[1]));
        $self->_proc_parts(['substr', $args[0], 'program_text', $key, 'end$'.$key], $opts);
    } elsif ($cmd eq 'byte_transfer' && scalar(@args) == 2 && $self->_get_value_type($args[0]) eq 'reg' && $self->_get_value_type($args[1]) eq 'string') {
        my $key = $self->_autostring_allocate($self->_parse_string($args[1]));
        my $reg = $self->_reg_alloc_phy('user*');

        $self->_proc_parts(['substr', $reg, 'program_text', $key, 'end$'.$key], $opts);
        $self->_proc_parts(['byte_transfer', $args[0], $reg, 'size$'.$key], $opts);
        $self->_proc_parts(['unref', $reg], $opts) if $self->{settings}{synthetic_auto_unref};
    } elsif ($cmd eq '.rodata' && scalar(@args) == 0) { # INTERNAL COMMAND! NOT FOR DOCS!
        my $aliases = $self->{aliases};
        my $rodata = $self->{rodata};
        my $base = $out->tell;
        print $out $rodata->result;
        $self->_set_alignment(1);
        foreach my $key (keys %{$self->{alias_rodata_idx}}) {
            my $idx = $self->{alias_rodata_idx}{$key};
            my $offset = $rodata->offset(index => $idx) + $base;
            my $size = $aliases->{'size$'.$key}[-1];
            push(@{$aliases->{$key} //= []}, $offset);
            push(@{$aliases->{'end$'.$key} //= []}, $offset + $size) if defined $size;
        }
    } elsif ($cmd eq '.include') {
        foreach my $arg (@args) {
            my $fh = $self->_open_file($self->_parse_string($arg));
            $fh->binmode;
            $fh->binmode(':utf8');

            $self->_proc_input($fh);
        }
    } elsif ($cmd eq '.cat') {
        local $/ = \4096;
        foreach my $arg (@args) {
            my $fh = $self->_open_file($self->_parse_string($arg));
            $fh->binmode;

            print $out $_ while <$fh>;
        }
        $self->_set_alignment(1);
    } elsif ($cmd eq '.noops' && scalar(@args) == 1) {
        my $num = $self->_parse_int($args[0]);
        my $opcode = SIRTX::VM::Opcode->from_template(parts => [qw(noop)], assembler => $self);

        $self->_align($opcode->required_alignment, 1);
        for (my $i = 0; $i < $num; $i++) {
            $opcode->write($out);
        }
        $self->_set_alignment($opcode->new_alignment);
    } elsif ($cmd eq '.org' && scalar(@args) == 1) {
        my $p = $self->_parse_int($args[0], $out->tell);
        carp 'New address in .org is not a multiple of the word size: line '.$opts->{line} if $p & 1;
        $out->seek($p, SEEK_SET);
        $self->_set_alignment(1);
    } elsif ($cmd eq '.align' && scalar(@args) == 1) {
        my $p = $self->_parse_int($args[0]);
        $self->_align($p);
    } elsif ($cmd eq '.label' && scalar(@args) == 1 && $args[0] =~ /^[a-z0-9A-Z_]+$/) {
        $self->{current}{label} = 'label$'.$args[0];
        $self->_save_position($self->{current}{label});
    } elsif ($cmd eq '.endlabel' && scalar(@args) == 0 && defined($self->{current}{label})) {
        $self->_save_endposition($self->{current}{label});
        $self->{current}{label} = undef;
    } elsif ($cmd eq '.function' && scalar(@args) == 1 && $args[0] =~ /^[a-z0-9A-Z_]+$/) {
        $self->_align(2, 1);
        $self->{current}{function} = $args[0];
        $self->_save_position('function$'.$self->{current}{function});
        $self->{rf}->map_reset;
    } elsif ($cmd eq '.endfunction' && scalar(@args) == 0 && defined($self->{current}{function})) {
        unless ($self->{was_return}) {
            $self->_write_opcode(SIRTX::VM::Opcode->from_template(parts => ['return'], assembler => $self));
        }
        $self->_save_endposition('function$'.$self->{current}{function});
        $self->{current}{function} = undef;
    } elsif ($cmd eq '.section' && (scalar(@args) == 1 || scalar(@args) == 2) && !defined($self->{current}{section})) {
        my $S = $_header_ids{$args[0]};
        my $T = 4;
        my $extra;
        my %tpl;

        unless (defined $S) {
            croak sprintf('Invalid section: line %s: section %s', $opts->{line}, $args[0]);
        }

        if (defined(my $bad = $_section_order_bad{$args[0]})) {
            foreach my $key (@_section_order) {
                next unless defined $self->{sections}{$key};
                croak sprintf('Invalid section: line %s: section %s must not follow section %s', $opts->{line}, $args[0], $key) if defined $bad->{$key};
            }
        }

        if (scalar(@args) == 2) {
            $extra = $self->_parse_string($args[1]);
            my $l = length($extra);
            croak sprintf('Invalid section magic: line %s: section %s: magic length %u', $opts->{line}, $args[0], $l) if $l != 6 && $l != 4 && $l != 2 && $l != 0;
            $T += $l/2;
        }

        $self->_align(2, 1);
        $self->_save_position('section$'.$args[0]);

        %tpl = (code => 0, P => 0, codeX => 0, S => $S, T => 0);

        $self->{current}{section} = {
            close_opcode => SIRTX::VM::Opcode->new(%tpl),
            name => $args[0],
        };

        $self->_write_opcode(SIRTX::VM::Opcode->new(%tpl, T => $T, extra => $extra));
        $self->_save_position('inner$section$'.$args[0]);

        $self->{sections}{$args[0]} = {};
    } elsif ($cmd eq '.endsection' && scalar(@args) == 0 && defined(my $section = $self->{current}{section})) {
        my $section_suffix = 'section$'.$section->{name};
        $self->_save_endposition('inner$'.$section_suffix);
        $self->_write_opcode($section->{close_opcode}) if defined $section->{close_opcode};
        $self->_save_endposition($section_suffix);
        $self->{current}{section} = undef;
    } elsif ($cmd =~ /^\.(regmap_auto|synthetic_auto_unref)$/ && scalar(@args) == 1) {
        $self->{settings}{$1} = $self->_parse_bool($args[0]);
    } elsif ($cmd eq '.map' && scalar(@args) == 2) {
        $self->_reg_map(@args);
    } elsif ($cmd eq '.force_mapped') {
        $self->_force_mapped($_) foreach $self->{rf}->expand(@args);
    } elsif ($cmd eq '.mine' || $cmd eq '.yours' || $cmd eq '.theirs') {
        my $mode = $cmd eq '.mine' ? SIRTX::VM::Register::OWNER_MINE() : $cmd eq '.yours' ? SIRTX::VM::Register::OWNER_YOURS() : SIRTX::VM::Register::OWNER_THEIRS();
        my $rf = $self->{rf};
        foreach my $reg ($rf->expand(@args)) {
            $rf->register_owner($reg, $mode);
        }
    } elsif ($cmd eq '.hot' || $cmd eq '.cold' || $cmd eq '.lukewarm') {
        my $mode = $cmd eq '.hot' ? SIRTX::VM::Register::TEMPERATURE_HOT() : $cmd eq '.cold' ? SIRTX::VM::Register::TEMPERATURE_COLD() : SIRTX::VM::Register::TEMPERATURE_LUKEWARM();
        my $rf = $self->{rf};
        foreach my $reg ($rf->expand(@args)) {
            $rf->register_temperature($reg, $mode);
        }
    } elsif ($cmd eq '.regattr' && scalar(@args) >= 1) {
        my ($reg, @attrs) = @args;
        my $rf = $self->{rf};

        foreach my $attr (@attrs) {
            if ($attr eq 'mine') {
                $rf->register_owner($reg, SIRTX::VM::Register::OWNER_MINE());
            } elsif ($attr eq 'yours') {
                $rf->register_owner($reg, SIRTX::VM::Register::OWNER_YOURS());
            } elsif ($attr eq 'theirs') {
                $rf->register_owner($reg, SIRTX::VM::Register::OWNER_THEIRS());
            } elsif ($attr eq 'hot') {
                $rf->register_temperature($reg, SIRTX::VM::Register::TEMPERATURE_HOT());
            } elsif ($attr eq 'cold') {
                $rf->register_temperature($reg, SIRTX::VM::Register::TEMPERATURE_COLD());
            } elsif ($attr eq 'lukewarm') {
                $rf->register_temperature($reg, SIRTX::VM::Register::TEMPERATURE_LUKEWARM());
            } elsif ($attr eq 'volatile') {
                # No-op
            } else {
                croak sprintf('Invalid register attribute: line %s: register %s: attribute: %s', $opts->{line}, $reg, $attr);
            }
        }

    } elsif ($cmd eq 'map' && scalar(@args) == 2) {
        $self->_reg_map_and_write(@args);

    } elsif (defined($opcode = eval {SIRTX::VM::Opcode->from_template(parts => $parts, assembler => $self, size => $opts->{size}, line => $opts->{line}, out => $out, autodie => $autodie)})) {
        $self->_write_opcode($opcode);
        $was_return = $opcode->is_return;
        ${$autodie} = undef if $opcode->is_autodie;
    } elsif (defined($opcode = eval {SIRTX::VM::Opcode->from_template(parts => [
                        $parts->[0],
                        map {scalar(eval {$self->_get_value_type($_) eq 'alias'}) ? 0xFFF0 : $_} $parts->@[1 .. (scalar(@{$parts}) - 1)]
                    ], assembler => $self, size => $opts->{size}, line => $opts->{line}, out => $out, autodie => $autodie)})) {
        my $pos;

        # first align, then look where we are.
        $self->_align($opcode->required_alignment, 1);
        $pos = $self->{out}->tell;

        $self->_write_opcode($opcode);
        $was_return = $opcode->is_return;
        ${$autodie} = undef if $opcode->is_autodie;
        $self->_pushback(pos => $pos, parts => $parts, opts => {%{$opts}, size => $opcode->required_size});
    } else {
        my $done;

        if (defined(my $entry = $_synthetic{$cmd})) {
            outer:
            for (my $i = 0; $i < scalar(@{$entry}); $i += 3) {
                my @argmap = @{$entry->[$i]};
                my @requests = @{$entry->[$i+1]};
                my %updates;
                my @allocations;
                my $reset_autodie;

                next unless (scalar(@args)*2) == scalar(@argmap);

                for (my $j = 0; ($j*2) < scalar(@argmap); $j++) {
                    my $type = $argmap[$j*2 + 0];
                    my $dst  = $argmap[$j*2 + 1];
                    my $val  = $args[$j];

                    if ($type =~ /^".+"$/) {
                        next outer if $val ne $self->_parse_string($type);
                    } elsif ($type eq 'any') {
                        # no-op.
                    } else {
                        my $t = $self->_get_value_type($val);
                        if (ref $type) {
                            my $found;
                            inner:
                            foreach my $tw (@{$type}) {
                                next inner if $t ne $tw && !($t =~ /:$/ && $tw eq 'id');
                                $found = 1;
                                last;
                            }
                            next outer unless $found;
                        } else {
                            next outer if $t ne $type && !($t =~ /:$/ && $type eq 'id');
                        }
                    }

                    if ($dst eq 'undef') {
                        # ignore this value
                    } else {
                        $updates{$dst} = $val;
                    }
                }

                for (my $j = 0; ($j*2) < scalar(@requests); $j++) {
                    my $req   = $requests[$j*2 + 0];
                    my $dst   = $requests[$j*2 + 1];
                    my $found = $self->_reg_alloc_phy($req);

                    $updates{$dst} = $found;
                    push(@allocations, $found);
                }

                foreach my $parts (@{$entry->[$i+2]}) {
                    my @parts = map {ref ? $updates{${$_}} : $_} @{$parts};
                    my $ad;

                    if ($parts[0] =~ s/\*$//) {
                        $ad = ${$autodie};
                        $reset_autodie = 1;
                    }

                    $self->_proc_parts(\@parts, $opts, \$ad);
                }

                if ($self->{settings}{synthetic_auto_unref}) {
                    $self->_proc_parts(['unref', $_], $opts) foreach @allocations;
                }

                $done = 1;
                ${$autodie} = undef if $reset_autodie;
                last outer;
            }
        }

        croak sprintf('Invalid input: line %s: command %s: arguments: %s', $opts->{line}, $cmd, join(', ', @args)) unless $done;
    }

    if (${$autodie}) {
        $opcode = SIRTX::VM::Opcode->from_template(parts => ['autodie'], assembler => $self, line => $opts->{line});
        $self->_write_opcode($opcode);
    }

    $self->{was_return} = $was_return;
}

sub _type_to_sni {
    my ($self, $type) = @_;
    return $_type_to_sni{$type} // croak 'Unknown type: '.$type;
}

sub _get_value_type {
    my ($self, $value) = @_;
    return 'reg' if defined(scalar(eval {$self->{rf}->get_physical_by_name($value)}));
    return 'bool' if $value eq 'true' || $value eq 'false';
    return 'undef' if $value eq 'undef';
    return 'string' if $value =~ /^(?:"|U\+)/;
    return 'int' if $value =~ /^[\+\-]?(?:0|[1-9][0-9]*|0x[0-9a-fA-F]+|0[0-7]+|0b[01]+)$/;
    if ($value =~ /^([a-z]+):(?:0|[1-9][0-9]*)$/) {
        my $type = $1;
        return $type.':' if defined $_type_to_sni{$type};
    }
    if ($value =~ /^([1-9][0-9]*):(?:0|[1-9][0-9]*)$/) {
        my $type = $1;
        if (defined $_sni_to_type{$type}) {
            $type = $_sni_to_type{$type};
        } else {
            $_type_to_sni{$type} = $type;
        }
        return $type.':';
    }
    return 'alias' if $value =~ /^[a-z0-9]*\$/;
    die 'Bad value: '.$value;
}

sub _parse_bool {
    my ($self, $bool) = @_;
    return $bool eq 'true';
}

sub _parse_int {
    my ($self, $val, $rel) = @_;
    my $neg;

    $rel //= 0;

    if ($val =~ s/^-//) {
        $neg = 1;
    } elsif ($val =~ s/^\+//) {
        # no-op
    } else {
        $rel = 0;
    }

    if ($val =~ /^[1-9]/) {
        $val = int($val);
    } elsif ($val =~ /^(?:0[0-7]*|0x[0-9a-f]+|0b[01]+)$/) {
        $val = oct($val);
    } else {
        die 'Bad integer';
    }

    $val *= -1 if $neg;

    return $val + $rel;
}

sub _parse_escape {
    my ($esc) = @_;

    return $_escapes{$esc} if defined $_escapes{$esc};
    return chr(hex($1)) if $esc =~ /^x([0-9a-f]{2})$/;
}

sub _parse_string {
    my ($self, $str) = @_;

    if ($str =~ s/^"(.*)"$/$1/) {
        # no-op
    } elsif ($str =~ /^U\+([0-9a-fA-F]{4,6})$/) {
        my $char = chr(hex($1));
        state $UTF_8 = Encode::find_encoding('UTF-8');
        return $UTF_8->encode($char);
    } else {
        die 'Bad string';
    }

    $str =~ s/\\(\\|[0nrte]|x[0-9a-f]{2})/_parse_escape($1)/ge;

    return $str;
}

sub _parse_id {
    my ($self, $str) = @_;
    if ($str =~ /^([a-z]+):(0|[1-9][0-9]*)$/) {
        my ($type, $num) = ($1, $2);
        return ($type, $self->_parse_int($num));
    } elsif ($str =~ /^([1-9][0-9]*):(0|[1-9][0-9]*)$/) {
        my ($type, $num) = ($1, $2);
        if (defined $_sni_to_type{$type}) {
            $type = $_sni_to_type{$type};
        } else {
            $_type_to_sni{$type} = $type;
        }
        return ($type, $self->_parse_int($num));
    } else {
        die 'Bad ID';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::VM::Assembler - module for assembling SIRTX VM code

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use SIRTX::VM::Assembler;

    my SIRTX::VM::Assembler $asm = SIRTX::VM::Assembler->new(in => $infile, out => $outfile);

    $asm->run;

This package inherits from L<Data::Identifier::Interface::Userdata>.

The syntax for the input files is described in details at L<https://sirtx.keep-cool.org/vm.html>.

=head1 METHODS

=head2 new

    my SIRTX::VM::Assembler $asm = SIRTX::VM::Assembler->new(in => $infile, out => $outfile);

(experimental)

Creates a new assembler object. This object can be used to convert code into byte code.

The following options are supported:

=over

=item C<in>

(required)

The input data as a filename or handle.
If a handle the handle must allow seeking.
Also attributes on the handle might be changed.
It is best to avoid reusing the handle with other code.

=item C<out>

(required)

The output to write the result to. The same aspects as for C<in> apply.

=back

=head2 run

    $asm->run;

(experimental)

Runs the assembler.

=head2 dump

    $asm->dump($filename);

(experimental)

Dumps data collected by L</run>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
