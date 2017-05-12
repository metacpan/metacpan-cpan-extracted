package NOLookup::BrregDifi::Entry;

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

my @json_data_methods = ( 
    
   qw /
    nkode2
    nkode1
    ansatte_dato
    tlf_mobil
    organisasjonsform
    ppoststed
    tvangsavvikling
    forretningsadr
    regifriv
    orgnr
    forradrland
    stiftelsesdato
    forradrkommnr
    konkurs
    regdato
    avvikling
    hovedenhet
    regifr
    forradrpoststed
    ppostland
    forradrkommnavn
    forradrpostnr
    navn
    regnskap
    url
    ansatte_antall
    sektorkode
    regimva
    ppostnr
    postadresse
    nkode3
    regiaa
    tlf
  
  / );

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

    #print Dumper $json;

    $self->status("");

    if ($json->{posts}) {

	push @aj, @{$json->{entries}};

	# count the current posts
	$self->result_count(scalar  @{$json->{entries}});
	$self->total_result_count($json->{posts});

	$self->cur_page($json->{page});

	if ($json->{page} == 1) {
	    $self->prev_page(1);
	} else {
	    $self->prev_page($json->{page} - 1);
	}
	if ($json->{pages} > $json->{page}) {
	    $self->next_page($json->{page} + 1);
	} else {
	    $self->next_page(undef);
	}

	$self->total_page_count($json->{pages});
	
	# Check entry array for supported keys
	# set a warning if some are not expected
	foreach my $ej (@aj) {
	    foreach my $k (keys %$ej) {
		unless ($self->can($k)) {
		    $self->status($self->status . "JSON data key entry not expected: $k\n");
		    $self->warning(1);
		}
	    }
	    my $eo = NOLookup::BrregDifi::Entry->new($ej);
	    push @ao, $eo;
	}
    }
    # return a ref to the data array
    return \@ao;
 }    

=pod

=encoding ISO-8859-1

=head1 NAME

NOLookup::BrregDifi::Entry - Map a Brreg json data structure element
to NOLookup::BrregDifi::Entry data objects.

=head1 DESCRIPTION

Map the json data to data objects.

Return a reference to an array of NOLookup::BrregDifi::Entry objects.

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

Map the JSON data structure from Brreg to NOLookup::BrregDifi::Entry 
data objects.

Returns a ref. to an array of NOLookup::BrregDifi::Entry data objects.

=head3 cur_page()

The number of the current page.

=head3 next_page()

The number of the next page, if any.

=head3 prev_page()

The number of the previous page, if not on first page.

=head3 total_page_count()

The total number of pages matching the search.

=head3 result_count()

The number of data entries in this page.

=head3 total_result_count()

The number of total data entries in all pages matching the search.

=head2 Accessor methods

Data elements are available through acessors in the
NOLookup::BrregDifi::Entry object.  This is the possible JSON data
methods, which are the accessor methods that can be used to find the
returned data elements.

The accessor methods are listed in the @json_methods array

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>(nospam)info(at)norid.noE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

C<NOLookup::BrregDifi::DataLookup>

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
