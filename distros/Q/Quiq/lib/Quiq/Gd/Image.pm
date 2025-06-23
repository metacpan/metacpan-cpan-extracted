# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gd::Image - Schnittstelle zur GD Graphics Library

=head1 BASE CLASSES

=over 2

=item *

GD::Image

=item *

L<Quiq::Object>

=back

=head1 SYNOPSIS

  use Quiq::Gd::Image;
  
  my $img = Quiq::Gd::Image->new(100,100);
  $img->background('#ffffff');
  print $img->jpg;

=head1 DESCRIPTION

Die Klasse ist eine Überdeckung der Klasse GD::Image. Sie
überschreibt existierende Methoden und ergänzt die Klasse um
weitere Methoden.  Die Klasse kann überall verwendet werden, wo
GD::Image verwendet wird.  Alle Methoden von GD::Image sind auch
auf Quiq::Gd::Image-Objekte anwendbar.

=head2 Vorteile

Die Klasse Quiq::Gd::Image bietet folgende Vorteile:

=over 2

=item *

Beliebig viele Farben, da alle Bilder per Default TrueColor sind.
Bei GD sind Bilder per Default pallette-basiert mit maximal
256 Farben.

=item *

Die Klasse verfügt mit der Methode string() über eine einheitliche
Schnittstelle zum Zeichnen von GD- und TrueType-Fonts, horizontal
und vertikal. Bei GD werden GD- und TrueType-Fonts uneinheitlich
behandelt.

=item *

Die Methoden der Klasse lösen im Fehlerfall eine Exception aus.

=back

=head2 Unterschiede zwischen Palette-basierten und TrueColor-Bildern

Bei TrueColor liefert die GD-Methode colorAllocate() - mehrfach
für denselben Farbwert aufgerufen - immer den gleichen
Farbindex. Bei einem Palette-Bild wird immer ein neuer Farbindex
geliefert, auch wenn der Farbwert gleich ist. Daher muss aus
portablitätsgründen die GD-Methode colorResolve() genutzt werden.
Diese Portabilität wird von der Methode L<color|"color() - Alloziere Farbe">() sichergestellt.

=head2 Portierung einer existierenden Anwendung

=over 4

=item 1.

Konstruktor-Aufruf ersetzen:

  $img = Quiq::Gd::Image->new($width,$height);

statt

  $img = GD::Image->new($width,$height);

=item 2.

Nach dem Konstruktor-Aufruf die Hintergrundfarbe setzen:

  $white = $img->background(255,255,255);

statt

  $white = $img->colorAllocate(255,255,255);

=item 3.

Anwendung testen. Sie sollte fehlerfrei laufen.

=back

=head2 Text in ein existierendes Bild schreiben

  use Quiq::Gd::Font;
  use Quiq::Gd::Image;
  use Quiq::Path;
  
  my $fnt = Quiq::Gd::Font->new('gdMediumBoldFont');
  my $img = Quiq::Gd::Image->new('bild.jpg');
  my $color = $img->color(255,0,0);
  $img->string($fnt,10,10,'TEST',$color);
  Quiq::Path->write('bild.jpg',$img->jpeg);

=head2 Hintergrund transparent machen

  my $img = Quiq::Gd::Image->new($width,$height);
  my $white = $img->background(255,255,255);
  $img->transparent($white);

=cut

# -----------------------------------------------------------------------------

package Quiq::Gd::Image;
use base qw/GD::Image Quiq::Object/;

use v5.10;
use strict;
use warnings;
use utf8;

our $VERSION = '1.228';

use GD ();
use Quiq::Gd::Font;
use Quiq::Gd::Image;
use Scalar::Util ();
use Quiq::Color;
use Quiq::Option;
use Quiq::Math;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Bildobjekt

=head4 Synopsis

  $img = $class->new($file);
  $img = $class->new($data);
  $img = $class->new($width,$height);
  $img = $class->new($width,$height,$maxColors);

=head4 Returns

Bildobjekt

=head4 Description

Instantiiere ein Bildobjekt der Breite $width und der Höhe $height mit
einer maximalen Anzahl von $maxColors Farben und liefere eine
Referenz auf dieses Objekt zurück. Schlägt der Aufruf fehl, löse
eine Exception aus.

Ist $maxColors nicht angegeben oder $maxColors > 256, wird ein
TrueColor-Bild erzeugt, andernfalls ein palette-basiertes Bild
mit maximal 256 Farben.

Die Methode blesst das Objekt auf die Klasse $class, da die Methoden
newPalette() und newTrueColor() der Klasse GD::Image dies nicht tun!

