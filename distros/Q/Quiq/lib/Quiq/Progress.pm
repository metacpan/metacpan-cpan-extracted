package Quiq::Progress;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Option;
use Time::HiRes ();
use Quiq::Duration;
use Quiq::Math;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Progress - Berechne Fortschrittsinformation

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

Mit print:

    use Quiq::Progress;
    
    $| = 1;
    my $n = 5;
    my $p = Quiq::Progress->new($n);
    print $p->msg('Waiting...');
    for my $i (1 .. $n) {
        sleep 1;
        print $p->msg($i,'i/n x% t/t(t) x/s t/1');
    }
    print $p->msg;

Mit R1::Log2:

    use R1::Log2;
    use Quiq::Progress;
    
    my $log = R1::Log2->new(\*STDOUT);
    
    my $msg;
    my $n = 5;
    my $p = Quiq::Progress->new($n);
    for my $i (1 .. $n) {
        sleep 1;
        $msg = sprintf '%s %s %s %s %s',$p->info($i);
        $log->printCr($msg);
    }
    $log->printLn($msg);

Ohne Gesamtanzahl der Schritte. Anmerkungen:

=over 2

=item *

die Ausgabe der Prozentangabe wird unterdrückt

=item *

alle Ausgaben erfolgen ohne Bezug zu einer Gesamtanzahl (statt
Ausgabe I/N nur I, statt ZEIT/GESAMTZEIT(RESTZEIT) nur ZEIT)

=back

*

    use Quiq::Progress;
    
    $| = 1;
    my $p = Quiq::Progress->new;
    for my $i (1 .. 5) {
        print $pro->msg($i,'i/n x% t/t(t) x/h x/s t/1');
        sleep 1;
    }
    print $p->msg;
    1 0s 3600000/h 1000.00/s 0.00s/1\r
    2 1s 7200/h 2.00/s 0.50s/1\r
    3 2s 5400/h 1.50/s 0.67s/1\r
    4 3s 4788/h 1.33/s 0.75s/1\r
    5 4s 4500/h 1.25/s 0.80s/1\r
    5 5s 3600/h 1.00/s 1.00s/1\r

=head1 ATTRIBUTES

=over 4

=item n

Gesamtzahl der Schritte

=item t0

Startzeitpunkt

=item i

Aktueller Schritt

=item duration

Vergangene Zeit in Sekunden (mit Nachkommastellen)

=item msg

Die letzte von msg() erzeugte Meldung.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $pi = $class->new($n,@opt);

=head4 Arguments

=over 4

=item $n

Gesamtzahl der Schritte

=back

=head4 Options

=over 4

=item -show => $bool (Default: 1)

Die Klasse liefert Meldungen. Mit -show=>0 kann die Ausgabe von
Meldungen an-/abgeschaltet werden. Beispiel:

    $pi = $class->new($n,-show=>$verbose);

=back

=head4 Returns

Referenz auf Progress-Objekt

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: $n,@opt -or- @opt

    # Optionen und Argumente

    my $show = 1;

    Quiq::Option->extract(\@_,
        -show => \$show,
    );
    my $n = shift || 0;

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        t0 => scalar Time::HiRes::gettimeofday,
        n => $n,
        duration => 0,
        i => 0,
        fmt => '', # letztes Format
        msg => '', # letzte Meldung
        show => $show,
    );

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Schritt setzen

=head3 step() - Setze Progress-Objekt auf nächsten Schritt

=head4 Synopsis

    $pi->step($i);

=head4 Arguments

=over 4

=item $i

Aktueller Schritt.

=back

=cut

# -----------------------------------------------------------------------------

sub step {
    my ($self,$i) = @_;

    # Wir rechnen mit einer Auflösung von einer tausendstel Sekunde

    my $d = Time::HiRes::gettimeofday-$self->{'t0'};
    if ($d > 0 && $d < 0.001) {
        $d = 0.001;
    }

    $self->{'i'} = $i;
    $self->{'duration'} = $d;

    return;
}

