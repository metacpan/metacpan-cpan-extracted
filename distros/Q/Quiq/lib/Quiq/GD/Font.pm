package Quiq::GD::Font;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.151';

use GD ();
use Quiq::Math;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::GD::Font - GD- oder TrueType-Font

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Abstraktion für GD- und TrueType-Fonts, die von GD nicht gemacht wird.

=head2 Geometrie der (monospaced) GD-Fonts

    Name             Breite Höhe
    ---------------- ------ ----
    gdTinyFont         5      8
    gdSmallFont        6     13
    gdMediumBoldFont   7     13
    gdLargeFont        8     16
    gdGiantFont        9     15

=head1 EXAMPLES

=over 2

=item *

GD-Font instantiieren

    $fnt = Quiq::GD::Font->new('gdSmallFont');

=item *

TrueType-Font instantiieren

    $fnt = Quiq::GD::Font->new('/opt/fonts/pala.ttf',20);

=back

=cut

# -----------------------------------------------------------------------------

# In neueren Versionen von GD ist auch ein Aufruf als Klassenmethode
# möglich. Aus Portabilitätsgründen instantiieren wir aber ein Bildobjekt.

my $r = GD::Image->new(1,1)->useFontConfig(1);
unless ($r) {
    Quiq::GD::Font->throw(
        'GD-00006: FontConfig-Unterstützung fehlt',
    );
}

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere GD- oder TrueType-Font

=head4 Synopsis

    $fnt = $class->new($name);
    $fnt = $class->new($name,$pt);
    $fnt = $class->new("$name,$pt");
    $fnt = $class->new($fnt);

=head4 Description

Instantiiere GD- oder TrueType-Font und liefere eine Referenz auf
dieses Objekt zurück. Wird bei einem TrueType-Font keine Fontgröße
angegeben, wird 10pt angenommen.

Ein TrueType-Font kann auch mit einem einzigen Argument - als
Arrayreferenz [$name,$pt] - angegeben werden.

Wird ein bereits instantiiertes Font-Objekt als Parameter übergeben,
wird dieses einfach zurückgeliefert.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: s.o.

    # * Argumente verarbeiten *

    my ($name,$pt);
    if (ref $_[0]) {
        # bereits instantiierter Font: $fnt
        return $_[0];
    }
    elsif ($_[0] =~ /^(.*),(\d+)$/) {
        # TrueType-Font als einzelner String: "$name,$pt"
        ($name,$pt) = ($1,$2);
    }
    else {
        ($name,$pt) = @_;
    }

    # * Fontobjekt instantiieren *

    if ($name =~ /^gd(.*)Font$/) {
        # * GD-Font *

        my $meth = ucfirst $1;
        return $class->SUPER::new(
            trueType => 0,
            name => $name,
            font => GD::Font->$meth,
            pt => undef,
        );
    }

    # * TrueType-Font *

    my $path = $name; # Name eines TrueType-Font ist ein Pfad
    $pt ||= 10; # Default-Fontgröße

    # Prüfen, ob Font vorhanden ist

    if (!-e $path) {
        $class->throw(
            'GDFONT-00001: Font existiert nicht',
            Error => $@,
            Font => $path,
        );
    }

    # Fontname ist Basename der Fontdatei plus Fontgröße

    $name =~ s|.*/||;
    $name =~ s|\.ttf$||;
    $name .= $pt;

    return $class->SUPER::new(
        trueType => 1,
        name => $name,
        font => $path,
        pt => $pt,
    );
}

# -----------------------------------------------------------------------------

=head2 Primitive Operationen

=head3 name() - Name des Font

=head4 Synopsis

    $name = $fnt->name;

=head4 Description

Liefere den Namen des Font. Bei einem GD-Font ist dies der Name, wie er
beim Konstruktor angegeben wurde. Bei einem TrueType-Font ist es der
Grundname der Datei, also ohne Pfad und Endung C<.ttf>.

=cut

# -----------------------------------------------------------------------------

sub name {
    return shift->{'name'};
}

# -----------------------------------------------------------------------------

=head3 pt() - Größe des Font

=head4 Synopsis

    $pt = $fnt->pt;

=head4 Description

Liefere die Größe des Font. Bei einem GD-Font C<undef>, bei einem
TrueType-Font die Größe in pt.

=cut

# -----------------------------------------------------------------------------

sub pt {
    return shift->{'pt'};
}

# -----------------------------------------------------------------------------

=head3 isTrueType() - Prüfe auf TrueType-Font

=head4 Synopsis

    $bool = $fnt->isTrueType;

=head4 Description

Liefere 1 wenn der Font ein TrueType-Font ist, liefere 0, wenn er
ein GD-Font ist.

=cut

# -----------------------------------------------------------------------------

sub isTrueType {
    return shift->{'trueType'};
}

# -----------------------------------------------------------------------------

=head3 stringGeometry() - Liefere den Platzbedarf einer Zeichenkette

=head4 Synopsis

    ($width,$height,$xOffset,$yOffset) = $fnt->stringGeometry($str,@opt);