Der Hintergrund eines TrueColor-Bildes ist schwarz. Eine andere
Hintergrundfarbe wird mit background() gesetzt. Anders als
bei einem palette-basierten Bild ist I<nicht> die erste allozierte
Farbe die Hintergrundfarbe!

=head4 See Also

Siehe "perldoc GD", Methoden newPalette(), newTrueColor().

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # my @args = @_; # @args wird nur im Fehlerfall gebraucht
    # @_: s.u.

    my $self;
    if (@_ == 1) { # $file -or- $data
        $self = $class->SUPER::new(shift);

        #my $file = shift;
        #
        #if ($file =~ /\.jpg$/i) {
        #    $self = $class->newFromJpeg($file,1);
        #}
        #elsif ($file =~ /\.png$/i) {
        #    $self = $class->newFromPng($file,1);
        #}
        #else {
        #    $class->throw(
        #        'GD-00005: Unbekannter Dateityp',
        #        File => $file,
        #    );
        #}
    }
    else { # $width,$height,$color
        my $width = shift;
        my $height = shift;
        my $colors = shift;

        if ($colors && $colors <= 256) {
            # Palettebasiertes Bild mit max. 256 Farben
            $self = $class->SUPER::newPalette($width,$height);
        }
        else {
            # TrueColor-Bild
            $self = $class->SUPER::newTrueColor($width,$height);
        }
    }
    unless ($self) {
        $class->throw(
            'GD-00001: Konstruktoraufruf fehlgeschlagen',
            # ConstructorArguments => "[@args]",
        );
    }

    return bless $self,$class;
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden

=head3 textImage() - Erzeuge Bild mit Text

=head4 Synopsis

  $img = $class->textImage($text,@opt);

=head4 Arguments

=over 4

=item $text

Text, der in das Bild geschrieben wird.

=back

=head4 Options

=over 4

=item -background => $color (Default: 'white')

Hintergrundfarbe.

=item -color => $color (Default: 'white')

Textfarbe.

=item -font => $font (Default: 'gdGiantFont')

Font, in dem der Text gesetzt wird.

=back

=head4 Returns

Bildobjekt

=head4 Description

Erzeuge ein Bild, das den Text $text enthält.

=cut

# -----------------------------------------------------------------------------

