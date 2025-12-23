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

our $VERSION = '1.233';

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
        hash => Quiq::Hash->new($h),
        read => {}, # Gelesene Elemente
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 add() - Setze Schlüssel/Wert-Paar ohne Exception

=head4 Synopsis

  $ssb->add($key,$val);

=head4 Description

Ist der Schlüssel vorhanden, wird sein Wert gesetzt. Ist er nicht
vorhanden wird er mit dem angegebenen Wert hinzugefügt.

=cut

# -----------------------------------------------------------------------------

sub add {
    my ($self,$key,$val) = @_;

    $self->hash->add($key,$val);

    return;
}

# -----------------------------------------------------------------------------

=head3 concat() - Konkateniere Attributwerte

=head4 Synopsis

  $val = $ssb->concat($sep,@keys);

=head4 Description

Konkateniere die Werte der Attribute @keys mit Trennzeichen $sep zu
einem Wert und liefere diesen zurück. Leere Werte werden übergangen.

=cut

# -----------------------------------------------------------------------------

sub concat {
    my $self = shift;
    my $sep = shift;
    # @_: @keys

    my $val;
    for my $key (@_) {
        if (my $str = $self->get($key)) {
            if ($val) {
                $val .= $sep;
            }
            $val .= $str;
        }
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head3 content() - Inhalt des Blocks

=head4 Synopsis

  $text =  $ssb->content;

=head4 Description

Liefere den Inhalt des Blocks als Text. Die Schlüssel sind alphanumerisch
sortiert.

=cut

# -----------------------------------------------------------------------------

sub content {
    my $self = shift;

    my $h = $self->hash;

    my $text = '';
    for my $key (sort $h->keys) {
        $text .= sprintf "%9s %s\n",$key,$h->{$key};
    }

    return $text;
}

# -----------------------------------------------------------------------------

=head3 set() - Setze Schlüssel/Wert-Paar

=head4 Synopsis

  $ssb->set($key,$val);

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
  $val = $ssb->get($key,$sloppy);

=head4 Arguments

=over 4

=item $key

Schlüssel

=back

=head4 Options

=over 4

=item $sloppy (Default: 0)

Wirf bei Nichtexistenz von $key keine Exception, sondern liefere C<undef>.

=back

=cut

# -----------------------------------------------------------------------------

sub get {
    my ($self,$key,$sloppy) = @_;

    $self->read->{$key} = 1; # Element wurde gelesen

    if ($sloppy) {
        local $@;
        eval {$self->hash->get($key)};
        if ($@) {
            return undef;
        }
    }

    return $self->hash->get($key);
}

# -----------------------------------------------------------------------------

=head3 getFirst() - Liefere ersten Attributwert

=head4 Synopsis

  $val = $ssb->getFirst(@keys);

=head4 Description

Liefere den ersten nichtleeren Wert der Attribute @keys. Attribute, die
nicht existieren, werden übergangen.

=cut

# -----------------------------------------------------------------------------

sub getFirst {
    my $self = shift;
    # @_: @keys

    for my $key (@_) {
        my $val = $self->get($key,1);
        if (defined($val) && $val ne '') {
            return $val;
        }
    }

    return undef;
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

1.233

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
