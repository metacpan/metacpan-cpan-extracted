# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for interacting with SIRTX VM code


package SIRTX::VM::RegisterFile;

use v5.16;
use strict;
use warnings;

use Carp;

use SIRTX::VM::Register;

use parent 'Data::Identifier::Interface::Userdata';

our $VERSION = v0.05;

my @_register_templates = (
    # user:

    (map{{name => 'user'.$_}}
        0 ..  7),               # user registers
    (map{{name => 'user'.$_}}
        8 .. 31),               # extended user registers

    # system:
    {name => 'arg'},            # arg register
    {name => 'ns'},             # namespace register
    {name => 'error'},          # error register
    {name => 'context'},        # context register
    {name => 'in'},             # call input register
    {name => 'out'},            # call output
    {name => 'deep'},           # deep storage
    (map{undef}
        39 .. 60),              # unassigned
    {name => 'io'},             # I/O register
    {name => 'rodata'},         # rodata
    {name => 'program_text'},   # program text
);


sub new {
    my ($pkg) = @_;
    my @registers;
    my %register_names;
    my $self = bless {
        physical_registers => \@registers,
        logical_registers => [],
        register_names => \%register_names,
        logical_temperature => {map {$_ => SIRTX::VM::Register::TEMPERATURE_LUKEWARM()} 0..7},
        logical_owner => {map {$_ => SIRTX::VM::Register::OWNER_MINE()} 0..7},
    }, $pkg;

    for (my $i = 0; $i < scalar(@_register_templates); $i++) {
        my $template = $_register_templates[$i];
        next unless defined $template;

        $registers[$i] = SIRTX::VM::Register->_new(%{$template}, physical => $i, type => ($i >= 32 ? SIRTX::VM::Register::TYPE_SYSTEM() : SIRTX::VM::Register::TYPE_USER()));

        if (defined $template->{name}) {
            $register_names{$template->{name}} = $registers[$i];
        }
    }

    $self->map_reset;

    return $self;
}


sub map_reset {
    my ($self) = @_;

    for (my $i = 0; $i < 8; $i++) {
        $self->map($i => $i);
    }
}


sub map {
    my ($self, $logical, $physical) = @_;

    if ($logical < 0 || $logical >= 8) {
        croak 'Bad logical register: '.$logical;
    }

    if (!ref($physical)) {
        $physical = $self->get_physical($physical);
    }

    $self->{logical_registers}[$logical] = $physical;
}


sub get_physical {
    my ($self, $physical) = @_;
    return $physical if ref $physical;
    return $self->{physical_registers}[$physical] // croak 'Bad physical register: '.$physical;
}


sub get_logical {
    my ($self, $logical) = @_;
    return $self->{logical_registers}[$logical] // croak 'Bad logical register: '.$logical;
}


sub get_physical_by_name {
    my ($self, $name) = @_;

    if (ref $name) {
        return $name;
    } elsif ($name =~ /^r([0-9]+)$/) {
        return $self->get_logical($1);
    } elsif (defined(my $r = $self->{register_names}{$name})) {
        return $r;
    }

    croak 'Unknown register: '.$name;
}

# deprecated alias:
*get_by_name = *get_physical_by_name;

sub get_logical_by_name {
    my ($self, $name) = @_;
    if ($name =~ /^r([0-9]+)$/) {
        return int($1);
    } elsif (defined(my $r = $self->{register_names}{$name})) {
        return $self->get_logical_by_physical($r);
    }

    croak 'Unknown register: '.$name;
}


sub get_logical_by_physical {
    my ($self, $physical) = @_;

    $physical = $self->get_physical($physical);

    for (my $i = 0; $i < 8; $i++) {
        if ($self->{logical_registers}[$i] == $physical) {
            return $i;
        }
    }

    croak 'Register is not mapped';
}


sub register_owner {
    my ($self, $register, $n) = @_;

    if (ref $register) {
        return $register->owner($n);
    } elsif ($register =~ /^r([0-9]+)$/) {
        my $logical = int($1);
        $self->{logical_owner}{$logical} = $n if defined $n;
        return $self->{logical_owner}{$logical};
    } else {
        return $self->get_physical_by_name($register)->owner($n);
    }
}


