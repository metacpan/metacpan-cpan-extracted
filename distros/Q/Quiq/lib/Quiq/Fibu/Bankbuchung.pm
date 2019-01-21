package Quiq::Fibu::Bankbuchung;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = 1.131;

use Quiq::Fibu::Buchung;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Fibu::Bankbuchung - Buchung von einem Postbank-Konto

=head1 BASE CLASS

L<Quiq::Hash>

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
        if ($self->betragZahl eq '-1070.00') {
            push @arr,
                Quiq::Fibu::Buchung->new(
                    vorgang => 'Grundstückskosten / Miete',
                    betrag => '-102,12',
                    text => 'Büro Miete',
                ),
                Quiq::Fibu::Buchung->new(
                    vorgang => 'Grundstückskosten / Gas, Wasser, Strom',
                    betrag => '-50,32',
                    text => 'Büro Nebenkosten',
                ),
                Quiq::Fibu::Buchung->new(
                    vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                    betrag => '-917,56',
                    text => 'Miete Privat',
                ),
            ;
        }
        elsif ($self->betragZahl eq '-970.00') {
            push @arr,
                Quiq::Fibu::Buchung->new(
                    vorgang => 'Grundstückskosten / Miete',
                    betrag => '-102,12',
                    text => 'Büro Miete',
                ),
                Quiq::Fibu::Buchung->new(
                    vorgang => 'Grundstückskosten / Gas, Wasser, Strom',
                    betrag => '-35,52',
                    text => 'Büro Nebenkosten',
                ),
                Quiq::Fibu::Buchung->new(
                    vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                    betrag => '-832,36',
                    text => 'Miete Privat',
                ),
            ;
        }
        else {
            die "ERROR: Miete hat sich geändert\n";
        }
    }
    elsif ($self->empfaenger =~ /Techniker Krankenkasse/i &&
            $self->umsatzart eq 'Lastschrift') {
        my ($monat) = $self->buchungsdetails =~ /Monat (\S+)/;
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                text => "Krankenkasse ($monat)",
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /PRIVATHAFTPF/i) {
        my ($datum) = $self->buchungsdetails =~ /(\d\d.\d\d.\d\d)/;
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                text => "Privathaftpflicht ($datum)",
                beleg => 1,
            ),
        ;
    }
    elsif ($self->umsatzart eq 'Zinsen/Entgelt') {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Kontoführungsgebühren',
                text => "Postbank Kontoführung",
            ),
        ;
    }
    elsif ($self->empfaenger =~ m|wilhelm\.tel|i) {
        my ($monat) = $self->buchungsdetails =~ m| (\d\d\.\d\d) |;
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Internetkosten',
                text => "wilhelm.tel ($monat)",
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|031/075/60766 EINK.ST (\S+ \d+)|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                text => "EkSt.-Vorauszahlung ($1)",
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|031/075/60059 UMS.ST (\S+)|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Steuern, Versicherungen, Beiträge'.
                    ' / Umsatzsteuervorauszahlung',
                text => "Umsatzsteuer ($1)",
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|ERSTATT\.31/075/60059 UMS.ST (\S+)|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Betriebseinnahmen'.
                    ' / Umsatzsteuervorauszahlung',
                text => "Umsatzsteuer Erstattung ($1)",
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|ERSTATT.31/075/60766 EINK.ST (\S+)|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldzugänge / Einlage von Privat',
                text => "Einkommensteuer Erstattung ($1)",
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|Rundfunk (\S+)|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                text => 'Rundfunkbeitrag',
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|Rechnung 70069042 Markisen Paradies|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                text => 'Markisen Paradies',
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|Re (\S+).*Goetzfried AG|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Betriebseinnahmen / Erlöse',
                text => "Goetzfried AG ($1)",
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|RNR (\S+).*Etengo|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Betriebseinnahmen / Erlöse',
                text => "Etengo ($1)",
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|Wikimedia|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                text => "Spende Wikimedia",
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|(\S+) congstar|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Telefonkosten',
                text => "Mobiltelefon ($1)",
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ m|XING|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => "XING Jahresbeitrag",
                beleg => 1,
            ),
        ;
    }
    elsif ($self->empfaenger =~ /Seitz, Frank/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                text => 'Privatentnahme',
            ),
        ;
    }
    elsif ($self->empfaenger =~ /STRATO AG/ && $self->betrag =~ /-37,92/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgnge / Entnahme nach Privat',
                text => 'Privatentnahme - Domains',
                beleg => 0,
            ),
        ;
    }
    elsif ($self->empfaenger =~ /STRATO AG/ && $self->betrag =~ /-9,48/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Strato Internet Domain',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->empfaenger =~ /STRATO AG/ && $self->betrag =~ /-59,70/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Strato Internet Server',
                beleg => 1,
            ),
        ;
    }

    # *** Einmalige Buchungen ***

    elsif ($self->buchungsdatum eq '25.10.2018' &&
            $self->empfaenger eq 'EBAY GMBH') {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                text => 'Privatentnahme',
                beleg => 0,
            ),
        ;
    }
    elsif ($self->buchungsdatum eq '27.08.2018' &&
            $self->empfaenger =~ /dubaro.de/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Rechner',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->empfaenger =~ /Borgert-Bühren/ &&
            $self->buchungsdetails =~ /Nebenkosten/i &&
            $self->betrag =~ /1\.720,07/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Grundstückskosten / Gas, Wasser, Strom',
                betrag => '-254,57',
                text => 'Büro Nebenkosten Nachzahlung',
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                betrag => '-1465,50',
                text => 'Nebenkosten Nachzahlung',
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /24.10.18 VISA CARD/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-0,99',
                text => 'Samsung Cloud Service (2018-09-26)',
                beleg => 0,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-6,13',
                text => 'github.com (2018-09-28)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-9,52',
                text => 'Amazon Server (2018-10-04)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                betrag => '-24,20',
                text => 'Privatentnahme',
                beleg => 0,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                betrag => '-2,99',
                text => 'Privatentnahme',
                beleg => 0,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /25.09.18 VISA CARD/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-0,99',
                text => 'Samsung Cloud Service (2018-08-27)',
                beleg => 0,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-6,15',
                text => 'github.com (2018-08-28)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-9,80',
                text => 'Amazon Server (2018-09-04)',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /23.08.18 VISA CARD/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-6,13',
                text => 'github.com (2018-07-30)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-9,68',
                text => 'Amazon Server (2018-08-06)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                betrag => '-329,00',
                text => 'Privat',
                beleg => 0,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /24.07.18 VISA CARD/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-6,18',
                text => 'github.com (2018-06-28)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-9,55',
                text => 'Amazon Server (2018-07-04)',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /25.06.18 VISA CARD/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Kontoführungsgebühren',
                betrag => '-29,00',
                text => 'VISA Jahresgebühr (2018-06-18)',
                beleg => 0,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-9,72',
                text => 'Amazon Server (2018-06-05)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-9,19',
                text => 'Amazon Server (2018-06-07)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-54,73',
                text => 'Visitenkarten',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /28.05.18 VISA CARD/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-5,92',
                text => 'github.com (2018-04-27)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgnge / Entnahme nach Privat',
                betrag => '-10,00',
                text => 'Privat',
                beleg => 0,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-9,30',
                text => 'Amazon Server (2018-05-03)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-6,12',
                text => 'github.com (2018-05-27)',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /25.04.18 VISA CARD/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-5,76',
                text => 'github.com (2018-03-28)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-9,19',
                text => 'Amazon Server (2018-04-04)',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /23.03.18 VISA CARD/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-5,84',
                text => 'github.com (2018-02-28)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-8,71',
                text => 'Amazon Server (2018-03-05)',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /23.02.18 VISA CARD/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgnge / Entnahme nach Privat',
                betrag => '-18,70',
                text => 'Privat',
                beleg => 0,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-5,76',
                text => 'github.com (2018-01-27)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-9,07',
                text => 'Amazon Server (2018-02-04)',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /22.12.17 VISA CARD/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-5,99',
                text => 'github.com (2017-11-28)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-9,37',
                text => 'Amazon Server (2017-12-04)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-0,99',
                text => 'Fachartikel',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /23.11.17 VISA CARD/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgnge / Entnahme nach Privat',
                betrag => '-20,90',
                text => 'Privatentnahme',
                beleg => 0,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-6,16',
                text => 'github.com (2017-10-30)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-9,70',
                text => 'Amazon Server (2017-11-06)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-4,49',
                text => 'Fachartikel',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /25.10.17 VISA CARD/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-6,08',
                text => 'github.com (2017-09-28)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-15,96',
                text => 'Amazon Server (2017-10-04)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-2,49',
                text => 'Fachartikel Heise',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgnge / Entnahme nach Privat',
                betrag => '-33,91',
                text => 'Privatentnahme',
                beleg => 0,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /25.09.17 VISA/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-6,06',
                text => 'github.com (2017-08-28)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-45,20',
                text => 'Amazon Server (2017-09-04)',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /23.08.17 VISA/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-6,12',
                text => 'github.com (2017-07-28)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-45,21',
                text => 'Amazon Server (2017-08-04)',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /25.07.17 VISA/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-6,38',
                text => 'github.com (2017-06-28)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-45,58',
                text => 'Amazon Server (2017-06-28)',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /24.01.18 VISA/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-6,02',
                text => 'github.com (2017-12-28)',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                betrag => '-9,39',
                text => 'Amazon Server (2018-01-04)',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->auftraggeber =~ m|Helmholtz-Zentrum Geesth|i &&
             $self->buchungshinweis =~ m|5166|i) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Betriebseinnahmen / Erlöse',
                text => "Rechnung 5166",
                beleg => 1,
            ),
        ;
    }
    elsif ($self->empfaenger =~ /Wieland Direkt Steuerberatung/i &&
            $self->buchungshinweis =~ m|Referenz 1801051139-0000005|i) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Rechts- und Beratungskosten',
                text => "Jahresabschluss 2016",
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /Rechnung Rogosch/
            && $self->auftraggeber =~ m|SBIT|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldzugänge / Einlage von Privat',
                text => 'Rückzahlung von SBIT',
                beleg => 0,
            ),
        ;
    }
    elsif ($self->empfaenger =~ /Buhl Rogosch Buckentin/
            && $self->buchungshinweis =~ m|FE5A6P/DE34200505501228123210|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                text => 'Anwaltskosten für SBIT',
                beleg => 0,
            ),
        ;
    }
    elsif ($self->empfaenger =~ /Buhl Rogosch Buckentin/
            && $self->buchungshinweis =~ m|3PZQL5/DE34200505501228123210|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                text => 'Anwaltskosten für SBIT',
                beleg => 0,
            ),
        ;
    }
    elsif ($self->empfaenger =~ /Buhl Rogosch Buckentin/
            && $self->buchungshinweis =~ m|G85XZA/DE34200505501228123210|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Anwalts- und Gerichtskosten',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->empfaenger =~ /Techniker Krankenkasse/
            && $self->buchungshinweis =~ m|VXQTZ9/DE18200100200045017206|) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Geldabgänge / Entnahme nach Privat',
                text => 'Krankenkasse Zuzahlung',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /Rechnung 16231348 HQ Patronen/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Bürobedarf',
                text => 'Toner Gelb',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /Bestellung 1033548807 HQ Patronen/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Bürobedarf',
                text => 'Toner Cyan + Magenta',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /Bestellung 1033551226 HQ Patronen/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Bürobedarf',
                text => 'Toner Schwarz',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~
            /DE94ZZZ00000561653305-6681488-1906758 AMZN/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Hülle Mobiltel',
                betrag => '-7,49',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Ladegerät',
                betrag => '-21,98',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /302-1954185-1444359 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Telefonzubehör',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /028-1339995-9721122 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Tastaturreiniger',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /028-6935362-2887511 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Monitor',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /028-2053102-8236345 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Monitor-Anschlusskabel',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /306-6879328-9464324 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Bürobedarf',
                text => 'Kopierpapier',
                betrag => '-18,13',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /306-4609505-0810703 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Audiosplitter',
                betrag => '-13,99',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /305-9225928-4491519 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Monitor',
                betrag => '-129,90',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /305-3507443-4917126 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'USB-Kabel',
                betrag => '-7,49',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /305-3575777-8398709 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Telefon Zubehör',
                betrag => '-7,90',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /302-1527414-2342759 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Telefon Zubehör',
                betrag => '-6,99',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Ladegerät',
                betrag => '-20,98',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /Referenz 1002997473072/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Fachliteratur',
                text => 'Fraktale Geometrie',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /305-0775021-4254764 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Fachliteratur',
                text => 'LaTeX Hacks',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /305-6865865-3285139 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Fachliteratur',
                text => 'Learning React',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /305-8859854-8599568 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Fachliteratur',
                text => 'Groovy in Action',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /304-7606673-8906700 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Fachliteratur',
                text => 'Perl 6 Fundamentals',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /305-2728033-2622722 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Rechner Headset',
                betrag => '-19,19',
                beleg => 1,
            );
    }
    elsif ($self->buchungshinweis =~ /304-8751683-9153101 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'AmazonBasics USB-Maus',
                betrag => '-7,39',
                beleg => 1,
            ),
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'JETech USB-Maus',
                betrag => '-6,99',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /306-2084539-8666714 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Monitor',
                betrag => '-134,47',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /306-4293199-5411517 Amazon/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Sonstige Kosten / Sonstige Kosten',
                text => 'Monitorhalterung',
                betrag => '-79,99',
                beleg => 1,
            ),
        ;
    }
    elsif ($self->buchungshinweis =~ /304-7873662-5739518 AMZ.kabelbude/) {
        push @arr,
            Quiq::Fibu::Buchung->new(
                vorgang => 'Betriebseinnahmen / Sonstige Erlöse',
                text => 'Rückzahlung wg. Umtausch Schalter',
            ),
        ;
    }

    # *** Nicht erkannt ***

    else {
        push @arr,
            Quiq::Fibu::Buchung->new(
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

=head3 buchungstag() - Liefere das Buchungsdatum

=head4 Synopsis

    $str = $bbu->buchungstag;

=head4 Alias

buchungsdatum()

=head4 Returns

String

=cut

# -----------------------------------------------------------------------------

sub buchungstag {
    my $self = shift;

    if ($self->exists('buchungstag')) {
        return $self->get('buchungstag');
    }

    return $self->buchungsdatum;
}

{
    no warnings 'once';
    *buchungsdatum = \&buchungstag;
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

1.131

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
