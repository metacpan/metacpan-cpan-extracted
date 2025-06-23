# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gd::Component::Graph - Polyline-Graph

=head1 BASE CLASS

L<Quiq::Gd::Component>

=head1 DESCRIPTION

Das Objekt repräsentiert einen Graph entlang der Weltkoordinaten @x und @y.
Per Default wird der Graph über der gesamten Fläche des Bildes gezeichnet.
Durch die Angabe C<< colors=>\@colors >> kann als dritte Dimension ein Farbwert
entlang des Graphen gezeichnet werden. Punkte und Linien werden in diesen
Farben gezeichnet, sofern per (C<pointColor>) oder (C<lineColor>) nichts
anderes vorgegeben ist.

=head1 ATTRIBUTES

Fett hervorgehobene Attribute sind Pflichtangaben beim Konstruktor-Aufruf.

=over 4

=item B<< width => $int >> (Default: keiner)

Breite der Grafik in Pixeln.

=item B<< height => $int >> (Default: keiner)

Höhe der Grafik in Pixeln.

=item x => \@x (Default: [])

Array der X-Werte (Weltkoordinate).

=item y => \@y (Default: [])

Array der Y-Werte (Weltkoordinate).

=item colors => \@colors (Default: undef)

Farben der Datenpunkte und Linien. Jeder Datenpunkt und jede
Verbindungslinie hat eine eigene Farbe. Siehe Beispiel
L<Graph mit verschiedenfarbigen Datenpunkten und Linien|"Graph mit verschiedenfarbigen Datenpunkten und Linien">.

=item lineColor => $color (Default: Defaultfarbe)

Farbe der Verbindungslinien. FIMXE: Verhältnis zu Attribut colors
beschreiben.

=item lineThickness => $n (Default: 1)

Dicke der Verbindungsline in Pixeln. Wenn 0, wird keine Linie gezeichnet.

=item xMin => $f (Default: Minimum der X-Werte)

Anfang des X-Wertebereichs (Weltkoodinate).

=item xMax => $f (Default: Maximum der X-Werte)

Ende des X-Wertebereichs (Weltkoodinate).

=item yMin => $f (Default: Minimum der Y-Werte)

Anfang des Y-Wertebereichs (Weltkoodinate).

=item yMax => $f (Default: Maximum der Y-Werte)

Ende des Y-Wertebereichs (Weltkoodinate).

=item xMaxDelta => $f (Default: undef)

Maximaler Abstand zwischen zwei benachbarten Punkten in X-Richtung.
Wird dieser Abstand überschritten, werden die Punkte nicht
durch eine Linie verbunden.

=item yMaxDelta => $f (Default: undef)

Wie C<xMaxDelta>, nur in Y-Richtung.

=item pointColor => $color (Default: Defaultfarbe)

Farbe, in der alle Datenpunkte gezeichnet werden.

=item pointSize => $n (Default: 1)

Größe des Punktes in Pixeln. Der Punkt wird gemäß C<pointStyle>
dargestellt. Der Wert sollte ungerade sein: 1, 3, 5, usw., damit
die Darstellung mittig über dem Datenpunkt stattfindet.

=item pointStyle => $style (Default: 'square')

Darstellung des Punktes: 'square', 'circle'.

=item adaptPlotRegion => $bool (Default: 0)

Ist die Punktgröße > 1 (s. Attribut C<pointSize>), erweitere den
Plotbereich (Attribute C<xMin>, C<xMax>, C<yMin>, C<yMax>) derart,
dass die Datenpunkte auch am Rand vollständig gezeichnet werden.

=back

=head1 EXAMPLES

=head2 Einfacher Graph

Code:

  require Quiq::Gd::Image;
  require Quiq::Gd::Component::Graph;
  
  my ($width,$height) = (500,100);
  
  $img = Quiq::Gd::Image->new($width,$height);
  $img->background('#ffffff');
  my $g = Quiq::Gd::Component::Graph->new(
      width=>$width,
      height=>$height,
      x=>[0, 1, 2,   3, 4,   5, 6, 7,   8,   9],
      y=>[0, 9, 7.5, 1, 1.9, 6, 4, 6.3, 0.5, 10],
  );
  $g->render($img);

