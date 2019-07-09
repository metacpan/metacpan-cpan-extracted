package Quiq::Time;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.151';

use POSIX ();
use Time::Local ();
use Quiq::Duration;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Time - Klasse zur Repräsentation von Datum und Uhrzeit

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse Quiq::Time repräsentiert eine Zeitangabe,
bestehend aus den Komponenten Jahr (Y), Monat (M), Tag (D),
Stunde (h), Minute (m) und Sekunde (s). Die Klasse stellt Methoden
zur Manipulation der Zeitangabe zur Verfügung.

Die Zeitangabe ist keiner bestimmten Zeitzone zugeordnet, alle Tage
haben 24 Stunden (keine Sommerzeit- und Winterzeit-Umschaltung) und
alle Tage haben genau 86400 Sekunden (keine Schaltsekunden).

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Zeitobjekt

=head4 Synopsis

    $ti = $class->new($year,$month,$day,$hour,$minute,$second);
    $ti = $class->new($year,$month,$day,$hour,$minute);
    $ti = $class->new($year,$month,$day,$hour);
    $ti = $class->new($year,$month,$day);
    $ti = $class->new($year,$month);
    $ti = $class->new($year);
    $ti = $class->new(local=>$epoch);
    $ti = $class->new(utc=>$epoch);
    $ti = $class->new(dmy=>'D M Y');
    $ti = $class->new(dmyhms=>'D M Y H M S');
    $ti = $class->new(ymd=>'Y M D');
    $ti = $class->new(ymdhm=>'Y M D');
    $ti = $class->new(ymdhms=>'Y M D H M S');
    $ti = $class->new(parse=>'D.M.Y ...'|'M/D/Y ...'|'Y-M-D ...');
    $ti = $class->new;

=head4 Description

Instantiiere Zeitobjekt, setze die Zeitkomponenten auf die
angegebenen Werte und liefere das Objekt zurück.

Aufrufargumente siehe $ti->set().

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;

    my $self = bless [],$class;
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head3 copy() - Kopiere Zeitobjekt

=head4 Synopsis

    $ti2 = $ti->copy;

=head4 Description

Kopiere Zeitobjekt und liefere die Kopie zurück.

=cut

# -----------------------------------------------------------------------------

sub copy {
    my $self = shift;
    return bless [@$self],ref($self);
}

# -----------------------------------------------------------------------------

=head3 asArray() - Liefere Zeit als Array

=head4 Synopsis

    ($year,$month,$day,$hour,$minute,$second) = $ti->asArray;

=cut

# -----------------------------------------------------------------------------

sub asArray {
    my $self = shift;
    return @$self;
}

# -----------------------------------------------------------------------------

=head2 Zeit/Datum setzen

=head3 set() - Setze Zeit neu

=head4 Synopsis

    $ti = $class->set($year,$month,$day,$hour,$minute,$second);
    $ti = $class->set($year,$month,$day,$hour,$minute);
    $ti = $class->set($year,$month,$day,$hour);
    $ti = $class->set($year,$month,$day);
    $ti = $class->set($year,$month);
    $ti = $class->set($year);
    $ti = $class->set(local=>$epoch);
    $ti = $class->set(utc=>$epoch);
    $ti = $class->set(dmy=>'D M Y');
    $ti = $class->set(dmyhm=>'D M Y H M');
    $ti = $class->set(dmyhms=>'D M Y H M S');
    $ti = $class->set(ymd=>'Y M D');
    $ti = $class->set(ymdhm=>'Y M D');
    $ti = $class->set(ymdhms=>'Y M D H M S');
    $ti = $class->set(parse=>'D.M.Y ...'|'M/D/Y ...'|'Y-M-D ...');
    $ti = $class->set;

=head4 Description

Setze die Zeit gemäß der angegebenen Zeitkomponenten und liefere
das Zeitobjekt zurück.

Alle nicht angegebenen Komponenten werden auf ihren kleinsten Wert
initialisiert (1 bei bei Monat und Tag, 0 bei Stunde, Minute,
Sekunde).

Ein Aufruf ohne Argument setzt das Objekt auf den Beginn der Epoche
(1.1.1970 0 Uhr).

Bei den Formaten dmy, dmyhms, ... sind beliebige Trennzeichen
zwischen den einzelnen Zahlen erlaubt.

=cut

# -----------------------------------------------------------------------------

