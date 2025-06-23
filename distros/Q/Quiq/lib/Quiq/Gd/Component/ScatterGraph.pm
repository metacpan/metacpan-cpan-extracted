# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gd::Component::ScatterGraph - Farbpunkte in einer Fläche

=head1 BASE CLASS

L<Quiq::Gd::Component::Graph>

=head1 DESCRIPTION

Die Klasse erweitert die Basisklasse Quiq::Gd::Component::Graph um
eine Z-Komponente. Die Werte dieser Komponente werden in Farbwerte
übersetzt und in den Positionen der X,Y-Komponenten abgetragen.

=head1 ATTRIBUTES

Weitere Attribute sind in der Basisklassen-Dokumentation beschrieben.

=over 4

=item z => \@z (Default: [])

Array der Z-Werte (Weltkoordinate).

=item zMin => $float (Default: Minimum der Z-Werte)

Anfang des Z-Wertebereichs (Weltkoodinate).

=item zMax => $float (Default: Maximum der Z-Werte)

Ende des Z-Wertebereichs (Weltkoodinate).

=item zLogarithmic => $bool (Default: 0)

Bilde den Z-Wertebereich logarithmisch auf die Farbwerte ab.

=item lowColor => $color (Default: undef)

Farbe für Z-Werte, die zMin unterschreiten.

=item highColor => $color (Default: undef)

Farbe für Z-Werte, die zMax überschreiten.

=back

=head1 EXAMPLE

Code:

  use Quiq::Gd::Image;
  use Quiq::Gd::Component::ScatterGraph;
  
  # Konfiguration
  
  my $width = 200;
  my $height = 200;
  my $numColors = 128;
  my $pointSize = 10;
  
  # Zufallsdaten erzeugen
  
  my (@x,@y,@z);
  for (1 .. 300) {
      push @x,int rand 100;
      push @y,int rand 100;
      push @z,int rand 128;
  }
  
  # Grafik-Objekt instantiieren
  
  my $g = Quiq::Gd::Component::ScatterGraph->new(
      width=>$width,
      height=>$height,
      pointSize=>$pointSize,
      pointStyle=>'circle',
      adaptPlotRegion=>1,
      x=>\@x,
      y=>\@y,
      z=>\@z,
      lineThickness=>0,
  );
  
  # Bild-Objekt instantiieren
  
  my $img = Quiq::Gd::Image->new($width,$height);
  $img->background('ffffff');
  $img->border('a0a0a0');
  
  # Grafik auf Bild zeichnen
  
  $g->render($img,0,0,
      colors=>[$img->rainbowColors($numColors)],
      lowColor=>$img->color('003366'),
      highColor=>$img->color('ff00ff'),
  );

Grafik:

    [Nur im Browser sichtbar]

=cut

# -----------------------------------------------------------------------------

package Quiq::Gd::Component::ScatterGraph;
use base qw/Quiq::Gd::Component::Graph/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Option;
use Quiq::Array;
use POSIX ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $g = $class->new(@keyVal);

=head4 Description

Instantiiere ein Grafik-Objekt mit den Eigenschaften @keyVal
(s. Abschnitt L<ATTRIBUTES|"ATTRIBUTES">) und liefere eine Referenz auf das Objekt
zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $opt = Quiq::Option->extract(-properties=>1,-mode=>'sloppy',\@_,
        z => [],
        zMin => undef,
        zMax => undef,
        zLogarithmic => 0,
        lowColor => undef,
        highColor => undef,
    );        
    my $self = $class->SUPER::new(@_);
    $self->add(%$opt);

    # Z-Minimum und Z-Maximum  berechnen, falls nicht angegeben.
    # Dies müssen wir im Konstruktor machen, damit die Objektmethoden
    # zMin() und zMax() korrekte Wert liefern.

    my $zMin = $self->{'zMin'};
    my $zMax = $self->{'zMax'};

    if (!defined $zMin) {
        $zMin = Quiq::Array->min($self->{'z'}) // 0;
    }
    if (!defined $zMax) {
        $zMax = Quiq::Array->max($self->{'z'}) // 0;
    }
    if ($zMin == $zMax) {
        $zMin -= 1;
        $zMax += 1;
    }

    $self->{'zMin'} = $zMin;
    $self->{'zMax'} = $zMax;

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Zeichnen

=head3 render() - Zeichne Grafik

=head4 Synopsis

  $g->render($img);
  $g->render($img,$x,$y,@keyVal);
  $class->render($img,$x,$y,@keyVal);

=head4 Description

Zeichne die Grafik in Bild $img an Position ($x,$y).
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub render {
    my $this = shift;
    my $img = shift;
    my $x = shift || 0;
    my $y = shift || 0;
    # @_: @keyVal

    my $self = $this->self(@_);

    # Attribute

    my $zA = $self->{'z'};
    my $zMin = $self->{'zMin'};
    my $zMax = $self->{'zMax'};
    my $zLogarithmic = $self->{'zLogarithmic'};
    my $colorA = $self->{'colors'};
    my $lowColor = $self->{'lowColor'};
    my $highColor = $self->{'highColor'};

    # Daten für das Rendern durch die Basisklasse aufbereiten

    my $min = $zLogarithmic? POSIX::log10($zMin): $zMin;
    my $max = $zLogarithmic? POSIX::log10($zMax): $zMax;

    my @c;
    for (@$zA) {
        my $z = $zLogarithmic? POSIX::log10($_): $_;

        my $c;
        if ($z < $min) {
            $c = $lowColor;
        }
        elsif ($z > $max) {
            $c = $highColor;
        }
        else {
            my $i = Quiq::Math->valueToPixel(scalar(@$colorA),$min,$max,$z);
            $c = $colorA->[$i];
        }
        push @c,$c;
    }

    # Zeichnen (übernimmt die Basisklasse)

    $self->SUPER::render($img,$x,$y,
        colors => \@c,
    );

    return;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 zMin() - Minimum des Z-Wertebereichs

=head4 Synopsis

  $zMin = $g->zMin;

=head4 Description

Liefere das Minimum des Z-Wertebereichs, das entweder beim
Konstruktoraufruf gesetzt oder aus den Daten ermittelt wurde.

=cut

# -----------------------------------------------------------------------------

sub zMin {
    return shift->{'zMin'};
}

# -----------------------------------------------------------------------------

=head3 zMax() - Maximum des Z-Wertebereichs

=head4 Synopsis

  $zMax = $g->zMax;

=head4 Description

Liefere das Maximum des Z-Wertebereichs, das entweder beim
Konstruktoraufruf gesetzt oder aus den Daten ermittelt wurde.

=cut

# -----------------------------------------------------------------------------

sub zMax {
    return shift->{'zMax'};
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
