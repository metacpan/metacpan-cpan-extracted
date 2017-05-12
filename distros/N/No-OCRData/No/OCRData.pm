package No::OCRData;

# This package deals with files that can be retrieved from Norwegian 
# banks, if you have proper agreements. In the good old days, these 
# files were generated mostly by scanning and OCRing paper, and for 
# that reason the service is still called "OCRGiro". The data 
# I've operated on has hardly been OCRed, but that is what they 
# to date emphasize... 

# For copyright and author information, see inline POD. 

require Exporter;

@ISA=qw(Exporter);
@EXPORT_OK = qw(parse reduce kid_hash);

use strict;
use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 0.93 $ =~ /(\d+)\.(\d+)/);


=head1 NAME

No::OCRData - Operate on OCRed data from Norwegian banks  

=head1 SYNOPSIS

    use No::OCRData qw(parse reduce kid_hash);
    @data = reduce(parse(@d));
    print $data[21]{'SUM_BELOP'};
    %mykids = kid_hash(reduce(parse(@d)));
    print $mykids{'900969'}{'OPPGJORSDATO'}

=head1 DESCRIPTION

B<This documentation is written in Norwegian>, for others, suffice to say that it does not really have much to do with Optical Character Recognition.

Denne modulen brukes til å parse og få ut noe fornuftig ut av filene som kommer fra Bankenes Betalingssentrals OCRGiro-tjeneste. 

Denne dokumentasjonen, eller modulen for den saks skyld, vil ikke gi deg mye uten at du leser BBS sin spesifikasjon, som finnes på 
L<http://www.bbs.no/ocr/brukerhandboeker/ocrg_systemhandbok030601.pdf>

Rutinene lager en hash av hashrefs eller array av hashrefs, der navnene på nøklene er de samme som i spesifikasjonen, med det unntak av mellomrom blir til '_' og ø blir til o. De er alle i store bokstaver. 

Ingen av rutinene eksporteres implisitt.  Du må be om dem. Rutinene er som følger:


=over

=item C<parse(@arr)>

Funksjonen C<parse()> tar en array som inneholder innholdet i fila (som må leses inn som en array på vanlig måte hvis man faktisk leser fra fil). Den gjør grovarbeidet med å parse fila. Den returnerer en array med hashrefs, der nøklene er navnene fra spesifikasjonen som beskrevet over. 0-er som brukes til padding taes ikke med, men forøvrig gjør ikke C<parse()> noe forsøk på å gjøre noe å gjøre noe med dataene. Se C<reduce()>.

=cut

