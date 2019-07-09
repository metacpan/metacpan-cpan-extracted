package Quiq::Math;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use 5.010;
use Quiq::Formatter;
use POSIX ();
use Math::Trig ();
use Scalar::Util ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Math - Mathematische Funktionen

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Konstanten

=head3 pi() - Liefere PI

=head4 Synopsis

    $pi = $class->pi;

=cut

# -----------------------------------------------------------------------------

sub pi {
    return 4*CORE::atan2(1,1);
}

# -----------------------------------------------------------------------------

=head2 Rundung

=head3 roundTo() - Runde Zahl auf n Nachkommastellen

=head4 Synopsis

    $y = $class->roundTo($x,$n);
    $y = $class->roundTo($x,$n,$normalize);

=head4 Description

Runde $x auf $n Nachkommastellen und liefere das Resultat zurück.

Ist $normalize "wahr", wird die Zahl nach der Rundung mit
normalizeNumber() normalisiert.

Bei $n > 0 rundet die Methode mittels

    $y = sprintf '%.*f',$n,$x;

bei $n == 0 mittels roundToInt().

=cut

# -----------------------------------------------------------------------------

sub roundTo {
    my ($class,$x,$n,$normalize) = @_;

    if ($n == 0) {
        return $class->roundToInt($x);
    }

    $x = sprintf '%.*f',$n,$x;
    if ($normalize) {
        $x = Quiq::Formatter->normalizeNumber($x);
    }

    return $x;
}

# -----------------------------------------------------------------------------

=head3 roundToInt() - Runde Zahl zu Ganzer Zahl (Integer)

=head4 Synopsis

    $n = $class->roundToInt($x);

=head4 Description

Runde Zahl $x zu ganzer Zahl und liefere das Resultat zurück, nach
folgender Regel:

Für Nachkommastellen < .5 runde ab, für Nachkommastellen >= .5 runde auf.
Für negative $x ist es umgekehrt.

Folgender Ansatz funktioniert nicht

    $n = sprintf '%.0f',$x;

denn dieser gibt inkonsistente Ergebnisse

    0.5 => 0
    1.5 => 2
    2.5 => 2

=cut

# -----------------------------------------------------------------------------

sub roundToInt {
    return $_[1] > 0? int($_[1]+0.5): -int(-$_[1]+0.5);
}

# -----------------------------------------------------------------------------

=head3 roundMinMax() - Runde Breichsgrenzen auf nächsten geeigneten Wert

=head4 Synopsis

    ($minRounded,$maxRounded) = $class->roundMinMax($min,$max);

=head4 Description

Die Methode rundet $min ab und $max auf, so dass geeignete
Bereichsgrenzen für eine Diagrammskala entstehen.

Sind $min und $max gleich, schaffen wir einen künstlichen Bereich
($min-1,$max+1).

Die Rundungsstelle leitet sich aus der Größe des Bereichs
$max-$min her.

=head4 Examples

8.53, 8.73 -> 8.5, 8.8

8.53, 8.53 -> 7, 10

=cut

# -----------------------------------------------------------------------------

sub roundMinMax {
    my ($class,$min,$max) = @_;

    if ($min == $max) {
        # Sind Minimum und Maximum gleich, schaffen wir einen
        # künstlichen Bereich

        $min -= 1;
        $max += 1;
    }

    my $delta = $max-$min;
    for (0.0001,0.001,0.01,0.1,1,10,100,1_000,10_000,100_000) {
        if ($delta < $_) {
            my $step = $_/10;
            $min = POSIX::floor($min/$step)*$step;
            $max = POSIX::ceil($max/$step)*$step;
            last;
        }
    }

    return ($min,$max)
}

# -----------------------------------------------------------------------------

=head2 Größter gemeinsamer Teiler

=head3 gcd() - Größter gemeinsamer Teiler

=head4 Synopsis

    $gcd = $class->gcd($a,b);

=head4 Description

Berechne den größten gemeinsamen Teiler (greatest common divisor)
der beiden natürlichen Zahlen $a und $b und liefere diesen
zurück. Die Methode ist nach dem L<Euklidschen Algorithmus|https://de.wikipedia.org/wiki/Euklidischer_Algorithmus#Rekursive_Variante> implementiert.

