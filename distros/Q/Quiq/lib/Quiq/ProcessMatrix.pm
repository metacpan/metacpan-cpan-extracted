package Quiq::ProcessMatrix;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.162';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ProcessMatrix - Matrix von zeitlichen Vorgängen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ordne eine Menge von zeitlichen Vorgängen (z.B. gelaufene Prozesse)
in einer Matrix an. Finden Vorgänge parallel statt, hat die Matrix
mehr als eine Kolumne.

=head2 Algorithmus

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $mtx = $class->new(\@objects,$beginMethod,$endMethod);

=head4 Arguments

=over 4

=item @objects

Liste von nicht näher bestimmten Objekten. Jedes Objekt ist durch
einen Anfangszeitpunkt und einen Endezeitpunkt gekennzeichnet,
beides in Unix Epoch.

=item $beginMethod

Name der Objektmethode, die den Anfangszeitpunkt (Unix Epoch) liefert.

=item $endMethod

Name der Objektmethode, die den Endezeitpunkt (Unix Epoch) liefert.

=back

=head4 Returns

Matrix-Objekt

=head4 Description

Instantiiere ein Matrix-Objekt für die Vorgänge @objects mit den
Methoden $beginMethod und $endMethod und liefere eine Referenz
auf dieses Objekt zurück.

B<Algorithmus>

=over 4

=item 1.

Die Objekte @objects werden nach Anfangszeitpunkt aufsteigend sortiert.

=item 2.

Eine leere Liste von Zeitschienen wird erzeugt.

=item 3.

Es wird über die Objekte iteriert. Das aktuelle Objekt wird zu der
ersten Zeitschiene hinzugefügt, die "frei" ist. Eine Zeitschiene
ist frei, wenn sie leer ist oder das letzte Element beendet ist und
die Anfangszeitpunkt des Objektes nicht belegt.

=back

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$objectA,$begin,$end) = @_;

    my @columns;
    for my $obj (sort {$a->$begin <=> $b->$begin} @$objectA) {
        for (my $i = 0; $i <= @columns; $i++) {
            if ($columns[$i] && $obj->$begin < $columns[$i]->[-1]->$end) {
                next;
            }
            push @{$columns[$i]},$obj;
            last;
        }
    }

    return $class->SUPER::new(
        columns => \@columns,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 width() - Breite der Matrix

=head4 Synopsis

  $width = $mtx->width;

=head4 Returns

Integer

=head4 Description

Liefere die Anzahl der Kolumnen der Matrix.

=cut

# -----------------------------------------------------------------------------

sub width {
    return scalar @{shift->{'columns'}};
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.162

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
