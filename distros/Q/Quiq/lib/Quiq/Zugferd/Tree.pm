# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Zugferd::Tree - Operatonen auf ZUGFeRD-Baum

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein ZUGFeRD-Baum ist die Repräsentation von ZUGFeRD-XML in Form einer
Perl-Datenstruktur. Diese Repräsentation wird genutzt, um die XML-Struktur
geeignet bearbeiten zu können.

=cut

# -----------------------------------------------------------------------------

package Quiq::Zugferd::Tree;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.226';

use Quiq::Tree;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $ztr = $class->new($ref);

=head4 Description

Instantiiere einen ZUGFeRD-Baum und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$ref) = @_;
    return bless $ref,$class;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 getMultiElement() - Liefere Mehrfach-Element

=head4 Synopsis

  $ztr = $ztr->getMultiElement($keyPath,$placeholder)

=head4 Arguments

=over 4

=item $keyPath

Pfad zu Array

=item $placeholder

Name des Platzhalters

=back

=head4 Description

Liefere die Struktur, die das erste Element des Arrays iat, das
$keyPath referenziert, und ersetze die Referenz durch den Platzhalter
$placeholder.

=cut

# -----------------------------------------------------------------------------

sub getMultiElement {
    my ($self,$keyPath,$placeholder) = @_;

    my $tree = $self->getDeep($keyPath)->[0];
    $self->setDeep($keyPath,$placeholder);

    return bless $tree,'Quiq::Zugferd::Tree';
}

# -----------------------------------------------------------------------------

=head3 reduceTree() - Reduziere den Baum

=head4 Synopsis

  $ztr->reduceTree;
  $ztr->reduceTree($sub);

=head4 Arguments

=over 4

=item $sub

Referenz auf Subroutine, die unaufgelöste Werte entfernt. Default:

  sub {
      my $val = shift;
      if (defined $val && $val =~ /^__\w+__$/) {
          $val = undef;
      }
      return $val;
  }

=back

=head4 Description

Reduziere den ZUGFeRD-Baum auf ein Minumum, d.h.

=over 2

=item *

Entferne alle Knoten mit unaufgelösten Werten

=item *

Entferne alle leeren Knoten

=back

=cut

# -----------------------------------------------------------------------------

sub reduceTree {
    my ($self,$sub) = @_;

    # Entferne Knoten mit unaufgelösten Werten (Default: ___XXX__ Platzhalter)

    $sub //= Quiq::Tree->setLeafValue($self,sub {
        my $val = shift;
        if (defined $val && $val =~ /^__\w+__$/) {
            $val = undef;
        }
        return $val;
    });

    # Entferne alle leere Knoten
    Quiq::Tree->removeEmptyNodes($self);

    return;
}

# -----------------------------------------------------------------------------

=head3 resolvePlaceholders() - Ersetze Platzhalter

=head4 Synopsis

  $ztr->resolvePlaceholders(@keyVal);

=head4 Arguments

=over 4

=item @keyVal

Liste der Platzhalter und ihrer Werte

=back

=head4 Description

Durchlaufe den ZUGFeRD-Baum rekursiv und ersetze auf den Blattknoten
die Platzhalter durch ihre Werte.

Fehlt einer der Platzhalter (key) im Baum, wird eine Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub resolvePlaceholders {
    my $self = shift;
    # @_: @keyVal

    my %map = @_;
    my %seen; # gesehene Platzhalter
    for my $key (keys %map) {
        $seen{$key} = 0;
    }
    Quiq::Tree->setLeafValue($self,sub {
        my $val = shift; # akt. Knotenwert
        if (defined $val) { # undef-Knoten belassen wir
            if (exists $map{$val}) { # wir haben einen Platzhalter-Knoten
                $seen{$val} = 1;
                my $newVal = $map{$val}; # neuer Wert
                if (defined($newVal) && $newVal ne '') {
                    # Wir setzen den neuen Wert nur, wenn er nicht leer ist
                    return $newVal;
                }
            }
        }
        return undef;
    });

    for my $key (keys %map) {
        if (!$seen{$key}) {
            $self->throw(
                'TREE-00099: Placeholder does not exist',
                Placeholder => $key,
            );
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.226

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