=cut

# -----------------------------------------------------------------------------

sub gcd {
    my ($class,$a,$b) = @_;
    return $b == 0? $a: $class->gcd($b,$a%$b);
}

# -----------------------------------------------------------------------------

=head2 Bogenmaß

=head3 degreeToRad() - Wandele Grad in Bogenmaß (rad)

=head4 Synopsis

    $rad = $class->degreeToRad($degree);

=cut

# -----------------------------------------------------------------------------

sub degreeToRad {
    my ($class,$degree) = @_;
    return $degree*$class->pi/180;
}

# -----------------------------------------------------------------------------

=head3 radToDegree() - Wandele Bogenmaß (rad) in Grad

=head4 Synopsis

    $degree = $class->radToDegree($rad);

=cut

# -----------------------------------------------------------------------------

sub radToDegree {
    my ($class,$rad) = @_;
    return 180/$class->pi*$rad;
}

# -----------------------------------------------------------------------------

=head2 Geo-Koordinaten

=head3 geoMidpoint() - Mittelpunkt von Geo-Postionen

=head4 Synopsis

    ($latitude,$longitude) = $class->geoMidpoint(\@coordinates);

=head4 Arguments

=over 4

=item @coordinates

Array von Geo-Koordinaten. Eine einzelne Geo-Koordinate ist ein
Tipel [$latitude,$logitude,$weight], wobei die Gewichtung $weight
optional ist. Fehlt die Gewichtung, wird als Wert 1 angenommen.

=back

=head4 Returns

Breite und Länge des geografischen Mittelpunkts

=head4 Description

Berechne den geografischen Mittelpunkt der Geo-Koordination (plus
optionaler Gewichtung) und liefere diesen zurck.

Beschreibung des Alogrithmus siehe
L<http://www.geomidpoint.com/example.html>

=cut

# -----------------------------------------------------------------------------

sub geoMidpoint {
    my ($class,$coordinateA) = @_;

    my $x = 0;
    my $y = 0;
    my $z = 0;
    my $w = 0;

    for (@$coordinateA) {
        my ($latitude,$longitude,$weight) = @$_;

        if (!defined($latitude) || !defined($longitude)) {
            # Undefiniert Ortskoordinaten übergehen wir
            next;
        }
    
        $latitude = $class->degreeToRad($latitude);
        $longitude = $class->degreeToRad($longitude);
        $weight //= 1;

        $x += cos($latitude) * cos($longitude) * $weight;
        $y += cos($latitude) * sin($longitude) * $weight;
        $z += sin($latitude) * $weight;
        $w += $weight; 
    }

    my ($midLongitude,$midLatitude);
    if ($w) {
        $x /= $w;
        $y /= $w;
        $z /= $w;

        $midLongitude = $class->radToDegree(atan2($y,$x));
        my $hyp = sqrt($x*$x+$y*$y);
        $midLatitude = $class->radToDegree(atan2($z,$hyp));
    }
                    
    return ($midLatitude,$midLongitude);
}

# -----------------------------------------------------------------------------

=head3 geoToDegree() - Wandele Geo-Ortskoordinate in dezimale Gradangabe

=head4 Synopsis

    $dezDeg = $class->geoToDegree($deg,$min,$sec,$dir);

=head4 Description

Wandele eine geographische Ortsangabe in Grad, Minuten, Sekunden,
Himmelsrichtung in eine dezimale Gradzahl und liefere diese zurück.

=head4 Example

    50 6 44 N -> 50.11222
    50 6 44 S -> -50.11222

=cut

# -----------------------------------------------------------------------------

sub geoToDegree {
    my ($class,$deg,$min,$sec,$dir) = @_;

    $deg = $deg + $min/60 + $sec/3600;

    if ($dir) {
        if ($dir eq 'N' || $dir eq 'E') {
            # nixtun
        }
        elsif ($dir eq 'S' || $dir eq 'W') {
            $deg = -$deg;
        }
        else {
            $class->throw(
                'MATH-00001: Unbekannte Himmelsrichtung',
                Direction => $dir,
            );
        }
    }

    return $deg;
}

# -----------------------------------------------------------------------------

