package Prty::Fibu::Bankbuchung;
use base qw/Prty::Hash/;

use strict;
use warnings;
use utf8;

our $VERSION = 1.121;

use Prty::Fibu::Buchung;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Fibu::Bankbuchung - Buchung von einem Postbank-Konto

=head1 BASE CLASS

L<Prty::Hash>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Bankbuchungs-Objekt

=head4 Synopsis

    $bbu = $class->new(\@keys,\@values);

=head4 Arguments

=over 4

=item @keys

Die Namen der Komponenten.

=item @values

Die Werte zu den Namen.

=back

=head4 Description

Instantiiere ein Bankbuchungs-Objekt und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$keyA,$valueA) = @_;

    my $self = $class->SUPER::new($keyA,$valueA);
    $self->add(
        erkannt => 0,
    );

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden

=head3 toBuchungen() - Wandele Bankbuchung in Fibu-Buchungen

=head4 Synopsis

    @buchungen | $buchungA = $bbu->toBuchungen;

=head4 Returns

Liste von Buchungen (Array)

=cut

# -----------------------------------------------------------------------------

sub toBuchungen {
    my $self = shift;

    my @arr;

    # *** Wiederkehrende Buchungen ***

    # Miete

    if ($self->isDauerauftrag && $self->buchungsdetails =~ /^MIETE/i) {
        if ($self->betragZahl ne '-970.00') {
            die "ERROR: Miete hat sich geändert\n";
        }
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Grundstückskosten / Miete',
                betrag => '-102,12',
                text => 'Büro Miete',
            ),
            Prty::Fibu::Buchung->new(
                vorgang => 'Grundstückskosten / Gas, Wasser, Strom',
                betrag => '-35,52',
                text => 'Büro Nebenkosten',
            ),
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                betrag => '-832,36',
                text => 'Miete Privat',
            ),
        ;
    }
    elsif ($self->empfaenger =~ /Techniker Krankenkasse/i) {
        my ($monat) = $self->buchungsdetails =~ /Monat (\S+)/;
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                text => "Krankenkasse ($monat)",
            ),
        ;
    }
    elsif ($self->empfaenger =~ m|wilhelm\.tel|i) {
        my ($monat) = $self->buchungsdetails =~ m| (\d\d\.\d\d) |;
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Internet',
                text => "wilhelm.tel ($monat)",
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|031/075/60059 UMS.ST (\S+)|) {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Steuern, Versicherungen, Beiträge'.
                    ' / Umsatzsteuervorauszahlung',
                text => "Umsatzsteuer ($1)",
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|Rundfunk (\S+)|) {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                text => 'Rundfunkbeitrag',
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|RNR (\S+).*Etengo|) {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Betriebseinnahmen / Erlöse',
                text => "Etengo ($1)",
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|(\S+) congstar|) {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Telefonkosten',
                text => "Mobiltelefon ($1)",
                beleg => 1,
            ),
        ;
    }

    # *** Einmalige Buchungen ***

    elsif ($self->buchungshinweis =~ /25.07.17 VISA/) {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-6,38',
                text => 'github.com (2017-06-28)',
                beleg => 1,
            ),
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-45,58',
                text => 'Amazon Server (2017-06-28)',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /23.08.17 VISA/) {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-6,12',
                text => 'github.com (2017-07-28)',
                beleg => 1,
            ),
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-45,21',
                text => 'Amazon Server (2017-08-04)',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /Rechnung 16231348 HQ Patronen/) {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Bürobedarf',
                text => 'Toner Gelb',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /Bestellung 1033548807 HQ Patronen/) {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Bürobedarf',
                text => 'Toner Cyan + Magenta',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /Bestellung 1033551226 HQ Patronen/) {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Bürobedarf',
                text => 'Toner Schwarz',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /305-8859854-8599568 Amazon/) {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Fachliteratur',
                text => 'Groovy in Action',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /304-7606673-8906700 Amazon/) {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Fachliteratur',
                text => 'Perl 6 Fundamentals',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /304-8751683-9153101 Amazon/) {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'AmazonBasics USB-Maus',
                betrag => '-7,39',
                beleg => 1,
            ),
            Prty::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'JETech USB-Maus',
                betrag => '-6,99',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /304-7873662-5739518 AMZ.kabelbude/) {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => 'Betriebseinnahmen / Sonstige Erlöse',
                text => 'Rückzahlung wg. Umtausch Schalter',
            ),
        ;
    }

    # *** Nicht erkannt ***

    else {
        push @arr,
            Prty::Fibu::Buchung->new(
                vorgang => '?',
                text => '? '.$self->buchungshinweis,
            ),
        ;
    }

    if (@arr == 1) {
        # Bei Bankbuchungen, die zu einer Fibu-Buchung führen,
        # setzen wir den Betrag automatisch, d.h. wir müssen ihn
        # bei der Instantiierung des Buchungsobjekts oben nicht
        # angeben

        $arr[0]->set(
            betrag => $self->betragLesbar,
        );
    }

    # Beim letzten Eintrag bertragen wir den Saldo der Bankbuchung
    $arr[-1]->saldoLesbar($self->saldoLesbar);

    # Wir übernehmen das Datum aus der Bankbuchung und prüfen,
    # ob die Summe der Buchungen mit dem Betrag der Bankbuchung
    # übereinstimmt

    my $summe = 0;
    for my $buc (@arr) {
        $buc->bankbuchung($self); # Referenz auf Bankbuchungs-Objekt
        $buc->datum($self->buchungstag);
        $summe += $buc->betragZahl;
    }
    $summe = sprintf '%.2f',$summe;
    if ($summe != $self->betragZahl) {
        die "ERROR: Summe der Buchungen ($summe) stimmt nicht mit dem".
            sprintf(" Betrag der Bankbuchung (%s) überein\n",
            $self->betragZahl);
    }

    # Bankbuchung als erkannt kennzeichnen
    $self->erkannt(1);

    return @arr
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 betragLesbar() - Liefere den Buchungsbetrag für die Ausgabe

