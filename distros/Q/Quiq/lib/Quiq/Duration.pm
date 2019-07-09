package Quiq::Duration;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.151';

use Quiq::Option;
use Quiq::Math;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Duration - Rechnen und Konvertieren von Zeiträumen

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Zeitdauer, die intern als
numerischer Wert (Sekunden mit Nachkommastellen) gespeichert wird.

Als externe Repäsentation wird die Darstellung

    DdHhMmS.Xs

verwendet, wobei

    D = Anzahl Tage
    H = Anzahl Stunden
    M = Anzahl Minuten
    S = Anzahl Sekunden
    X = Bruchteil einer Sekunde

Es gelten folgende Eingenschaften:

=over 2

=item *

führende Anteile bis auf Ss fehlen, wenn sie 0 sind

=item *

X fehlt, wenn 0

=item *

Ss erscheint immer, auch bei 0 Sekunden

=item *

die leere Zeichenkette ('') oder undef entspricht 0 Sekunden

=item *

der Sekundenanteil kann Nachkommastellen haben

=back

Bei der Instantiierung kann die Zeitdauer auch in Doppelpunkt-Notation
übergeben werden:

    D:H:M:S.X

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $dur = Quiq::Duration->new($sec);
    $dur = Quiq::Duration->new($str);

=head4 Description

Instantiiere ein Zeitdauer-Objekt und liefere einen Referenz auf
dieses Objekt zurück. Die Zeitdauer kann als numerischer Wert $sec
oder als Zeichenkette $str angegeben werden. Die Zeichenkette
kann auch in Doppelpunkt-Notation (D:H:M:S.X) angegeben sein.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $sec = shift || 0;

    # Schlägt unerwünschterweise bei Zahl mit Exponentialdarstellung zu
    #
    #if ($sec !~ /^[0-9.:dhms]+$/) {
    #    $class->throw(
    #        'DURATION-00002: Illegal duration',
    #        Duration => $sec,
    #    );
    #}

    if ($sec =~ tr/:dhms//) {
        $sec = $class->stringToSeconds($sec);
    }

    return bless \$sec,$class;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 asSeconds() - Dauer in Sekunden

=head4 Synopsis

    $sec = $dur->asSeconds;

=head4 Description

Liefere die Zeitdauer in Sekunden - sofern vorhanden,
mit Nachkommastellen.

=cut

# -----------------------------------------------------------------------------

sub asSeconds {
    my $self = shift;
    return $$self;
}

# -----------------------------------------------------------------------------

=head3 asString() - Dauer als Zeichenkette

=head4 Synopsis

    $str = $dur->asString;
    $str = $dur->asString($prec);

=head4 Description

Liefere die Zeitdauer als Zeichenkette in der Form DdHhMmS.Xs.

=cut

# -----------------------------------------------------------------------------

sub asString {
    my ($self,$prec) = @_;
    return ref($self)->secondsToString($$self,$prec);
}

# -----------------------------------------------------------------------------

=head3 asShortString() - Dauer als kürzestmögliche Zeichenkette

=head4 Synopsis

    $str = $dur->asShortString(@opt);

=head4 Options

=over 4

=item -maxUnit => 'd'|'h'|'m'|'s' (Default: 'd')

Größte dargestellte Einheit.

=item -minUnit => 'd'|'h'|'m'|'s' (Default: 's')

Kleinste dargestellte Einheit.

=item -notBlank => $bool (Default: 0)

Bei einer Zeit von 0 Sekunden wird ein Leerstring geliefert.
Ist diese Option gesetzt, erfolgt immer eine Ausgabe -
mit -minUnit als Einheit.

=item -precision => $n (Default: 0)

Anzahl der Sekunden-Nachkommastellen.

=back

=head4 Description

Liefere die Zeitdauer als Zeichenkette der Form DdHhMmSs (per
Default, siehe Option -maxUnit), wobei alle Anteile, die 0 sind,
weggelassen werden, sowohl am Anfang als auch am Ende.

=cut

# -----------------------------------------------------------------------------

