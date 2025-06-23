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

=cut

# -----------------------------------------------------------------------------

package Quiq::Axis::Time;
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

    # Mögliche Schrittweiten ermitteln

    my @candidates;

    # Einteilung bis Tag

    STEP_LOOP:
    for my $step (1,60,3600,86400) {
        my $val = $self->firstTick($step);
        if ($val > $max) {
            # Ende: erster Tick liegt jenseits der Achse
            last STEP_LOOP;
        }

        if ($debug) {
            print STDERR "$step: ";
        }

        # Alle Ticks für die Schrittweite durchlaufen und prüfen, ob
        # genug Raum für jedes Label ist. Gibt es eine Überlappung,
        # wird mit der nächsten Schrittweite weiter gemacht.

        my (@values,$minPos,$maxPos,$minGap);
        while ($val <= $max) {
            push @values,$val;
            my $pos = Quiq::Math->valueToPixel($length,$min,$max,$val);
            my $size = $self->labelSize($val); # Größe Tick-Label
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
                    next STEP_LOOP;
                }
            }
            if (!defined $minPos) {
                $minPos = $pos0; # erste Pixelkoordinate
            }
            $maxPos = $pos1; # letzte Pixelkoordinate

            # Nächster Tick-Wert
            $val += $step;
        }

        if ($debug) {
            printf STDERR " minGap=%s\n",$minGap || '';
        }

        push @candidates,Quiq::Hash->new(
             # Weltkoordinaten
             step => $step, # Schrittweite
             valueA => \@values, # Liste der Ticks
             # Pixelkoordinaten
             tickDistance => Quiq::Math->valueToPixel($length,$min,
                 $max,$min+$step),
             minGap => $minGap, # kleinster Pixelabstand zw. Ticks
             minPos => $minPos, # erste Pixelposition (kann < 0 sein)
             maxPos => $maxPos, # letzte Pixelposition
                                # (kann >= $length sein)
        );

        if ($step > $max-$min) {
            # Ende: die folgenden Schrittweiten sind so groß,
            # dass sie auch höchstens einen Tick produzieren, wie
            # die aktuelle Schrittweite auch schon.
            last;
        }
    }

    if (!@candidates) {
        # Keine Ticks, wir haben Keine passende Schrittweite gefunden.
        return $self;
    }

    # Die beste Schrittweite auswählen

    my $stp;
    for my $e (@candidates) {
        # Wir haben hier aktuell keine Kriterien -> s. %<Quiq::Axis::Numeric
        if (0) {
            last;
        }
    }
    $stp ||= $candidates[0];

    # Step-Definition sichern
    $self->set(step=>$stp);

    # Tick-Listen erstellen

    # tick

    my @values = @{$stp->get('valueA')};

    my $tickA = $self->ticks;
    for my $val (@values) {
        push @$tickA,Quiq::AxisTick->new($self,$val);
    }

    # subTick

    my ($step,$tickDistance) = $stp->get(qw/step tickDistance/);

    if ($step > 1 && $step <= 86400) {
        my @numSubSteps;
        if ($step == 60) {
            @numSubSteps = (4,2);
        }
        elsif ($step == 3600) {
            @numSubSteps = (4,2);
        }
        elsif ($step == 86400) {
            @numSubSteps = (4,2);
        }
        my ($subStep,$numSubSteps);
        for my $n (@numSubSteps) {
            if ($tickDistance/$n > 4) {
                $subStep = $step/$n;
                $numSubSteps = $n;
                last;
            }
        }
        if ($subStep) {
            my $subTickA = $self->subTicks;
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

    # FIXME: Wir liefern hier z.Zt. nur Stundenformat
    $val = POSIX::strftime('%H:%M',localtime $val);

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