=head4 Options

=over 4

=item -up => $bool (Default: 0)

Schreibe den Text aufrecht.

=item -debug => $bool (Default: 0)

Gib Informationen auf STDDER aus.

=back

=head4 Description

Liefere den Platzbedarf (Breite, Höhe) und den x- und y-Offset
der Zeichenkette $str.

B<Geometrie>

TrueType-Fonts können um einen beliebigen Winkel gedreht werden.

            4,5
            /\
           /  \
          /  T \ 2,3
         /  X  /
    6,7 /  E  /
        \ T  /
         \  /
          \/
          0,1
    
    $width = $bounds[2]-$bounds[6]
    $height = $bounds[1]-$bounds[5]
    $xOffset = -$bounds[6]
    $yOffset = $up? 0: -$bounds[5]

Von dieser Möglichkeit machen wir allerdings keinen Gebrauch. Wir
lassen lediglich 0 und 90 Grad zu. Das sind die Möglichkeiten, die
die GD-Fonts erlauben.

=cut

# -----------------------------------------------------------------------------

sub stringGeometry {
    my $self = shift;
    my $string = shift;
    # @_: @opt

    # Optionen

    my $up = 0;
    my $debug = 0;

    $self->parameters(\@_,
        -up => \$up,
        -debug => \$debug,
    );

    my $font = $self->{'font'};
    my $width = 0;
    my $height = 0;
    my $xOffset = 0;
    my $yOffset = 0;

    if ($debug) {
        warn "font=$font, up=$up\n";
    }

    if (!$self->{'trueType'}) {
        # GD-Font

        $width = $font->width*length($string);
        $height = $font->height;

        if ($up) {
            # Höhe und Breite vertauschen
            ($height,$width) = ($width,$height);
        }
    }
    else {
        # TrueType-Font

        my $pt = $self->{'pt'};
        my $angle = $up? Quiq::Math->degreeToRad(90): 0;

        my @a = GD::Image->stringFT(0,$font,$pt,$angle,0,0,$string);
        unless (@a) {
            $self->throw(
                'GDFONT-00002: String kann nicht gerendert werden',
                Error => $@,
                Font => $font,
            );
        }

        if ($debug) {
            warn "pt=$pt, angle=$angle\n";
            warn "bounds=($a[0],$a[1]) ($a[2],$a[3])",
                " ($a[4],$a[5]) ($a[6],$a[7])\n";
        }

        $width = $a[2]-$a[6];
        $height = $a[1]-$a[5];
        $xOffset = -$a[6];
        $yOffset = $up? 0: -$a[5];
    }

    if ($debug) {
        warn "width=$width, height=$height",
            " xOffset=$xOffset, yOffset=$yOffset\n";
    }

    return ($width,$height,$xOffset,$yOffset);
}

# -----------------------------------------------------------------------------

=head3 charWidth() - Liefere (maximale) Breite eines Fontzeichens

=head4 Synopsis

    $width = $fnt->charWidth(@opt);

=head4 Alias

width()

=head4 Options

=over 4

=item -up => $bool (Default: 0)

Vertikaler Text.

=back

=head4 Description

Liefere die maximale Breite eines Fontzeichens.

Da die GD-Fonts fixed/monospaced Fonts sind, ist die Breite aller
Zeichen gleich.

Bei TrueType-Fonts wird die Breite der Zeichenkette "M" ermittelt.

=cut

# -----------------------------------------------------------------------------

sub charWidth {
    return (shift->stringGeometry('M',@_))[0];
}

{
    no warnings 'once';
    *width = \&charWidth;
}

# -----------------------------------------------------------------------------

=head3 charHeight() - Liefere (maximale) Höhe eines Fontzeichens

=head4 Synopsis

    $height = $fnt->charHeight(@opt);

=head4 Alias

height()

=head4 Options

=over 4

=item -up => $bool (Default: 0)

Vertikaler Text.

=back

=head4 Description

Liefere die maximale Höhe eines Fontzeichnes.

Da die GD-Fonts fixed/monospaced Fonts sind, ist die Höhe
aller Zeichen gleich.

Ist der Font ein TrueType-Font wird die Höhe der Zeichenkette
"Xy" bestimmt.

=cut

# -----------------------------------------------------------------------------

sub charHeight {
    return (shift->stringGeometry('Xy',@_))[1];
}

{
    no warnings 'once';
    *height = \&charHeight;
}

# -----------------------------------------------------------------------------

=head3 digitWidth() - Liefere Breite einer Ziffer

=head4 Synopsis

    $width = $fnt->digitWidth(@opt);

=head4 Options

=over 4

=item -up => $bool (Default: 0)

Vertikaler Text.

=back

=head4 Description

Liefere die Breite einer Ziffer. Alle Ziffern eines Font sollten
dieselbe Breite haben. Für GD-Fonts ist dies ohnehin der Fall.
Bei TrueType-Fonts ermitteln wir die Breite der "0".

=cut

# -----------------------------------------------------------------------------

{
    package GD::Font;
    no warnings 'once';
    *digitWidth = *width;
}

