# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gd::Component::BlockDiagram - Farbige Blöcke in einer Fläche

=head1 BASE CLASS

L<Quiq::Gd::Component>

=head1 ATTRIBUTES

Fett hervorgehobene Attribute sind Pflichtangaben beim Konstruktor-Aufruf.

=over 4

=item B<< width => $int >> (Default: keiner)

Breite der Grafik in Pixeln.

=item B<< height => $int >> (Default: keiner)

Höhe der Grafik in Pixeln.

=item xMin => $f (Default: Minimum der X-Werte)

Anfang des X-Wertebereichs (Weltkoodinate).

=item xMax => $f (Default: Maximum der X-Werte)

Ende des X-Wertebereichs (Weltkoodinate).

=item yMin => $f (Default: Minimum der Y-Werte)

Anfang des Y-Wertebereichs (Weltkoodinate).

=item yMax => $f (Default: Maximum der Y-Werte)

Ende des Y-Wertebereichs (Weltkoodinate).

=item yReverse => $bool (Default: 0)

Die Y-Achse geht von oben nach unten statt von unten nach oben,
d.h. die kleineren Werte sind oben.

=item objects => \@objects (Default: [])

Liste der Objekte, die die Blockinformation liefern.

=item objectCallback => $sub

Subroutine, die aus einem Objekt die Block-Information liefert.
Signatur:

  sub {
      my $obj = shift;
      ...
      return ($x,$y,$width,$height,$color);
  }

=back

=head1 EXAMPLE

=begin html

<p class="sdoc-fig-p">
  <img class="sdoc-fig-img" src="https://raw.github.com/s31tz/Quiq/master/img/quiq-gd-component-blockdiagram.png" width="430" height="887" alt="" />
</p>

=end html

=cut

# -----------------------------------------------------------------------------

package Quiq::Gd::Component::BlockDiagram;
use base qw/Quiq::Gd::Component/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Math;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $g = $class->new(@keyVal);

=head4 Description

Instantiiere ein Blockdiagramm-Objekt mit den Eigenschaften @keyVal
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
        xMin => undef,
        xMax => undef,
        yMin => undef,
        yMax => undef,
        yReverse => 0,
        objects => [],
        objectCallback => undef,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Zeichnen

=head3 render() - Zeichne Grafik

=head4 Synopsis

  @blocks | $blockA = $g->render($img);
  @blocks | $blockA = $g->render($img,$x,$y,@keyVal);
  @blocks | $blockA = $class->render($img,$x,$y,@keyVal);

=head4 Returns

Liste der gezeichneten Blöcke. Im Skalarkontext eine Referenz auf
die Liste. Ein Listenelement hat die Komponenten:

  [$obj,$x1,$y1,$x2,$y2]

Ein Element gibt zu jedem Objekt die Pixelkoordinaten des Blocks
im Bild $img an.

=head4 Description

Zeichne die Grafik in Bild $img an Position ($x,$y).

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
    my $xMin = $self->{'xMin'};
    my $xMax = $self->{'xMax'};
    my $yMin = $self->{'yMin'};
    my $yMax = $self->{'yMax'};
    my $yReverse = $self->{'yReverse'};
    my $objectA = $self->{'objects'};
    my $objectCallback = $self->{'objectCallback'};

    # Zeichnen
    
    my $m = Quiq::Math->new;

    my $xFactor = $m->valueToPixelFactor($width,$xMin,$xMax);
    my $yFactor = $m->valueToPixelFactor($height,$yMin,$yMax);

    my @blocks;
    my $black = $img->color('#000000');
    for my $obj (@$objectA) {
        my ($oX,$oY,$oW,$oH,$rgb,$border) = $objectCallback->($obj);

        my $color = $img->color($rgb);

        my $pX = $x+$m->valueToPixelX($width,$xMin,$xMax,$oX);
        my $pY;
        if ($yReverse) {
            $pY = $y+$m->valueToPixelYTop($height,$yMin,$yMax,$oY);
        }
        else {
            $pY = $y+$m->valueToPixelY($height,$yMin,$yMax,$oY);
        }
        my $pW = $oW*$xFactor-1; # -1 -> 1 Pixel Lücke zw. den Blöcken
        my $pH = $oH*$yFactor;

        my ($x1,$y1,$x2,$y2);
        if ($yReverse) {
            ($x1,$y1,$x2,$y2) = (int($pX),int($pY),int($pX+$pW),int($pY+$pH));
        }
        else {
            ($x1,$y1,$x2,$y2) = (int($pX),int($pY-$pH),int($pX+$pW),int($pY));
        }

        $img->filledRectangle($x1,$y1,$x2,$y2,$color);
        if ($border) {
            $img->rectangle($x1,$y1,$x2,$y2,$black);
        }

        push @blocks,[$obj,$x1,$y1,$x2,$y2];
    }

    return wantarray? @blocks: \@blocks;
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
