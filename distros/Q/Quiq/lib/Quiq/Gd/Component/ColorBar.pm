# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gd::Component::ColorBar - Rechteck mit einem Farbverlauf

=head1 BASE CLASS

L<Quiq::Gd::Component>

=head1 ATTRIBUTES

Fett hervorgehobene Attribute sind Pflichtangaben beim Konstruktor-Aufruf.

=over 4

=item B<< width => $int >> (Default: keiner)

Breite der Grafik in Pixeln.

=item B<< height => $int >> (Default: keiner)

Höhe der Grafik in Pixeln.

=item colors => \@colors (Default: [])

Farben des Farbverlaufs.

=back

=head1 EXAMPLE

Code:

  use Quiq::Gd::Image;
  use Quiq::Gd::Component::ColorBar;
  
  # Konfiguration
  
  my $width = 300;
  my $height = 25;
  my $numColors = 512;
  
  # Grafik-Objekt instantiieren
  
  my $g = Quiq::Gd::Component::ColorBar->new(
      width=>$width,
      height=>$height,
  );
  
  # Bild-Objekt instantiieren
  my $img = Quiq::Gd::Image->new($width,$height);
  
  # Grafik auf Bild zeichnen
  
  $g->render($img,0,0,
      colors=>[$img->rainbowColors($numColors)],
  );

Grafik:

    [Nur im Browser sichtbar]

=cut

# -----------------------------------------------------------------------------

package Quiq::Gd::Component::ColorBar;
use base qw/Quiq::Gd::Component/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

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
        colors => [],
    );
    $self->set(@_);

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
    my $colorA = $self->{'colors'};

    # Zeichnen

    if (!@$colorA) {
        # Keine Farben, nichts zu tun
        return;
    }

    my $w = $width/@$colorA;
    for my $color (@$colorA) {
        $img->filledRectangle($x,$y,$x+$w-1,$y+$height-1,$color);
        $x += $w;
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