sub set {
    my $self = shift;

    if (!@_ || $_[0] eq 'utc' || $_[0] eq 'local') {
        my $zone = shift || 'utc';
        my $t = shift || 0;

        my @t = $zone eq 'utc'? gmtime($t): localtime($t);
        $#t = 5;
        $t[4]++;
        $t[5] += 1900;

        @$self = reverse @t;

        return $self;
    }

    my ($y,$mo,$d,$h,$mi,$s);

    if ($_[0] eq 'parse') {
        $_[1] =~ /^\d+(.)/;
        if ($1 eq '.') {        
            # deutsches Datum
            ($d,$mo,$y,$h,$mi,$s) = $_[1] =~ /\d+/g;
        }
        elsif ($1 eq '/') {
            # amerikanisches Datum
            ($mo,$d,$y,$h,$mi,$s) = $_[1] =~ /\d+/g;
        }
        elsif ($1 eq '-') {
            # ISO Datum
            ($y,$mo,$d,$h,$mi,$s) = $_[1] =~ /\d+/g;
        }
        else {
            # unbekanntes Format
            $self->throw('Not implemented');
        }
    }
    elsif ($_[0] eq 'ymd') {
        ($y,$mo,$d) = $_[1] =~ /^(\d+)\D+(\d+)\D+(\d+)$/;
        if (!$y) {
            ($y,$mo,$d) = $_[1] =~ /^(\d{4})(\d{2})(\d{2})$/;
        }
        $h = $mi = $s = 0;
    }
    elsif ($_[0] eq 'ymdhm') {
        ($y,$mo,$d,$h,$mi) =
            $_[1] =~ /^(\d+)\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d+)$/;
            # split /\D+/,$_[1];
    }
    elsif ($_[0] eq 'ymdhms') {
        ($y,$mo,$d,$h,$mi,$s) =
            $_[1] =~ /^(\d+)\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d+)$/;
            # split /\D+/,$_[1];
    }
    elsif ($_[0] eq 'dmy') {
        ($d,$mo,$y) = $_[1] =~ /^(\d+)\D+(\d+)\D+(\d+)$/;
        $h = $mi = $s = 0;
    }
    elsif ($_[0] eq 'dmyhms') {
        ($d,$mo,$y,$h,$mi,$s) =
            $_[1] =~ /^(\d+)\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d+)$/;
            # split /\D+/,$_[1];
    }
    else {
        ($y,$mo,$d,$h,$mi,$s) = @_;
    }

    $mo ||= 1;
    $d ||= 1;
    $h ||= 0;
    $mi ||= 0;
    $s ||= 0;

    # Prüfe Angaben auf Korrektheit

    if (!defined $y || $y !~ /^\d\d\d\d$/ ||
        !defined $mo || $mo !~ /^\d+$/ || $mo < 1 || $mo > 12 ||
        !defined $d || $d !~ /^\d+$/ || $d < 1 || $d > 31 ||
        !defined $h || $h !~ /^\d+$/ || $h < 0 || $h > 24 ||
        !defined $mi || $mi !~ /^\d+$/ || $mi < 0 || $mi > 60 ||
        !defined $s || $s !~ /^\d+$/ || $s < 0 || $s > 60) {
        $self->throw(
            'TIME-00002: Ungültige Zeitangabe',
            Time => join(', ',@_),
        );
    }

    eval {Time::Local::timegm($s,$mi,$h,$d,$mo-1,$y-1900)};
    if ($@) {
        $self->throw(
            'TIME-00002: Ungültige Zeitangabe',
            Time => join(',',@_),
            InternalError => $@,
        );
    }

    # +0 um führende 0en wegzubekommen
    @$self = ($y+0,$mo+0,$d+0,$h+0,$mi+0,$s+0);

    return $self;
}

# -----------------------------------------------------------------------------

=head3 setTime() - Setze Zeitanteil

=head4 Synopsis

    $ti = $ti->setTime($hour,$minute,$second);

=head4 Description

Setze die Zeit auf die angegebenen Stunden, Minuten, Sekunden
und liefere das Zeitobjekt zurück. Wird für eine Zeitkomponente CL<lt>undef>
angegeben, wird diese nicht gesetzt.

=cut

# -----------------------------------------------------------------------------

