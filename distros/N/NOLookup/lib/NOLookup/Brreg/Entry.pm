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

    /);

# note: orgnr is inserted to be compatible with
# Difi entry name
my @json_data_methods = ( 
    
    # number and name
    qw /
       organisasjonsnummer
       orgnr
       navn
    /,
    
    # dates
    qw /
       registreringsdatoEnhetsregisteret
       stiftelsesdato
       sisteInnsendteAarsregnskap
    /,

    # Org form, like AS etc.
    qw /
       organisasjonsform
       overordnetEnhet
    /,

    # BOOL (J/N)
    qw /
       registrertIStiftelsesregisteret
       registrertIFrivillighetsregisteret
       registrertIMvaregisteret
       registrertIForetaksregisteret
       frivilligRegistrertIMvaregisteret
       underAvvikling
       konkurs
       underTvangsavviklingEllerTvangsopplosning
    /,

    # hashes with their own extra keys
    qw /
       forretningsadresse
       postadresse
       institusjonellSektorkode
       naeringskode1
       naeringskode2
       naeringskode3
       links
    /,

    # web page, number of employed
    qw /
       hjemmeside
       antallAnsatte
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
	
    } elsif ($json->{data}) {
	# multiple entries 
	push @aj, @{$json->{data}};
    }
    
    # Check entry array for supported keys
    # set a warning if some are not expected
    foreach my $ej (@aj) {
	foreach my $k (keys %$ej) {
	    unless ($self->can($k)) {
		$self->status($self->status . "JSON data key entry not expected: $k\n");
		$self->warning(1);
	    }
	}
	my $eo = NOLookup::Brreg::Entry->new($ej);
	$eo->orgnr($eo->organisasjonsnummer);  
	push @ao, $eo;
    }
    # Set next link page if more pages are present 
    $self->next_page(undef);
    foreach my $l (@{$json->{links}}) {
	if ($l->{rel} eq 'next') {
	    $self->next_page($l->{href});
	}
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

=head3 next_page()

If more pages (of 100 elements) can be fetched,
this method gives the URL to that page.

=head2 Accessor methods

Data elements are available through acessors in the NOLookup::Brreg::Entry object.
This is the possible JSON data methods, which are the accessor
methods that can be used to find the returned data elements.

The accessor methods are:

  organisasjonsnummer 
  navn 
  registreringsdatoEnhetsregisteret 
  stiftelsesdato 
  sisteInnsendteAarsregnskap 
  organisasjonsform
  overordnetEnhet
  registrertIStiftelsesregisteret
  registrertIFrivillighetsregisteret
  registrertIMvaregisteret
  registrertIForetaksregisteret
* frivilligRegistrertIMvaregisteret
  underAvvikling
  konkurs
  underTvangsavviklingEllerTvangsopplosning
* forretningsadresse 
* postadresse
* institusjonellSektorkode 
* naeringskode1 
* naeringskode2
* naeringskode3
* links 
  hjemmeside 
  antallAnsatte

Returned values:

Most of the accessor methods returns a single value, like 'navn',
which returns a scalar with the name of the organization.

Some of the methods returns a hash, and are marked with an asterix (*).
Hash data must be accessed via their respective keys.

The hashes are described below.

=head3 forretningsadresse() / postadresse()

The hash looks like follows:

  'forretningsadresse' => {
    'land' => 'Norge',
    'kommune' => 'STAVANGER',
    'postnummer' => '4035',
    'poststed' => 'STAVANGER',
    'kommunenummer' => '1103',
    'landkode' => 'NO',
    'adresse' => 'Forusbeen 50'
  },

=head3 institusjonellSektorkode()

The hash looks like follows:

 'institusjonellSektorkode' => {
    'beskrivelse' => 'Statlig eide aksjeselskaper mv.',
    'kode' => '1120'
  }

=head3 naeringskode1() / naeringskode2()

The hash looks like follows:

  'naeringskode1' => {
    'beskrivelse' => "Utvinning av r\x{e5}olje",
    'kode' => '06.100'
  },

=head3 frivilligRegistrertIMvaregisteret()

The hash looks like follows:

  'frivilligRegistrertIMvaregisteret' => [
    'Utleier av bygg eller anlegg'
  ],


=head3 links() 

The hash looks like follows:

  'links' => [
     {
       'rel' => 'self',
       'href' => 'http://data.brreg.no/enhetsregisteret/enhet/923609016'
     }
   ]


=head1 SUPPORT

For now, support questions should be sent to:

E<lt>(nospam)info(at)norid.noE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

C<NOLookup::Brreg::DataLookup>

=head1 AUTHOR

Trond Haugen, E<lt>(nospam)info(at)norid.noE<gt>

=head1 COPYRIGHT

Copyright (c) 2017 Trond Haugen <(nospam)info(at)norid.no>.
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