sub digitWidth {
    return (shift->stringGeometry('0',@_))[0];
}

# -----------------------------------------------------------------------------

=head3 digitHeight() - Liefere Höhe einer Ziffer

=head4 Synopsis

    $height = $fnt->digitHeight(@opt);

=head4 Options

=over 4

=item -up => $bool (Default: 0)

Vertikaler Text.

=back

=head4 Description

Liefere die Höhe einer Ziffer. Alle Ziffern eines Font sollten
dieselbe Höhe haben. Für GD-Fonts ist dies ohnehin der Fall.
Bei TrueType-Fonts ermitteln wir die Höhe der "0".

=cut

# -----------------------------------------------------------------------------

{
    package GD::Font;
    no warnings 'once';
    *digitHeight = *height;
}

sub digitHeight {
    return (shift->stringGeometry('0',@_))[1];
}

# -----------------------------------------------------------------------------

=head3 stringWidth() - Horizontaler Platzbedarf einer Zeichenkette

=head4 Synopsis

    $n = $fnt->stringWidth($str,@opt);

=head4 Options

=over 4

=item -up => $bool (Default: 0)

Vertikaler Text.

=back

=head4 Description

Liefere den horizontalen Platzbedarf der Zeichenkette $str.

=cut

# -----------------------------------------------------------------------------

{
    package GD::Font;

    sub stringWidth {
        my $self = shift;
        my $str = shift;
        return $self->width*length($str);
    }
}

sub stringWidth {
    my $self = shift;
    my $str = shift;
    # @_: @opt

    my ($width) = $self->stringGeometry($str,@_);
    return $width;
}

# -----------------------------------------------------------------------------

=head3 stringHeight() - Vertikaler Platzbedarf einer Zeichenkette

=head4 Synopsis

    $n = $fnt->stringHeight($str,@opt);

=head4 Options

=over 4

=item -up => $bool (Default: 0)

Vertikaler Text.

=back

=head4 Description

Liefere den horizontalen Platzbedarf der Zeichenkette $str.

=cut

# -----------------------------------------------------------------------------

{
    package GD::Font;
    no warnings 'once';
    *stringHeight = *height;
}

sub stringHeight {
    my $self = shift;
    my $str = shift;
    # @_: @opt

    my (undef,$height) = $self->stringGeometry($str,@_);
    return $height;
}

# -----------------------------------------------------------------------------

=head2 Alignment

Die folgenden Methoden liefern den Offset, der benötigt wird, wenn
ein Text eng an eine rechte oder obere Grenze ausgerichtet werden soll,
wie z.B. bei der Beschriftung einer X- oder Y-Achse.

Die Offsets sind Font-abhängig. Für die GD-Fonts und den TrueType-Font
pala bis 20pt ist der Offset ausgearbeitet. Für andere TrueType-Fonts
und Fontgrößen müssen die Methoden u.U. erweitert werden.

=head3 alignRightOffset() - Korrektur-Offset für Ausrichtung an rechten Rand

=head4 Synopsis

    $n = $g->alignRightOffset;

=head4 Description

Der Korrektur-Offset ist so bemessen, dass der Text möglichst
dicht an einen rechten Rand angrenzt, z.B. das Label an den Tick
einer Y-Achse.

=cut

# -----------------------------------------------------------------------------

sub alignRightOffset {
    my $self = shift;

    if (!$self->isTrueType) {
        # Offset für alle GD-Fonts
        return 1;
    }
    else {
        my $xOffset = 2;

        my $pt = $self->pt;
        if ($pt < 10) {
            $xOffset = 2;
        }
        elsif ($pt <= 20) {
            $xOffset = 3;
        }
        elsif ($pt <= 30) {
            $xOffset = 4;
        }

        return $xOffset;
    }

    # not reached
}

# -----------------------------------------------------------------------------

=head3 alignTopOffset() - Korrektur-Offset für Ausrichtung an oberen Rand

=head4 Synopsis

    $n = $g->alignTopOffset;

=head4 Description

Der Korrektur-Offset ist so bemessen, dass der Text möglichst
dicht an einen oberen Rand angrenzt, z.B. das Label an den Tick
einer X-Achse.

=cut

# -----------------------------------------------------------------------------

sub alignTopOffset {
    my $self = shift;

    my $fontName = $self->name;
    if ($fontName eq 'gdTinyFont') {
        return 0;
    }
    elsif (substr($fontName,0,2) eq 'gd') {
        return -2;
    }

    return 0;
}

# -----------------------------------------------------------------------------

=head3 hCenterOffset() - Korrektur für horizontal zentrierten Text

=head4 Synopsis

    $n = $fnt->hCenterOffset;

=head4 Description

Bei horizontal zentriertem Text ist manchmal eine Korrektur nötig,
die diese Methode liefert.

=cut

# -----------------------------------------------------------------------------

sub hCenterOffset {
    my $self = shift;

    my $fontName = $self->name;
    if ($fontName eq 'gdLargeFont') {
        return 0;
    }

    return -1;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.151

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
