package Quiq::Fibu::BankbuchungListe;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = 1.138;

use Quiq::Formatter;
use Quiq::Fibu::Bankbuchung;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Fibu::BankbuchungListe - Liste von Buchungen von einem Postbank-Konto

=head1 BASE CLASS

L<Quiq::Hash>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Bankbuchungslisten-Objekt

=head4 Synopsis

    $bbl = $class->new($line);

=head4 Arguments

=over 4

=item $line

Titelzeile einer Postbank CSV-Datei.

=back

=head4 Description

Instantiiere ein Bankbuchungslisten-Objekt aus der Titelzeile
$line und liefere eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$line) = @_;

    # Wir nehmen das erste Wort in Kleinschreibung. Aus "empfänger"
    # machen wir "empfaenger".
    my @titles = map {s/ .*//; s/ä/ae/; lc} $class->splitLine($line);

    return $class->SUPER::new(
        titleA => \@titles, 
        entryA => [],
    );
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden

=head3 splitLine() - Zelege CSV-Zeile in ihre Bestandteile

=head4 Synopsis

    $arr = $class->splitLine($line);

=head4 Arguments

=over 4

=item $line

Zeile der CSV-Datei.

=back

=head4 Returns

Liste der Kolumnenwerte (Referenz auf Array)

=cut

# -----------------------------------------------------------------------------

sub splitLine {
    my ($class,$line) = @_;
    my @arr = map {s/^"//; s/"$//; $_} split /;/,$line;
    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 anfangssaldoLesbar() - Liefere den Anfangsstand des Kontos

=head4 Synopsis

    $betrag = $bbl->anfangssaldoLesbar;

=head4 Returns

Betrag (String)

=cut

# -----------------------------------------------------------------------------

sub anfangssaldoLesbar {
    my $self = shift;

    my $e = $self->entryA->[0];
    my $saldo = sprintf '%.2f',$e->saldoZahl-$e->betragZahl;
    return Quiq::Formatter->readableNumber($saldo);
}

# -----------------------------------------------------------------------------

=head3 append() - Füge Bankbuchungsobjekt hinzu

=head4 Synopsis

    $bbu = $bbl->append($line);

=head4 Arguments

=over 4

=item $line

Datenzeile einer Postbank CSV-Datei.

=back

=head4 Returns

Liste der Kolumnenwerte (Referenz auf Array)

=cut

# -----------------------------------------------------------------------------

sub append {
    my ($self,$line) = @_;

    my $valueA = $self->splitLine($line);
    my $bbu = Quiq::Fibu::Bankbuchung->new($self->titleA,$valueA);
    $self->unshift(entryA=>$bbu);

    return $bbu;    
}

# -----------------------------------------------------------------------------

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

=head3 summe() - Liefere den Saldo des Kontos

=head4 Synopsis

    $betrag = $bbl->summe;

=head4 Returns

Betrag (String)

=cut

# -----------------------------------------------------------------------------

sub summe {
    my $self = shift;

    my $saldo = 0;
    for my $bbu ($self->entries) {
        $saldo += $bbu->betragZahl;
    }

    return sprintf '%.2f',$saldo;
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
