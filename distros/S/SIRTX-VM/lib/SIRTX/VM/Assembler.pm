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
use List::Util qw(uniq);

use String::Super;

use SIRTX::VM::RegisterFile;
use SIRTX::VM::Opcode;

use parent 'Data::Identifier::Interface::Userdata';

our $VERSION = v0.10;

my %_escapes = (
    '\\' => '\\',
    '0' => chr(0x00),
    'n' => chr(0x0A),
    'r' => chr(0x0D),
    't' => chr(0x09),
    'e' => chr(0x1B),
);
my %_type_to_sni = %SIRTX::VM::Opcode::_logicals_to_sni; # copy
my %_sni_to_type = map {$_type_to_sni{$_} => $_} keys %_type_to_sni;

my %_header_ids = (
    init        => 1,
    header      => 2,
    rodata      => 3,
    text        => 4,
    trailer     => 5,
    resources   => 6,
);

our %_header_ids_rev = reverse %_header_ids;

my @_section_order = qw(header init text rodata resources trailer);
my @_section_text  = qw(header init text);
my @_section_load  = (@_section_text, qw(rodata resources));

my %_disabled_sections = (
    'resources_only' => {map {$_ => 1} qw(init text)},
);

my %_info          = map {$_ => 1} (
    qw(.author .license .copyright_years .copyright_holder),
    qw(.description .comment .displayname .displaycolour .icon .icontext),
    qw(.subject_webpage .vendor_webpage .author_webpage .webpage),
    qw(.repo_uri),
);

my %_profiles      = (
    default         => 0,
    resources_only  => 1,
    minimal         => 2,
);