sub asShortString {
    my $self = shift;
    # @_: @opt

    my $maxUnit = 'd';
    my $minUnit = 's';
    my $notBlank = 0;
    my $precision = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -maxUnit => \$maxUnit,
            -minUnit => \$minUnit,
            -notBlank => \$notBlank,
            -precision => \$precision,
        );
    }

    my @unit = qw/d h m s/;
    my @arr = $self->asArray;

    if ($maxUnit =~ /^[hms]$/ && $arr[0]) {
        $arr[1] += $arr[0]*24;
        $arr[0] = 0;
    }
    if ($maxUnit =~ /^[ms]$/ && $arr[1]) {
        $arr[2] += $arr[1]*60;
        $arr[1] = 0;
    }
    if ($maxUnit eq 's' && $arr[2]) {
        $arr[3] += $arr[2]*60;
        $arr[2] = 0;
    }

    if ($minUnit =~ /^[dhm]$/ && $arr[3]) {
        $arr[2] += Quiq::Math->roundToInt($arr[3]/60);
        $arr[3] = 0;
    }
    if ($minUnit =~ /^[dh]$/ && $arr[2]) {
        $arr[1] += Quiq::Math->roundToInt($arr[2]/60);
        $arr[2] = 0;
    }
    if ($minUnit eq 'd' && $arr[1]) {
        $arr[0] += Quiq::Math->roundToInt($arr[1]/24);
        $arr[1] = 0;
    }

    if ($precision) {
        $arr[3] = sprintf '%.*f',$precision,$arr[3];
    }

    my $str = '';
    for my $i (0 .. 3) {
        if ($arr[$i] != 0) {
            $str .= $arr[$i].$unit[$i];
        }
    }
    if ($str eq '' && $notBlank) {
        $str = "0$minUnit";
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 asArray() - Dauer als Array

=head4 Synopsis

    @arr | $arr = $dur->asArray;

=head4 Description

Liefere die Dauer als Array mit den Komponenten
($days,$hours,$minutes,$seconds).

=cut

# -----------------------------------------------------------------------------

sub asArray {
    my $self = shift;

    my @arr;
    my $sec = $$self;
    for my $x (86400,3600,60) {
        my $fac = int($sec/$x);
        push @arr,$fac;
        $sec -= $fac*$x;
    }
    push @arr,$sec;

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 asFFmpegString() - Dauer als Parameter für ffmpeg-Option -t

=head4 Synopsis

    $str = $dur->asFFmpegString;

=head4 Description

Liefere Dauer in der Form wie sie ffmpeg bei der Option -t erwartet,
also im Format

    H:M:S.XXX

=cut

# -----------------------------------------------------------------------------

sub asFFmpegString {
    my $self = shift;
    my @arr = $self->asArray;
    return sprintf '%d:%d:%.3f',$arr[1],$arr[2],$arr[3];
}

# -----------------------------------------------------------------------------

=head3 stringToSeconds() - Wandele Zeitdauer-Angabe in Sekunden

=head4 Synopsis

    $sec = $this->stringToSeconds($str);

=head4 Description

Wandele Zeichenkette zur Bezeichnung einer Zeitdauer in die Anzahl
Sekunden.

=head4 Examples

Zeitdauer-Zeichenkette bestehend aus Tagen, Stunden, Mintuten, Sekunden:

    $sec = Quiq::Duration->stringToSeconds('152d5h25m3.457s');
    # 13152303.457

Dasselbe mit Doppelpunkt-Notation:

    $sec = Quiq::Duration->stringToSeconds('152:5:25:3.457');
    # 13152303.457

=cut

# -----------------------------------------------------------------------------

sub stringToSeconds {
    my ($class,$str) = @_;

    if ($str =~ tr/://) {
        # Repräsentation D:H:M:S.X nach DdHhMmS.Xs wandeln

        my @unit = qw/s m h d/;
        my @arr = reverse split /:/,$str;
        for (my $i = 0; $i < @arr; $i++) {
            $arr[$i] .= $unit[$i];
        }
        $str = join '',reverse @arr;
    }

    my $sec = 0;
    my @arr = split /([dhms])/,$str;
    for (my $i = 0; $i < @arr; $i += 2) {
        my $x = $arr[$i];
        my $unit = $arr[$i+1] || 's';
        if ($unit eq 'd') {
            $sec += $x*86400;
        }
        elsif ($unit eq 'h') {
            $sec += $x*3600;
        }
        elsif ($unit eq 'm') {
            $sec += $x*60;
        }
        elsif ($unit eq 's') {
            $sec += $x;
        }
        else {
            $class->throw(
                'DURATION-00001: Unbekannter Anteil einer Dauer',
                Unit => $unit,
                Value => $x,
            );
        }
    }

    return $sec;
}

# -----------------------------------------------------------------------------

=head3 secondsToString() - Wandele Sekunden in Zeitdauer-Zeichenkette

=head4 Synopsis

    $str = $this->secondsToString($sec,@opt);

=head4 Arguments

=over 4

=item $sec

Anzahl Sekunden, ggf. mit Nachkommastellen.

=back

=head4 Options

=over 4

=item $prec (Default: 0)

Anzahl der Nachkommastellen bei den Sekunden. Ist kein Wert angegeben,
wird auf ganze Sekunden gerundet.

=item $unit (Default: undef)

Liefere String fester Breite ab Einheit $unit.

=back

=head4 Description

Wandele Anzahl Sekunden in eine Zeichenkette zur Bezeichnung einer
Zeitdauer.

=cut

# -----------------------------------------------------------------------------

sub secondsToString {
    my $class = shift;
    my $sec = shift;
    # @_: $prec -and/or- $unit (Reihenfolge egal)

    # Negative Sekundenzahl

    my $minusSign = 0;
    if ($sec < 0) {
        $sec = abs $sec;
        $minusSign = 1;
    }

    # Optionen

    my $unit = '';
    my $prec = 0;
    while (@_) {
        if (!defined $_[0]) {
            # undef übergehen wir
            shift;
        }
        elsif ($_[0] =~ /^\d+$/) {
            $prec = shift;
        }
        else {
            $unit = shift;
        }
    }

    # Operation ausführen

    my @unit = qw/d h m s/;
    my @arr = $class->new($sec)->asArray;

    my $str = '';
    my $started = 0;
    my $append = 0;
    for (my $i = 0; $i <= 2; $i++) {
        if ($arr[$i]) {
            $started = 1;
        }
        if ($unit eq $unit[$i]) {
            $append = 1;
        }
        if ($started) {
            if ($append) {
                $str .= sprintf '%02d%s',$arr[$i],$unit[$i];
            }
            else {
                $str .= sprintf '%d%s',$arr[$i],$unit[$i];
            }
        }
    }
    $str =~ s/^0//;
    

    # Sekundenanteil immer liefern

    if ($unit) {
        $str .= sprintf "%02.*f%s",$prec,$arr[3],$unit[3];
        $str =~ s/^0(\d)/$1/; # etwaig führende 0 entfernen 
    }
    else {
        $str .= sprintf "%.*f%s",$prec,$arr[3],$unit[3];
        # 0-Angaben vom Ende her entfernen
        # FIXME: nicht nur Sekunden, sondern auch Minuten etc. entfernen,
        # wenn sie 0 sind. Besseren Ansatz wählen.
        # $str =~ s/(\D)0s$/$1/;
    }

    return $minusSign? "-$str": $str;
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
