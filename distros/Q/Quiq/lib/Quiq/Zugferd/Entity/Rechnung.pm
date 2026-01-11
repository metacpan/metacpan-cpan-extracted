# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Zugferd::Entity::Rechnung - Rechnung

=head1 BASE CLASS

L<Quiq::Zugferd::Entity>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Rechnung.

=cut

# -----------------------------------------------------------------------------

package Quiq::Zugferd::Entity::Rechnung;
use base qw/Quiq::Zugferd::Entity/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.234';

use Quiq::Zugferd::Entity::Freitext;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $rch = $class->new(@keyVal);

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        # Profil EN16931
        profilKennung => 'urn:cen.eu:en16931:2017', # BT-24
        rechnungsart => undef,                      # BT-3
        rechnungsnummer => undef,                   # BT-1
        rechnungsdatum => undef,                    # BT-2
        waehrung => undef,                          # BT-5
        leitwegId => undef,                         # BT-10
        faelligkeitsdatum => undef,                 # BT-9
        abrechnungszeitraumVon => undef,            # BT-73
        abrechnungszeitraumBis => undef,            # BT-74
        projektnummer => undef,                     # BT-11
        vertragsnummer => undef,                    # BT-12
        auftragsnummer => undef,                    # BT-14
        vergabenummer => undef,                     # BT-17
        objektkennung => undef,                     # BT-18
        zahlungsbedingungen => undef,               # BT-20
        zahlungsmittel => undef,                    # BT-82
        verwendungszweck => undef,                  # BT-83
        zahlungsart => undef,                       # BT-81
        iban => undef,                              # BT-84
        bic => undef,                               # BT-86
        # Beträge
        summePositionenNetto => undef,              # BT-106
        summeNachlaesseNetto => undef,              # BT-107
        summeZuschlaegeNetto => undef,              # BT-108
        gesamtsummeNetto => undef,                  # BT-109
        summeUmsatzsteuer => undef,                 # BT-110
        gesamtsummeBrutto => undef,                 # BT-112
        gezahlterBetrag => undef,                   # BT-113
        rundungsbetrag => undef,                    # BT-114
        faelligerBetrag => undef,                   # BT-115
        # Zugeordnete Objekte
        verkaeufer => undef,
        kaeufer => undef,
        empfaenger => undef,
        freitexte => [],
        positionen => [],
        umsatzsteuern => [],
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 addFreitext() - Füge Freitext hinzu

=head4 Synopsis

  $rch->addFreitext($code,$text);

=head4 Description

Füge Freitext $text mit dem Code $code zu den Freitexten hinzu. Ist $code
C<undef> wird der Text ohne qualifizierenden Code hinzugefügt.

=cut

# -----------------------------------------------------------------------------

sub addFreitext {
    my ($self,$code,$text) = @_;

    my $frt = Quiq::Zugferd::Entity::Freitext->new(
        code => $code,
        text => $text,
    );
    $self->push('freitexte',$frt);

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.234

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2026 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