sub parse
{
    my @data;
    foreach my $str (@_) {
	my %record;
	$record{'FORMATKODE'}   = substr($str,0,2);
	$record{'TJENESTEKODE'} = substr($str,2,2);
	if ($record{'TJENESTEKODE'} eq '00') {
	    # Vi har et start/slutt-record for forsendelse
	    $record{'FORSENDELSESTYPE'} = substr($str,4,2);
	    $record{'RECORDTYPE'} = substr($str,6,2);
	    if ($record{'RECORDTYPE'} eq '10') {
		# startrecord for forsendelse
		$record{'DATAAVSENDER'} = substr($str,8,8);
		$record{'FORSENDELSESNUMMER'} = substr($str,16,7);
		$record{'DATAMOTTAKER'} = substr($str,23,8);
	    } 
	    elsif ($record{'RECORDTYPE'} eq '89') {
		# sluttrecord for forsendelse
		$record{'ANTALL_TRANSAKSJONER'} = substr($str,8,8);
		$record{'ANTALL_RECORDS'} = substr($str,16,8);
		$record{'SUM_BELOP'} = substr($str,24,17);
		$record{'OPPGJORSDATO'} = substr($str,41,6);
	    } else {
		die "Ukjent RECORDTYPE $record{'RECORDTYPE'} $!";
	    }
	} 
	elsif ($record{'TJENESTEKODE'} eq '09') {
	    $record{'TRANSAKSJONSTYPE'} = substr($str,4,2);
	    $record{'RECORDTYPE'} = substr($str,6,2);
            if($record{'TRANSAKSJONSTYPE'} eq '00') {
		# Start eller sluttrecord for oppdrag
		$record{'OPPDRAGSTYPE'} = $record{'TRANSAKSJONSTYPE'};
		delete $record{'TRANSAKSJONSTYPE'}; # Finnes ikke naa
		if ($record{'RECORDTYPE'} eq '20') {
		    # startrecord for forsendelse
		    $record{'AVTALE-ID'} = substr($str,8,9);
		    $record{'OPPDRAGSNUMMER'} = substr($str,17,7);
		    $record{'OPPDRAGSKONTO'} = substr($str,24,11);
		} 
		elsif ($record{'RECORDTYPE'} eq '88') {
		    # sluttrecord for oppdrag
		    $record{'ANTALL_TRANSAKSJONER'} = substr($str,8,17);
		    $record{'ANTALL_RECORDS'} = substr($str,16,8);
		    $record{'SUM_BELOP'} = substr($str,24,17);
		    $record{'OPPGJORSDATO'} = substr($str,41,6);
		    $record{'FORSTE_OPPGJORSDATO'} = substr($str,47,6);
		    $record{'SISTE_OPPGJORSDATO'} = substr($str,53,6);
		} else {
		    die "Ukjent RECORDTYPE $record{'RECORDTYPE'} $!";
		}
	    } else {
		# Transaksjonsrecord
		$record{'TRANSAKSJONSNUMMER'} = substr($str,8,7);
		if ($record{'RECORDTYPE'} eq '30') {
		    # Belopspost 1
		    $record{'OPPGJORSDATO'} = substr($str,15,6);
		    $record{'SENTRAL-ID'} = substr($str,21,2);
		    $record{'DAGKODE'} = substr($str,23,2);
		    $record{'DELAVREGNINGSNUMMER'} = substr($str,25,1);
		    $record{'LOPENUMMER'} = substr($str,26,5);
		    $record{'BELOP'} = substr($str,32,17);
		    $record{'KID'} = substr($str,49,25);
		} 
		elsif ($record{'RECORDTYPE'} eq '31') {
		    # Belopspost 2
		    $record{'BLANKETTNUMMER'} = substr($str,15,10);
		    $record{'AVTALE-ID'} = substr($str,25,9);
		    $record{'POSTGIROKONTO'} = substr($str,34,7);
		    $record{'OPPDRAGSDATO'} = substr($str,41,6);
		    $record{'DEBET_KONTO'} = substr($str,47,11);
		} else {	
		    die "Ukjent RECORDTYPE $record{'RECORDTYPE'} $!";
		}
	    }
	} else {
	    die "Ukjent TJENESTEKODE $record{'TJENESTEKODE'} $!";
	}
	push(@data,\%record);
    }
    return @data;
}

=item C<reduce(@arr)>

C<reduce()> tar en array som har kommet fra C<parse()> som input og prøver å gjøre en del nødvendige ting med den (astronomer har det med å kalle det denne rutinen gjør for "redusering av data"). Det anbefales at C<reduce()> brukes umiddelbart etter C<parse()>, men det kan jo tenkes at andre vil gjøre det på en annen måte.  Den returner så en modifisert versjon av samme array. Disse forandringene gjøres av C<reduce()>:

=over 

=item * 

Sletter det overflødige FORMATKODE-feltet.

=item * 

Fjerner whitespace fra starten av KID-feltet. 

=item * 

Alle datoer blir transformert fra formen DDMMYY (bare de to siste tallene i årstallet brukes) til en streng på formen YYYY-MM-DD (ISO8601). Det antas her at årstallet begynner med 20.  

=item * 

Ledende nuller fra felter som ikke er en KONTO, en KODE eller en TYPE fjernes.

=item * 

Alle beløper er i øre i fila, og deles på hundre for å gjøres om til kroner. 

=item * 

Tomme felter fjernes (dette inkluderer felter som kun hadde nuller). 

=item * 

DEBET_KONTO og POSTGIROKONTO fjernes hvis den kun inneholdt nuller. 

=back

=cut

