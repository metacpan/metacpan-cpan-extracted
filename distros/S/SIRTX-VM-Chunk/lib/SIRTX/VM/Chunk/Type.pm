# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for interacting with SIRTX VM chunks


package SIRTX::VM::Chunk::Type;

use v5.16;
use strict;
use warnings;

use Carp;

use parent 'SIRTX::VM::Chunk';

our $VERSION = v0.02;

sub new {
    my ($pkg, @opts) = @_;
    my $self = $pkg->SUPER::new(@opts);
    $pkg->_upgrade($self);
    return $self;
}

sub type {
    my ($self, $n, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;
    croak 'Type is read only' if defined $n;

    return $self->SUPER::type($n, @opts);
}

sub attach_data {
    croak 'Cannot attach raw data on this type of chunk';
}

sub write {
    my ($self, @opts) = @_;
    $self->_render unless $self->{no_render};
    return $self->SUPER::write(@opts);
}

sub read_data {
    my ($self, @opts) = @_;
    $self->_render unless $self->{no_render};
    return $self->SUPER::read_data(@opts);
}

# ---- Private helpers ----

sub _upgrade {
    my ($pkg, $self) = @_;
    bless($self, $pkg);
    $self->SUPER::type($self->_type);
    unless (defined $self->{data}) {
        $self->_create_data;
    }

    local $self->{no_render} = 1;
    $self->_parse;
}

sub _create_data {
    ...;
}

sub _parse {
    ...;
}

sub _render {
    ...;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::VM::Chunk::Type - module for interacting with SIRTX VM chunks

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use SIRTX::VM::Chunk::Type;

(experimental since v0.02)

This package is an internal package.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
