package NOLookup::Brreg::Entry;

use warnings;
use strict;
use base qw(Class::Accessor::Chained); ## provides a new() method
use Encode;
use POSIX qw(locale_h);

use Data::Dumper;
$Data::Dumper::Indent=1;

# module methods
my @module_methods = (

    qw /
       status
       error
       warning

       map_json_entries

       next_page
       cur_page
       prev_page
       total_page_count

       result_count
       total_result_count

    /);


# Brreg entry name
my @json_data_methods = ( 
    
    # number and name
    qw /
       organisasjonsnummer
       navn
       oppdateringsid
    /,
    
    # dates
    qw /
       registreringsdatoEnhetsregisteret
       stiftelsesdato
       sisteInnsendteAarsregnskap
       slettedato
       oppstartsdato
       dato
       datoEierskifte
    /,

    qw /
       overordnetEnhet
       maalform
    /,

    # BOOL
    qw /
       registrertIStiftelsesregisteret
       registrertIFrivillighetsregisteret
       registrertIMvaregisteret
       registrertIForetaksregisteret
       underAvvikling
       konkurs
       underTvangsavviklingEllerTvangsopplosning
    /,

    # hashes with their own extra keys
    qw /
       forretningsadresse
       beliggenhetsadresse
       postadresse
       institusjonellSektorkode
       naeringskode1
       naeringskode2
       naeringskode3
       _links
       page
       organisasjonsform
    /,

    # web page, number of employed
    qw /
       hjemmeside
       antallAnsatte
    /,

    # Arrays
    qw / 
       frivilligMvaRegistrertBeskrivelser
    /
    
    );

# The new method and also the accessor methods
__PACKAGE__->mk_accessors(
    @module_methods,
    @json_data_methods
);

sub map_json_entries {
    my ($self, $json) = @_;

    return unless ($json);    
        
    my @aj;
    my @ao;

    $self->status("");
    if ($json->{navn}) {
        # single entry on the data array
        push @aj, $json;

    } elsif ($json->{_embedded} && $json->{_embedded}->{enheter}) {
        # multiple entries
        push @aj, @{$json->{_embedded}->{enheter}};

    } elsif ($json->{_embedded} && $json->{_embedded}->{underenheter}) {
        # multiple entries
        push @aj, @{$json->{_embedded}->{underenheter}};

    } elsif ($json->{_embedded} && $json->{_embedded}->{oppdaterteEnheter}) {
        # multiple updated entries
        push @aj, @{$json->{_embedded}->{oppdaterteEnheter}};

    } elsif ($json->{_embedded} && $json->{_embedded}->{oppdaterteUnderenheter}) {
        # multiple updated entries
        push @aj, @{$json->{_embedded}->{oppdaterteUnderenheter}};

    }

    # count the current posts
    $self->result_count(scalar  @aj);
    
    #print STDERR "Entry self: ", Dumper $self;

    if ($json->{page}) {
        # page data
        #print STDERR "page entry: ", Dumper $json->{page};

	$self->total_result_count($json->{page}->{totalElements});
	$self->cur_page($json->{page}->{number});
	$self->total_page_count($json->{page}->{totalPages});
	    
	$self->prev_page(undef);
	$self->next_page(undef);

	if ($self->cur_page > 0) {
	    $self->prev_page($self->cur_page - 1);
	}
	if ($self->total_page_count > $self->cur_page) {
	    $self->next_page($self->cur_page + 1);
	}
    }

    # Mape found orgs into NOLookup::Brreg::Entry objects
    foreach my $ej (@aj) {
        foreach my $k (keys %$ej) {
	    # Check entry array for supported keys
	    # set a warning if some are not expected
            unless ($self->can($k)) {
                $self->status($self->status . "JSON data key entry not expected: $k\n");
                $self->warning(1);
            }
        }
        my $eo = NOLookup::Brreg::Entry->new($ej);
        push @ao, $eo;
    }

    # return a ref to the data array
    return \@ao;
 }    

=pod

=encoding ISO-8859-1

=head1 NAME

NOLookup::Brreg::Entry - Map a Brreg json data structure element
to Brreg::Entry data objects.

=head1 DESCRIPTION

Map the json data to data objects.

Return a reference to an array of NOLookup::Brreg::Entry objects.

=head1 METHODS

=head2 module methods

The methods provided by this module.

=head3 error()

Set if an error has occured. 
On errors, the lookup terminates.

=head3 warning()

Set if a warning has occured.
On warnings, the lookup continues.

=head3 status()

Further description of an error/warning situation.

If the returned JSON structure contains an unsupported data element,
the lookup will be performed, but a warning may be returned and
and with a status saying: 

 'Warning: JSON data key entry not expected: xxxx'

where 'xxxx' is the unexpected key. If this happens, the module
should be updated with a new method to support the element 'xxx'.

=head3 map_json_entries()

Map the JSON data structure from Brreg to NOLookup::Brreg::Entry 
data objects.

Returns a ref. to an array of NOLookup::Brreg::Entry data objects.

=head3 cur_page()/prev_page()/next_page()

If more pages can be fetched, those methods give the URL to that page

=head3 total_page_count()

Count of total nuber of pages matching the search

=head3 result_count()

Count of results on this page

=head3 total_result_count()

Count of total results for the search


=head2 Accessor methods

Data elements are available through acessors in the NOLookup::Brreg::Entry object.
This is the possible JSON data methods, which are the accessor
methods that can be used to find the returned data elements.

The accessor methods from @json_data_methods

  organisasjonsnummer 
  navn 
  oppdateringsid
  registreringsdatoEnhetsregisteret 
  stiftelsesdato
  oppstartsdato
  sisteInnsendteAarsregnskap 
* organisasjonsform
  overordnetEnhet
  maalform
  registrertIStiftelsesregisteret
  registrertIFrivillighetsregisteret
  registrertIMvaregisteret
  registrertIForetaksregisteret
  frivilligMvaRegistrertBeskrivelser

  underAvvikling
  konkurs
  underTvangsavviklingEllerTvangsopplosning
* forretningsadresse 
* postadresse
* institusjonellSektorkode 
* naeringskode1 
* naeringskode2
* naeringskode3
* _links
* page
  hjemmeside 
  antallAnsatte

Returned values:

Most of the accessor methods returns a single value, like 'navn',
which returns a scalar with the name of the organization.

Some of the methods returns a hash, and are marked with an asterix (*).
Hash data must be accessed via their respective keys.

The hashes are described below.

=head3 organisasjonsform()

The hash looks like follows:

  "organisasjonsform": {
    "kode": "AS",
    "beskrivelse": "Aksjeselskap",
    "_links": {
      "self": {
        "href": "https://data.brreg.no/enhetsregisteret/api/organisasjonsformer/AS"
      }
    }
  },


=head3 forretningsadresse() / postadresse()

The hash looks like follows:

 "forretningsadresse": {
    "land": "Norge",
    "landkode": "NO",
    "postnummer": "7030",
    "poststed": "TRONDHEIM",
    "adresse": [
      "Abels gate 5"
    ],
    "kommune": "TRONDHEIM",
    "kommunenummer": "5001"
  },

=head3 institusjonellSektorkode()

The hash looks like follows:

 'institusjonellSektorkode' => {
    'beskrivelse' => 'Statlig eide aksjeselskaper mv.',
    'kode' => '1120'
  }

=head3 naeringskode1/2/3()

The hash looks like follows:

  'naeringskode1' => {
    'beskrivelse' => "Utvinning av r\x{e5}olje",
    'kode' => '06.100'
  },

=head3 frivilligMvaRegistrertBeskrivelser()

The hash looks like follows:

  'frivilligMvaRegistrertBeskrivelser' => [
    'Utleier av bygg eller anlegg'
  ],


=head3 _links() 

The hash looks like follows:

 "_links": {
    "self": {
      "href": "https://data.brreg.no/enhetsregisteret/api/enheter/985821585"
    }
  }


=head1 SUPPORT

For now, support questions should be sent to:

E<lt>(nospam)info(at)norid.noE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

C<NOLookup::Brreg::DataLookup>

=head1 AUTHOR

Trond Haugen, E<lt>(nospam)info(at)norid.noE<gt>

=head1 COPYRIGHT

Copyright (c) 2017- Trond Haugen <(nospam)info(at)norid.no>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