# -----------------------------------------------------------------------------

=head2 Fortschritts- und Performance-Information

=head3 count() - Liefere "I/N"

=head4 Synopsis

    $str = $pi->count;

=head4 Description

Liefere Stand in der Form "I/N". I ist die Anzahl der absolvierten
Schritte, N ist die Anzahl der Gesamtschritte.

Liefere Stand in der Form "I", wenn die Anzahl der Gesamtschritte
(N) nicht bekannt ist.

=cut

# -----------------------------------------------------------------------------

sub count {
    my $self = shift;

    my $n = $self->{'n'};
    my $i = $self->{'i'};

    return $n? "$i/$n": $i;
}

# -----------------------------------------------------------------------------

=head3 percent() - Liefere Verarbeitungsstand als Prozentsatz

=head4 Synopsis

    $str = $pi->percent;

=head4 Description

Liefere Verarbeitungsstand in Prozent in der Form "X". Ist die
Gesamtanzahl der Schritte nicht bekannt, liefere einen Leersting.

=cut

# -----------------------------------------------------------------------------

sub percent {
    my $self = shift;

    my $n = $self->{'n'};
    if ($n == 0) {
        return '';
    }

    return sprintf '%.0f',$self->{'i'}/$n*100;
}

# -----------------------------------------------------------------------------

=head3 time() - Liefere "HhMmSs/HhMmSs(HhMmSs)"

=head4 Synopsis

    $str = $pi->time;

=head4 Description

Liefere Zeitinformation in der Form "HhMmSs/HhMmSs(HhMmSs)". Der erste
Teil ist die bislang verstrichene Zeit, der zweite Teil die geschätzte
Gesamtzeit, der dritte Teil ist die geschätzte verbleibende Zeit.

Liefere die Zeitinformation in der Form "HhMmSs", wenn die Anzahl
der Gesamtschritte (N) nicht bekannt ist.

=cut

# -----------------------------------------------------------------------------

sub time {
    my $self = shift;

    my $n = $self->{'n'};
    my $i = $self->{'i'};
    my $duration = $self->{'duration'};

    my $durStr .= sprintf '%s',Quiq::Duration->secondsToString($duration);

    if ($duration > 60) {
        $durStr .= sprintf '[%ds]',Quiq::Math->roundToInt($duration);
    }
    if (!$n || !$i) {
        return $durStr;
    }        

    my $durEst = $duration/$i*$n;
    my $durEstStr = Quiq::Duration->secondsToString($durEst);

    my $delta = $durEst-$duration;
    my $deltaStr = Quiq::Duration->secondsToString($delta);

    return "$durStr/$durEstStr($deltaStr)";
}

# -----------------------------------------------------------------------------

=head3 performance() - Liefere Durchsatz

=head4 Synopsis

    $str = $pi->performance;
    $str = $pi->performance($prec);

=head4 Arguments

=over 4

=item $prec

Anzahl Nachkommastellen

=back

=head4 Description

Liefere Durchsatz in der Form "X.XX" (Schritte pro Sekunde).

=cut

# -----------------------------------------------------------------------------

sub performance {
    my ($self,$prec) = @_;

    if (!defined $prec) {
        $prec = 2;
    }
    return sprintf '%.*f',$prec,$self->{'i'}/$self->{'duration'};
}

# -----------------------------------------------------------------------------

=head3 timePerStep() - Liefere Zeit pro Schritt

=head4 Synopsis

    $str = $pi->timePerStep;
    $str = $pi->timePerStep($prec);

=head4 Arguments

=over 4

=item $prec

Anzahl Nachkommastellen der Sekunde

=back

=head4 Description

Liefere Durchsatz in der Form "HhMmSs.x" (Zeit pro Schritt).

=cut

# -----------------------------------------------------------------------------

