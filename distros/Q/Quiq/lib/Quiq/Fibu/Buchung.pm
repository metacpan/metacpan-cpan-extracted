package Quiq::Fibu::Buchung;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.138;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Fibu::Buchung - Fibu-Buchung

=head1 BASE CLASS

L<Quiq::Hash>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Buchungs-Objekt

=head4 Synopsis

    $buc = $class->new(@attVal);

=head4 Arguments

=over 4

=item @attVal

Attribut/Wert-Paare.

=back

=head4 Description

Instantiiere ein Buchungs-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        datum => undef,
        vorgang => undef,
        betrag => undef,
        text => undef,
        saldoLesbar => '',
        beleg => 0, # es gibt einen Beleg
        bankbuchung => undef, # Bankbuchungs-Objekt
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 betragZahl() - Liefere den Buchungsbetrag als Zahl

=head4 Synopsis

    $betr = $buc->betragZahl;

=head4 Returns

Buchungsbetrag (Float)

=cut

# -----------------------------------------------------------------------------

sub betragZahl {
    my $self = shift;

    my $betrag = $self->betrag;
    $betrag =~ s/\.//;
    $betrag =~ s/,/./;

    return $betrag;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.138

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
