# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Epoch - Ein Zeitpunkt

=head1 BASE CLASS

L<Quiq::Object>

=head1 GLOSSARY

=over 4

=item Epoch-Wert

Anzahl der Sekunden seit 1.1.1970, 0 Uhr UTC in hoher Auflösung,
also mit Nachkommastellen.

=item ISO-Zeitangabe

Zeitangabe in der Darstellung C<YYYY-MM-DD HH:MI:SS.X>.

=back

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Zeitpunkt. Die Klasse
implementiert Operationen auf einem solchen Zeitpunkt. Der
Zeitpunkt ist hochauflösend, umfasst also auch Sekundenbruchteile.

=cut

# -----------------------------------------------------------------------------

package Quiq::Epoch;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Time::HiRes ();
use Time::Local ();
use Quiq::Duration;
use Time::Zone ();
use POSIX ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $t = $class->new;
  $t = $class->new($epoch);
  $t = $class->new($iso);
  $t = $class->new('start-of-month');
  $t = $class->new('start-of-previous-month');
  $t = $class->new('start-of-next-month');

=head4 Description

Instantiiere ein Zeitpunkt-Objekt für Epoch-Wert $epoch bzw.
ISO-Zeitangabe $iso, letztere interpretiert in der lokalen
Zeitzone, und liefere dieses Objekt zurück. Ist kein Argument
angegeben, wird der aktuelle Zeitpunkt genommen.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $epoch = shift // scalar(Time::HiRes::gettimeofday);

    if ($epoch eq 'start-of-month') {
        my (undef,undef,undef,undef,$m,$y) = localtime;
        $epoch = Time::Local::timelocal(0,0,0,1,$m,$y);
    }
    elsif ($epoch eq 'start-of-next-month') {
        my (undef,undef,undef,undef,$m,$y) = localtime;
        if ($m == 11) {
            $m = 1;
            $y++;
        }
        else {
            $m++;
        }
        $epoch = Time::Local::timelocal(0,0,0,1,$m,$y);
    }
    elsif ($epoch eq 'start-of-previous-month') {
        my (undef,undef,undef,undef,$m,$y) = localtime;
        if ($m == 0) {
            $m = 11;
            $y--;
        }
        else {
            $m--;
        }
        $epoch = Time::Local::timelocal(0,0,0,1,$m,$y);
    }
    elsif ($epoch !~ /^[\d.]+$/) {
        # ISO Zeitangabe

        my $x;
        if ($epoch =~ s/(\.\d+)//) {
            $x = $1;
        }

        if (length($epoch) == 10) {
            $epoch .= ' 00:00:00';
        }

        my @arr = reverse split /\D+/,$epoch;
        $arr[4]--;
        $epoch = Time::Local::timelocal(@arr);
        if ($x) {
            $epoch .= $x;
        }
    }

    return bless \$epoch,$class;
} 

# -----------------------------------------------------------------------------

=head2 Zeitkomponenten

=head3 dayOfWeek() - Wochentagsnummer

=head4 Synopsis

  $i = $t->dayOfWeek;

=head4 Returns

Integer

=head4 Description

Liefere Wochentagsnummer im Bereich 0-6, 0 = Sonntag.

=cut

# -----------------------------------------------------------------------------

sub dayOfWeek {
    my $self = shift;
    return (localtime $$self)[6];
}

# -----------------------------------------------------------------------------

=head3 dayAbbr() - Abgekürzter Wochentagsname

=head4 Synopsis

  $abbr = $ti->dayAbbr;

=head4 Returns

String

=head4 Description

Liefere abgekürzten Wochentagsnamen (So, Mo, Di, Mi, Do, Fr, Sa).

=cut

# -----------------------------------------------------------------------------

our @DayAbbr = qw(So Mo Di Mi Do Fr Sa);

sub dayAbbr {
    my $self = shift;
    return $DayAbbr[$self->dayOfWeek];
}