sub register_temperature {
    my ($self, $register, $n) = @_;

    if (ref $register) {
        return $register->temperature($n);
    } elsif ($register =~ /^r([0-9]+)$/) {
        my $logical = int($1);
        $self->{logical_temperature}{$logical} = $n if defined $n;
        return $self->{logical_temperature}{$logical};
    } else {
        return $self->get_physical_by_name($register)->temperature($n);
    }
}


sub expand {
    my ($self, @args) = @_;
    my @res;

    foreach my $reg (@args) {
        if ($reg eq 'r*') {
            push(@res, map {'r'.$_} 0..7);
        } elsif ($reg eq 'user*') {
            push(@res, map {'user'.$_} 0..31);
        } elsif ($reg eq 'system*') {
            push(@res, grep {defined} map {scalar(eval {$self->get_physical($_)->name})} 32..63);
        } else {
            push(@res, $reg);
        }
    }

    return @res;
}


sub clone {
    my ($self) = @_;
    my @registers;
    my %register_names;
    my $clone = bless {
        physical_registers => \@registers,
        logical_registers => [],
        register_names => \%register_names,
        logical_temperature => {%{$self->{logical_temperature}}},
        logical_owner => {%{$self->{logical_owner}}},
    }, __PACKAGE__;

    # clone registers:
    foreach my $register (@{$self->{physical_registers}}) {
        if (defined $register) {
            my $c = $register->clone;
            push(@registers, $c);

            if (defined(my $name = $c->name)) {
                $register_names{$name} = $c;
            }
        } else {
            push(@registers, undef);
        }
    }

    # clone map:
    for (my $i = 0; $i < scalar(@{$self->{logical_registers}}); $i++) {
        $clone->map($i => $self->get_logical($i)->physical);
    }

    return $clone;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::VM::RegisterFile - module for interacting with SIRTX VM code

=head1 VERSION

version v0.05

=head1 SYNOPSIS

    use SIRTX::VM::RegisterFile;

This package inherits from L<Data::Identifier::Interface::Userdata>.

=head1 METHODS

=head2 new

    my SIRTX::VM::RegisterFile $rf = SIRTX::VM::RegisterFile->new;

Creates a new register file. The registers are in default configuration.

=head2 map_reset

    $rf->map_reset;

Resets the mapping between logical and physical registers.

=head2 map

    $rf->map($logical => $physical);

Maps the logical register to a physical register.

=head2 get_physical

    my SIRTX::VM::Register $register = $rf->get_physical($physical);

Gets the register by it's physical number.

If the requested register does not exist the method C<die>s.

=head2 get_logical

    my SIRTX::VM::Register $register = $rf->get_logical($logical);

Gets the register by it's logical number.

If the requested register does not exist the method C<die>s.

=head2 get_physical_by_name

    my SIRTX::VM::Register $register = $rf->get_physical_by_name($name);

Gets the register by it's name. The name may be a name for a physical or a logical register.

If the requested register does not exist the method C<die>s.

=head2 get_logical_by_physical

    my $logical = $rf->get_logical_by_physical($physical);

Get the logical register number for a given physical register.

If the requested register is not mapped the method C<die>s.

=head2 register_owner

    my $owner = $rf->register_owner($register);

    $register->register_owner($register, $owner);
    # e.g:
    $register->register_owner($register, SIRTX::VM::Register::OWNER_YOURS());

Gets or sets the register owner.

=head2 register_temperature

    my $temperature = $rf->register_temperature($register);

    $register->register_temperature($register, $temperature);
    # e.g.:
    $register->register_temperature($register, SIRTX::VM::Register::TEMPERATURE_HOT());

Gets or sets the register temperature.

=head2 expand

    my @expanded_names = $rf->expand(@names);

Expands a list of register names. Returns the list of explicit names.

=head2 clone

    my SIRTX::VM::RegisterFile $clone = $rf->clone;

Clones the register file.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
