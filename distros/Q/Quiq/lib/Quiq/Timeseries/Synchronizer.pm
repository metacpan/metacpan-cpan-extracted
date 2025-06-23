# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Timeseries::Synchronizer - Rasterung/Synchronisation von Zeitreihen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

Instantiiere Objekt, vereinbare Zeitraster und Werte

  my $tsy = Quiq::Timeseries::Synchronizer->new(600,
      qw/Temperature Windspeed/,
      -geoCoordinates => 1, # $latitude,$longitude bei add()
      -offset => 300,
  );

Füge Temperatur-Daten hinzu

  for my $row (Temperature->select($db,@where)) {
      $tsy->add($row->time,$row->latitude,$row->longitude,
          Temperature => $row->value,
      );
  }

Füge Windgeschwindigkeits-Daten hinzu

  for my $row (WindSpeed->select($db,@where)) {
      $tsy->add($row->time,$row->latitude,$row->longitude,
          Windspeed => $row->value,
      );
  }

Generiere Tabelle mit Daten

  my ($titleA,$rowA) = $tsy->rows(
      Temperature => [roundTo=>2,meanValue=>1,count=>1,stdDeviation=>1],
      WindSpeed => [roundTo=>2,meanValue=>1,count=>1,stdDeviation=>1],
      -noValue => 'NULL',
  );

Die resultierende Tabelle besitzt folgende Kolumnen:

  0 Time               (Rasterpunkt)
  1 Latitude           (Breite des Geo-Mittelpunkts)
  2 Longitude          (Länge des Geo-Mittelpunkts)
  3 Temperature        (Mittelwert)
  4 Temperature_Count  (Anzahl Werte)
  5 Temperature_StdDev (Standardabweichung)
  6 WindSpeed          (Mittelwert)
  7 WindSpeed_Count    (Anzahl Werte)
  8 WindSpeed_StdDev   (Standardabweichung)

=head1 DESCRIPTION

Die Klasse richtet eine oder mehrere Zeitreihen auf ein
gemeinsames Zeitraster mit der Intervallbreite $interval aus. Die
Intervallbreite wird in Sekunden angegeben.

  $interval = 600;

legt das Zeitraster auf 0, 10, 20, 30, 40, 50 Minuten.

  $interval = 600, -offset => 300

legt das Zeitraster auf 5, 15, 25, 35, 45, 55 Minuten.

=cut

# -----------------------------------------------------------------------------

package Quiq::Timeseries::Synchronizer;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Option;
use Quiq::Array;
use Quiq::Time;
use Quiq::Math;
use Quiq::Formatter;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor/Destruktor

=head4 Synopsis

  $tsy = $class->new($interval,@param,@opt);

=head4 Options

=over 4

=item -geoCoordinates => $bool (Default: 0)

Die Messerwerte haben zusätzlich zur Zeit eine Ortskoordinate.
Wenn gesetzt, erwartet die Methode L<add|"add() - Füge Parameterwerte hinzu">() zusätzlich die
Ortsangaben $latitude und $longitude.

=item -minTime => $t (Default: undef)

Ignoriere alle Daten, die vor Zeitpunkt $t (Unixzeit) liegen.

=item -maxTime => $t (Default: undef)

Ignoriere alle Daten, die nach Zeitpunkt $t (Unixzeit) liegen.

=item -offset => $s (Default: 0)

Versetze das Zeitraster um einem Offset von $s Sekunden.
Beispiel: Ein Offset von 300 bei einer Intervallbreite von 600 Sekunden
legt die Rasterpunkte auf 5, 15, 25, 35, 45, 55 Minuten.

=item -window => $s (Default: undef)

Betrachte nur Daten, die innerhalb von $s Sekunden um einen Rasterpunkt
liegen. Ignoriere Daten, die außerhalb liegen.

=back

=head4 Description

Instantiiere Synchronizer-Objekt für die Parameter @param mit einem
Zeitraster von $interval Sekunden und liefere eine Referenz auf
dieses Objekt zurück.