=head4 Synopsis

    $betr = $bbu->betragLesbar;

=head4 Returns

Buchungsbetrag (String)

=cut

# -----------------------------------------------------------------------------

sub betragLesbar {
    my $self = shift;

    my $betrag = $self->betrag;
    $betrag =~ s/ *€//;
    $betrag =~ s/\.//;
    if (substr($betrag,0,1) ne '-') {
        $betrag = "+$betrag";
    }

    return $betrag;
}

# -----------------------------------------------------------------------------

=head3 betragZahl() - Liefere den Buchungsbetrag als Zahl

=head4 Synopsis

    $betr = $bbu->betragZahl;

=head4 Returns

Buchungsbetrag (Float)

=cut

# -----------------------------------------------------------------------------

sub betragZahl {
    my $self = shift;

    my $betrag = $self->betrag;
    $betrag =~ s/ *€//;
    $betrag =~ s/\.//;
    $betrag =~ s/,/./;

    return $betrag;
}

# -----------------------------------------------------------------------------

=head3 buchungshinweis() - Liefere Buchungsdetails und Empfänger

=head4 Synopsis

    $str = $bbu->buchungshinweis;

=head4 Returns

String

=cut

# -----------------------------------------------------------------------------

sub buchungshinweis {
    my $self = shift;

    my $str;
    if ($self->isGutschrift) {
        $str = $self->buchungsdetails.' '.$self->auftraggeber;
    }
    else {
        $str = $self->buchungsdetails.' '.$self->empfaenger;
    }
    $str =~ s/\s\s+/ /; # zu viel Whitespace entfernen

    return $str;
}

# -----------------------------------------------------------------------------

=head3 isDauerauftrag() - Prüfe auf Dauerauftrag

=head4 Synopsis

    $bool = $bbu->isDauerauftrag;

=head4 Returns

Boolean

=cut

# -----------------------------------------------------------------------------

sub isDauerauftrag {
    my $self = shift;
    return $self->umsatzart eq 'Dauerauftrag';
}

# -----------------------------------------------------------------------------

=head3 isGutschrift() - Prüfe auf Gutschrift

=head4 Synopsis

    $bool = $bbu->isGutschrift;

=head4 Returns

Boolean

=cut

# -----------------------------------------------------------------------------

sub isGutschrift {
    my $self = shift;
    return $self->umsatzart eq 'Gutschrift';
}

# -----------------------------------------------------------------------------

=head3 saldoLesbar() - Liefere den Saldo für die Ausgabe

=head4 Synopsis

    $saldo = $bbu->saldoLesbar;

=head4 Returns

Saldo (String)

=cut

# -----------------------------------------------------------------------------

sub saldoLesbar {
    my $self = shift;

    my $saldo = $self->saldo;
    $saldo =~ s/ *€//;

    return $saldo;
}

# -----------------------------------------------------------------------------

=head3 saldoZahl() - Liefere den Saldo als Zahl

=head4 Synopsis

    $saldo = $bbu->saldoZahl;

=head4 Returns

Saldo (Float)

=cut

# -----------------------------------------------------------------------------

sub saldoZahl {
    my $self = shift;

    my $saldo = $self->saldo;
    $saldo =~ s/ *€//;
    $saldo =~ s/\.//;
    $saldo =~ s/,/./;

    return $saldo;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.121

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2017 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
