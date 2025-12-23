# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Zugferd::Entity::ZuAbschlagPosition - Zu- oder Abschlage auf Position

=head1 BASE CLASS

L<Quiq::Zugferd::Entity>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Zu- oder Abschlag auf
Positionsebene.

=cut

# -----------------------------------------------------------------------------

package Quiq::Zugferd::Entity::ZuAbschlagPosition;
use base qw/Quiq::Zugferd::Entity/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.233';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $atr = $class->new(@keyVal);

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        typ => undef,         # BG-27-1_BG-28-1 / Abschlag: false
        prozent => undef,     # BT-138_BT-143
        grundbetrag => undef, # BT-137_BT-142
        differenz => undef,   # BT-136_BT-141
        grundCode => undef,   # BT-140_BT-145
        grund => undef,       # BT-139_BT-144
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.233

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