Im Browser:

    [Nur im Browser sichtbar]

=head2 Graph mit gekennzeichneten Datenpunkten

Code:

  require Quiq::Gd::Image;
  require Quiq::Gd::Component::Graph;
  
  my ($width,$height) = (500,100);
  
  $img = Quiq::Gd::Image->new($width,$height);
  $img->background('#ffffff');
  $img->border('#d0d0d0');
  
  my $g = Quiq::Gd::Component::Graph->new(
      width=>$width,
      height=>$height,
      x=>[0, 1, 2,   3, 4,   5, 6, 7,   8,   9],
      y=>[0, 9, 7.5, 1, 1.9, 6, 4, 6.3, 0.5, 10],
      pointColor=>'#ff0000',
      pointSize=>5,
  );
  $g->render($img);

Im Browser:

    [Nur im Browser sichtbar]

Wir setzen die Punktfarbe und die Punktgröße. Die Endpunkte sind
abgeschnitten, da ein Teil von ihnen außerhalb des Bildes liegt.

=head2 Graph mit verschiedenfarbigen Datenpunkten und Linien

Code:

  require Quiq::Gd::Image;
  require Quiq::Gd::Component::Graph;
  
  my ($width,$height) = (504,104);
  
  $img = Quiq::Gd::Image->new($width,$height);
  $img->background('#ffffff');
  $img->border('#d0d0d0');
  
  my $g = Quiq::Gd::Component::Graph->new(
      width=>$width-4,
      height=>$height-4,
      x=>[0, 1, 2,   3, 4,   5, 6, 7,   8,   9],
      y=>[0, 9, 7.5, 1, 1.9, 6, 4, 6.3, 0.5, 10],
      colors=>[
          '#ff0000',
          '#00ff00',
          '#0000ff',
          '#ffff00',
          '#ff00ff',
          '#00ffff',
          '#000000',
          '#808000',
          '#800080',
          '#008080',
      ],
      pointSize=>5,
  );
  $g->render($img,2,2);

Im Browser:

    [Nur im Browser sichtbar]

Wenn Eigenschaft C<colors> definiert ist, werden die Punkte und
Verbindungslinien in den angegebenen Farben dargestellt.
Die Linie hat die Farbe des Anfangspunktes, der letzte Punkt
hat keine Verbindungsline. Mit C<pointColor> oder C<lineColor>
kann die Punkt- oder Linienfarbe auf eine bestimmte Farbe
festgelegt werden (beide im Falle von C<colors> fix
einzustellen, macht wenig Sinn, denn dann hat C<colors> keinen
Effekt mehr). Die Endpunkte sind hier im Gegensatz zum
vorigen Beispiel vollständig dargestellt, da wir das Bild um 4 Pixel
breiter und höher gemacht haben als den Plotbereich.

=head2 Größe Plotregion anpassen mit adaptPlotRegion

Code:

  require Quiq::Gd::Image;
  require Quiq::Gd::Component::Graph;
  
  my ($width,$height) = (504,104);
  
  $img = Quiq::Gd::Image->new($width,$height);
  $img->background('#ffffff');
  $img->border('#d0d0d0');
  
  my $g = Quiq::Gd::Component::Graph->new(
      width=>$width,
      height=>$height,
      pointSize=>5,
      adaptPlotRegion=>1,
      x=>[0, 1, 2,   3, 4,   5, 6, 7,   8,   9],
      y=>[0, 9, 7.5, 1, 1.9, 6, 4, 6.3, 0.5, 10],
      colors=>[
          '#ff0000',
          '#00ff00',
          '#0000ff',
          '#ffff00',
          '#ff00ff',
          '#00ffff',
          '#000000',
          '#808000',
          '#800080',
          '#008080',
      ],
  );
  $g->render($img);

Im Browser:

    [Nur im Browser sichtbar]

Mit C<adaptPlotRegion> wird der Plotbereich so verkleinert, dass
Punkte am Rand vollständig sichtbar sind.

=cut

