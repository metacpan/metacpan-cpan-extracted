# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::StreamServe::Block - Inhalt eines StreamServe Blocks

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert den Inhalt eines StreamServe-Blocks,
also eine Menge von Schlüssel/Wert-Paaren eines Typs (der durch den
gemeinsamen Namenspräfix gegeben ist).

=cut

# -----------------------------------------------------------------------------

package Quiq::StreamServe::Block;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Hash;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $ssb = $class->new($prefix);
  $ssb = $class->new($prefix,$h);

=head4 Arguments

=over 4

=item $prefix

Block-Präfix

=item $h (Default: {})

Hash mit den Schlüssel/Wert-Paaren des Blocks

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$prefix) = splice @_,0,2;
    my $h = shift // {};

    return $class->SUPER::new(
        prefix => $prefix,
        hash => Quiq::Hash->new($h)->unlockKeys,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektnmethoden

=head3 set() - Setze Schlüssel/Wert-Paar

=head4 Synopsis

  $ssb = $class->set($key,$val);

=cut

# -----------------------------------------------------------------------------

sub set {
    my ($self,$key,$val) = @_;

    $self->hash->set($key,$val);
    return;
}

# -----------------------------------------------------------------------------

=head3 get() - Liefere Wert eines Schlüssels

=head4 Synopsis

  $val = $ssb->get($key);

=cut

# -----------------------------------------------------------------------------

sub get {
    my ($self,$key) = @_;

    return $self->hash->get($key);
}

# -----------------------------------------------------------------------------

=head3 prefix() - Liefere Präfix

=head4 Synopsis

  $prefix = $ssb->prefix;

=cut

# -----------------------------------------------------------------------------

# Attributmethode

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