sub textImage {
    my ($self,$text) = splice @_,0,2;

    # Optionen

    my $background = '#ffffff';
    my $color = '#000000';
    my $font = 'gdGiantFont';

    $self->parameters(\@_,
        background => \$background,
        color => \$color,
        font => 'gdGiantFont',
    );

    # Bild erzeugen

    my $fnt = Quiq::Gd::Font->new($font);
    my $width = $fnt->stringWidth($text)+1;
    my $height = $fnt->stringHeight($text);
    my $img = Quiq::Gd::Image->new($width,$height);
    $img->background($background);
    $img->string($fnt,1,0,$text,$img->color($color));

    return $img;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 color() - Alloziere Farbe

=head4 Synopsis

  $color = $img->color;             # Default-Farbe
  $color = $img->color(undef);      # Default-Farbe
  $color = $img->color($n);         # Index, bereits allozierte GD-Farbe
  $color = $img->color($r,$g,$b);   # dezimal
  $color = $img->color(\@rgb);      # dezimal als Array-Referenz
  $color = $img->color('RRGGBB');   # hexadezimal
  $color = $img->color('#RRGGBB');  # hexadezimal

=head4 Aliases

=over 2

=item *

colorAllocate()

=item *

colorResolve()

=item *

colorFindAllocate()

=back

=head4 Returns

Farbe

=head4 Description

Alloziere Farbe in der Farbtabelle des Bildes und liefere den Index des
Eintrags zurück. Existiert die Farbe bereits, liefere den existierenden
Index.

=head4 See Also

"perldoc GD" Methode colorResolve()

=cut

# -----------------------------------------------------------------------------

my @DefaultColor = (0,0,0);

sub color {
    my $self = shift;
    # @_: @color

    # Farbangabe @color in Tripel ($r,$g,$b) übersetzen

    if (@_ == 0) {
        # Default-Farbe
        @_ = @DefaultColor;
    }
    elsif (@_ == 1) {
        if (!defined $_[0]) {
            # Default-Farbe
            @_ = @DefaultColor;
        }
        elsif ($_[0] =~ /^\d+$/ && length($_[0]) != 6) {
            # bereits allozierte GD-Farbe
            return $_[0];
        }
        else {
            # alles andere mittels Farbklasse übersetzen
            # \@rgb, #RRGGBB, RRGGBB
            @_ = Quiq::Color->new($_[0])->rgb;
        }
    }
    elsif (@_ == 3) {
        # nichts tun
    }
    else {
        $self->throw(
            'GD-00003: Unerlaubte Farbangabe',
            Color => join(',',@_),
        );
    }

    my $color = $self->SUPER::colorResolve(@_); # $r,$g,$b
    if ($color < 0) {
        $self->throw(
            'GD-00002: Kann Farbtabelleneintrag nicht allozieren',
            RGB => join(',',@_),
        );
    }

    return $color;
}

{
    no warnings 'once';
    *colorAllocate = \&color;
    *colorResolve = \&color;
    *colorFindAllocate = \&color;
}

# -----------------------------------------------------------------------------

=head3 background() - Alloziere Farbe und setze Hintergrund

=head4 Synopsis

  $color = $img->background(@color);

=head4 Returns

Farbe

=head4 Description

Alloziere Farbe @color, fülle das gesamte Bild mit der Farbe
und liefere den Farbindex zurück.

Zu den möglichen Angaben für @color siehe Methode $img->L<color|"color() - Alloziere Farbe">().

Der Hintergrund eines TrueColor-Bildes ist anfänglich schwarz.
Anders als bei einem Palette-basierten Bild wird I<nicht> die erste
allozierte Farbe automatisch die Hintergrundfarbe. Daher sollte die
erste Farbe mit dieser Methode alloziert werden, damit
gleichzeitig die Hintergrundfarbe gesetzt wird.

=cut

# -----------------------------------------------------------------------------

sub background {
    my $self = shift;
    # @_: @color

    my $color = $self->color(@_);
    $self->filledRectangle(0,0,$self->width-1,$self->height-1,$color);

    return $color;
}

# -----------------------------------------------------------------------------

=head3 border() - Zeichne inneren Rahmen um das Bild

=head4 Synopsis

  $img->border($color);

=head4 Returns

Nichts

=head4 Description

Zeichne einen inneren Rahmen in Farbe $color um das Bild.
"Innerer Rahmen" bedeutet, dass der Rahmen Teil des Bildes ist
und nicht außen um das Bild herumgelegt ist.

=cut

# -----------------------------------------------------------------------------

sub border {
    my $self = shift;
    my $color = shift;

    my $width = $self->width-1;
    my $height = $self->height-1;
    $color = $self->color($color);
    $self->rectangle(0,0,$width,$height,$color);

    return;
}

# -----------------------------------------------------------------------------

=head3 drawCross() - Zeichne ein Kreuz

=head4 Synopsis

  $img->drawCross($x,$y,$color);

=cut

# -----------------------------------------------------------------------------

sub drawCross {
    my ($self,$x,$y,$color) = @_;

    $self->line($x-2,$y,$x+2,$y,$color);
    $self->line($x,$y-2,$x,$y+2,$color);

    return;
}

# -----------------------------------------------------------------------------

=head3 string() - Zeichne Zeichenkette horizontal oder vertikal

=head4 Synopsis

  $img->string($font,$x,$y,$string,$color,@opt);

=head4 Options

=over 4

=item -up => $bool (Default: 0)

Schreibe den Text nicht horizontal sondern vertikal.

=back

=head4 Returns

Nichts

=head4 Description

Zeichne Zeichenkette $string an Position ($x,$y). Die Zeichenkette
kann mehrzeilig sein.

Der Font ist ein C<< Quiq::Gd::Font >>-Objekt. Diese Klasse
vereinheitlicht GD- und TrueType-Fonts. GD-Fonts können nicht
in beliebigem Winkel, sondern nur horizontal und vertikal geschrieben
werden, daher erlaubt die Methode nur diese beiden Ausrichtungen.

Die Position ($x,$y) ist in beiden Ausrichtungen die linke Ecke
oberhalb des ersten Zeichens.

  horizontal          vertikal
  
  ($x,$y)
     x---------+         +---+
     | ....... |         | . |
     +---------+         | . |
                         | . |
                         | . |
                         | . |
                 ($x,$y) x---+

=cut

# -----------------------------------------------------------------------------

sub string {
    my $self = shift;
    my $font = shift;
    my $x = shift;
    my $y = shift;
    my $string = shift;
    my $color = shift;
    # @_: @opt

    # Optionen

    my $up = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -up => \$up,
        );
    }

    if (!$font->isTrueType) {
        # GD-Font

        my $gdFont = $font->{'font'};

        unless ($string =~ tr/\n//) {
            # Einzeiliger Text

            if ($up) {
                $self->SUPER::stringUp($gdFont,$x,$y,$string,$color);
            }
            else {
                $self->SUPER::string($gdFont,$x,$y,$string,$color);
            }
        }
        else {
            # Mehrzeiliger Text. Da die GD-Methoden string() und stringUp()
            # mit mehrzeiligem Text nicht richtig umgehen kann (statt Newline
            # wird "VT" geschrieben und es wird keine Zeile weiter
            # geschaltet), realisieren wird das Schreiben von mehrzeiligem
            # Text hier selbst.

            my $charHeight = $font->charHeight;

            if ($up) {
                for my $line (split /\n/,$string) {
                    $self->SUPER::stringUp($gdFont,$x,$y,$line,$color);
                    $x += $charHeight;
                }
            }
            else {
                for my $line (split /\n/,$string) {
                    $self->SUPER::string($gdFont,$x,$y,$line,$color);
                    $y += $charHeight;
                }
            }
        }
    }
    else {
        # TrueType Font

        my (undef,undef,$xOffset,$yOffset) = $font->stringGeometry($string,
            -up => $up,
        );
        $x += $xOffset;
        $y += $yOffset;

        my $fontName = $font->{'font'};
        my $pt = $font->{'pt'};
        my $angle = $up? Quiq::Math->degreeToRad(90): 0;
        $self->stringFT($color,$fontName,$pt,$angle,$x,$y,$string);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 stringUp() - Zeichne Zeichenkette vertikal

=head4 Synopsis

  $img->stringUp($font,$x,$y,$string,$color);

=head4 Returns

Nichts

=head4 Description

Die Methode ist die font-portable Überdeckung für die gleichnmige
Methode in der GD-Bibliothek.

=cut

# -----------------------------------------------------------------------------

sub stringUp {
    return shift->string(@_,-up=>1);
}

# -----------------------------------------------------------------------------

=head3 stringCentered() - Zeichne Zeichenkette horizontal oder vertikal zentriert

=head4 Synopsis

  $img->stringCentered($font,$orientation,$x,$y,$string,$color);

=cut

# -----------------------------------------------------------------------------

sub stringCentered {
    my ($self,$fnt,$orientation,$x,$y,$string,$color) = @_;

    if ($orientation eq 'v') {
        # Bei vertikaler Zentrierung ist kein Korrekturwert nötig
        # (sowohl bei GD- als auch TrueType-Fonts)

        $y -= $fnt->stringHeight($string)/2;
    }
    else {
        # Bei horizontaler Zentrierung ist ein Korrekturwert nötig: -1
        # (sowohl bei GD- als auch TrueType-Fonts)

        $x -= $fnt->stringWidth($string)/2+$fnt->hCenterOffset;
    }
    $self->string($fnt,$x,$y,$string,$color);

    return;
}

# -----------------------------------------------------------------------------

=head3 rainbowColors() - Alloziere Regenbogenfarben-Palette

=head4 Synopsis

  @colors | $colorA = $img->rainbowColors($n);

=head4 Returns

Array von Farben

=head4 Description

Alloziere eine Palette von $n Regenbogenfarben (Blau nach Rot) und
liefere die Liste der Farbtabellen-Indizes zurück.

Werte für $n: 4, 8, 16, 32, 64, 128, 256, 512, 1024.

Die Regenbogenfarben können verwendet werden, um die Werte
eines Wertebereichs in einen Farbverlauf zu übersetzen.

  Farbe     % Wertebereich  R   G   B
  --------- -------------- --- --- ---
  Blau             0        0   0  255
                                |        G-Anteil nimmt zu
  Hellblau        25        0  255 255
                                    |    B-Anteil nimmt ab
  Gruen           50        0  255  0
                            |            R-Anteil nimmt zu
  Gelb            75       255 255  0
                                |        G-Anteil nimmt ab
  Rot            100       255  0   0

=cut

# -----------------------------------------------------------------------------

sub rainbowColors {
    my $self = shift;
    my $n = shift;

    if ($n % 4) {
        $self->throw(
            'GD-00007: Anzahl Farben muss durch 4 teilbar sein',
            N => $n,
        );
    }
    if (256 % ($n/4)) {
        $self->throw(
            'GD-00008: Unzulässige Anzahl Farben',
            N => $n,
        );
    }

    my $step = 256/($n/4);

    my @colors;
    for (my $i = 0; $i < 256; $i += $step) {
        push @colors,$self->color(0,$i,255);
    }

    for (my $i = 256-$step; $i >= 0; $i -= $step) {
        push @colors,$self->color(0,255,$i);
    }

    for (my $i = 0; $i < 256; $i += $step) {
        push @colors,$self->color($i,255,0);
    }

    for (my $i = 256-$step; $i >= 0; $i -= $step) {
        push @colors,$self->color(255,$i,0);
    }

    return wantarray? @colors: \@colors;
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
