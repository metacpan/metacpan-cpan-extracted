package Prty::Progress;
use base qw/Prty::Hash/;

use strict;
use warnings;

our $VERSION = 1.107;

use Prty::Option;
use Time::HiRes ();
use Prty::Duration;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Progress - Berechne Fortschrittsinformation

=head1 BASE CLASS

L<Prty::Hash>

=head1 SYNOPSIS

Mit print:

    use Prty::Progress;
    
    $| = 1;
    my $n = 5;
    my $p = Prty::Progress->new(5);
    for my $i (1 .. $n) {
        sleep 1;
        print $p->msg($i,'i/n x% t/t(t) x/s t/1');
    }
    print $p->msg;

Mit R1::Log2:

    use R1::Log2;
    use Prty::Progress;
    
    my $log = R1::Log2->new(\*STDOUT);
    
    my $msg;
    my $n = 5;
    my $p = Prty::Progress->new($n);
    for my $i (1 .. $n) {
        sleep 1;
        $msg = sprintf '%s %s %s %s %s',$p->info($i);
        $log->printCr($msg);
    }
    $log->printLn($msg);

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

Die Methode liefert Meldungen. Mit -show=>0 kann die Ausgabe von
Meldungen verhindert werden. Beispiel:

    $pi = $class->new($n,-show=>$verbose);

=back

=head4 Returns

Referenz auf Progress-Objekt

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $n = shift;
    # @_: @opt

    # Optionen

    my $show = 1;
    Prty::Option->extract(\@_,
        -show=>\$show,
    );

    # Objekt instantiieren

    return $class->SUPER::new(
        t0=>scalar Time::HiRes::gettimeofday,
        n=>$n,
        duration=>0,
        i=>0,
        msg=>'',
        show=>$show,
    );
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

=cut

# -----------------------------------------------------------------------------

sub count {
    my $self = shift;
    return "$self->{'i'}/$self->{'n'}";
}

# -----------------------------------------------------------------------------

=head3 percent() - Liefere "X%"

=head4 Synopsis

    $str = $pi->percent;

=head4 Description

Liefere Verarbeitungsstand in Prozent.

=cut

# -----------------------------------------------------------------------------

sub percent {
    my $self = shift;
    return sprintf '%.0f%%',$self->{'i'}/$self->{'n'}*100;
}

# -----------------------------------------------------------------------------

=head3 time() - Liefere "HhMmSs/HhMmSs(HhMmSs)"

=head4 Synopsis

    $str = $pi->time;

=head4 Description

Liefere Zeitinformation in der Form "HhMmSs/HhMmSs(HhMmSs)". Der erste
Teil ist die bislang verstrichene Zeit, der zweite Teil die geschätzte
Gesamtzeit, der dritte Teil ist die geschätzte verbleibende Zeit.

=cut

# -----------------------------------------------------------------------------

sub time {
    my $self = shift;

    my $n = $self->{'n'};
    my $i = $self->{'i'};
    my $duration = $self->{'duration'};

    my $durStr = Prty::Duration->secondsToString($duration);
    my $durEst = $duration/$i*$n;
    my $durEstStr = Prty::Duration->secondsToString($durEst);

    my $delta = $durEst-$duration;
    my $deltaStr = Prty::Duration->secondsToString($delta);

    return "$durStr/$durEstStr($deltaStr)";
}

# -----------------------------------------------------------------------------

=head3 performance() - Liefere "X.XX/s"

=head4 Synopsis

    $str = $pi->performance;
    $str = $pi->performance($prec);

=head4 Description

Liefere Durchsatz in der Form "X.XX/s" (Schritte pro Sekunde).

=head4 Arguments

=over 4

=item $prec

Anzahl Nachkommastellen

=back

=cut

# -----------------------------------------------------------------------------

sub performance {
    my ($self,$prec) = @_;

    if (!defined $prec) {
        $prec = 2;
    }
    return sprintf '%.*f/s',$prec,$self->{'i'}/$self->{'duration'};
}

# -----------------------------------------------------------------------------

=head3 timePerStep() - Liefere "HhMmS.XXs/1"

=head4 Synopsis

    $str = $pi->timePerStep;
    $str = $pi->timePerStep($prec);

=head4 Description

Liefere Durchsatz in der Form "HhMmSs.x/1" (Zeit pro Schritt).

=head4 Arguments

=over 4

=item $prec

Anzahl Nachkommastellen der Sekunde

=back

=cut

# -----------------------------------------------------------------------------

sub timePerStep {
    my ($self,$prec) = @_;

    if (!defined $prec) {
        $prec = 2;
    }
    my $x = $self->{'i'}/$self->{'duration'};
    return sprintf '%s/1',Prty::Duration->secondsToString($x,$prec);
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

Durchsatz in der Form "X.XX/s" (Schritte pro Sekunde).

=item $timePerStep

Durchsatz in der Form "HhMmSs.x/1" (Zeit pro Schritt).

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

=head4 Description

Erzeuge eine Fortschrittsmeldung und liefere diese zurück.

Die Methode ist für die eine einzeilige Ausgabe konzipiert, die
sich kontnuierlich überschreibt, bis das Ende der Verarbeitung
erreicht ist. Die letzte Meldung bleibt stehen.

=over 4

=item 1.

Die erste Form (ohne Parameter) liefert die zuletzt erzeugte
Meldung noch einmal mit "\n" am Zeilenende.

=item 2.

Die zweite Form erzeugt die Meldung für den aktuellen Schritt
und beendet sie mit "\r".

=item 3.

Die dritte Form bewirkt dasselbe wie 2), nur dass zuvor das
Objekt auf Schritt $i gesetzt wird.

=back

Ist bislang kein Schritt ausgeführt worden, liefert die Methode einen
Leerstring ("").

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

=item t/1

Wert von $pi->timePerStep.

=back

=item @args

Argumente für sprintf-Platzhalter.

=back

=head4 Returns

=over 4

=item $msg

Erzeugte Meldung

=back

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

        my $l0 = length $self->{'msg'};

        $fmt =~ s|i/n|$self->count|e;
        $fmt =~ s|x%|$self->percent.'%'|e;
        $fmt =~ s|t/t\(t\)|$self->time|e;
        $fmt =~ s|x/s|$self->performance|e;
        $fmt =~ s|t/1|$self->timePerStep|e;

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
        $msg = $self->{'msg'};
        if ($msg ne '') {
            $self->{'msg'} = '';
            $msg .= "\n";
        }
    }

    return $msg;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.107

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
