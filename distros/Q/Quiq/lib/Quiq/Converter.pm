package Quiq::Converter;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.147';

use POSIX ();
use Time::Local ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Converter - Konvertierung von Werten

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Zeichenketten

=head3 newlineToName() - Liefere Namen einer Newline-Zeichenkette

=head4 Synopsis

    $nlName = $this->newlineToName($nl);

=head4 Description

Liefere den "Namen" einer Newline-Zeichenkette, also "LF", "CRLF"
oder "CR".

=cut

# -----------------------------------------------------------------------------

sub newlineToName {
    my ($this,$nl) = @_;

    if ($nl eq "\cJ") {
        return 'LF';
    }
    elsif ($nl eq "\cM\cJ") {
        return 'CRLF';
    }
    elsif ($nl eq "\cM") {
        return 'CR';
    }
    
    $this->throw(
        'PATH-00099: Unknown newline string',
        NewlineString => $nl,
    );
}

# -----------------------------------------------------------------------------

=head3 snakeCaseToCamelCase() - Wandele Snake Case nach Camel Case

=head4 Synopsis

    $camel = $this->snakeCaseToCamelCase($snake);

=head4 Description

Wandele einen in Snake Case geschriebenen Bezeichner in einen Camel Case
Bezeichner und liefere diesen zurück.

Snake Case:

    ims-apply-delta-row-by-row
    ims_apply_delta_row_by_row

Camel Case:

    imsApplyDeltaRowByRow

=cut

# -----------------------------------------------------------------------------

sub snakeCaseToCamelCase {
    my ($this,$str) = @_;

    # Eingebettete Bindestriche und Unterstriche in Camel Case wandeln

    $str =~ s/(.)[_-](.)/$1\U$2/g;

    return $str;
}

# -----------------------------------------------------------------------------

=head3 strToHex() - Wandele String in Hex-Darstellung

=head4 Synopsis

    $strHex = $this->strToHex($str);

=cut

# -----------------------------------------------------------------------------

sub strToHex {
    my ($this,$str) = @_;

    $str =~ s/(.)/sprintf '%02x ',ord $1/seg;
    substr($str,-1) = '';

    return $str;
}

# -----------------------------------------------------------------------------

=head3 textToHtml() - Wandele Text nach HTML

=head4 Synopsis

    $html = $this->textToHtml($text);

=head4 Description

Ersetze in $text die Zeichen &, < und > durch HTML-Entities und
liefere das Resultat zurück.

=cut

# -----------------------------------------------------------------------------

sub textToHtml {
    my ($this,$str) = @_;

    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;

    return $str;
}

# -----------------------------------------------------------------------------

=head3 doubleDecode() - Wandele doppelt enkodiertes UTF-8 zurück

=head4 Synopsis

    $class->doubleDecode(\$str);
    $newStr = $class->doubleDecode($str);

=head4 Description

Wandele doppelt enkodiertes UTF-8 zurück in einfach enkodiertes UTF-8.
Behandelt werden aktuell nur deutsche Umlaute und Sz.

=cut

# -----------------------------------------------------------------------------

sub doubleDecode {
    my ($class,$arg) = @_;

    my $ref = ref $arg? $arg: \$arg;

    if (defined $$ref) {
        $$ref =~ s/\N{U+00C3}\N{U+00A4}/ä/g;
        $$ref =~ s/\N{U+00C3}\N{U+00B6}/ö/g;
        $$ref =~ s/\N{U+00C3}\N{U+00BC}/ü/g;
        $$ref =~ s/\N{U+00C3}\N{U+0084}/Ä/g;
        $$ref =~ s/\N{U+00C3}\N{U+0096}/Ö/g;
        $$ref =~ s/\N{U+00C3}\N{U+009C}/Ü/g;
        $$ref =~ s/\N{U+00C3}\N{U+009F}/ß/g;
    }

    return ref $arg? (): $$ref;
}

# -----------------------------------------------------------------------------

=head3 umlautToAscii() - Wandele deutsche Umlaute und SZ nach ASCII

=head4 Synopsis

    $class->umlautToAscii(\$str);
    $newStr = $class->umlautToAscii($str);

=head4 Description

Schreibe ä, Ä, ö, Ö, ü, Ü, ß in ae, Ae, oe, Oe, ue, Ue, ss um
und liefere das Resultat zurück. Wird eine Stringreferenz angegeben,
findet die Umschreibung "in-place" statt.

Die Methode setzt voraus, dass der String korrekt dekodiert wurde.

=cut

# -----------------------------------------------------------------------------

