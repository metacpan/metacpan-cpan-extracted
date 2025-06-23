# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gd::Component::ColorLegend - Legende zu einem Farb-Plot

=head1 BASE CLASS

L<Quiq::Gd::Component>

=head1 DESCRIPTION

Grafischer Aufbau der Legende:

    [SVG kann nicht in POD eingebettet werden]

=head1 ATTRIBUTES

=over 4

=item width => $int (Default: keiner)

Breite der Legende in Pixeln.

=item axisColor => $color (Default: keiner)

Farbe der Achse, also der Linie und der Ticks.

=item colors => \@colors (Default: [])

Array der Farben.

=item min => $float (Default: keiner)

Kleinster Wert des Wertebereichs.

=item max => $float (Default: keiner)

Größter Wert des Wertebereichs.

=item logarithmic => $bool (Default: 0)

Die Skala erhält eine logarithmische Einteilung (Basis 10).

=item labelColor => $color (Default: keiner)

Farbe der Beschriftung.

=item labelFont => $font (Default: keiner)

Font für die Beschriftung.

=item blockWidth => $int (Default: keiner)

Breite der Überschreitungsblöcke in Pixeln. Hat nur eine Bedeutung, wenn
C<ltColor> und/oder C<gtColor> definiert sind.

=item blockHeight => $int (Default: keiner)

Höhe der Farbblöcke in Pixeln.

=item blockGap => $int (Default: keiner)

Lücke zwischen den Farbblöcken in Pixeln. Hat nur eine Bedeutung, wenn
C<blockLtColor> und/oder C<blockGtColor> definiert sind.

=item blockLtColor => $color (Default: keiner)

Farbe des Blocks, der die Werte, die I<min> unterschreiten, repräsentiert.

=item blockGtColor => $color (Default: keiner)

Farbe des Blocks, der die Werte, die I<max> überschreiten, repräsentiert.

=item title => $str (Default: undef)

Titel (optional).

=item titleColor => $color (Default: keiner)

Farbe des Titels.

=item titleFont => $font (Default: keiner)

Font des Titels.

=item titleGap => $int (Default: keiner)

Vertikale Lücke zwischen dem Titel und den Farbblöcken in Pixeln.

=back

=head1 EXAMPLE

Eine Farblegende mit Titel. Die Höhe des Bildes geben wir nicht vor,
sie richtet sich nach der Höhe der Grafik. Wir ermitteln sie mit
$g->height. Die Farben definieren wir erst beim Rendern, da das Bild
bei der Instantiierung des Grafik-Objekts noch nicht existiert.

  my $width = 400;
  
  my $g = Quiq::Gd::Component::ColorLegend->new(
      title => 'Test',
      titleFont => Quiq::Gd::Font->new('Blob/font/pala.ttf,14'),
      labelFont => Quiq::Gd::Font->new('Blob/font/pala.ttf,10'),
      width => $width,
      min => 0,
      max => 100,
      logarithmic => 0,
      blockWidth => 50,
      blockHeight => 18,
      blockGap => 20,
  );
  
  $img = Quiq::Gd::Image->new($width,$g->height);
  my $white = $img->background('ffffff');
  $img->transparent($white);
  
  $g->render($img,0,0,
      colors => scalar $img->rainbowColors(512),
      blockLtColor => $img->color('000080'),
      blockGtColor => $img->color('ff00ff'),
      titleColor => $img->color('ff00ff'),
      labelColor => $img->color('ff00ff'),
  );

Erzeugte Grafik (der Rahmen ist per CSS hinzugefügt):

    [Bild nur im Browser sichtbar]

=cut

# -----------------------------------------------------------------------------

package Quiq::Gd::Component::ColorLegend;
use base qw/Quiq::Gd::Component/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Axis::Numeric;
use Quiq::Gd::Component::Axis;
use Quiq::Gd::Component::ColorBar;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $g = $class->new(@keyVal);

=head4 Description

