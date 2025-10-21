# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Zugferd::Entity::Position - Position

=head1 BASE CLASS

L<Quiq::Zugferd::Entity>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Rechnungsposition.

=cut

# -----------------------------------------------------------------------------

package Quiq::Zugferd::Entity::Position;
use base qw/Quiq::Zugferd::Entity/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.232';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $pos = $class->new(@keyVal);

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        positionsnummer => undef,          # BT-126
        artikelnummer => undef,            # BT-155
        artikelname => undef,              # BT-153
        artikelbeschreibung => undef,      # BT-154
        menge => undef,                    # BT-129
        einheit => undef,                  # BT-130
        preisProEinheitNetto => undef,     # BT-146
        umsatzsteuersatz => undef,         # BT-152
        m3Umsatzsteuercode => undef,       # intern
        gesamtpreisNetto => undef,         # BT-131
        kontierungshinweis => undef,       # BT-133
        nummerAuftragsposition => undef,   # BT-132
        artikelkennungKaeufer => undef,    # BT-156
        abrechnungszeitraumVon => undef,   # BT-134
        abrechnungszeitraumBis => undef,   # BT-135
        attribute => [],
        # Nachlass
        nachlassNetto => undef,            # BT-136
        nachlassGrund => undef,            # BT-139
        nachlassGrundbetragNetto => undef, # BT-137
        nachlassProzentsatz => undef,      # BT-138
        # Zuschlag
        zuschlagNetto => undef,            # BT-141
        zuschlagGrund => undef,            # BT-144
        zuschlagGrundbetragNetto => undef, # BT-142
        zuschlagProzentsatz => undef,      # BT-143
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.232

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