sub umlautToAscii {
    my ($class,$arg) = @_;

    my $ref = ref $arg? $arg: \$arg;

    if (defined $$ref) {
        $$ref =~ s/ä/ae/g;
        $$ref =~ s/ö/oe/g;
        $$ref =~ s/ü/ue/g;
        $$ref =~ s/Ä/Ae/g;
        $$ref =~ s/Ö/Oe/g;
        $$ref =~ s/Ü/Ue/g;
        $$ref =~ s/ß/ss/g;
    }

    return ref $arg? (): $$ref;
}

# -----------------------------------------------------------------------------

=head2 Zahlen

=head3 germanToProgramNumber() - Wandele deutsche Zahldarstellung in Zahl

=head4 Synopsis

    $x = $this->germanToProgramNumber($germanX);

=head4 Description

Wandele deutsche Zahldarstellung mit Punkt (.) als Stellen-Trenner und
Komma (,) als Dezimaltrennzeichen in eine Zahl der Programmiersprache
und liefere das Resultat zurück.

=cut

# -----------------------------------------------------------------------------

sub germanToProgramNumber {
    my ($this,$x) = @_;

    $x =~ s/\.//;
    $x =~ s/,/./;

    return $x;
}

# -----------------------------------------------------------------------------

=head3 intToWord() - Wandele positive ganze Zahl in Wort über Alphabet

=head4 Synopsis

    $word = $this->intToWord($n);
    $word = $this->intToWord($n,$alphabet);

=head4 Returns

Zeichenkette

=head4 Description

Wandele positive ganze Zahl $n in ein Wort über dem Alphabet
$alphabet und liefere dieses zurück. Für 0 liefere
einen Leerstring.

Das Alphabet, über welchem die Worte gebildet werden, wird in Form
einer Zeichenkette angegeben, in der jedes Zeichen einmal
vorkommt. Per Default wird das Alphabet

    'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

verwendet. Die Funktion implementiert folgende Abbildung:

    0 -> ''
    1 -> 'A'
    2 -> 'B'
    
    ...
    26 -> 'Z'
    27 -> 'AA'
    28 -> 'AB'
    ...
    52 -> 'AZ'
    53 -> 'BA'
    ...

=cut

# -----------------------------------------------------------------------------

sub intToWord {
    my $this = shift;
    my $n = shift;
    my $alphabet = shift || 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    my $l = length $alphabet;

    my $word = '';
    my $m = $n; # warum dies?

    while ($m) {
        my $mod = $m%$l;
        $word = substr($alphabet,$mod-1,1).$word;
        $m = POSIX::floor($m/$l);
        $m -= 1 if $mod == 0;
    }

    return $word;
}

# -----------------------------------------------------------------------------

=head2 Längen

=head3 ptToPx() - Rechne Punkt (pt) in Pixel (px) um

=head4 Synopsis

    $px = $this->ptToPx($pt);

=head4 Alias

pointToPixel()

=head4 Arguments

=over 4

=item $pt (Number)

Punkt-Wert

=back

=head4 Returns

Pixel-Wert (Number)

=head4 Description

Rechne Punkt in Pixel um und liefere das Resultat zurück.

    1 Punkt = 1/0.75 Pixel

=cut

# -----------------------------------------------------------------------------

sub ptToPx {
    my ($this,$pt) = @_;
    return $pt*(1/0.75);
}

{
    no warnings 'once';
    *pointToPixel = \&ptToPx;
}

# -----------------------------------------------------------------------------

=head3 pxToPt() - Rechne Pixel (px) in Punkt (pt) um

=head4 Synopsis

    $pt = $this->pxToPt($px);

=head4 Alias

pixelToPoint()

=head4 Arguments

=over 4

=item $px (Number)

Pixel-Wert

=back

=head4 Returns

Punkt-Wert (Number)

=head4 Description

Rechne Pixel in Punkt um und liefere das Resultat zurück.

    1 Pixel = 0.75 Punkt

=cut

# -----------------------------------------------------------------------------

sub pxToPt {
    my ($this,$px) = @_;
    return $px*0.75;
}

{
    no warnings 'once';
    *pixelToPoint = \&pxToPt;
}

# -----------------------------------------------------------------------------

=head2 Zeitdarstellung

=head3 epochToDuration() - Wandele Sekunden in (lesbare) Angabe einer Dauer

=head4 Synopsis

    $str = $class->epochToDuration($epoch,$truncate,$format);

=head4 Alias

secondsToDuration()

=head4 Description

Wandele eine Zeitangabe in Sekunden in eine Zeichenkette der Form

    HH:MM:SS  ($format nicht angegeben oder 1)

