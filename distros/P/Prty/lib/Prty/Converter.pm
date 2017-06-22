package Prty::Converter;
use base qw/Prty::Object/;

use strict;
use warnings;
use utf8;

our $VERSION = 1.108;

use POSIX ();
use Time::Local ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Converter - Konvertierung von Werten

=head1 BASE CLASS

L<Prty::Object>

=head1 METHODS

=head2 Zeichenketten

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

    $$ref =~ s/ä/ae/g;
    $$ref =~ s/ö/oe/g;
    $$ref =~ s/ü/ue/g;
    $$ref =~ s/Ä/Ae/g;
    $$ref =~ s/Ö/Oe/g;
    $$ref =~ s/Ü/Ue/g;
    $$ref =~ s/ß/ss/g;

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

=head4 Returns

Zeichenkette

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

L</timestampToEpoch>()

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

1.108

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2017 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