sub timePerStep {
    my ($self,$prec) = @_;

    if (!defined $prec) {
        $prec = 2;
    }
    my $x = $self->{'duration'}/$self->{'i'};
    return Quiq::Duration->secondsToString($x,$prec);
}

# -----------------------------------------------------------------------------

=head2 Information mit einem Aufruf

=head3 info() - Liefere alle Fortschritts- und Performance-Information

=head4 Synopsis

    ($count,$percent,$time,$performance,$timePerStep) = $pi->info;
    ($count,$percent,$time,$performance,$timePerStep) = $pi->info($i);

=head4 Arguments

=over 4

=item $i

Setze auf Schritt $i. Ist $i nicht angegeben, wird kein neuer Schritt
gesetzt, sondern die Information zum aktuellen Schritt geliefert.

=back

=head4 Returns

=over 4

=item $count

Verarbeitungsstand in der Form "I/N". I ist die Anzahl der absolvierten
Schritte, N ist die Anzahl der Gesamtschritte.

=item $percent

Verarbeitungsstand in Prozent.

=item $time

Zeitinformation in der Form "HhMmSs/HhMmSs". Der erste Teil ist die
bislang verstrichene Zeit, der zweite Teil die geschätzte Gesamtzeit.

=item $performance

Durchsatz in der Form "X.XX" (Schritte pro Sekunde).

=item $timePerStep

Durchsatz in der Form "HhMmSs.x" (Zeit pro Schritt).

=back

=cut

# -----------------------------------------------------------------------------

sub info {
    my ($self,$i) = @_;

    if ($i) {
        $self->step($i);
    }

    return (
        $self->count,
        $self->percent,
        $self->time,
        $self->performance,
        $self->timePerStep,
    );
}

# -----------------------------------------------------------------------------

=head2 Meldung generieren

=head3 msg() - Erzeuge Fortschrittsmeldung

=head4 Synopsis

    $str = $pi->msg;
    $str = $pi->msg($fmt,@args);
    $str = $pi->msg($i,$fmt,@args);

=head4 Arguments

=over 4

=item $i

Setze Objekt auf Schritt $i. Ist $i nicht angegeben, wird kein neuer
Schritt gesetzt, sondern die Information des aktuellen Schritts in
die Meldung eingesetzt.

=item $fmt

Formatelement für sprintf(), erweitert um folgende Platzhalter:

=over 4

=item i/n

Wert von $pi->count.

=item x%

Wert von $pi->percent.

=item t/t(t)

Wert von $pi->time.

=item x/s

Wert von $pi->performance.

=item x/h

Wert von $pi->performance*3600.

=item t/1

Wert von $pi->timePerStep.

=back

=item @args

Ausgabe-Zeichenketten oder Argumente für sprintf-Platzhalter.

=back

=head4 Returns

=over 4

=item $str

Erzeugte Meldung

=back

=head4 Description

Erzeuge eine Fortschrittsmeldung und liefere diese zurück.

Die Methode ist für die eine einzeilige Ausgabe konzipiert, die
sich kontnuierlich überschreibt, bis das Ende der Verarbeitung
erreicht ist. Die letzte Meldung bleibt stehen.

=over 4

=item 1.

Die erste Form (ohne Parameter) liefert die beim letzten
Aufruf produzierte Meldung - allerdings mit neu berechneten
Durchschittswerten - noch einmal mit "\n" am Zeilenende.

=item 2.

Die zweite Form erzeugt die Meldung für den aktuellen Schritt
und beendet sie mit "\r".

=item 3.

Die dritte Form bewirkt dasselbe wie 2), nur dass zuvor das
Objekt auf Schritt $i gesetzt wird.

=back

Ist bislang kein Schritt ausgeführt worden, liefert die Methode einen
Leerstring ("").

=cut

# -----------------------------------------------------------------------------