oder

    HHhMMmSSs ($format == 2)

oder

    HhMmSs ($format == 3)

=cut

# -----------------------------------------------------------------------------

sub epochToDuration {
    my $class = shift;
    my $s = shift;
    my $truncate = shift || 0;
    my $format = shift || 1;

    my $h = int $s/3600;
    $s -= $h*3600;
    my $m = int $s/60;
    $s -= $m*60;

    my $str;
    if ($format == 1) {
        $str = sprintf '%02d:%02d:%02d',$h,$m,$s;
    }
    elsif ($format == 2) {
        $str = sprintf '%02dh%02dm%02ds',$h,$m,$s;
    }
    elsif ($format == 3) {
        $str = sprintf '%dh%dm%ds',$h,$m,$s;
    }
    if ($truncate) {
        $str =~ s/^[0\D]+//;
        if ($str eq '') {
            $str = '0';
            if ($format > 1) {
                $str .= 's';
            }
        }
    }
    
    return $str;
}

{
    no warnings 'once';
    *secondsToDuration = \&epochToDuration;
}

# -----------------------------------------------------------------------------

=head3 timestampToEpoch() - Wandele Timestamp in lokaler Zeit nach Epoch

=head4 Synopsis

    $t = $class->timestampToEpoch($timestamp);

=head4 Description

Es wird vorausgesetzt, dass der Timestamp das Format

    YYYY-MM-DD HH24:MI:SSXFF

hat.

Fehlende Teile werden als 0 angenommen, so dass insbesondere
auch folgende Formate gewandelt werden können:

    YYYY-MM-DD HH24:MI:SS    (keine Sekundenbruchteile)
    YYYY-MM-DD               (kein Zeitanteil)

Diese Methode ist z.B. nützlich, um einen Oracle-Timestamp
(in lokaler Zeit) nach Epoch zu wandeln.

=cut

# -----------------------------------------------------------------------------

sub timestampToEpoch {
    my ($class,$timestamp) = @_;

    my ($y,$m,$d,$h,$mi,$s,$ms) = split /\D+/,$timestamp;
    $y -= 1900;
    $m -= 1;
    $h ||= 0;
    $mi ||= 0;
    $s ||= 0;
    my $t = Time::Local::timelocal($s,$mi,$h,$d,$m,$y);
    if ($ms) {
        $t .= ".$ms";
    }

    return $t;
}

# -----------------------------------------------------------------------------

=head3 epochToTimestamp() - Wandele Epoch in Timestamp in lokaler Zeit

=head4 Synopsis

    $timestamp = $class->epochToTimestamp($t);

=head4 Description

Wandele Epoch-Wert $t in einen Timestamp der lokalen Zeitzone um
und liefere diesen zurück.

=head4 See Also

L<timestampToEpoch|"timestampToEpoch() - Wandele Timestamp in lokaler Zeit nach Epoch">()

=cut

# -----------------------------------------------------------------------------

sub epochToTimestamp {
    my ($class,$t) = @_;

    ($t,my $ms) = split /\./,$t;
    my ($s,$mi,$h,$d,$m,$y) = localtime $t;
    $m++;
    $y += 1900;

    my $str = sprintf '%4d-%02d-%02d %02d:%02d:%02d',$y,$m,$d,$h,$mi,$s;
    if ($ms) {
        $str .= ",$ms";
    }
    return $str;
}

# -----------------------------------------------------------------------------

=head2 Array/Hash

=head3 stringToKeyVal() - Wandele Zeichenkette in Schüssel/Wert-Paare

=head4 Synopsis

    $arr|@arr = $class->stringToKeyVal($str);

=head4 Description

Liefere die in der Zeichenkette enthaltenen Schlüssel/Wert-Paare.

Die Schlüssel/Wert-Paare haben die Form:

    $key="$val"

Wenn $val kein Whitespace enthält, können die Anführungsstriche
weggelassen werden:

    $key=$val

=head4 Example

    $class->stringToKeyVal(q|var1=val1 var2="val2"|);
    =>
    ('var1','val1','var2','val2a')

=head4 Caveats

Wenn $val mit einem doppelten Anführungsstrich beginnt, darf $val
keine doppelten Anführungsstiche enthalten.

=cut

# -----------------------------------------------------------------------------

sub stringToKeyVal {
    my ($class,$str) = @_;

    my @arr;
    while ($str =~ s/^\s*(\w+)=//) {
        push @arr,$1;
        $str =~ s/^"([^"]*)"// || $str =~ s/^\{([^}]*)\}// ||
            $str =~ s/^(\S*)//;
        push @arr,$1;
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.147

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
