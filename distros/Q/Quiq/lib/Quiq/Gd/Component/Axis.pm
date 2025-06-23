# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gd::Component::Axis - Achse eines XY-Plot

=head1 BASE CLASS

L<Quiq::Gd::Component>

=head1 SYNOPSIS

Numerische X-Achse definieren:

  $ax = Quiq::Axis::Numeric->new(
      orientation => 'x',
      font => Quiq::Gd::Font->new('gdSmallFont'),
      length => 400,
      min => 0,
      max => 100,
  );

Achsengrafik-Objekt erzeugen:

  $g = Quiq::Gd::Component::Axis->new(axis=>$ax);

Vertikalen Platzbedarf der Achsengrafik ermitteln:

  $height = $g->height;

Achsengrafik in Bild rendern:

  $g->render($img,$x,$y);

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine gezeichnete X- oder Y-Achse
einschließlich Ticks und Labeln. Mit den Methoden C<< $g->width() >>
und C<< $g->height() >> kann der Platzbedarf der Achse ermittelt werden,
I<bevor> sie konkret gezeichnet wird.

=head1 ATTRIBUTES

=over 4

=item axis => $ax (Pflichtargument des Konstruktors)

Referenz auf die Achsen-Definition.

=item axisColor => $color (Default: '000000')

Farbe der Achse.

=item labelColor => $color (Default: Farbe der Achse)

Farbe der Schrift.

=item subTickColor => $color (Default: Farbe der Achse)

Farbe der Sub-Ticks.

=item tickColor => $color (Default: Farbe der Achse)

Farbe der Ticks.

=item tickDirection => $direction (Default: 'd' bei X-Achse, 'l' bei Y-Achse)

Richtung, die die Ticks der Achse sowie die Label gezeichnet werden.
Mögliche Werte bei einer X-Achse: 'u' (up), 'd' (down). Mögliche Werte
bei einer Y-Achse: 'l' (left), 'r' (right).

=item tickLabelGap => $n (Default: 1)

Abstand zwischen Tick und Label.

=item tickLength => $n (Default: 4)

Länge eines beschrifteten Tick.

=back

=head1 EXAMPLES

Quelltext:

  r1-gd-graphic-axis-example

=head2 X-Achse bei verschiedenen Fontgrößen

    [Bild nur im Browser sichtbar]

=head2 Y-Achse bei verschiedenen Fontgrößen

    [Bild nur im Browser sichtbar]

=head2 X-Achse mit logarithmischer Skala

    [Bild nur im Browser sichtbar]

=head2 XY-Diagramm

    [Bild nur im Browser sichtbar]

=cut

# -----------------------------------------------------------------------------

package Quiq::Gd::Component::Axis;
use base qw/Quiq::Gd::Component/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Assert;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $g = $class->new(@keyVal);

=head4 Description

Instantiiere die Grafik einer X- oder Y-Achse mit den
Darstellungseigenschaften @keyVal (s. Abschnitt L<ATTRIBUTES|"ATTRIBUTES">) und
liefere eine Referenz auf das Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        axis => undef,
        axisColor => '000000',
        labelColor => undef,
        reverse => 0,
        subTickColor => undef,
        tickColor => undef,
        tickDirection => undef,
        tickLabelGap => 1,
        tickLength => 4,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Rendern

=head3 render() - Zeichne Achse

=head4 Synopsis

  $g->render($img,$x,$y,@keyVal);
  $class->render($img,$x,$y,@keyVal);

=head4 Description

Zeichne die Achse in Bild $img an Position ($x,$y). Die Postion ($x,$y)
befindet sich am Anfang der jeweiligen Achsenlinie, also an der Position
des Achsen-Minimums.

  Y-Achse
  
  max +
      |
      |
      |
      |($x,$y)
  min x----------+   X-Achse
     min        max

=cut

# -----------------------------------------------------------------------------