sub setTime {
    my $self = shift;
    my $h = shift;
    my $mi = shift;
    my $s = shift;

    if (defined $h) {
        if ($h < 0 || $h > 24) {
            $self->throw('TIME-00003: Illegale Stundenangabe',Hour=>$h);
        }
        $self->[3] = $h;
    }
    if (defined $mi) {
        if ($mi < 0 || $mi > 60) {
            $self->throw('TIME-00004: Illegale Minutenangabe',Minute=>$mi);
        }
        $self->[4] = $mi;
    }
    if (defined $s) {
        if ($s < 0 || $s > 60) {
            $self->throw('TIME-00005: Illegale Sekundenangabe',Second=>$s);
        }
        $self->[5] = $s;
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head3 truncate() - Kürze Zeitkomponenten

=head4 Synopsis

    $ti = $ti->truncate($unit);

=head4 Description

Kürze Zeit auf Jahr (Y), Monat (M), Tag (D), Stunde (h) oder Minute (m),
d.h. setze alle kleineren Zeitkomponenten auf ihren kleinsten Wert
und liefere das Zeitobjekt zurück.

=head4 Example

    $ti = Quiq::Time->new(2005,12,28,22,56,37);
    $ti->truncate('D');
    ==>
    2005-12-28-00-00-00

=cut

# -----------------------------------------------------------------------------

sub truncate {
    my $self = shift;
    my $unit = shift;

    unless ($unit =~ tr/mhDMY//) {
        $self->throw('TIME-00006: Ungültige Zeitkomponente',Unit=>$unit);
    }

    $self->[1] = 1 if $unit =~ tr/Y//;     # M
    $self->[2] = 1 if $unit =~ tr/MY//;    # D
    $self->[3] = 0 if $unit =~ tr/DMY//;   # h
    $self->[4] = 0 if $unit =~ tr/hDMY//;  # m
    $self->[5] = 0 if $unit =~ tr/mhDMY//; # s

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Abfrage von Zeitkomponenten

=head3 year() - Liefere Jahr

=head4 Synopsis

    $year = $ti->year;

=cut

# -----------------------------------------------------------------------------

sub year {
    return shift->[0];
}

# -----------------------------------------------------------------------------

=head3 month() - Liefere Monat (Nummer)

=head4 Synopsis

    $month = $ti->month;

=head4 Description

Liefere die Nummer des Monats. Wertebereich: 1-12.

=cut

# -----------------------------------------------------------------------------

sub month {
    return shift->[1];
}

# -----------------------------------------------------------------------------

=head3 day() - Liefere Tag des Monats (Nummer)

=head4 Synopsis

    $day = $ti->day;

=cut

# -----------------------------------------------------------------------------

sub day {
    return shift->[2];
}

# -----------------------------------------------------------------------------

=head3 dayAbbr() - Abgekürzter Wochentagsname

=head4 Synopsis

    $str = $ti->dayAbbr;

=head4 Description

Liefere abgekürzten Wochentagsnamen (Mo, Di, Mi, Do, Fr, Sa, So).

=cut

# -----------------------------------------------------------------------------

our @DayAbbr = qw(Mo Di Mi Do Fr Sa So);

sub dayAbbr {
    my $self = shift;
    return $DayAbbr[$self->dayOfWeek-1];
}

# -----------------------------------------------------------------------------

=head3 dayName() - Wochentagsname

=head4 Synopsis

    $n = $ti->dayName;

=head4 Description

Liefere Wochentagsname (Montag, Dienstag, Mittwoch, Donnerstag,
Freitag, Samstag, Sonntag).

=cut

# -----------------------------------------------------------------------------

our @DayName = qw(Montag Dienstag Mittwoch Donnerstag Freitag Samstag Sonntag);

sub dayName {
    my $self = shift;
    return $DayName[$self->dayOfWeek-1];
}

# -----------------------------------------------------------------------------

=head3 monthName() - Monatsname

=head4 Synopsis

    $str = $ti->monthName;

=head4 Description

Liefere Monatsnamen (Januar, Februar, ..., Dezember).

=cut

# -----------------------------------------------------------------------------

our %MonthName = (
    english => [qw/
        January
        February
        March
        April
        May
        June
        July
        August
        September
        October
        November
        December
    /],
    german => [qw/
        Januar
        Februar
        März
        April
        Mai
        Juni
        Juli
        August
        September
        Oktober
        November
        Dezember
    /],
);

sub monthName {
    my $self = shift;
    my $lang = shift // 'german';
    return $MonthName{$lang}->[$self->month-1];
}

# -----------------------------------------------------------------------------

=head3 dayOfWeek() - Wochentagsnummer

=head4 Synopsis

    $n = $ti->dayOfWeek;

=head4 Description

Liefere Wochentagsnummer im Bereich 1-7, 1 = Montag.

=cut

# -----------------------------------------------------------------------------

sub dayOfWeek {
    my $self = shift;
    my $t = Time::Local::timegm(0,0,0,$self->[2],$self->[1]-1,
        $self->[0]-1900);
    return (gmtime($t))[6] || 7;
}

# -----------------------------------------------------------------------------

=head3 daysOfMonth() - Anzahl der Tage des Monats

=head4 Synopsis

    $n = $ti->daysOfMonth;

=head4 Description

Liefere die Anzahl der Tage des Monats, also 31 für Januar,
28 oder 29 für Februar usw.

=cut

# -----------------------------------------------------------------------------

our @DaysOfMonth = (31,28,31,30,31,30,31,31,30,31,30,31);

sub daysOfMonth {
    my $self = shift;

    my $mo = $self->[1];
    return 29 if $mo == 2 && $self->isLeapyear;
    return $DaysOfMonth[$mo-1];
}

# -----------------------------------------------------------------------------

=head3 dayOfYear() - Tag des Jahres (Nummer)

=head4 Synopsis

    $n = $ti->dayOfYear;

=head4 Description

Liefere die Tagesnummer innerhalb des Jahres.

=cut

# -----------------------------------------------------------------------------

sub dayOfYear {
    my $self = shift;

    my $t1 = $self->epoch;
    my $t0 = ref($self)->new($self->year)->epoch;
    my $days = int(($t1-$t0)/86400)+1;

    return $days;
}

# -----------------------------------------------------------------------------

=head3 weekOfYear() - Kalenderwoche (Jahr, Wochennummer)

=head4 Synopsis

    ($year,$n) = $ti->weekOfYear;

=head4 Description

Liefere die Kalenderwoche, bestehend aus Jahr und Wochennummer
gemäß DIN 1355.

=cut

# -----------------------------------------------------------------------------

sub weekOfYear {
    my $self = shift;

    my $year = $self->year;
    my $day = $self->dayOfYear;
    my $dayOfWeek = ref($self)->new($year,1,1)->dayOfWeek;
    if ($dayOfWeek > 4) {
        $day -= 8-$dayOfWeek;
    }
    else {
        $day += $dayOfWeek-1;
    }
    if ($day <= 0) {
        return ($year-1,int(ref($self)->new($year-1,12,31)->dayOfYear/7)+1);
    }

    return ($year,int($day/7)+1);
}

# -----------------------------------------------------------------------------

=head3 epoch() - Epoch-Zeit

=head4 Synopsis

    $epoch = $ti->epoch('local');
    $epoch = $ti->epoch('utc');
    $epoch = $ti->epoch;

=head4 Description

Liefere Epoch-Zeit. Ein Aufruf ohne Argument ist äquivalent zu
$ti->epoch('utc').

=cut

# -----------------------------------------------------------------------------

sub epoch {
    my $self = shift;
    my $zone = shift || 'utc';

    my @t = reverse @$self;
    $t[4]--;
    # NEIN: $t[5] -= 1900;

    return $zone eq 'utc'? Time::Local::timegm(@t):
        Time::Local::timelocal(@t);
}

# -----------------------------------------------------------------------------

=head3 isLeapyear() - Prüfe auf Schaltjahr

=head4 Synopsis

    $bool = $ti->isLeapyear;

=head4 Description

Prüfe, ob Jahr ein Schaltjahr ist. Wenn ja, liefere "wahr",
andernfalls "falsch".

=cut

# -----------------------------------------------------------------------------

sub isLeapyear {
    my $y = shift->[0];
    return $y%4 == 0 && $y%100 != 0 || $y%400 == 0? 1: 0;
}

# -----------------------------------------------------------------------------

=head2 Ausgabe von Zeit/Datum

=head3 strftime() - Formatiere per strftime formatierte Zeit

=head4 Synopsis

    $str = $ti->strftime($fmt);

=cut

# -----------------------------------------------------------------------------

sub strftime {
    my ($self,$fmt) = @_;

    require POSIX;
    return POSIX::strftime $fmt,
        $self->[5], # s
        $self->[4], # mi
        $self->[3], # h
        $self->[2], # d
        $self->[1]-1, # mo
        $self->[0]-1900; # y
}

# -----------------------------------------------------------------------------

=head3 ddmmyyyy() - Liefere formatiertes Datum

=head4 Synopsis

    $str = $ti->ddmmyyyy;
    $str = $ti->ddmmyyyy($sep);

=head4 Description

Liefere Datum im Format DD.MM.YYYY, wobei Tag (DD) und Monat (MM) mit
führender 0 angegeben werden. Ist $sep angegeben, wird anstelle des
Punktes (.) die betreffende Zeichenkette als Trenner verwendet.

=cut

# -----------------------------------------------------------------------------

sub ddmmyyyy {
    my $self = shift;
    my $sep = @_? shift: '.';

    return sprintf '%02d%s%02d%s%04d',
        $self->[2],$sep,$self->[1],$sep,$self->[0];
}

# -----------------------------------------------------------------------------

=head3 ddmmyyyyhhmmss() - Liefere formatiertes Datum+Zeit

=head4 Synopsis

    $str = $ti->ddmmyyyyhhmmss;

=head4 Description

Liefere Datum/Zeit im Format "DD.MM.YYYY HH:MI:SS". Der Aufruf ist
äquvalent zu

    $str = $ti->ddmmyyyy.' '.$ti->hhmmss;

=cut

# -----------------------------------------------------------------------------

sub ddmmyyyyhhmmss {
    my $self = shift;
    return $self->ddmmyyyy.' '.$self->hhmmss;
}

# -----------------------------------------------------------------------------

=head3 dmy() - Liefere formatiertes Datum

=head4 Synopsis

    $str = $ti->dmy;
    $str = $ti->dmy($sep);

=head4 Description

Liefere Datum im Format D.M.YYYY, wobei Tag (D) und Monat (M) ohne
führende 0 angegeben werden. Ist $sep angegeben, wird anstelle des
Punktes (.) die betreffende Zeichenkette als Trenner verwendet.

=cut

# -----------------------------------------------------------------------------

sub dmy {
    my $self = shift;
    my $sep = @_? shift: '.';

    return sprintf '%d%s%d%s%d',
        $self->[2],$sep,$self->[1],$sep,$self->[0];
}

# -----------------------------------------------------------------------------

=head3 dmyhhmmss() - Liefere formatiertes Datum+Zeit

=head4 Synopsis

    $str = $ti->dmyhhmmss;

=head4 Description

Liefere Datum/Zeit im Format "D.M.YYYY HH:MI:SS". Der Aufruf ist
äquvalent zu

    $str = $ti->dmy.' '.$ti->hhmmss;

=cut

# -----------------------------------------------------------------------------

sub dmyhhmmss {
    my $self = shift;
    return $self->dmy.' '.$self->hhmmss;
}

# -----------------------------------------------------------------------------

=head3 dump() - Liefere Zeitobjekt als Zeichenkette

=head4 Synopsis

    $str = $ti->dump;
    $str = $ti->dump($sep);

=head4 Description

Liefere den internen Zustand des Zeitobjekts als Zeichenkette
im Format

    YYYY-MM-DD-hh-mm-ss

Ist $sep angegeben, verwende diesen String anstelle von '-' als
Trenner.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my ($self,$sep) = @_;

    if (!defined $sep) {
        $sep = '-';
    }

    return sprintf "%4d$sep%02d$sep%02d$sep%02d$sep%02d$sep%02d",@$self;
}

# -----------------------------------------------------------------------------

=head3 hhmmss() - Liefere formatierte Zeit

=head4 Synopsis

    $str = $ti->hhmmss;
    $str = $ti->hhmmss($sep);

=head4 Description

Liefere Zeit im Format HH:MM:SS, wobei alle Angaben zweistellig sind,
also ggf. eine führende 0 vorangestellt wird. Ist $sep angegeben, wird
anstelle des Doppelpunkts (:) die betreffende Zeichenkette als Trenner
verwendet.

=cut

# -----------------------------------------------------------------------------

sub hhmmss {
    my $self = shift;
    my $sep = @_? shift: ':';

    return sprintf '%02d%s%02d%s%02d',
        $self->[3],$sep,$self->[4],$sep,$self->[5];
}

# -----------------------------------------------------------------------------

=head3 hhmm() - Liefere formatierte Zeit

=head4 Synopsis

    $str = $ti->hhmm;
    $str = $ti->hhmm($sep);

=head4 Description

Liefere Zeit im Format HH:MM, wobei alle Angaben zweistellig sind,
also ggf. eine führende 0 vorangestellt wird. Ist $sep angegeben, wird
anstelle des Doppelpunkts (:) die betreffende Zeichenkette als Trenner
verwendet.

=cut

# -----------------------------------------------------------------------------

sub hhmm {
    my $self = shift;
    my $sep = @_? shift: ':';

    return sprintf '%02d%s%02d',$self->[3],$sep,$self->[4];
}

# -----------------------------------------------------------------------------

=head3 yymmdd() - Liefere formatiertes Datum

=head4 Synopsis

    $str = $ti->yymmdd;
    $str = $ti->yymmdd($sep);

=head4 Description

Liefere Datum im Format YY-MM-DD, wobei das Jahr zweistellig angegeben
ist und Tag (DD) und Monat (MM) mit führender 0 angegeben werden. Ist
$sep angegeben, wird anstelle des Bindestrichs (-) die betreffende
Zeichenkette als Trenner verwendet.

=cut

# -----------------------------------------------------------------------------

sub yymmdd {
    return substr(shift->yyyymmdd(@_),2);
}

# -----------------------------------------------------------------------------

=head3 yyyymmdd() - Liefere formatiertes Datum

=head4 Synopsis

    $str = $ti->yyyymmdd;
    $str = $ti->yyyymmdd($sep);

=head4 Description

Liefere Datum im Format YYYY-MM-DD, wobei Tag (DD) und Monat (MM) mit
führender 0 angegeben werden. Ist $sep angegeben, wird anstelle des
Bindestrichs (-) die betreffende Zeichenkette als Trenner verwendet.

=cut

# -----------------------------------------------------------------------------

sub yyyymmdd {
    my $self = shift;
    my $sep = @_? shift: '-';

    return sprintf '%04d%s%02d%s%02d',
        $self->[0],$sep,$self->[1],$sep,$self->[2];
}

# -----------------------------------------------------------------------------

=head3 yyyymmddhhmmss() - Liefere formatiertes Datum+Zeit

=head4 Synopsis

    $str = $ti->yyyymmddhhmmss;
    $str = $ti->yyyymmddhhmmss($sep);

=head4 Alias

iso()

=head4 Description

Liefere Datum/Zeit im Format "YYYY-MM-DDXHH:MI:SS", wobei X
das Trennzeichen zwischen Datum und Uhrzeit ist. Der Aufruf ist
äquvalent zu

    $str = $ti->yyyymmdd.$sep.$ti->hhmmss;

Ist $sep nicht angegeben, wird ein Leerzeichen als Trenner genommen.

=cut

# -----------------------------------------------------------------------------

sub yyyymmddhhmmss {
    my $self = shift;
    my $sep = @_? shift: ' ';
    return $self->yyyymmdd.$sep.$self->hhmmss;
}

{
    no warnings 'once';
    *iso = \&yyyymmddhhmmss;
}

# -----------------------------------------------------------------------------

=head3 yyyymmddhhmm() - Liefere formatiertes Datum + Stunde + Minute

=head4 Synopsis

    $str = $ti->yyyymmddhhmm;
    $str = $ti->yyyymmddhhmm($sep);

=head4 Description

Liefere Datum/Zeit im Format "YYYY-MM-DDXHH:MI", wobei X
das Trennzeichen zwischen Datum und Uhrzeit ist. Der Aufruf ist
äquvalent zu

    $str = $ti->yyyymmdd.$sep.$ti->hhmm;

Ist $sep nicht angegeben, wird ein Leerzeichen als Trenner genommen.

=cut

# -----------------------------------------------------------------------------

sub yyyymmddhhmm {
    my $self = shift;
    my $sep = @_? shift: ' ';
    return $self->yyyymmdd.$sep.$self->hhmm;
}

# -----------------------------------------------------------------------------

=head3 yyyymmddxhhmmss() - Liefere formatiertes Datum+Zeit mit +-Trenner

=head4 Synopsis

    $str = $ti->yyyymmddxhhmmss;

=head4 Description

Liefere Datum/Zeit im Format "YYYY-MM-DD+HH:MI:SS". Der Aufruf ist
äquvalent zu

    $str = $ti->yyyymmddhhmmss('+');

=cut

# -----------------------------------------------------------------------------

sub yyyymmddxhhmmss {
    return shift->yyyymmddhhmmss('+');
}

# -----------------------------------------------------------------------------

=head2 Zeitarithmetik

=head3 add() - Addiere Zeitkomponenten

=head4 Synopsis

    $ti = $ti->add($n1,$unit1,$n2,$unit2,...);

=head4 Description

Addiere die angegebenen Zeitkomponenten ($nI, $unitI) für Jahr (Y),
Monat (M) oder Tag (D) zur Zeit hinzu und liefere das modifizierte
Zeitobjekt zurück. Die $nI sind ganze Zahlen, können also auch negativ
sein.

=head4 Example

    $ti = Quiq::Time->new(2005,12,28,22,56,37);
    $ti->add(3,'Y',5,'M',-1,'D');
    ==>
    2009-05-27-22-56-37

=cut

# -----------------------------------------------------------------------------

sub add {
    my $self = shift;

    while (@_) {
        my $n = shift;
        my $unit = shift;

        if ($unit eq 'Y') { $self->addYears($n) }
        elsif ($unit eq 'M') { $self->addMonths($n) }
        elsif ($unit eq 'D') { $self->addDays($n) }
        else {
            $self->throw('TIME-00001: Ungültige Zeitkomponente',Unit=>$unit);
        }
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head3 addYears() - Addiere n Jahre

=head4 Synopsis

    $ti = $ti->addYears($n);

=head4 Description

Addiere $n Jahre zum Zeitobjekt hinzu ($n ist eine ganze Zahl, kann
also auch negativ sein) und liefere das modifizierte Zeitobjekt
zurück.

=head4 Example

=over 2

=item *

Jahre hinzuaddieren

    $ti = Quiq::Time->new(2005,12,28,22,56,37);
    $ti->addYears(5);
    ==>
    2010-12-28-00-00-00

=item *

Jahre abziehen

    $ti = Quiq::Time->new(2005,12,28,22,56,37);
    $ti->addYears(-6);
    ==>
    1999-12-28-00-00-00

=back

=cut

# -----------------------------------------------------------------------------

sub addYears {
    my $self = shift;
    my $n = shift;

    $self->[0] += $n;

    return $self;
}

# -----------------------------------------------------------------------------

=head3 addMonths() - Addiere n Monate

=head4 Synopsis

    $ti = $ti->addMonths($n);

=head4 Description

Addiere $n Monate zum Zeitobjekt hinzu ($n ist eine ganze Zahl, kann
also auch negativ sein) und liefere das modifizierte Zeitobjekt
zurück.

=cut

# -----------------------------------------------------------------------------

sub addMonths {
    my $self = shift;
    my $n = shift;

    # $sum ==
    # -13 -12 -11 -10 -9 ... -3 -2 -1  0 1 2 3 4 5 6 7 8 9 10 11 12 13 14
    # $m =
    #  11  12   1   2  3 ...  9 10 11 12 1 2 3 4 5 6 7 8 9 10 11 12  1  2
    # $y +=
    #  -2  -2  -1  -1 -1     -1 -1 -1 -1 0 0 0 0 0 0 0 0 0  0  0  0 +1 +1 

    my $sum = $self->[1]+$n;
    $self->[0] += POSIX::floor(($sum-1)/12);
    $self->[1] = $sum%12 || 12;

    return $self;
}

# -----------------------------------------------------------------------------

=head3 addDays() - Addiere n Tage

=head4 Synopsis

    $ti = $ti->addDays($n);

=head4 Description

Addiere $n Tage zum Zeitobjekt hinzu ($n ist eine ganze Zahl, kann
also auch negativ sein) und liefere das modifizierte Zeitobjekt
zurück.

=cut

# -----------------------------------------------------------------------------

sub addDays {
    my $self = shift;
    my $n = shift;

    my $t = $self->epoch;
    $t += 86400*$n;
    $self->set(utc=>$t);

    return $self;
}

# -----------------------------------------------------------------------------

=head3 addHours() - Addiere n Stunden

=head4 Synopsis

    $ti = $ti->addHours($n);

=head4 Description

Addiere $n Stunden zum Zeitobjekt hinzu ($n ist eine ganze Zahl, kann
also auch negativ sein) und liefere das modifizierte Zeitobjekt
zurück.

=cut

# -----------------------------------------------------------------------------

sub addHours {
    my $self = shift;
    my $n = shift;

    my $t = $self->epoch;
    $t += $n*3600;
    $self->set(utc=>$t);

    return $self;
}

# -----------------------------------------------------------------------------

=head3 addMinutes() - Addiere n Minuten

=head4 Synopsis

    $ti = $ti->addMinutes($n);

=head4 Description

Addiere $n Minuten zum Zeitobjekt hinzu ($n ist eine ganze Zahl, kann
also auch negativ sein) und liefere das modifizierte Zeitobjekt
zurück.

=cut

# -----------------------------------------------------------------------------

sub addMinutes {
    my $self = shift;
    my $n = shift;

    my $t = $self->epoch;
    $t += $n*60;
    $self->set(utc=>$t);

    return $self;
}

# -----------------------------------------------------------------------------

=head3 addSeconds() - Addiere n Sekunden

=head4 Synopsis

    $ti = $ti->addSeconds($n);

=head4 Description

Addiere $n Sekunden zum Zeitobjekt hinzu ($n ist eine ganze Zahl, kann
also auch negativ sein) und liefere das modifizierte Zeitobjekt
zurück.

=cut

# -----------------------------------------------------------------------------

sub addSeconds {
    my $self = shift;
    my $n = shift;

    my $t = $self->epoch;
    $t += $n;
    $self->set(utc=>$t);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Vergleich von Zeiten

=head3 equal() - Prüfe auf Gleichheit

=head4 Synopsis

    $bool = $ti1->equal($ti2);

=head4 Description

Liefere "wahr", wenn der Zeitpunkt $ti1 gleich dem Zeitpunkt $ti2
ist, andernfalls "falsch".

=cut

# -----------------------------------------------------------------------------

sub equal {
    return shift->epoch == shift->epoch;
}

# -----------------------------------------------------------------------------

=head3 less() - Prüfe auf kleiner

=head4 Synopsis

    $bool = $ti1->less($ti2);

=head4 Description

Liefere "wahr", wenn der Zeitpunkt $ti1 vor dem Zeitpunkt $ti2
liegt, andernfalls "falsch".

=cut

# -----------------------------------------------------------------------------

sub less {
    return shift->epoch < shift->epoch;
}

# -----------------------------------------------------------------------------

=head3 lessOrEqual() - Prüfe auf kleinergleich

=head4 Synopsis

    $bool = $ti1->lessOrEqual($ti2);

=head4 Description

Liefere "wahr", wenn der Zeitpunkt $ti1 vor oder gleich dem Zeitpunkt
$ti2 ist, andernfalls "falsch".

=cut

# -----------------------------------------------------------------------------

sub lessOrEqual {
    return shift->epoch <= shift->epoch;
}

# -----------------------------------------------------------------------------

=head2 Zeitdifferenz

=head3 diff() - Differenz zweier Zeiten

=head4 Synopsis

    $dur = $ti1->diff($ti2);

=head4 Description

Bilde die Differenz zweier Zeit-Objekte $ti2-$ti1 und liefere ein
Zeitdauer-Objekt $dur zurück.

Dauer in Sekunden:

    $sec = $dur->asSeconds;

Dauer als Zeichenkette (I<D>dI<H>hI<M>mI<S.X>s):

    $str = $dur->asString;

=cut

# -----------------------------------------------------------------------------

sub diff {
    my ($t1,$t2) = @_;
    return Quiq::Duration->new($t2->epoch-$t1->epoch);
}

# -----------------------------------------------------------------------------

=head2 Konvertierung (Klassenmethoden)

=head3 monthAbbrToNum() - Liefere Monatsnummer zu Monats-Abkürzung

=head4 Synopsis

    $n = $class->monthAbbrToNum($abbr);
    $n = $class->monthAbbrToNum($abbr,$lang);

=head4 Description

Liefere Monatsnummer (1, ..., 12) zur Monatsabkürzung der
Sprache $lang. Default für $lang ist 'en'.

=cut

# -----------------------------------------------------------------------------

our $MonthAbbr = {
    de => {
        Jan => 1,
        Feb => 2,
        Mär => 3,
        Apr => 4,
        Mai => 5,
        Jun => 6,
        Jul => 7,
        Aug => 8,
        Sep => 9,
        Okt => 10,
        Nov => 11,
        Dez => 12,
    },
    en => {
        Jan => 1,
        Feb => 2,
        Mar => 3,
        Apr => 4,
        May => 5,
        Jun => 6,
        Jul => 7,
        Aug => 8,
        Sep => 9,
        Oct => 10,
        Nov => 11,
        Dec => 12,
    },
};

sub monthAbbrToNum {
    my $self = shift;
    my $abbr = shift;
    my $lang = shift || 'en';

    my $n = $MonthAbbr->{$lang}->{$abbr};
    if (!$n) {
        $self->throw(
            'TIME-00099: Unknown month abbreviation',
            Abbreviation => $abbr,
            Language => $lang,
        );
    }

    return $n;
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
