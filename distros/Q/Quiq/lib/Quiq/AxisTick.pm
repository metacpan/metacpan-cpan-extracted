# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::AxisTick - Tick einer Plot-Achse

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Tick-Objekt repräsentiert eine Postion auf einer Plot-Achse, an
der eine Markierung - mit oder ohne Label - gesetzt wird.
Das Tick-Objekt ist einem Achsen-Objekt zugeordnet.
Über das Tick-Objekt gelangt eine Klasse, die eine Plot-Achse zeichnet,
an alle Information, die zum Zeichnen des Tick nötig ist.

=head1 ATTRIBUTES

=over 4

=item axis => $axis (Default: undef)

Referenz auf das Achsen-Objekt.

=item value => $val (Default: undef)

Wert des Tick.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::AxisTick;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Math;
use POSIX ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Tick-Objekt

=head4 Synopsis

  $tik = Quiq::AxisTick->new($axis,$val);

=head4 Arguments

=over 4

=item $axis

Referenz auf das Plot-Achsen-Objekt.

=item $val

Wert des Tick.

=back

=head4 Description

Instantiiere ein Tick-Objekt und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$axis,$val) = @_;

    return $class->SUPER::new(
        axis => $axis,
        value => $val,
    );
}

# -----------------------------------------------------------------------------

=head2 Attributmethoden

=head3 value() - Wert des Tick

=head4 Synopsis

  $val = $tik->value;

=head4 Description

Liefere den Wert des Tick.

=cut

# -----------------------------------------------------------------------------

sub value {
    return shift->{'value'};
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 position() - Pixel-Position auf der Achse

=head4 Synopsis

  $pos = $tik->position;

=head4 Description

Liefere die Pixel-Position des Tick auf der Achse.

=cut

# -----------------------------------------------------------------------------

sub position {
    my $self = shift;

    # FIXME: optimieren

    my $ax = $self->{'axis'};
    my $length = $ax->{'length'};
    my $logarithmic = $ax->try('logarithmic'); # nur bei numerischer Achse
    my $min = $ax->{'min'};
    if ($logarithmic) {
        $min = POSIX::log10($min);
    }
    my $max = $ax->{'max'};
    if ($logarithmic) {
        $max = POSIX::log10($max);
    }
    my $val = $self->{'value'};

    return Quiq::Math->valueToPixel($length,$min,$max,$val);
}

# -----------------------------------------------------------------------------

=head3 label() - Tick-Label

=head4 Synopsis

  $label = $tik->label;

=head4 Description

Liefere das Tick-Label, also die Achsenbeschriftung.

=cut

# -----------------------------------------------------------------------------

sub label {
    my $self = shift;

    my $ax = $self->{'axis'};
    my $val = $self->{'value'};

    return $ax->label($val);
}

# -----------------------------------------------------------------------------

=head3 width() - Breite des Tick

=head4 Synopsis

  $width = $tik->width;

=head4 Description

Liefere die Breite des Tick. Bei einem Tick mit Label wird die Breite
des Tick von seinem Label bestimmt.

=cut

# -----------------------------------------------------------------------------

sub width {
    my $self = shift;

    my $ax = $self->{'axis'};
    my $fnt = $ax->font;
    my $val = $self->{'value'};
    my $label = $ax->label($val);

    return $fnt->stringWidth($label)+1; # +1 für zusätzlichen Leerraum
}

# -----------------------------------------------------------------------------

=head3 height() - Höhe des Tick

=head4 Synopsis

  $height = $tik->height;

=head4 Description

Liefere die Höhe des Tick. Bei einem Tick mit Label wird die Höhe
des Tick von seinem Label bestimmt.

=cut

# -----------------------------------------------------------------------------

sub height {
    my $self = shift;

    my $ax = $self->{'axis'};
    my $fnt = $ax->font;
    my $val = $self->{'value'};
    my $label = $ax->label($val);

    return $fnt->stringHeight($label);
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