Die Liste @param vereinbart die Parameternamen, die auch bei add()
und rows() angegeben werden.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $interval = shift;
    # @_: @param,@opt

    # Optionen

    my $geoCoordinates = 0;
    my $maxTime;
    my $minTime;
    my $offset = 0;
    my $window;

    Quiq::Option->extract(\@_,
        -geoCoordinates => \$geoCoordinates,
        -maxTime => \$maxTime,
        -minTime => \$minTime,
        -offset => \$offset,
        -window => \$window,
    );

    # Parameter-Liste

    my %paramHash;
    @paramHash{@_} = (1)x@_;

    if ($window) {
        if ($window > $interval/2) {
            $class->throw(
                'TSYNC-00099: Windowbreite groesser Intervallbreite',
                WindowWidth => $window,
                IntervalWidth => $interval,
            );
        }
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        geoCoordinates => $geoCoordinates,
        interval => $interval,
        maxTime => $maxTime,
        minTime => $minTime,
        offset => $offset,
        window => $window,
        raster => {},
        paramArr => \@_,
        paramHash => \%paramHash,
    );
    $self->lockKeys;

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methoden

=head3 add() - Füge Parameterwerte hinzu

=head4 Synopsis

  $tsy->add($time,$param=>$value,...);
  $tsy->add($time,$latitude,$longitude,$param=>$value,...);

=head4 Description

Füge Wert $value des Parameters $param zur Zeit $time (Unixtime)
und (optional) dem Ort ($latitude, $longitude) hinzu.  Die Methode
liefert keinen Wert zurück. Es können mehrere Parameter/Wert-Paare
für dieselbe Zeit und demselben Ort hinzugefügt werden.

=cut

# -----------------------------------------------------------------------------