sub render {
    my $this = shift;
    my $img = shift;
    my $x = shift;
    my $y = shift;
    # @_: @keyVal

    my $self = $this->self(@_);

    # Attribute

    my ($ax,$axisColor,$labelColor,$reverse,$subTickColor,$tickColor,
        $tickDirection,$tickLabelGap,$tickLength) =
        $self->get(qw/axis axisColor labelColor reverse subTickColor
        tickColor tickDirection tickLabelGap tickLength/);

    $axisColor = $img->color($axisColor);
    if (!defined $labelColor) {
        $labelColor = $axisColor;
    }
    if (!defined $tickColor) {
        $tickColor = $axisColor;
    }
    if (!defined $subTickColor) {
        $subTickColor = $tickColor;
    }

    # Achseninformation

    my $orientation = $ax->get('orientation');
    my $length = $ax->get('length');
    my $fnt = $ax->font;

    # Zeichnen

    # Achsenlinie

    if ($orientation eq 'y') {
        if ($reverse) {
            # Der Achsenursprung liegt immer beim kleinsten Wert, d.h.
            # bei reverse=>1 zeichnen wir die Achse von oben nach unten.
            $img->line($x,$y,$x,$y+$length-1,$axisColor);
        }
        else {
            # Warum $y-1, $y-$length?
            $img->line($x,$y-1,$x,$y-$length,$axisColor);
        }
    }
    else {
        $img->line($x,$y,$x+$length-1,$y,$axisColor);
    }

    # Ticks und Label

    if (!$tickDirection) {
        # Defaultwert tickDirection
        $tickDirection = $orientation eq 'y'? 'l': 'd';
    }
    Quiq::Assert->isEnumValue($tickDirection,[qw/d u l r/]);

    my @ticks = $ax->ticks;
    if (!@ticks) {
        # Keine Tick-Einteilung

        if ($orientation eq 'y') {
            # Noch nicht implementiert
            #$img->stringCentered($fnt,'v',$x-$tickLength-$tik->width-
            #    $tickLabelGap+$fnt->alignRightOffset,
            #    $y-$pos,$tik->label,$labelColor);
        }
        else {
            $img->stringCentered($fnt,'h',$x+($length/2),
                $y+$tickLength+$tickLabelGap+$fnt->alignTopOffset,
                'no ticks',$labelColor);
        }
    }
    for my $tik (@ticks) {
        my $pos = $tik->position;
        if ($orientation eq 'y') {
            # Warum $y-$pos-1?
            my $yPos = $reverse? $y+$pos: $y-$pos-1;
            if ($tickDirection eq 'r') {
                $img->line($x+$tickLength,$yPos,$x+1,$yPos,$tickColor);
                $img->stringCentered($fnt,'v',$x+$tickLength+
                    $tickLabelGap+$fnt->alignLeftOffset,
                    $yPos,$tik->label,$labelColor);
            }
            else { # 'l'
                $img->line($x-$tickLength,$yPos,$x-1,$yPos,$tickColor);
                $img->stringCentered($fnt,'v',$x-$tickLength-$tickLabelGap-
                    $tik->width+1+$fnt->alignRightOffset,
                    $yPos,$tik->label,$labelColor);
            }
        }
        else {
            if ($tickDirection eq 'u') {
                $img->line($x+$pos,$y,$x+$pos,$y-$tickLength,$tickColor);
                $img->stringCentered($fnt,'h',
                    $x+$pos,$y-$tickLength-$tickLabelGap-
                    $fnt->alignTopOffset-$fnt->digitHeight,
                    $tik->label,$labelColor);
            }
            else { # 'd'
                $img->line($x+$pos,$y,$x+$pos,$y+$tickLength,$tickColor);
                $img->stringCentered($fnt,'h',
                    $x+$pos,$y+$tickLength+$tickLabelGap+$fnt->alignTopOffset,
                    $tik->label,$labelColor);
            }
        }
    }

    #my $base = $ax->get('step')->get('base');
    #my $exp = $ax->get('step')->get('exp');
    my $subTickLength = $tickLength-2; # ($base == 1 || $exp < 0? 2: 0);
    for my $tik ($ax->subTicks) {
        my $pos = $tik->position;
        if ($orientation eq 'y') {
            # Warum $y-$pos-1?
            my $yPos = $reverse? $y+$pos: $y-$pos-1;
            if ($tickDirection eq 'r') {
                $img->line($x+$subTickLength,$yPos,$x+1,$yPos,
                    $subTickColor);
            }
            else { # 'l'
                $img->line($x-$subTickLength,$yPos,$x-1,$yPos,
                    $subTickColor);
            }
        }
        else {
            if ($tickDirection eq 'u') {
                $img->line($x+$pos,$y,$x+$pos,$y-$subTickLength,$subTickColor);
            }
            else { # 'd'
                $img->line($x+$pos,$y,$x+$pos,$y+$subTickLength,$subTickColor);
            }
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 length() - Länge der Achse

=head4 Synopsis

  $length = $g->length;

=head4 Description

Liefere die Länge der Achse (= Achsenlinie) in Pixeln.

=cut

# -----------------------------------------------------------------------------

sub length {
    return shift->get('axis')->get('length');
}

# -----------------------------------------------------------------------------

=head3 width() - Breite der Achsen-Grafik

=head4 Synopsis

  $width = $g->width;

=head4 Description

Liefere die Gesamt-Breite der Achsen-Grafik in Pixeln. Im Falle
einer X-Achse kann die Achsen-Grafik wegen überstehender Label-Texte
links und rechts breiter sein als die Länge der Achse.

=cut

# -----------------------------------------------------------------------------

sub width {
    my $self = shift;

    # Attribute

    my ($ax,$tickLength,$tickLabelGap) =
        $self->get(qw/axis tickLength tickLabelGap/);
    my $orientation = $ax->get('orientation');

    # Breite berechnen

    if ($orientation eq 'y') {
        my $fnt = $ax->font;

        my $fac = $fnt->isTrueType? 1.5: 2; # Heuristik

        my $n = 1;                          # Dicke Achsenlinie
        $n += $tickLength;                  # Länge Tick
        $n += $tickLabelGap;                # Abstand zw. Tick und Label
        $n -= $fac*$fnt->alignRightOffset;  # Korrektur überstehnende Label
        $n += $ax->width;
        return $n;
    }
    else { # X-Achse
        $self->throw('Not implemented');
    }

    # not reached
}

# -----------------------------------------------------------------------------

=head3 height() - Höhe der Achsen-Grafik

=head4 Synopsis

  $height = $g->height;

=head4 Description

Liefere die Gesamt-Höhe der Achsen-Grafik in Pixeln. Im Falle
einer Y-Achse kann die Achsen-Grafik wegen überstehender Label-Texte
oben und unten höher sein als die Länge der Achse.

=cut

# -----------------------------------------------------------------------------

sub height {
    my $self = shift;

    # Attribute

    my ($ax,$tickLength,$tickLabelGap) =
        $self->get(qw/axis tickLength tickLabelGap/);
    my $orientation = $ax->get('orientation');

    # Höhe berechnen

    if ($orientation eq 'y') {
        $self->throw('Not implemented');
    }
    else { # X-Achse
        my $fnt = $ax->font;
        my $min = $ax->get('min');

        my $fac = $fnt->isTrueType? 1: 2; # Heuristik

        my $n = 1;                       # Dicke Achsenlinie
        $n += $tickLength;               # Länge Tick
        $n += $tickLabelGap;             # Abstand zw. Tick und Label
        $n += $fac*$fnt->alignTopOffset; # Korrektur-Offset
        $n += $ax->height;               # Höhe Label
        return $n;
    }

    # not reached
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