sub msg {
    my $self = shift;

    # Step setzen, wenn angegeben

    if (@_ && $_[0] =~ /^\d+$/) {
        $self->step(shift);
    }

    # Meldung erzeugen

    my $msg = '';
    if (!$self->{'show'}) {
        # Keine Meldung
    }
    elsif (@_) {
        my $fmt = shift;
        # @_: sprintf-Argumente

        # Format sichern (für $pro->msg ohne Parameter)

        $fmt =~ s/x%/x%%/g;
        $self->{'fmt'} = sprintf $fmt,@_;
        $fmt =~ s/x%%/x%/g;

        my $l0 = length $self->{'msg'};

        my $percent = $self->percent;
        if ($percent eq '') {
            $fmt =~ s|\s*x%||; # Prozentsatz unterdrücken
        }
        else {
            $fmt =~ s|x%|$self->percent.'%%'|e;
        }
        $fmt =~ s|i/n|$self->count|e;
        $fmt =~ s|t/t\(t\)|$self->time|e;
        $fmt =~ s|x/s|$self->performance.'/s'|e;
        $fmt =~ s|x/h|($self->performance*3600).'/h'|e;
        $fmt =~ s|t/1|$self->timePerStep.'/1'|e;

        $msg = sprintf $fmt,@_;

        my $eol = "\r";
        if ($msg =~ s/(\n+)$//) {
            # Ausgabe endet mit \n, wir setzen kein "\r" ans Ende,
            # nutzen aber die Überschreibung längerer Zeilen.

            $self->{'msg'} = '';
            $eol = $1;
        }
        else {
            $self->{'msg'} = $msg;
        }

        # Überstehenden Text längerer Zeilen mit Leerzeichen überschreiben

        my $l = length $msg;
        if ($l < $l0) {
            # Meldung mit Leerzeichen auffüllen, wenn vorige Meldung
            # länger war, damit überzählige Zeichen überschrieben werden.
            $msg .= ' ' x ($l0-$l+1);
        }
        $msg .= $eol;
    }
    else {
        # Wir berechnen die letzte Ausgabe auf Basis des Format-Strings
        # neu und berücksichtigen auf dem Weg die Laufzeit des
        # letzten Schritts. 

        my $fmt = $self->{'fmt'};
        if ($fmt ne '') {
            $msg = $self->msg($self->{'i'},$fmt);
            $msg =~ s/\r/\n/g;
        }
    }

    return $msg;
}

# -----------------------------------------------------------------------------

=head3 warn() - Erzeuge Warnung

=head4 Synopsis

    $str = $pi->warn(@args);
    $str = $pi->warn($fmt,@args);

=head4 Arguments

=over 4

=item $fmt

Formatelement für sprintf().

=item @args

Ausgabe-Zeichenketten oder Argumente für sprintf-Platzhalter.

=back

=head4 Returns

=over 4

=item $str

Erzeugte Meldung

=back

=head4 Example

Schreibe Warnung nach STDERR, die oberhalb der Fortschrittsanzeige
erscheint:

    warn $pro->warn("WARNING: Pfad erfüllt Regex nicht: $file");

=cut

# -----------------------------------------------------------------------------

sub warn {
    my $self = shift;
    # @_: @args -or- $fmt,@args

    # Meldung erzeugen

    my $msg = '';
    if (!$self->{'show'}) {
        # Keine Meldung
    }
    elsif (@_) {
        my $fmt = shift;
        # @_: sprintf-Argumente

        my $l0 = length $self->{'msg'};
        $msg = sprintf $fmt,@_;

        # Überstehenden Text längerer Zeilen mit Leerzeichen überschreiben

        $msg =~ s/\n+//;
        my $l = length $msg;
        if ($l < $l0) {
            # Meldung mit Leerzeichen auffüllen, wenn vorige Meldung
            # länger war, damit überzählige Zeichen überschrieben werden.
            $msg .= ' ' x ($l0-$l+1);
        }
        $msg .= "\n";
    }

    return $msg;
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
