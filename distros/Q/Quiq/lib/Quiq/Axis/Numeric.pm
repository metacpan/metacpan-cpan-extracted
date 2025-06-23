# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Axis::Numeric - Definition einer numerischen Achse

=head1 BASE CLASS

L<Quiq::Axis>

=head1 SYNOPSIS

  $ax = Quiq::Axis::Numeric->new(
      orientation => $str, # 'x', 'y'
      font => $font,
      length => $int,
      min => $float,
      max => $float,
      logarithmic => $bool,
      minTickGap => $int,
      debug => $bool,
  );
  
  # Haupt-Ticks
  @ticks = $ax->ticks;

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert die Definition einer numerischen
Achse eines XY-Plots. Die Achse kann eine X- oder eine Y-Achse sein.
Die Klasse berechnet eine geeignete Einteilung der Achse in Ticks
und Unter-Ticks unter Berücksichtigung der echten Breite/Höhe der
Tick-Label. Die betreffenden Tick-Objekte werden von den Methoden
$ax->ticks() und $ax->subTicks() geliefert.

=head2 Font-Klasse

Die Achseneinteilung kann für beliebige Fonts berechnet werden. Es
wird lediglich vorausgesetzt, dass die Font-Klasse zwei Methoden zur
Berechnung der Label-Breite und der Label-Höhe implementiert:

  $n = $fnt->stringWidth($str);
  $n = $fnt->stringHeight($str);

=head1 ATTRIBUTES

=over 4

=item orientation => 'x'|'y' (Default: 'x')

Orientierung der Achse: 'x' oder 'y'.

=item font => $font (Default: keiner)

Font für die Tick-Label.

=item length => $int (Default: keiner)

Länge der Achse.

=item min => $float (Default: keiner)

Kleinster Wert auf der Achse.

=item max => $float (Default: keiner)

Größter Wert auf der Achse.

=item logarithmic => $bool (Default: 0)

Die Achse erhält eine logarithmische Einteilung (Basis 10).

=item minTickGap => $int (Default: 5)

Mindestabstand zwischen zwei Ticks: C<< LABELL<lt>--minTickGap-->LABEL >>

=item debug => $bool (Default: 0)

Gib Information über die Tickberechnung auf STDERR aus.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Axis::Numeric;
use base qw/Quiq::Axis/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Math;
use Quiq::Hash;
use Quiq::AxisTick;
use POSIX ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Achsen-Objekt

=head4 Synopsis

  $ax = Quiq::Axis::Numeric->new(@keyVal);

=head4 Description