# -----------------------------------------------------------------------------

package Quiq::Gd::Component::Graph;
use base qw/Quiq::Gd::Component/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Array;
use Quiq::Math;

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

    my $self = $class->SUPER::new(
        width => undef,
        height => undef,
        x => [],
        y => [],
        colors => undef,
        lineColor => undef,
        lineThickness => 1,
        xMin => undef,
        xMax => undef,
        yMin => undef,
        yMax => undef,
        xMaxDelta => undef,
        yMaxDelta => undef,
        pointColor => undef,
        pointSize => 1,
        pointStyle => 'square',
        adaptPlotRegion => 0,
    );
    $self->set(@_);

    # Pflicht-Attribute prüfen

    for my $key (qw/width height/) {
        if (!defined $self->{$key}) {
            $self->throw(
                'GRAPHIC-00001: Pflicht-Attribut ist nicht gesetzt',
                Attribute => $key,
            );
        }
    }

    # Defaultwerte berechnen, die wir im Konstruktor berechnen müssen,
    # damit die Objektmethoden (xMin(), ...) korrekte Wert liefern.

    my $xMin = $self->{'xMin'};
    my $xMax = $self->{'xMax'};
    my $yMin = $self->{'yMin'};
    my $yMax = $self->{'yMax'};

    if (!defined $xMin) {
        $xMin = Quiq::Array->min($self->{'x'}) // 0;
    }
    if (!defined $xMax) {
        $xMax = Quiq::Array->max($self->{'x'}) // 0;
    }
    if (!defined $yMin) {
        $yMin = Quiq::Array->min($self->{'y'}) // 0;
    }
    if (!defined $yMax) {
        $yMax = Quiq::Array->max($self->{'y'}) // 0;
    }
    if ($xMin == $xMax) {
        $xMin -= 1;
        $xMax += 1;
    }
    if ($yMin == $yMax) {
        $yMin -= 1;
        $yMax += 1;
    }

    my $pointSize = $self->{'pointSize'};
    if ($pointSize > 1 && $self->{'adaptPlotRegion'}) {
        # Wertebereich in X- und Y-Richtung erweitern, so dass 
        # Platz für die vollständige Darstellung der Punkte ist

        my $pixel = int($pointSize/2); # zusätzliche Pixel pro Seite

        my $valPerPixelX = ($xMax-$xMin)/($self->{'width'}-2*$pixel);
        $xMin -= $pixel*$valPerPixelX;
        $xMax += $pixel*$valPerPixelX;

        my $valPerPixelY = ($yMax-$yMin)/($self->{'height'}-2*$pixel);
        $yMin -= $pixel*$valPerPixelY;
        $yMax += $pixel*$valPerPixelY;
    }

    $self->{'xMin'} = $xMin;
    $self->{'xMax'} = $xMax;
    $self->{'yMin'} = $yMin;
    $self->{'yMax'} = $yMax;

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

    my $width = $self->{'width'};
    my $height = $self->{'height'};
    my $xA = $self->{'x'};
    my $yA = $self->{'y'};
    my $colorA = $self->{'colors'};
    my $lineColor = $self->{'lineColor'};
    my $lineThickness = $self->{'lineThickness'};
    my $xMin = $self->{'xMin'};
    my $xMax = $self->{'xMax'};
    my $yMin = $self->{'yMin'};
    my $yMax = $self->{'yMax'};
    my $xMaxDelta = $self->{'xMaxDelta'};
    my $yMaxDelta = $self->{'yMaxDelta'};
    my $pointColor = $self->{'pointColor'};
    my $pointSize = $self->{'pointSize'};
    my $pointStyle = $self->{'pointStyle'};

    # Zeichnen

    if (@$xA == 0) {
        # Keine Daten, nichts tun
        return;
    }

    # Farben

    if (defined $lineColor || !$colorA) {
        $lineColor = $img->color($lineColor);
    }
    if (defined $pointColor || !$colorA) {
        $pointColor = $img->color($pointColor);
    }

    # Weltkoordinaten in Pixelkoordinaten umrechnen

    my (@x,@y,@c);
    for (my $i = 0; $i < @$xA; $i++) {
        push @x,$x+Quiq::Math->valueToPixelX($width,$xMin,$xMax,
            $xA->[$i]);
        push @y,$y+Quiq::Math->valueToPixelY($height,$yMin,$yMax,
            $yA->[$i]);
        if ($colorA) {
            push @c,$img->color($colorA->[$i]);
        }
    }

    # Einen einzelnen Punkt zeichnen wir als Kreuz

    if (@$xA == 1) {
        my $color = defined $lineColor? $lineColor: $c[0];
        $img->drawCross($x[0],$y[0],$color);
        return;
    }

    # Verbindungslinien zeichnen

    if ($lineThickness) {
        $img->setThickness($lineThickness);
        for (my $i = 0; $i < @x-1; $i++) {
            # Prüfe, ob Punkte zu weit auseinander liegen

            if (defined $xMaxDelta &&
                    $xA->[$i+1]-$xA->[$i] > $xMaxDelta) {
                next;
            }
            if (defined $yMaxDelta &&
                    abs($yA->[$i+1]-$yA->[$i]) > $yMaxDelta) {
                next;
            }

            # Zeichne Linie

            my $color = defined $lineColor? $lineColor: $c[$i];
            $img->line($x[$i],$y[$i],$x[$i+1],$y[$i+1],$color);
        }
    }

    # Punkte zeichnen

    if (!$lineThickness || $pointSize > $lineThickness ||
            $pointColor != $lineColor || $colorA) {
        $img->setThickness(1);
        for (my $i = 0; $i < @x; $i++) {
            my $color = defined $pointColor? $pointColor: $c[$i];

            if ($pointSize == 1) {
                $img->setPixel($x[$i],$y[$i],$color);
            }
            elsif ($pointStyle eq 'square') {
                my $e0 = int(($pointSize-1)/2);
                my $e1 = $e0+($pointSize-1)%2;

                $img->filledRectangle(
                    $x[$i]-$e0,$y[$i]-$e0,
                    $x[$i]+$e1,$y[$i]+$e1,
                    $color);
            }
            elsif ($pointStyle eq 'circle') {
                $img->filledArc($x[$i],$y[$i],$pointSize,$pointSize,0,360,
                    $color);
            }
            else {
                $img->throw(
                    'GD-00009: Unbekannte Punkt-Darstellungsart',
                    PointStyle => $pointStyle,
                );
            }
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 xMin() - Minimum des X-Wertebereichs

=head4 Synopsis

  $xMin = $g->xMin;

=head4 Description

Liefere das Minimum des X-Wertebereichs, das entweder beim
Konstruktoraufruf gesetzt oder aus den Daten ermittelt wurde.

=cut

# -----------------------------------------------------------------------------

sub xMin {
    return shift->{'xMin'};
}

# -----------------------------------------------------------------------------

=head3 xMax() - Maximum des X-Wertebereichs

=head4 Synopsis

  $xMax = $g->xMax;

=head4 Description

Liefere das Maximum des X-Wertebereichs, das entweder beim
Konstruktoraufruf gesetzt oder aus den Daten ermittelt wurde.

=cut

# -----------------------------------------------------------------------------

sub xMax {
    return shift->{'xMax'};
}

# -----------------------------------------------------------------------------

=head3 yMin() - Minimum des X-Wertebereichs

=head4 Synopsis

  $yMin = $g->yMin;

=head4 Description

Liefere das Minimum des Y-Wertebereichs, das entweder beim
Konstruktoraufruf gesetzt oder aus den Daten ermittelt wurde.

=cut

# -----------------------------------------------------------------------------

sub yMin {
    return shift->{'yMin'};
}

# -----------------------------------------------------------------------------

=head3 yMax() - Maximum des Y-Wertebereichs

=head4 Synopsis

  $yMax = $g->yMax;

=head4 Description

Liefere das Maximum des Y-Wertebereichs, das entweder beim
Konstruktoraufruf gesetzt oder aus den Daten ermittelt wurde.

=cut

# -----------------------------------------------------------------------------

sub yMax {
    return shift->{'yMax'};
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