my %_synthetic = (
    default => {
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
        control         => [[reg => 1, [qw(reg sni:)] => 2, [qw(string bool)] => 3] => ['user*' => 4] => [
                ['open', \4, \3],
                ['control', \1, \2, \4],
            ],
            [reg => 1, [qw(reg sni:)] => 2, [qw(string bool)] => 3, reg => 4] => ['user*' => 5, 'arg' => 6] => [
                ['open', \5, \3],
                ['replace', \6, \4],
                ['control', \1, \2, \5],
            ],
            [reg => 1, [qw(reg sni:)] => 2, [qw(string bool)] => 3, any => 4] => ['user*' => 5, 'arg' => 6] => [
                ['open', \5, \3],
                ['open', \6, \4],
                ['control', \1, \2, \5],
            ],
            [any => 1, any => 2, any => 3, reg => 4] => ['arg' => 5] => [
                ['replace', \5, \4],
                ['control', \1, \2, \3, \5],
            ],
            [any => 1, any => 2, any => 3, any => 4] => ['arg' => 5] => [
                ['open', \5, \4],
                ['control', \1, \2, \3, \5],
            ]],
        push            => [[any => 1, string => 2] => ['user*' => 3] => [
                ['open', \3, \2],
                ['push', \1, \3],
            ],
            [any => 1, any => 2] => ['user*' => 3] => [
                ['open', \3, \2],
                ['push', \1, \3],
            ],
            [any => 1, [qw(int id string bool)] => 2, '"arg"' => 3] => ['user*' => 4] => [
                ['open', \4, \2],
                ['control', \1, 'sni:180', \4, \3],
            ],
            [any => 1, reg => 2, '"arg"' => 3] => [] => [
                ['control', \1, 'sni:180', \2, \3],
            ],
            [any => 1, [qw(int id string bool)] => 2, reg => 3] => ['user*' => 4, 'arg' => 5] => [
                ['open', \4, \2],
                ['replace', \5, \3],
                ['control', \1, 'sni:180', \4, \3],
            ],
            [any => 1, reg => 2, reg => 3] => ['arg' => 4] => [
                ['replace', \4, \3],
                ['control', \1, 'sni:180', \2, \4],
            ],
            [any => 1, [qw(int id string bool)] => 2, any => 3] => ['user*' => 4, 'arg' => 5] => [
                ['open', \4, \2],
                ['open', \5, \3],
                ['control', \1, 'sni:180', \4, \3],
            ],
            [any => 1, reg => 2, any => 3] => ['arg' => 4] => [
                ['open', \4, \3],
                ['control', \1, 'sni:180', \2, \4],
            ]],
        pop             => [[reg => 1, reg => 2] => [] => [
                ['control', \2, 'sni:181'],
                ['replace', \1, 'out'],
            ]],
        setvalue        => [
            [reg => 1, reg => 2, '"arg"' => 3] => [] => [
                ['control', \1, 'sni:102', \2, \3],
            ],
            [reg => 1, any => 2, '"arg"' => 3] => ['user*' => 4] => [
                ['open', \4, \2],
                ['control', \1, 'sni:102', \4, \3],
            ],
            [reg => 1, reg => 2, reg => 3] => ['arg' => 4] => [
                ['replace', \4, \3],
                ['control', \1, 'sni:102', \2, \4],
            ],
            [reg => 1, any => 2, reg => 3] => ['arg' => 4, 'user*' => 5] => [
                ['replace', \4, \3],
                ['open', \5, \2],
                ['control', \1, 'sni:102', \5, \4],
            ],
            [reg => 1, reg => 2, any => 3] => ['arg' => 4] => [
                ['open', \4, \3],
                ['control', \1, 'sni:102', \2, \4],
            ],
            [reg => 1, any => 2, any => 3] => ['arg' => 4, 'user*' => 5] => [
                ['open', \4, \3],
                ['open', \5, \2],
                ['control', \1, 'sni:102', \5, \4],
            ]],
        getvalue        => [
            ['"out"' => 1, reg => 2, any => 3] => ['user*' => 4] => [
                ['open', \4, \3],
                ['getvalue', \1, \2, \4],
            ],
            [reg => 1, reg => 2, reg => 3] => [] => [
                ['getvalue', 'out', \2, \3],
                ['replace', \1, 'out'],
            ],
            [reg => 1, reg => 2, any => 3] => ['user*' => 4] => [
                ['open', \4, \3],
                ['getvalue', 'out', \2, \4],
                ['replace', \1, 'out'],
            ]],
        relations       => [[alias => 1, reg => 2, id => 3, any => 4] => ['user*' => 5, 'user*' => 6] => [
                ['.force_mapped', \5],
                ['open_function', \5, \1],
                ['open', \6, \3],
                ['relations', \5, \2, \6, \4],
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
        '.filechunk'    => [[string => 1, 'any...' => 2] => [] => [
                ['.chunk', \2],
                ['.cat', \1],
                ['.endchunk'],
            ]],
    },
    minimal => {
        '.autosection' => [
            ['"rodata"' => 1] => [] => [
                ['data_start_marker'],
                ['.rodata'], # INTERNAL COMMAND, NOT FOR DOCS!
            ],
            [any => 1] => [] => [
            ]],
    },
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
            auto_host_defined   => undef,
            profiles            => [],
            profiles_hash       => undef,
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

    $self->_join_profile('default');

    if (defined(my $profile = delete $opts{profile})) {
        $profile = [$profile] unless ref $profile;

        foreach my $p (@{$profile}) {
            $self->_join_profile(split(/(?:\s*,\s*|\s+)/, $p));
        }
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

    # We are past the first pass.
    # We disable automapping here. If there is still mapping needed there is a bug somewhere as this all should be resolved by now.
    # So turning it off to let any requests fail is the safest option.
    $self->{settings}{regmap_auto} = undef;

    {
        my $pushback = $self->{pushback};

        $self->{pushback} = []; # reset

        foreach my $entry (@{$pushback}) {
            local $self->{rf} = $entry->{rf};
            $self->{out}->seek($entry->{pos}, SEEK_SET);
            $entry->{update}->($self, $entry) if defined $entry->{update};
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

    say $dumpfh '; Profiles:';
    foreach my $key (@{$self->{profiles}}) {
        printf $dumpfh ";   %s\n", $key;
    }

    say $dumpfh '';
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

sub _join_profile {
    my ($self, @profiles) = @_;
    push(@profiles, @{$self->{profiles}});

    $self->{profiles} = [uniq sort {($_profiles{$b} // croak 'Bad profile: '.$b) <=> ($_profiles{$a} // croak 'Bad profile: '.$a)} @profiles];
    $self->{profiles_hash} = {map {$_ => 1} @{$self->{profiles}}};
}

sub _using_profile {
    my ($self, @profile) = @_;
    my $hash = $self->{profiles_hash};

    foreach my $profile (@profile) {
        return 1 if $hash->{$profile};
    }

    return undef;
}

sub _get_synthetic {
    my ($self, $cmd) = @_;

    foreach my $profile (@{$self->{profiles}}) {
        if (defined(my $entry = $_synthetic{$profile}{$cmd})) {
            return $entry;
        }
    }

    return undef;
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
    my ($reg) = sort {(eval {$rf->get_logical_by_name($a)} // 999) <=> (eval {$rf->get_logical_by_name($b)} // 999)}
                grep {$rf->register_owner($_) eq SIRTX::VM::Register::OWNER_YOURS()}
                grep {!$regmap_mapped->{$_}}
                $rf->expand(@names);

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

sub _auto_host_defined {
    my ($self) = @_;
    my $auto_host_defined = $self->{auto_host_defined};
    my $res;

    croak 'No auto host defined IDs available' unless defined($auto_host_defined) && defined($auto_host_defined->[2]);

    $res = $auto_host_defined->[2]++;

    if ($auto_host_defined->[2] > $auto_host_defined->[1]) {
        $auto_host_defined->[2] = undef;
    }

    return '~'.$res;
}

sub _pushback {
    my ($self, %opts) = @_;
    $opts{rf} = $self->{rf}->clone;
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
        ($cmd, @args) = @{$parts};
    }

    foreach my $arg (@args) {
        if ($arg eq '~auto') {
            $arg = $self->_auto_host_defined;
        }
    }

    if ($cmd eq '.quit' && scalar(@args) == 0) {
        $self->_quit;
    } elsif ($cmd eq '.profile' && scalar(@args) > 0) {
        $self->_join_profile(@args);
    } elsif ($cmd eq '.pushname' && !(scalar(@args) & 1)) {
        for (my $i = 0; $i < scalar(@args); $i += 2) {
            my $key   = $args[$i + 0];
            my $value = $args[$i + 1];

            $key =~ s/^\$?/\$/; # ensure it starts with a '$'.
            if ($key !~ /^\$[0-9a-zA-Z_]+/) {
                croak sprintf('Bad key name: line %s: key %s', $opts->{line}, $key);
            }
            push(@{$self->{aliases}{$key} //= []}, $value);
        }
    } elsif ($cmd eq '.popname') {
        foreach my $key (@args) {
            $key =~ s/^\$?/\$/; # ensure it starts with a '$'.
            unless (defined $self->{aliases}{$key}) {
                croak sprintf('Bad/unknown key name: line %s: key %s', $opts->{line}, $key);
            }

            pop(@{$self->{aliases}{$key}});
            delete $self->{aliases}{$key} unless scalar @{$self->{aliases}{$key}};
        }
    } elsif ($cmd eq '.tag' && scalar(@args) == 2 && $args[0] =~ /^[0-9a-zA-Z_]+$/ && defined($_type_to_sni{$args[1]})) {
        push(@{$self->{aliases}{'tag$'.$args[0]} //= []}, 'sni:'.$_type_to_sni{$args[1]});
    } elsif ($cmd eq '.tag' && scalar(@args) == 2 && $args[0] =~ /^[0-9a-zA-Z_]+$/ && $self->_get_value_type($args[1]) =~ /:$/) {
        push(@{$self->{aliases}{'tag$'.$args[0]} //= []}, $args[1]);
    } elsif ($cmd eq '.tag' && scalar(@args) == 2 && $args[0] =~ /^[0-9a-zA-Z_]+$/ && $self->_get_value_type($args[1]) eq 'int') {
        push(@{$self->{aliases}{'tag$'.$args[0]} //= []}, 'sni:'.$self->_parse_int($args[1]));
    } elsif ($cmd eq '.tag' && scalar(@args) == 3 && $args[0] =~ /^[0-9a-zA-Z_]+$/ && $args[1] =~ /^[0-9a-zA-Z_]+$/ && $self->_get_value_type($args[2]) eq 'int') {
        push(@{$self->{aliases}{'tag$'.$args[0]} //= []}, $args[1].':'.$self->_parse_int($args[2]));
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
    } elsif ($cmd eq '.uint16') { # INTERNAL COMMAND! NOT FOR DOCS!
        my $last;
        foreach my $str (@args) {
            my $c = $self->_parse_int($str, $last);
            print $out pack('n', $c);
            $last = $c;
        }
        $self->_set_alignment(1);
    } elsif ($cmd eq '.uint16_half_up') { # INTERNAL COMMAND! NOT FOR DOCS!
        my $last;
        foreach my $str (@args) {
            my $c = $self->_parse_int($str, $last);
            print $out pack('n', ($c / 2) + ($c & 1));
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
    } elsif ($cmd eq '.host_defined_auto_range' && scalar(@args) == 2 && $self->_get_value_type($args[0]) eq 'int' && $self->_get_value_type($args[1]) eq 'int') {
        my $start = $self->_parse_int($args[0]);
        my $end   = $self->_parse_int($args[1], $start);
        croak 'Invalid range for host defined identifiers: '.$start.' to '.$end if $end < $start || $start < 1;
        croak 'Host defined range already set, trying to set it again in line '.$opts->{line} if defined $self->{auto_host_defined};
        $self->{auto_host_defined} = [$start, $end, $start];
    } elsif ($cmd eq '.label' && (scalar(@args) == 1 || scalar(@args) == 3) && $args[0] =~ /^[a-z0-9A-Z_]+$/ && (scalar(@args) == 1 || ($args[1] eq 'as' && $args[2] =~ /^~[0-9]+$/))) {
        $self->{current}{label} = 'label$'.$args[0];
        $self->_save_position($self->{current}{label});
        if (scalar(@args) == 3 && $args[1] eq 'as' && $args[2] =~ /^~[0-9]+$/) {
            push(@{$self->{aliases}{'hostdefined$label$'.$self->{current}{label}} //= []}, $args[2]);
        }
    } elsif ($cmd eq '.endlabel' && scalar(@args) == 0 && defined($self->{current}{label})) {
        $self->_save_endposition($self->{current}{label});
        $self->{current}{label} = undef;
    } elsif ($cmd eq '.function' && (scalar(@args) == 1 || scalar(@args) == 3) && $args[0] =~ /^[a-z0-9A-Z_]+$/ && (scalar(@args) == 1 || ($args[1] eq 'as' && $args[2] =~ /^~[0-9]+$/))) {
        $self->_align(2, 1);
        $self->{current}{function} = $args[0];
        $self->_save_position('function$'.$self->{current}{function});
        $self->{rf}->map_reset;
        if (scalar(@args) == 3 && $args[1] eq 'as' && $args[2] =~ /^~[0-9]+$/) {
            push(@{$self->{aliases}{'hostdefined$function$'.$self->{current}{function}} //= []}, $args[2]);
        }
    } elsif ($cmd eq '.endfunction' && scalar(@args) == 0 && defined($self->{current}{function})) {
        unless ($self->{was_return}) {
            $self->_save_position('return$function$'.$self->{current}{function});
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

        foreach my $profile (@{$self->{profiles}}) {
            if (defined(my $disabled = $_disabled_sections{$profile})) {
                if ($disabled->{$args[0]}) {
                    croak sprintf('Invalid section for profile: line %s: section %s not allowed in profile %s', $opts->{line}, $args[0], $profile);
                }
            }
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

        unless ($self->_using_profile('minimal')) {
            $self->_write_opcode(SIRTX::VM::Opcode->new(%tpl, T => $T, extra => $extra));
        }
        $self->_save_position('inner$section$'.$args[0]);

        $self->{sections}{$args[0]} = {};
    } elsif ($cmd eq '.endsection' && scalar(@args) == 0 && defined(my $section = $self->{current}{section})) {
        my $section_suffix = 'section$'.$section->{name};
        $self->_save_endposition('inner$'.$section_suffix);
        unless ($self->_using_profile('minimal')) {
            $self->_write_opcode($section->{close_opcode}) if defined $section->{close_opcode};
        }
        $self->_save_endposition($section_suffix);
        $self->{current}{section} = undef;
    } elsif ($cmd eq '.chunk' && scalar(@args) >= 2) {
        my @in = @args;
        my $flags = 0;
        my $type;
        my $identifier = 0;
        my %info;
        $self->_align(2, 1);

        while (scalar(@in)) {
            my $c = shift(@in);

            if (($c eq 'of' || $c eq 'as' || $c eq 'name') && scalar(@in)) {
                $info{$c} = shift(@in);
            } elsif ($c eq 'standalone') {
                $info{$c} = 1;
            } else {
                croak sprintf('Invalid chunk option: line %s: %s', $opts->{line}, $c);
            }
        }

        if (defined(my $as = $info{as})) {
            if ($as !~ /^~([0-9]+)$/) {
                croak sprintf('Invalid chunk option: line %s: as %s', $opts->{line}, $as);
            }

            $identifier = int($1);
        }

        if (defined($info{name}) && length($info{name})) {
            unless ($info{name} =~ /^[0-9a-z]+$/) {
                croak sprintf('Invalid chunk name: line %s: %s', $opts->{line}, $info{name});
            }
        } elsif ($identifier) {
            $info{name} = sprintf('idchunk$%u', $identifier);
        } else {
            state $autochunk = 0;
            $info{name} = sprintf('autochunk$%u', $autochunk++);
        }

        # Allow for chunks' ID to be accessed via it's name
        push(@{$self->{aliases}{'hostdefined$chunk$'.$info{name}} //= []}, $info{as}) if defined $info{as};

        if (defined(my $of = $info{of})) {
            if ($of =~ /^~([0-9]+)$/) {
                $type = int($1);
                $flags |= 1<<15;
            } else {
                my $t;
                ($t, $type) = $self->_parse_id($of);

                if ($t eq 'sid') {
                    $flags |= 1<<14;
                } elsif ($t eq 'sni') {
                    # no-op
                } else {
                    croak sprintf('Invalid chunk type: line %s: of type %s not supported', $opts->{line}, $t);
                }
            }
        } else {
            croak sprintf('Invalid chunk: line %s: no of (type) given', $opts->{line});
        }

        $flags |= 1<<7 if $info{standalone};
        $flags |= 1<<1 if $identifier > 0;

        print $out chr(0x06), chr(0x38+1);
        $self->_pushback(pos => $out->tell, parts => ['.uint16_half_up', 'size$chunk$'.$info{name}], opts => {%{$opts}, size => 2});
        print $out chr(0) x 2;

        $self->{current}{chunk} = $info{name};
        $self->_save_position('chunk$'.$info{name});

        $self->_pushback(pos => $out->tell, parts => ['.uint16', $flags], opts => {%{$opts}, size => 2}, update => sub {
                my (undef, $entry) = @_;
                $entry->{parts}[1] |= $self->{aliases}{'size$chunk$'.$info{name}}[-1] & 1; # update padding flag
            });
        print $out chr(0) x 2;

        print $out pack('n', $type);
        print $out pack('n', $identifier) if $identifier > 0;
        $self->_save_position('inner$chunk$'.$info{name});
    } elsif ($cmd eq '.endchunk' && scalar(@args) == 0 && defined($self->{current}{chunk})) {
        $self->_save_endposition('inner$chunk$'.$self->{current}{chunk});
        $self->_save_endposition('chunk$'.$self->{current}{chunk});
        $self->{current}{chunk} = undef;
        $self->_align(2);
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
    } elsif (defined($_info{$cmd}) && scalar(@args) > 1 && $args[0] =~ /^~0?$/) {
        # no-op for now.
    } else {
        my $done;

        if (defined(my $entry = $self->_get_synthetic($cmd))) {
            outer:
            for (my $i = 0; $i < scalar(@{$entry}); $i += 3) {
                my @argmap = @{$entry->[$i]};
                my @requests = @{$entry->[$i+1]};
                my %updates;
                my @allocations;
                my $reset_autodie;

                if (scalar(@argmap) >= 2 && $argmap[-2] eq 'any...') {
                    next unless (scalar(@args)*2) >= scalar(@argmap);
                } else {
                    next unless (scalar(@args)*2) == scalar(@argmap);
                }

                # Process argument map:
                for (my $j = 0; ($j*2) < scalar(@argmap); $j++) {
                    my $type = $argmap[$j*2 + 0];
                    my $dst  = $argmap[$j*2 + 1];
                    my $val  = $args[$j];

                    if ($type =~ /^".+"$/) {
                        next outer if $val ne $self->_parse_string($type);
                    } elsif ($type eq 'any') {
                        # no-op.
                    } elsif ($type eq 'any...') {
                        $val = [@args[$j..$#args]];
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

                # Find suitable temp registers:
                for (my $j = 0; ($j*2) < scalar(@requests); $j++) {
                    my $req   = $requests[$j*2 + 0];
                    my $dst   = $requests[$j*2 + 1];
                    my $found = $self->_reg_alloc_phy($req);

                    $updates{$dst} = $found;
                    push(@allocations, $found);
                }

                # Actually run the parts:
                foreach my $parts (@{$entry->[$i+2]}) {
                    my @parts = map {ref ? ref($updates{${$_}}) ? @{$updates{${$_}}} : $updates{${$_}} : $_} @{$parts};
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
    return 'int' if $value =~ /^'?[\+\-]?(?:0|[1-9][0-9]*|0x[0-9a-fA-F]+|0[0-7]+|0b[01]+)$/;

    if ($value =~ /^([a-z]+):(?:0|[1-9][0-9]*)$/) {
        my $type = $1;
        return $type.':' if defined $_type_to_sni{$type};
    }

    $value =~ s/^\/(0|[1-9][0-9]*)$/127:$1/;
    if ($value =~ /^([1-9][0-9]*):(?:0|[1-9][0-9]*)$/) {
        my $type = $1;
        if (defined $_sni_to_type{$type}) {
            $type = $_sni_to_type{$type};
        } else {
            $_type_to_sni{$type} = $type;
        }
        return $type.':';
    }
    return 'logical:' if $value =~ /^logical:/;
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

    $val =~ s/^'//;

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
    } elsif ($val =~ /^(?:0[0-7]*|0x[0-9a-fA-F]+|0b[01]+)$/) {
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

    $str =~ s/^\/(0|[1-9][0-9]*)$/127:$1/;

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

version v0.10

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

=item C<profile>

(optional)

Profile (or list of profiles) to be used by the assembler.

=back

=head2 run

    $asm->run;

(experimental)

Runs the assembler.

=head2 dump

    $asm->dump($filename);

(experimental)

Dumps data collected by L</run>.
C<$filename> may be a file name or a already open file handle.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