sub add {
    my $self = shift;
    my $time = shift;
    # @_: $latitude,$logitude,$param=>$value,... -or- $param=>$value,...

    my $geoCoordinates = $self->{'geoCoordinates'};
    my $interval = $self->{'interval'};
    my $minTime = $self->{'minTime'};
    my $maxTime = $self->{'maxTime'};
    my $offset = $self->{'offset'};
    my $window = $self->{'window'};
    my $raster = $self->{'raster'};
    my $paramHash = $self->{'paramHash'};
    my $paramArr = $self->{'paramArr'};

    # Werte außerhalb des Gesamtzeitbereichs (falls angegeben) wegfiltern

    if (defined $minTime && $time < $minTime
        || defined $maxTime && $time > $maxTime) {
        return;
    }

    # Raster-Zeitpunkt ermitteln (sicheres Runden wie in roundToInt())
    my $point = int(($time-$offset)/$interval+0.5)*$interval+$offset;

    # Abstand zu Rasterpunkt ermitteln
    my $distance = abs $time-$point;

    # Wert ignorieren, wenn er außerhalb des Fensters um den Rasterpunkt liegt
    return if $window && $distance > $window;

    # Geoposition sichern

    my ($latitude,$longitude);
    if ($geoCoordinates) {
        $latitude = shift;
        $longitude = shift;
    }

    for (my $i = 0; $i < @_; $i += 2) {
        my ($param,$value) = @_[$i,$i+1];

        # Gültigkeit des Parameter-Bezeichners prüfen

        if (!$paramHash->{$param}) {
            $self->throw(
                'TSYNC-00099: Unbekannter Parameter',
                Parameter => $param,
            );
        }

        # Nullwerte ignorieren

        if (!defined $value || $value eq '') {
            next;
        }

        # Wert in Punktraster eintragen. Aufbau der Datenstruktur:
        # $raster->{$point}->{$param}->[\@vals,\@coordinates,
        #     $closestDist,$closestVal]

        my $infoArr = $raster->{$point}->{$param} ||=
            [Quiq::Array->new,[],undef,undef];

        # Wert auf Liste pushen
        push @{$infoArr->[0]},$value;

        # Wert mit kleinstem zeitlichen Abstand zum Rasterpunkt speichern

        if (!defined $infoArr->[2] || $distance < $infoArr->[2]) {
            $infoArr->[2] = $distance;
            $infoArr->[3] = $value;
        }

        # Ortskoordinate auf Liste pushen

        if ($geoCoordinates) {
            push @{$infoArr->[1]},[$latitude,$longitude];
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 addParameter() - Füge Parameter hinzu

=head4 Synopsis

  $tsy->addParameter($param);

=head4 Description

Füge den zusätzlichen Parameter $param zum Objekt hinzu.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub addParameter {
    my ($self,$param) = @_;

    my ($paramArr,$paramHash) = $self->get(qw/paramArr paramHash/);
    push @$paramArr,$param;
    $paramHash->{$param} = 1;

    return;
}

# -----------------------------------------------------------------------------

=head3 parameters() - Liefere Liste der Parameterbezeichner

=head4 Synopsis

  @arr | $arr = $tsy->parameters;

=head4 Description

Liefere die Liste der Parameterbezeichner. Im Skalarkontext liefere
eine Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub parameters {
    my $self = shift;
    return wantarray? @{$self->{'paramArr'}}: $self->{'paramArr'};
}

# -----------------------------------------------------------------------------

=head3 rows() - Liefere Tabelle mit Zeitraster-Daten

=head4 Synopsis

  [$titleA,$rowA] = $tsy->rows(
      $param => [$paramOpt=>$val,...],
      ...,
      @opt,
  );

=head4 Options

=over 4

=item -noValue => $str (Default: '')

Zeichenkette für "Wert nicht vorhanden".

=item -timeFormat => $fmt (Default: 'yyyymmddhhmmss')

Format der Zeitkolumne.

=back

=head4 Description

Die erste Kolumne enthält die Zeit. Wenn bei Konstruktor die
Option -geoCoordinates gesetzt wurde, folgen geografische Breite
und Lnge.  Danach folgen die angegebenen Parameter mit ihren
Kolumnen.

B<Parameter-Optionen>

=over 4

=item meanValue => $bool

Generiere Kolumne mit Mittelwert über den Werten im Intervall.

=item stdDeviation => $bool

Generiere Kolumne mit Standardabweichung über den Werten im Intervall.

=item min => $bool

Generiere Kolumne mit kleinstem Wert im Intervall.

=item max => $bool

Generiere Kolumne mit größtem Wert im Intervall.

=item roundTo => $n

Runde die folgenden Kolumnenwerte auf $n Nachkommastellen.
Undef bedeutet keine Rundung, alle Stellen werden wiedergegeben.

=item count => $bool

Generiere Kolumne mit Anzahl der Werte im Intervall.

=item closestValue => $bool

Generiere Kolumne mit dem zeitlich am dichtesten am Rasterpunkt
gelegenen Wert.

=item closestTime => $bool

Generiere Kolumne mit dem Abstand in Sekunden, den der zeitlich
am dichtesten am Rasterpunkt gelegenen Wert hat.

=back

=cut

# -----------------------------------------------------------------------------

sub rows {
    my $self = shift;
    # @_: $param=>\@paramOpt,...@opt

    # Optionen

    my $noValue = '';
    my $timeFormat = 'yyyymmddhhmmss';

    Quiq::Option->extract(\@_,
        -noValue => \$noValue,
        -timeFormat => \$timeFormat,
    );

    # Objektattribute

    my $geoCoordinates = $self->{'geoCoordinates'};
    my $paramHash = $self->{'paramHash'};
    my $raster = $self->{'raster'};

    # Prüfe die Existenz der angegebenen Parameter

    for (my $i = 0; $i < @_; $i += 2) {
        my $param = $_[$i];

        unless ($paramHash->{$param}) {
            $self->throw(
                'TSYNC-00099: Unbekannter Parameter',
                Parameter => $param,
            );
        }
    }

    # Liste der Kolumnentitel erzeugen

    my @titles = ('Time');
    if ($geoCoordinates) {
        push @titles,'Latitude','Longitude';
    }
    for (my $i = 0; $i < @_; $i += 2) {
        my ($param,$optA) = @_[$i,$i+1];

        for (my $i = 0; $i < @$optA; $i += 2) {
            my ($opt,$optVal) = ($optA->[$i],$optA->[$i+1]);

            if ($opt eq 'roundTo') {
                next;
            }
            elsif ($opt eq 'meanValue') {
                next if !$optVal;
                push @titles,$param;
            }
            elsif ($opt eq 'stdDeviation') {
                next if !$optVal;
                push @titles,$param.'_StdDev';
            }
            elsif ($opt eq 'min') {
                next if !$optVal;
                push @titles,$param.'_Min';
            }
            elsif ($opt eq 'max') {
                next if !$optVal;
                push @titles,$param.'_Max';
            }
            elsif ($opt eq 'count') {
                next if !$optVal;
                push @titles,$param.'_Count';
            }
            elsif ($opt eq 'closestValue') {
                next if !$optVal;
                push @titles,$param.'_ClosestValue';
            }
            elsif ($opt eq 'closestTime') {
                next if !$optVal;
                push @titles,$param.'_ClosestTime';
            }
            else {
                $self->throw(
                    'TSYNC-00099: Unbekannte Parameter-Option',
                    Option => $opt,
                );
            }
        }
    }

    # Tabelle erzeugen

    my @rows;

    # Durchlaufe aufsteigend alle Raster-Zeitpunkte

    for my $point (sort keys %$raster) {
        my @row;
        my $ti = Quiq::Time->new(utc=>$point);
        push @row,$ti->$timeFormat;

        if ($geoCoordinates) {
            # Mittele die Geo-Koordinaten

            my @coordinates;
            for (my $i = 0; $i < @_; $i += 2) {
                my $param = $_[$i];
                # Quick-Fix: Wann ist das Array nicht definiert?
                if ($raster->{$point}->{$param}->[1]) {
                    push @coordinates,@{$raster->{$point}->{$param}->[1]};
                }
            }
            push @row,Quiq::Math->geoMidpoint(\@coordinates);
        }

        # Durchlaufe alle Parameter

        for (my $i = 0; $i < @_; $i += 2) {
            my ($param,$optA) = @_[$i,$i+1];

            my ($valueA,$coordA,$timeLag,$closestVal);
            if (exists $raster->{$point}->{$param}) {
                ($valueA,$coordA,$timeLag,$closestVal) =
                    @{$raster->{$point}->{$param}};
            }

            # Durchlaufe Parameter-Optionen

            my $places;
            for (my $i = 0; $i < @$optA; $i += 2) {
                my ($opt,$optVal) = ($optA->[$i],$optA->[$i+1]);

                if ($opt eq 'roundTo') {
                    $places = $optVal;
                    next;
                }

                my $val;
                if ($opt eq 'meanValue') {
                    next if !$optVal;
                    $val = $valueA? $valueA->meanValue: undef;
                }
                elsif ($opt eq 'stdDeviation') {
                    next if !$optVal;
                    $val = $valueA? $valueA->standardDeviation: undef;
                }
                elsif ($opt eq 'min') {
                    next if !$optVal;
                    $val = $valueA? $valueA->min: undef;
                }
                elsif ($opt eq 'max') {
                    next if !$optVal;
                    $val = $valueA? $valueA->max: undef;
                }
                elsif ($opt eq 'count') {
                    next if !$optVal;
                    $val = $valueA? @$valueA: undef;
                }
                elsif ($opt eq 'closestValue') {
                    next if !$optVal;
                    $val = $valueA? $closestVal: undef;
                }
                elsif ($opt eq 'closestTime') {
                    next if !$optVal;
                    $val = $valueA? $timeLag: undef;
                }
                else {
                    $self->throw(
                        'TSYNC-00099: Unbekannte Parameter-Option',
                        Option => $opt,
                    );
                }

                if (defined $places && defined $val) {
                    $val = Quiq::Math->roundTo($val,$places);
                }

                push @row,Quiq::Formatter->normalizeNumber($val);
            }
        }
        push @rows,\@row;
    }

    return (\@titles,\@rows);
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