sub reduce {
    my @data;
    foreach my $record (@_) {
	delete ${$record}{'FORMATKODE'}; # FORMATKODE-feltet er overfloedig
	if (${$record}{'KID'}) {
	    ${$record}{'KID'} =~ s/^\s*//; # Fjern blanke fra starten av KID
        }
	foreach my $key (keys(%{$record})) {
	    if ($key =~ m/DATO/)
	    {
		# Omform datoer til ISO8601-form
		# NB: Problemer med forrige og neste aarhundre...
		${$record}{$key} = '20' . substr(${$record}{$key},4,2)
                                   . '-' . substr(${$record}{$key},2,2)
                                   . '-' . substr(${$record}{$key},0,2);
            }
            unless (($key =~ m/KODE/) || ($key =~ m/TYPE/) || ($key =~ m/KONTO/))
            {
                # Fjern 0 fra starten av felt som ikke er en KODE, TYPE eller KONTO
		${$record}{$key} =~ s/^0*//; 
            }
            unless (${$record}{'DEBET_KONTO'} =~ m/[1-9]/)
            {
		delete ${$record}{'DEBET_KONTO'};
            }
            unless (${$record}{'POSTGIROKONTO'} =~ m/[1-9]/)
            {
		delete ${$record}{'POSTGIROKONTO'};
            }
            if ($key =~ m/BELOP/) {
		# Alle beloeper er i oere og deles derfor paa hundre
		${$record}{$key} /= 100;
            }
            # Felter som naa er tomme kan fjernes
            if (length(${$record}{$key}) == 0) {
                delete ${$record}{$key};
            } 
        }
        push(@data, $record); 
    } 
return @data;
}

=item C<kid_hash(@arr)>

C<kid_hash()> tar en array som har blitt redusert med C<reduce()> og returnerer en hash der KID-nummerne brukes som nøkler for transaksjonene som fila inneholder. Transaksjonene selv representeres ved hashrefs, der nøkkelordene fra spesifikasjonen brukes (se over).

Data fra fila som ikke er tilknyttet enkelte transaksjoner (f.eks. sum beløp) kastes vekk av denne rutinen.  Feltet RECORDTYPE fjernes også fordi data fra RECORDTYPEne 30 og 31 begge inkluderes. 

Hvordan dette gjøres i detalj er en smule innviklet, og det er potensiale for en bug i dette. Se under "L<BUGS|/"Sammenstilling av transaksjoner">" hvis detaljene er interessante. 


=cut


sub kid_hash
{
    my @indata = @_;
    my %data;
    my $kid;     
    foreach my $record (@indata) {
	if (${$record}{'RECORDTYPE'} eq '30') {
	    $kid = ${$record}{'KID'};
	    $data{$kid} = $record;
	}
        if (${$record}{'RECORDTYPE'} eq '31') {
            my $transnr = ${$record}{'TRANSAKSJONSNUMMER'};
            if ($data{$kid}{'TRANSAKSJONSNUMMER'} eq $transnr) {
                foreach my $key (keys(%{$record})) {
                    $data{$kid}{$key} = ${$record}{$key};
                }
                delete $data{$kid}{'RECORDTYPE'};
            } else {
                die "Du har sannsynligvis funnet en bug i No::OCRData::kid_hash, se BUGS i POD.";
            }
        }
    }
    return %data;
}

1;

=back

=head1 BUGS/TODO

=head2 Y2K

C<reduce()> antar at årstallet begynner med 20. Dette vil selvfølgelig ikke fungere hvis man jobber på data fra 1900-tallet (eller 2100-tallet...). Dette er ikke min feil, fordi BBS sine filer representerer årstall med kun to siffer. De har således en Y2K-feil. 

=head2 Ett oppdrag

Jeg har kun operert på filer der det har vært et enkelt oppdrag per fil. Flere oppdrag per fil er utestet og C<kid_hash()> vil sannsynligvis ikke fungere på slike filer, så se på det som en TODO. Det bør ikke influere de andre rutinene. Jeg antar at hvis man kun har en OCRGiro-avtale vil man kunne bruke C<kid_hash()> som den er. 

=head2 Sammenstilling av transaksjoner

Å sette sammen transaksjoner fra forskjellige RECORDTYPEr slik det gjøres av C<kid_hash()> er som nevnt litt innviklet. Det gjøres ved å sammenligne feltene TRANSAKSJONSNUMMER fra forskjellige records. I seg selv greit, og siden alle filer jeg har sett har hatt records med samme transaksjonsnummer umiddelbart etter hverandre, er det antatt at dette gjelder generelt. Spesifikasjonen er ikke klar på dette punktet. C<kid_hash()> inneholder en enkel sjekk på om dette er tilfelle for hver enkel record, og vil dø med en feilmelding hvis antagelsen ikke holder. 

=head2 Operere på filehandles

Det hadde vært mer elegant om C<parse()> faktisk kunne operere på filehandles, av mer generisk art. 


=head1 AUTHOR

Kjetil Kjernsmo <kk@kjernsmo.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2003, Kjetil Kjernsmo. Some rights reserved.

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut

