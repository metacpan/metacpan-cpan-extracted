# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for interacting with SIRTX VM code


package SIRTX::VM::Register;

use v5.16;
use strict;
use warnings;

use Carp;

use parent 'Data::Identifier::Interface::Userdata';

our $VERSION = v0.02;

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

# ---- Private helpers ----

sub _new {
    my ($pkg, %opts) = @_;
    my $self = bless {
        owner       => OWNER_MINE,
        temperature => TEMPERATURE_LUKEWARM,
        %opts,
    }, $pkg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::VM::Register - module for interacting with SIRTX VM code

=head1 VERSION

version v0.02

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

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
