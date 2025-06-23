# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Axis - Definition einer Plot-Achse (abstrakte Basisklasse)

=head1 BASE CLASS

L<Quiq::Hash>

=cut

# -----------------------------------------------------------------------------

package Quiq::Axis;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::AxisTick;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Gemeinsame Methoden

Die folgenden Methoden sind allen Subklassen gemeinsam.

=head3 font() - Label-Font

=head4 Synopsis

  $fnt = $ax->font;

=head4 Description

Liefere den Font, in der die Label der Achse gesetzt werden.

=cut

# -----------------------------------------------------------------------------

sub font {
    return shift->{'font'};
}

# -----------------------------------------------------------------------------

=head3 ticks() - Liste der Haupt-Ticks

=head4 Synopsis

  @ticks | $tickA = $ax->ticks;

=head4 Description

Liefere die Liste der Haupt-Ticks der Achse. Im Skalarkontext liefere eine
Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub ticks {
    my $self = shift;
    my $arr = $self->{'tickA'};
    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 subTicks() - Liste der Unter-Ticks

=head4 Synopsis

  @subTicks | $subTickA = $ax->subTicks;

=head4 Description

Liefere die Liste der Unter-Ticks der Achse. Im Skalarkontext liefere eine
Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub subTicks {
    my $self = shift;
    my $arr = $self->{'subTickA'};
    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 width() - Breite des breitesten Labels

=head4 Synopsis

  $width = $ax->width;

=head4 Description

Ermittele die Breite des breitesten Label in Pixeln und liefere
diesen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub width {
    my $self = shift;

    my $width = 0;
    for my $tik ($self->ticks) {
        my $n = $tik->width;
        if ($n > $width) {
            $width = $n;
        }
    }
    if ($width == 0) {
        # Keine Ticks. Wir nehmen stattdessen den Wert min.
        $width = Quiq::AxisTick->new($self,$self->get('min'))->width;
    }

    return $width;
}

# -----------------------------------------------------------------------------

=head3 height() - Höhe des höchsten Labels

=head4 Synopsis

  $height = $ax->height;

=head4 Description

Ermittele die Höhe des höchsten Label in Pixeln und liefere
diesen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub height {
    my $self = shift;

    my $height = 0;
    for my $tik ($self->ticks) {
        my $n = $tik->height;
        if ($n > $height) {
            $height = $n;
        }
    }
    if ($height == 0) {
        # Keine Ticks. Wir nehmen stattdessen den Wert min.
        $height = Quiq::AxisTick->new($self,$self->get('min'))->height;
    }

    return $height;
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
