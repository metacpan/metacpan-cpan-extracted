package Quiq::Axis::Time;
use base qw/Quiq::Axis/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.164';

use Quiq::Math;
use Quiq::Hash;
use Quiq::AxisTick;
use POSIX ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Axis::Time - Definition einer Zeit-Achse

=head1 BASE CLASS

L<Quiq::Axis>

=head1 SYNOPSIS

  $ax = Quiq::Axis::Time->new(
      orientation => $str, # 'x', 'y'
      font => $font,
      length => $int,
      min => $float,
      max => $float,
      minTickGap => $int,
      debug => $bool,
  );
  
  # Haupt-Ticks
  @ticks = $ax->ticks;

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert die Definition einer Zeit-Achse
eines XY-Plots. Die Achse kann eine X- oder eine Y-Achse sein.
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

=item minTickGap => $int (Default: 5)

Mindestabstand zwischen zwei Ticks: C<< LABELL<lt>--minTickGap-->LABEL >>

=item debug => $bool (Default: 0)

Gib Information über die Tickberechnung auf STDERR aus.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Achsen-Objekt

=head4 Synopsis

  $ax = Quiq::Axis::Time->new(@keyVal);

=head4 Description

Instantiiere ein Achsen-Objekt auf Basis der Angaben @keyVal,
berechne die beste Achseneinteilung, und liefere eine Referenz auf
das Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    # Attribute

    my $self = $class->SUPER::new(
        orientation => 'x',
        font => undef,
        length => undef,
        min => undef,
        max => undef,
        minTickGap => undef,
        debug => 0,
        # ---
        step => undef, # Referenz auf Step-Objekt
        tickA => [],
        subTickA => [],
    );
    $self->set(@_);

    # Default minTickGap

    my $minTickGap = $self->get('minTickGap');
    if (!defined $minTickGap) {
        $minTickGap = $self->get('orientation') eq 'x'? 6: 6;
        $self->set(minTickGap=>$minTickGap);
    }

    # Berechne Ticks

    my ($length,$min,$max,$debug) = $self->get(qw/length min max debug/);

    my @stepList = (
        1,          # 1 Sekunde
        5,          # 5 Sekunden
        10,         # 10 Sekunden
        30,         # 30 Sekunden
        60,         # 1 Minute
        300,        # 5 Minuten
        600,        # 10 Minuten
        1_800,      # eine halbe Stunde
        3_600,      # eine Stunde
        86_400,     # ein Tag
        2_592_000,  # ungefähr ein Monat (30 Tage)
        31_536_000, # ungefähr ein Jahr (365 Tage)
    );

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
                my $pos0 = int $pos-$size/2; # Anfangsposition Tick
                my $pos1 = int $pos+$size/2; # Endposition Tick
                
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

    my $min = $self->get('min');
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

Liefere das Achsenlabel für Wert $val.

=cut

# -----------------------------------------------------------------------------

sub label {
    my ($self,$val) = @_;

    return $val;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.164

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