Instantiiere die Legende mit den Eigenschaften @keyVal
(s. Abschnitt L<ATTRIBUTES|"ATTRIBUTES">) und liefere eine Referenz auf das Objekt
zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        width => undef,
        axisColor => undef,
        colors => [],
        min => undef,    
        max => undef,
        logarithmic => 0,
        labelColor => undef, 
        labelFont => undef,
        title => undef,
        titleColor => undef,
        titleFont => undef,
        titleGap => 2,
        blockWidth => 0,
        blockHeight => undef,
        blockGap => 0,
        blockLtColor => undef,
        blockGtColor => undef,
        # interne Attribute
        axis => undef,
    );
    $self->set(@_);

    # Instantiiere Achse (brauchen wir für die Höhenbestimmung)

    my ($width,$blockWidth,$blockGap) =
        $self->get(qw/width blockWidth blockGap/);

    my $ax = Quiq::Axis::Numeric->new(
        orientation => 'x',
        font => $self->get('labelFont'),
        length => $width-2*$blockWidth-2*$blockGap,
        min => $self->get('min'),
        max => $self->get('max'),
        logarithmic => $self->get('logarithmic'),
        debug => 0,
    );

    my $g = Quiq::Gd::Component::Axis->new(
       axis => $ax,
    );
    $self->set(axis=>$g);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Zeichnen

=head3 render() - Zeichne Legende

=head4 Synopsis

  $g->render($img,$x,$y,@keyVal);
  $class->render($img,$x,$y,@keyVal);

=head4 Description

Zeichne die Legende in Bild $img an Position ($x,$y).

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

    my $ax = $self->{'axis'};
    my $axisColor = $self->{'axisColor'};
    my $blockWidth = $self->{'blockWidth'};
    my $blockHeight = $self->{'blockHeight'};
    my $blockGap = $self->{'blockGap'};
    my $blockLtColor = $self->{'blockLtColor'};
    my $blockGtColor = $self->{'blockGtColor'};
    my $colorA = $self->{'colors'};
    my $labelColor = $self->{'labelColor'};
    my $labelFont = $self->{'labelFont'};
    my $logarithmic = $self->{'logarithmic'};
    my $min = $self->{'min'};
    my $max = $self->{'max'};
    my $width = $self->{'width'};
    my $title = $self->{'title'};
    my $titleColor = $self->{'titleColor'};
    my $titleFont = $self->{'titleFont'};
    my $titleGap = $self->{'titleGap'};

    # Zeichnen

    # 1. Titel (optional)

    if ($title) {
        $img->stringCentered($titleFont,'h',$x+$width/2,$y,$title,$titleColor);
        $y += $titleFont->stringHeight($title)+$titleGap;
    }

    # 2. Achse

    $ax->set(
        axisColor => $axisColor,
        labelColor => $labelColor,
    );
    $ax->render($img,$x+$blockWidth+$blockGap,$y+$blockHeight-1);

    # 3. Gradient

    my $g = Quiq::Gd::Component::ColorBar->new(
        width => $ax->length,
        height => $blockHeight,
    );
    $g->render($img,$x+$blockWidth+$blockGap,$y,
        colors => $colorA,
    );

    # 4. Blöcke

    $img->filledRectangle($x,$y,$x+$blockWidth-1,$y+$blockHeight-1,
        $blockLtColor);
    $img->filledRectangle($x+$width-$blockWidth,$y,$x+$width-1,
        $y+$blockHeight-1,$blockGtColor);
    $y += $blockHeight-1;

    # 5. Blockbeschriftung

    my ($tickLength,$tickLabelGap) = $ax->get(qw/tickLength tickLabelGap/);
    my $tickOffset = $tickLength+$tickLabelGap+$labelFont->alignTopOffset;

    $img->stringCentered($labelFont,'h',$x+$blockWidth/2,
        $y+$tickOffset,"<$min",$labelColor);
    $img->stringCentered($labelFont,'h',
        $x+$blockWidth+2*$blockGap+$ax->length+$blockWidth/2,
        $y+$tickOffset,">$max",$labelColor);

    return;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 height() - Höhe der Farb-Legende

=head4 Synopsis

  $height = $g->height;

=head4 Description

Liefere die Höhe der Legende. Die Höhe wird aus den Komponenten berechnet.

=cut

# -----------------------------------------------------------------------------

sub height {
    my $self = shift;

    # Attribute

    my $ax = $self->{'axis'};
    my $blockHeight = $self->{'blockHeight'};
    my $title = $self->{'title'};
    my $titleFont = $self->{'titleFont'};
    my $titleGap = $self->{'titleGap'};

    # Höhe berechnen

    my $n = 0;
    if ($title) {
        # Titel-Höhe
        $n += $titleFont->stringHeight($title)+$titleGap;
    }
    $n += $blockHeight; # Block-Höhe
    $n += $ax->height;  # Höhe der X-Achse einschl. Label
    $n += -1;           # da 1 Pixel Überlappung

    return $n;
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
