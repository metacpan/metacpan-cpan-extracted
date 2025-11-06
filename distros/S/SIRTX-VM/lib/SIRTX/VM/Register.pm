# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for interacting with SIRTX VM code


package SIRTX::VM::Register;

use v5.16;
use strict;
use warnings;

use Carp;

use parent 'Data::Identifier::Interface::Userdata';

our $VERSION = v0.10;

use constant {
    TYPE_USER               => 'user',
    TYPE_SYSTEM             => 'system',

    OWNER_MINE              => 'mine',
    OWNER_YOURS             => 'yours',
    OWNER_THEIRS            => 'theirs',

    TEMPERATURE_HOT         => 'hot',
    TEMPERATURE_COLD        => 'cold',
    TEMPERATURE_LUKEWARM    => 'lukewarm',
};


sub physical {
    my ($self) = @_;
    return $self->{physical};
}


sub name {
    my ($self) = @_;
    return $self->{name};
}


sub owner {
    my ($self, $n) = @_;
    $self->{owner} = $n if defined $n;
    return $self->{owner};
}


sub temperature {
    my ($self, $n) = @_;
    $self->{temperature} = $n if defined $n;
    return $self->{temperature};
}


sub clone {
    my ($self) = @_;
    return __PACKAGE__->_new(%{$self});
}

# ---- Private helpers ----

sub _new {
    my ($pkg, %opts) = @_;
    my $self = bless {
        owner       => OWNER_MINE,
        temperature => TEMPERATURE_LUKEWARM,
        %opts,
    }, $pkg;
}

# ---- Docs for constants ----


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::VM::Register - module for interacting with SIRTX VM code

=head1 VERSION

version v0.10

=head1 SYNOPSIS

    use SIRTX::VM::Register;

This package inherits from L<Data::Identifier::Interface::Userdata>.

=head1 METHODS

=head2 physical

    my $physical = $register->physical;

Returns the physical number of the register.

=head2 name

    my $name = $register->name;

Returns the name of the register.

=head2 owner

    my $owner = $register->owner;

    $register->owner($owner);
    # e.g:
    $register->owner(SIRTX::VM::Register::OWNER_YOURS());

Gets or sets the register owner.

=head2 temperature

    my $temperature = $register->temperature;

    $register->temperature($temperature);
    # e.g.:
    $register->temperature(SIRTX::VM::Register::TEMPERATURE_HOT());

Gets or sets the register temperature.

=head2 clone

    my SIRTX::VM::Register $clone = $register->clone;

Clones the register.

=head1 CONSTANTS

=head2 Type

Each register has a type, which is a read only property. The following values are supported:

=over

=item C<SIRTX::VM::Register::TYPE_USER()>

The register is a user register.
It's meaning is defined by the user/application.

=item C<SIRTX::VM::Register::TYPE_SYSTEM()>

The register is a system register.
It's meaning is defined by the formal specification and must not be used in any other way.

=back

=head2 Owner

Each register has a owner. The owner is a read-write property that defines who currently owns the register.

=over

=item C<SIRTX::VM::Register::OWNER_MINE()>

The register is owned by the user/application.
The application may use the register anyway it pleases.

This is the default.

=item C<SIRTX::VM::Register::OWNER_YOURS()>

The register is currently owned by the assembler. The assembler is free to use the register as sees fit.
The user/application is not allowed to alter the content of the register (unless specifically documented).

=item C<SIRTX::VM::Register::OWNER_THEIRS()>

The register is owned by external code (such as a library).
Both user/application and assembler are not allowed to alter the register.

=back

=head2 Temperature

The register temperature tells how much a register is currently used.
This is a read-write property.
This is used by the assembler to optimise code.

=over

=item C<SIRTX::VM::Register::TEMPERATURE_COLD()>

The register is currently not or only rarely used.

=item C<SIRTX::VM::Register::TEMPERATURE_LUKEWARM()>

The register is used sometimes.

This is the default.

=item C<SIRTX::VM::Register::TEMPERATURE_HOT()>

The register is currently in active use.

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