# -----------------------------------------------------------------------------

=head3 dayName() - Wochentagsname

=head4 Synopsis

  $name = $ti->dayName;

=head4 Returns

String

=head4 Description

Liefere Wochentagsname (Sonntag, Montag, Dienstag, Mittwoch, Donnerstag,
Freitag, Samstag).

=cut

# -----------------------------------------------------------------------------

our @DayName = qw(Sonntag Montag Dienstag Mittwoch Donnerstag Freitag Samstag);

sub dayName {
    my $self = shift;
    return $DayName[$self->dayOfWeek];
}

# -----------------------------------------------------------------------------

=head3 year() - Jahr

=head4 Synopsis

  $year = $t->year;

=head4 Returns

Integer

=head4 Description

Liefere (vierstellige) Jahreszahl.

=cut

# -----------------------------------------------------------------------------

sub year {
    my $self = shift;
    return (localtime $$self)[5]+1900;
}

# -----------------------------------------------------------------------------

=head3 month() - Monatsnummer

=head4 Synopsis

  $month = $t->month;

=head4 Returns

Integer

=head4 Description

Liefere die ein- oder zweistellige Monatsnummer (1 .. 12).

=cut

# -----------------------------------------------------------------------------

sub month {
    my $self = shift;
    return (localtime $$self)[4]+1;
}

# -----------------------------------------------------------------------------

=head2 Zeit-Arithmetik

=head3 minus() - Verschiebe Zeitpunkt in Vergangenheit

=head4 Synopsis

  $t = $t->minus($duration);

=head4 Arguments

=over 4

=item $duration

Dauer, um die der Zeitpunkt in die Vergangenheit verschoben wird.
Die Dauer wird wie beim Konstruktor von Quiq::Duration angegeben.

=back

=head4 Returns

Geändertes Epoch-Objekt (für Method-Chaining)

=head4 Description

Verschiebe den Zeitpunkt um Dauer $duration in die Vergangenheit.

=cut

# -----------------------------------------------------------------------------

sub minus {
    my ($self,$duration) = @_;
    $$self -= Quiq::Duration->new($duration)->asSeconds;
    return $self;
}

# -----------------------------------------------------------------------------

=head3 plus() - Verschiebe Zeitpunkt in Zukunft

=head4 Synopsis

  $t = $t->plus($duration);

=head4 Arguments

=over 4

=item $duration

Dauer, um die der Zeitpunkt in die Zukunft verschoben wird. Die Dauer
wird wie beim Konstruktor von Quiq::Duration angegeben.

=back

=head4 Returns

Geändertes Epoch-Objekt (für Method-Chaining)

=head4 Description

Verschiebe den Zeitpunkt um Dauer $duration in die Zukunft.

=cut

# -----------------------------------------------------------------------------

sub plus {
    my ($self,$duration) = @_;
    $$self += Quiq::Duration->new($duration)->asSeconds;
    return $self;
}

# -----------------------------------------------------------------------------

=head3 tzOffset() - Zeit-Offset der lokalen Zeitzone

=head4 Synopsis

  $s = $this->tzOffset;

=head4 Returns

Anzahl Sekunden (Integer)

=head4 Description

Ermittele den aktuellen Offset der lokalen Zeitzone gegenüber UTC
in Sekunden und liefere diesen zurück.

=head4 Example

  Quiq::Epoch->tzOffset; # MEST
  ==>
  7200

(in Zeitzone MESZ)

=cut

# -----------------------------------------------------------------------------

sub tzOffset {
    my $this = shift;
    return Time::Zone::tz_local_offset;
}

# -----------------------------------------------------------------------------

=head2 Externe Repräsentation

=head3 epoch() - Liefere Epoch-Wert

=head4 Synopsis

  $epoch = $t->epoch;

=head4 Description

Liefere den Epoch-Wert des Zeitpunkts.