Instantiiere ein Achsen-Objekt auf Basis der Angaben @keyVal,
berechne die beste Achseneinteilung, und liefere eine Referenz auf
das Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        orientation => 'x',
        font => undef,
        length => undef,
        min => undef,
        max => undef,
        logarithmic => 0,
        minTickGap => undef,
        debug => 0,
        # ---
        step => undef, # Referenz auf Step-Objekt
        tickA => [],
        subTickA => [],
    );
    $self->set(@_);

    # * Prüfe Attributwerte *

    # Default minTickGap

    my $minTickGap = $self->get('minTickGap');
    if (!defined $minTickGap) {
        $minTickGap = $self->get('orientation') eq 'x'? 6: 6;
        $self->set(minTickGap=>$minTickGap);
    }

    # * Berechne Ticks *

    my ($length,$min,$max,$logarithmic,$debug) =
        $self->get(qw/length min max logarithmic debug/);

    if ($logarithmic) {
        $min = POSIX::log10($min);
        $max = POSIX::log10($max);
    }

    my $minTickSize = $self->labelSize(int $min); # min. Breite bzw. Höhe
    my $maxTicks = $length/$minTickSize;
    my $minStep = ($max-$min)/$maxTicks;
    my $maxStep = $max-$min;

    # Mögliche Schrittweiten ermitteln

    my @candidates;

    LOOP_EXP:
    for my $exp (-10 .. 10) { # Exponent
        LOOP_BASE:
        for my $base (1,2,5) { # Basiswert
            if ($logarithmic && ($base != 1 || $exp != 0)) {
                # Im Falle von Logarithmus-Werten ist die Einteilung auf
                # jeden Fall in 1er-Schritten. Alle anderen Schrittweiten
                # übergehen wir.
                next;
            }

            my $step = $base*10**$exp; # Schrittweite

            if ($step < $minStep) {
                # Weiter: die Schrittweite ist so klein, es würden
                # mehr Ticks als theoretisch auf die Achse passen
                next;
            }

            my $val = $self->firstTick($step);
            if ($val > $max) {
                # Ende: erster Tick liegt jenseits der Achse
                last LOOP_EXP;
            }

            if ($debug) {
                print STDERR "$step: ";
            }

            # Alle Ticks für die Schrittweite durchlaufen und prüfen, ob
            # genug Raum für jedes Label ist. Gibt es eine Überlappung,
            # wird mit der nächsten Schrittweite weiter gemacht.

            my (@values,$minPos,$maxPos,$minGap);
            # for (; $val <= $max; $val += $step) {
            while ($val <= $max) {
                push @values,$val;
                my $pos = Quiq::Math->valueToPixel($length,$min,$max,$val);
                my $size = $self->labelSize($val); # Größe Tick
                my $pos0 = int($pos-$size/2); # Anfangsposition Tick
                my $pos1 = int($pos+$size/2); # Endposition Tick
                
                if ($debug) {
                    print STDERR " $val($pos0/$pos/$pos1)";
                }
                if (defined $maxPos) { # beim ersten Step keine Überlappung
                    if ($pos0 > $maxPos+$minTickGap) {
                        my $gap = $pos0-$maxPos;
                        if (!defined($minGap) || $gap < $minGap) {
                            $minGap = $gap;
                        }
                    }
                    else {
                        # Weiter: Label überlappen sich
                        if ($debug) {
                            print STDERR " Ueberlappung\n";
                        }
                        next LOOP_BASE;
                    }
                }
                if (!defined $minPos) {
                    $minPos = $pos0; # erste Pixelkoordinate
                }
                $maxPos = $pos1; # letzte Pixelkoordinate

                # Nächster Tick-Wert. Bei Schrittweiten < 0 müssen wir
                # runden, da sonst manchmal der letzte Tick nicht
                # hinzugenommen wird (offenbar ist der Wert > $max)

                $val = sprintf '%.*f',($exp < 0? abs $exp: 0),$val+$step;
                if (index($val,'.') >= 0) {
                    $val =~ s/\.?0+$//;
                }
            }

            if ($debug) {
                printf STDERR " minGap=%s\n",$minGap || '';
            }

            push @candidates,Quiq::Hash->new(
                 # Weltkoordinaten
                 step => $step, # Schrittweite
                 base => $base, # 1, 2, oder 5
                 exp => $exp, # -10 .. 10
                 valueA => \@values, # Liste der Ticks
                 # Pixelkoordinaten
                 tickDistance => Quiq::Math->valueToPixel($length,$min,
                     $max,$step),
                 minGap => $minGap, # kleinster Pixelabstand zw. Ticks
                 minPos => $minPos, # erste Pixelposition (kann < 0 sein)
                 maxPos => $maxPos, # letzte Pixelposition
                                    # (kann >= $length sein)
            );

            if ($step > $maxStep) {
                # Ende: die folgenden Schrittweiten sind so groß,
                # dass sie auch höchstens einen Tick produzieren, wie
                # die aktuelle Schrittweite auch schon
                last LOOP_EXP;
            }
        }
    }

    if (!@candidates) {
        # Keine Ticks, wir haben Keine passende Schrittweite gefunden.
        # Dies kann bei einer logarithmischen Achse passieren, wenn
        # innerhalb des Wertebereichs kein ganzahliger Logarithmus vorkommt.
        return $self;
    }

    # Die beste Schrittweite auswählen

    my $stp;
    for my $e (@candidates) {
        if ($e->get('base') == 1 && @{$e->get('valueA')} >= 6) {
            # Wir bevorzugen die 10er-Einteilung mit genügend Ticks
            $stp = $e;
            last;
        }
    }
    $stp ||= $candidates[0];

    # Step-Definition sichern
    $self->set(step=>$stp);

    # * Tick-Listen erstellen *

    # tick

    my @values = @{$stp->get('valueA')};

    my $tickA = $self->ticks;
    for my $val (@values) {
        push @$tickA,Quiq::AxisTick->new($self,$val);
    }

    # subTick

    my ($step,$base,$tickDistance) = $stp->get(qw/step base tickDistance/);

    my $subTickA = $self->subTicks;
    if ($self->get('logarithmic')) {
        for my $log ($values[0]-1,@values) {
            my $val = 10**$log;
            my $subStep = $val;
            for my $i (1..8) {
                $val += $subStep;
                my $log = POSIX::log10($val);
                if ($log >= $min && $log <= $max) {
                    push @$subTickA,Quiq::AxisTick->new($self,$log);
                }
            }
        }
    }
    else {
        my $numSubSteps;
        if ($base == 1 || $base == 2) {
            $numSubSteps = 1;
        }
        elsif ($base == 5 && $tickDistance >= 40) {
            $numSubSteps = 4;
        }

        if (defined $numSubSteps) {
            my $subStep = $step/($numSubSteps+1);

            for my $tickVal ($values[0]-$step,@values) {
                for my $i (1..$numSubSteps) {
                    my $val = $tickVal+$i*$subStep;
                    if ($val >= $min && $val <= $max) {
                        push @$subTickA,Quiq::AxisTick->new($self,$val);
                    }
                }
            }
        }
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

Siehe Basisklasse

=head2 Hilfsmethoden

=head3 firstTick() - Wert des ersten Tick

=head4 Synopsis

  $val = $ax->firstTick($step);

=head4 Description

Liefere für Schrittweite $step den ersten Tick in Weltkoordinaten.

=cut

# -----------------------------------------------------------------------------

sub firstTick {
    my ($self,$step) = @_;

    my $val;

    my ($min,$logarithmic) = $self->get('min','logarithmic');
    if ($logarithmic) {
        $min = POSIX::log10($min);
    }
    if ($min < 0) {
        $val = POSIX::ceil($min/$step)*$step;
        if ($val >= $min) {
            $val -= $step;
        }
    }
    else { # $min >= 0
        $val = POSIX::floor($min/$step)*$step;
        if ($val < $min) {
            $val += $step;
        }
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head3 labelSize() - Tickgröße in Pixeln

=head4 Synopsis

  $n = $ax->labelSize($val);

=head4 Description

Liefere für Wert $val den Platzbedarf des Label in Pixeln.
FIXME: Wert in Label wandeln.

=cut

# -----------------------------------------------------------------------------

sub labelSize {
    my ($self,$val) = @_;

    my ($orientation,$fnt) = $self->get(qw/orientation font/);

    my $label = $self->label($val);
    if ($orientation eq 'y') {
        # Y-Achse
        return $fnt->stringHeight($label);
    }

    # X-Achse
    return $fnt->stringWidth($label);
}

# -----------------------------------------------------------------------------

=head3 label() - Liefere Achsenlabel zu Wert

=head4 Synopsis

  $label = $ax->label($val);

=head4 Description

Liefere das Achsenlabel für Wert $val. Das Label $label kann vom
Wert $val verschieden sein, wenn die Darstellung logarithmisch ist.

=cut

# -----------------------------------------------------------------------------

sub label {
    my ($self,$val) = @_;

    if ($self->get('logarithmic')) {
        return 10**$val;
    }

    return $val;
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
