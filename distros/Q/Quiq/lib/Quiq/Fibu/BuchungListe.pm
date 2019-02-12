package Quiq::Fibu::BuchungListe;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.134;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Fibu::BuchungListe - Liste von Fibu-Buchungen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Buchungslisten-Objekt

=head4 Synopsis

    $bul = $class->new($bbl);

=head4 Arguments

=over 4

=item $bbl

BankbuchungsListen-Objekt.

=back

=head4 Returns

Fibu-Buchungslisten-Objekt (Quiq::Fibu::BuchungListe)

=head4 Description

Instantiiere ein Fibu-Buchungslisten-Objekt aus einer Liste von
Bankbuchungen und liefere eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$bbl) = @_;

    my @entries;
    for my $bbu ($bbl->entries) {
        push @entries,$bbu->toBuchungen;
    }

    return $class->SUPER::new(
        entryA => \@entries,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 entries() - Liefere Liste der Bankbuchungen

=head4 Synopsis

    @entries | $entryA = $bbl->entries;

=head4 Returns

Liste der Bankbuchungen (Array, im Skalarkontext Referenz auf Array)

=cut

# -----------------------------------------------------------------------------

sub entries {
    my $self = shift;
    my $entryA = $self->entryA;
    return wantarray? @$entryA: $entryA;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.134

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