=head4 Example

  Quiq::Epoch->new->epoch;
  ==>
  1464342621.73231

=cut

# -----------------------------------------------------------------------------

sub epoch {
    return ${(shift)}
} 

# -----------------------------------------------------------------------------

=head3 localtime() - Zeitkomponenten in lokaler Zeit

=head4 Synopsis

  ($s,$mi,$h,$d,$m,$y) = $t->localtime;

=head4 Description

Liefere die Zeitkomponenten Sekunden, Minuten, Stunden, Tag, Monat, Jahr
in lokaler Zeit. Im Unterschied zu localtime() aus dem Perl Core sind
Monat ($m) und Jahr (y) "richtig" wiedergegeben. d.h die Komponente $m
muss nicht um 1 erhöht und die Komponente $y muss nicht um 1900
erhöht werden.

=head4 Example

  Quiq::Epoch->new(1559466751)->localtime;
  ==>
  (31,12,11,2,6,2019) # 2019-06-02 11:12:31

(in Zeitzone MESZ)

=cut

# -----------------------------------------------------------------------------

sub localtime {
    my $self = shift;

    my @arr = CORE::localtime $$self;
    $arr[4]++;
    $arr[5] += 1900;

    return @arr;
} 

# -----------------------------------------------------------------------------

=head3 as() - Erzeuge externe Darstellung

=head4 Synopsis

  $str = $t->as($fmt);

=head4 Arguments

=over 4

=item $fmt

Formatangabe. Folgende Formate sind definiert:

=over 4

=item YYYY-MM-DD

Datum in ISO-Darstellung.

=item YYYY-MM-DD HH:MI:SS

Zeit in ISO-Darstellung.

=item YYYY-MM-DD HH:MI:SS.XXX

Zeit in ISO-Darstellung mit Nachkommastellen. Die Anzahl der X
gibt die Anzahl der Nachkommastellen an (in obiger Angabe drei).

=back

=back

=head4 Returns

Zeit-Darstellung (String)

=head4 Description

Liefere eine externe Darstellung des Zeitpunkts gemäß Formatangabe $fmt.
Der Zeitpunkt wird in der lokalen Zeitzone interpretiert.

=head4 Example

  Quiq::Epoch->new->as('YYYY-MM-DD HH:MI:SS');
  =>
  2016-05-27 11:50:21

=cut

# -----------------------------------------------------------------------------

sub as {
    my ($self,$fmt) = @_;

    my ($strFmt,$n);
    if ($fmt eq 'YYYY-MM-DD HH:MI:SS') {
        $strFmt = '%Y-%m-%d %H:%M:%S';
    }
    elsif ($fmt eq 'YYYY-MM-DD') {
        $strFmt = '%Y-%m-%d';
    }
    elsif ($fmt =~ /^YYYY-MM-DD HH:MI:SS\.(X+)$/) {
        $strFmt = '%Y-%m-%d %H:%M:%S';
        $n = length($1);
    }
    else {
        $self->throw(
            'EPOCH-00001: Unknown time format',
            Format => $fmt,
        );
    }
    
    my $str = POSIX::strftime($strFmt,CORE::localtime $$self);
    if ($n) {
        # Mit Nachkommastellen

        my ($x) = $$self =~ /\.(\d+)/;
        $x //= '000000';
        $str .= '.'.substr $x,0,$n;
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 asIso() - Erzeuge ISO-Darstellung

=head4 Synopsis

  $str = $t->asIso;
  $str = $t->asIso($x);

=head4 Arguments

=over 4

=item $x (Default: 0)

Anzahl der Nachkommastellen.

=back

=head4 Returns

Zeit-Darstellung (String)

=cut

# -----------------------------------------------------------------------------

sub asIso {
    my ($self,$x) = @_;

    my $fmt = 'YYYY-MM-DD HH:MI:SS';
    if ($x) {
         $fmt .= '.'.('X' x $x);
    }

    return $self->as($fmt);
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
