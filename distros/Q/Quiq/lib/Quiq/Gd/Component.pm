# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gd::Component - Basisklasse aller Component-Klassen (abstrakt)

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die von dieser Klasse abgeleiteten Klassen realisieren Grafiken oder
Grafik-Elemente, die mittels GD auf ein Rasterbild gezeichnet werden
können. Dies geschieht in zwei Schritten:

=over 4

=item 1.

Definition der Grafik

=item 2.

Zeichnen der Grafik

=back

Diese Aufteilung hat gegenüber einem direkten Zeichnen den Vorteil,
dass nach Schritt 1 Eigenschaften des Grafik-Objekts abgefragt werden
können, die u.U. schwer zu ermitteln sind, wie z.B. die Breite
und die Höhe. Grafiken mit dynamischen Eigenschaften können dann
leichter zu einem resultierenden Ganzen kombiniert werden.

Beispiel: Eine Plot-Grafik, bestehend aus Graphen, Achsen,
Beschriftungen, einem Gitter usw.

=head2 Systematik

=head3 Definition eines Grafik-Objekts

  $g = $class->new(@keyVal);

=head3 Abfragen von Grafik-Eingenschaften

  $width = $g->width;
  $height = $g->height;
  ...

=head3 Zeichnen der Grafik in ein Bild

  $g->render($img,$x,$y,@keyVal); # $x,$y,@keyVal sind optional

Als Eigenschaften @keyVal können hier Eigenschaften des Bildes $img,
wie z.B. Farben, gesetzt werden. Diese sind u.U. zum Zeitpunkt der
Instantiierung des Grafik-Objektes noch nicht verfügbar.

=head3 Unmittelbares Zeichnen

  $class->render($img,$x,$y,@keyVal);

Ein unmittelbares Zeichnen ist auch möglich, indem die Methode C<render()>
als Klassenmethode unter Angabe aller Eigenschaften @keyVal des
Grafik-Objekts aufgerufen wird.

=cut

# -----------------------------------------------------------------------------

package Quiq::Gd::Component;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 self() - Liefere Instanz

=head4 Synopsis

  $self = $this->self(@keyVal);

=head4 Description

Liefere die Referenz auf das Grafik-Objekt. Die Methode
self() wird in den render()-Methoden der abgeleiteten Klassen
genutzt. Denn diese können sowohl als Objekt- wie auch als
Klassenmethode aufgerufen werden. Die Methode sorgt dafür, dass
das Objekt im Falle eines Aufrufs als Klassenmethode mit den
Attributen @keyVal instantiiert wird. Andernfalls werden die
Attribute auf dem bestehenden Objekt gesetzt.

Das Gerüst der Methode render() in den abgeleiteten Klassen sieht
unter Verwendung der Methode self() so aus:

  sub render {
      my $this = shift;
      my $img = shift;
      my $x = shift || 0;
      my $y = shift || 0;
      # @_: @keyVal
  
      my $self = $this->self(@_);
  
      # Grafik rendern
      ...
  
      return;
  }

=cut

# -----------------------------------------------------------------------------

sub self {
    my $this = shift;
    # @_: @keyVal

    my $self;
    if (ref $this) {
        # Das Objekt ist bereits instantiiert. Wir setzen die angegebenen
        # Attribute, falls vorhanden.

        $self = $this;
        $self->set(@_);
    }
    else {
        # Wir instantiieren das Objekt mit den angegebenen Attributen
        $self = $this->new(@_);
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 width() - Breite der Grafik

=head4 Synopsis

  $width = $g->width;

=head4 Description

Liefere die Breite der Grafik. Diese Basisklassenmethode liefert den
Wert des Attributs C<width>.

=cut

# -----------------------------------------------------------------------------

sub width {
    return shift->{'width'};
}

# -----------------------------------------------------------------------------

=head3 height() - Höhe der Grafik

=head4 Synopsis

  $height = $g->height;

=head4 Description

Liefere die Höhe der Grafik. Muss die Höhe berechnet werden,
überschreibt die Subklasse die Methode.

=cut

# -----------------------------------------------------------------------------

sub height {
    return shift->{'height'};
}

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
