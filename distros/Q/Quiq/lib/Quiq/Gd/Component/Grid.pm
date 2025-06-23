# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gd::Component::Grid - Gitter eines XY-Plot

=head1 BASE CLASS

L<Quiq::Gd::Component>

=head1 DESCRIPTION

Ein Objekt der Klasse definiert ein Gitter für den Hintergrund
(oder Vordergrund, je nach Reihenfolge beim Zeichnen) eines
XY-Plot. Das Gitter besteht aus gepunkteten Linien an den
Haupt-Ticks der X- und der Y-Achse.

=head1 ATTRIBUTES

Fett hervorgehobene Attribute sind Pflicht-Attribute. Sie müssen
beim Konstruktoraufruf immer angegeben werden.

=over 4

=item B<< xAxix => $axis >>

X-Achse (Subklasse von Quiq::Axis).

=item B<< yAxix => $axis >>

Y-Achse (Subklasse von Quiq::Axis).

=item color => $color (Default: '#000000')

Farbe der Gitterlinien.

=back

=head1 EXAMPLE

Code:

  use Quiq::Gd::Image;
  use Quiq::Gd::Component::Grid;
  use Quiq::Axis::Numeric;
  use Quiq::Axis::Time;
  
  my ($width,$height) = (500,200);
  
  # Achsen definieren
  
  my $ax = Quiq::Axis::Numeric->new(
      orientation => 'x',
      font => Quiq::Gd::Font->new('gdSmallFont'),
      length => $width,
      min => 0,
      max => 20,
  );
  my $gAx = Quiq::Gd::Component::Axis->new(
      axis => $ax,
      tickDirection => 'u',
  );
  
  my $ay = Quiq::Axis::Time->new(
      orientation => 'y',
      font => Quiq::Gd::Font->new('gdSmallFont'),
      length => $height,
      min => Quiq::Epoch->new('2019-11-08 08:00:00')->epoch,
      max => Quiq::Epoch->new('2019-11-08 16:00:00')->epoch,
      debug => 0,
  );
  my $gAy = Quiq::Gd::Component::Axis->new(
      axis => $ay,
      reverse => 1,
  );
  
  # Gitter definieren
  
  my $grid = Quiq::Gd::Component::Grid->new(
      xAxis => $ax,
      yAxis => $ay,
      color => '#ff0000',
  );
  
  # Rasterbild erzeugen
  
  my $axHeight = $gAx->height;
  my $ayWidth = $gAy->width;
  
  my $img = Quiq::Gd::Image->new(
      $width + 2*$ayWidth,
      $height + 2*$axHeight,
      # $width,
      # $height,
  );
  $img->background('#ffffff');
  
  # Grid und Achsen zeichnen
  
  $grid->render($img,$ayWidth,$axHeight);
  $gAx->render($img,$ayWidth,$axHeight);
  $gAx->render($img,$ayWidth,$axHeight+$height-1,tickDirection=>'d');
  $gAy->render($img,$ayWidth,$axHeight);
  $gAy->render($img,$ayWidth+$width-1,$axHeight,tickDirection=>'r');

Grafik:

    [Grafik: Gitter eines XY-Plot]

=cut

# -----------------------------------------------------------------------------

package Quiq::Gd::Component::Grid;
use base qw/Quiq::Gd::Component/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use GD ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $g = $class->new(@keyVal);

=head4 Description

Instantiiere ein Grafik-Objekt mit den Eigenschaften @keyVal
(s. Abschnitt L<ATTRIBUTES|"ATTRIBUTES">) und liefere eine Referenz auf das
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        xAxis => undef,
        yAxis => undef,
        color => '#000000',
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Zeichnen

=head3 render() - Zeichne Gitter

=head4 Synopsis

  $g->render($img);
  $g->render($img,$x,$y,@keyVal);
  $class->render($img,$x,$y,@keyVal);

=head4 Description

Zeichne das Gitter in Bild $img an Position ($x,$y).

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

    my ($color,$xAxis,$yAxis) = $self->get(qw/color xAxis yAxis/);

    # Zeichnen

    $color = $img->color($color);

    my $gdTransparent = GD->gdTransparent;
    my $gdStyled = GD->gdStyled;
    $img->setStyle($color,$gdTransparent); # Pixel+Transparent = Punktlinie

    # Grid zur X-Achse

    my $length = $yAxis->length;
    for my $tik ($xAxis->ticks) {
        my $pos = $tik->position;
        $img->line($x+$pos,$y,$x+$pos,$y+$length-1,$gdStyled);
    }

    # Grid zur Y-Achse

    $length = $xAxis->length;
    for my $tik ($yAxis->ticks) {
        my $pos = $tik->position;
        $img->line($x,$y+$pos,$x+$length-1,$y+$pos,$gdStyled);
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

siehe L<BASE CLASS|"BASE CLASS">

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