=head3 geoDistance() - Entfernung zw. zwei Punkten auf der Erdoberfäche

=head4 Synopsis

    $km = $class->geoDistance($lat1,$lon1,$lat2,$lon2);

=head4 Description

Berechne die Entfernung zwischen den beiden Geokoordinaten ($lat1,$lon1)
und (lat2,$lon2) und liefere die Distanz in Kilometern zurück. Die Angabe
der Geokoordinaten ist in Grad.

Der Berechnung liegt die Formel zugrunde:

    km = 1.852*60*180/pi*acos(
        sin($lat1*pi/180)*sin($lat2*pi/180)+
        cos($lat1*pi/180)*cos($lat2*pi/180)*cos(($lon2-$lon1)*pi/180)
    )

=head4 See Also

=over 2

=item *

L<Prof. Dirk Reichhardt - Hinweise zur Berechnung von Abständen|http://wwwlehre.dhbw-stuttgart.de/~reichard/content/vorlesungen/lbs/uebungen/abstandsberechnung.pdf>

=item *

L<Blog Martin Kompf - Entfernungsberechnung|http://www.kompf.de/gps/distcalc.html>

=back

=head4 Examples

Abstand zw. zwei Längengraden (359. und 360.) am Äquator:

    sprintf '%.2f',Quiq::Math->geoDistance(0,359,0,360);
    # -> 111.12

Abstand zw. zwei Längengraden am Pol:

    Quiq::Math->geoDistance(90,359,90,360);
    # -> 0

=cut

# -----------------------------------------------------------------------------

sub geoDistance {
    my ($class,$lat1,$lon1,$lat2,$lon2) = @_;

    # Wir rechnen im Bogenmaß

    $lat1 = $class->degreeToRad($lat1);
    $lon1 = $class->degreeToRad($lon1);
    $lat2 = $class->degreeToRad($lat2);
    $lon2 = $class->degreeToRad($lon2);

    return 1.852*60*$class->radToDegree(Math::Trig::acos(
        sin($lat1)*sin($lat2)+cos($lat1)*cos($lat2)*cos($lon2-$lon1)));

    # 6371
    # 6366.7
    #return 6371*Math::Trig::acos(sin($lat1)*sin($lat2)+
    #    cos($lat1)*cos($lat2)*cos($lon2-$lon1));
}

# -----------------------------------------------------------------------------

=head3 latitudeDistance() - Abstand zwischen zwei Längengraden

=head4 Synopsis

    $km = $class->latitudeDistance($lat);

=head4 Description

Liefere den Abstand zwischen zwei Längengraden bei Breitengrad $lat.
Die Methode ist eigentlich nicht nötig, da sie einen Spezialfall der
Mehode geoDistance() behandelt. Die Formel stammt von
Wilhelm Petersen.

=cut

# -----------------------------------------------------------------------------

sub latitudeDistance {
    my ($class,$lat) = @_;

    $lat = $class->degreeToRad($lat); # Breite im Bogenmaß
    my $d = $class->degreeToRad(1);   # 1 Grad im Bogenmaß

    return 1.852*60*$class->radToDegree(
        Math::Trig::acos((sin($lat)**2+cos($lat)**2*cos($d))));
}

# -----------------------------------------------------------------------------

=head2 Welt/Pixel-Koordinaten

=head3 valueToPixelFactor() - Umrechnungsfaktor Wertebereich in Pixelkoordinaten

=head4 Synopsis

    $factor = $class->valueToPixelFactor($length,$min,$max)

=head4 Returns

Faktor

=head4 Description

Liefere den Faktor für die Umrechung von Wertebereich in Pixelkoordinaten.
Die Werte werden transformiert auf einen Bildschirmabschnitt
der Länge $length, dessen Randpunkte den Werten $min und $max
entsprechen.

=cut

# -----------------------------------------------------------------------------

sub valueToPixelFactor {
    my ($class,$size,$min,$max) = @_;
    return ($size-1)/($max-$min);
}

# -----------------------------------------------------------------------------

=head3 pixelToValueFactor() - Umrechnungsfaktor von Pixel in Wertebereich

=head4 Synopsis

    $factor = $class->pixelToValueFactor($length,$min,$max);

=head4 Returns

Faktor

=head4 Description

Liefere den Faktor für die Umrechung von Pixel in Werte
entlang eines Bildschirmabschnitts der Länge $length, dessen Randpunkt
dem Werteberich $min und $max entsprechen.

=cut

# -----------------------------------------------------------------------------

sub pixelToValueFactor {
    my ($class,$length,$min,$max) = @_;
    return 1/Quiq::Math->valueToPixelFactor($length,$min,$max);
}

# -----------------------------------------------------------------------------

=head3 valueToPixelX() - Transformiere Wert in X-Pixelkoordinate

=head4 Synopsis

    $x = $class->valueToPixelX($width,$xMin,$xMax,$xVal);

=head4 Alias

valueToPixel()

=head4 Description

Transformiere Wert $xVal in eine Pixelkoordinate auf einer X-Pixelachse
der Breite $width. Das Minimum des Wertebereichs ist $xMin und das Maximum
ist $xMax. Die gelieferten Werte liegen im Bereich 0 .. $width-1.

=cut

# -----------------------------------------------------------------------------

sub valueToPixelX {
    my ($class,$width,$xMin,$xMax,$xVal) = @_;
    return sprintf '%.0f',($xVal-$xMin)*($width-1)/($xMax-$xMin);
}

{
    no warnings 'once';
    *valueToPixel = \&valueToPixelX;
}

# -----------------------------------------------------------------------------

=head3 valueToPixelY() - Transformiere Wert in Y-Pixelkoordinate

=head4 Synopsis

    $y = $class->valueToPixelY($height,$yMin,$yMax,$yVal);

=head4 Description

Transformiere Wert $yVal in eine Pixelkoordinate auf einer Y-Pixelachse
der Höhe $height. Das Minimum des Wertebereichs ist $yMin und das Maximum
ist $yMax. Die gelieferten Werte liegen im Bereich $height-1 .. 0.

=cut

# -----------------------------------------------------------------------------

sub valueToPixelY {
    my ($class,$height,$yMin,$yMax,$yVal) = @_;
    return sprintf '%.0f',$height-1-($yVal-$yMin)*($height-1)/($yMax-$yMin);
}

# -----------------------------------------------------------------------------

=head2 Interpolation

=head3 interpolate() - Ermittele Wert durch lineare Interpolation

=head4 Synopsis

    $y = $class->interpolate($x0,$y0,$x1,$y1,$x);

=head4 Returns

Float

=head4 Description

Berechne durch lineare Interpolation den Wert y=f(x) zwischen
den gegebenen Punkten y0=f(x0) und y1=f(x1) und liefere diesen zurück.

Siehe: L<http://de.wikipedia.org/wiki/Interpolation_%28Mathematik%29#Lineare_Interpolation>

=cut

# -----------------------------------------------------------------------------

sub interpolate {
    my ($class,$x0,$y0,$x1,$y1,$x) = @_;
    return $y0+($y1-$y0)/($x1-$x0)*($x-$x0);
}

# -----------------------------------------------------------------------------

=head2 Zahlen

=head3 isNumber() - Prüfe, ob Skalar eine Zahl darstellt

=head4 Synopsis

    $bool = $class->isNumber($str);

=cut

# -----------------------------------------------------------------------------

sub isNumber {
    return Scalar::Util::looks_like_number($_[1])? 1: 0;
}

# -----------------------------------------------------------------------------

=head2 Spike Test

=head3 spikeValue() - Berechne Spike-Wert

=head4 Synopsis

    $val = $class->spikeValue($v1,$v2,$v3,$t1,$t3);

=head4 Description

Berechnung gemäß der Mail von Wilhelm Petersen vom 2017-05-03:

    $v = (abs($v2-($v3+$v1)/2)-abs(($v3-$v1)/2))/($t3/60-$t1/60);

Die Parameter $t1 und $t2 werden in Sekunden angeben, die
Funktion rechnet jedoch in Minuten, daher die Division durch 60.

=cut

# -----------------------------------------------------------------------------

sub spikeValue {
    my ($class,$v1,$v2,$v3,$t1,$t3) = @_;
    return (abs($v2-($v3+$v1)/2)-abs(($v3-$v1)/2))/($t3/60-$t1/60);
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
