package NOLookup::Patent::Entry;

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

       result_count
       total_result_count

       map_json_entries

    /);

my @json_data_methods = ( 

    # search lookup methods
    qw /
       thumbnail_url
       trademark_image
       trademark_text
       status
       toplevelstatus
       applicant
       application_number
    /,

    # id lookup methods
    qw / 
       trademark_text
       status
       toplevelstatus
       application_number
       registration_number
       registered_date
       filed_date
       case_type
       trademark_category
       type_of_mark
       goods_and_services
       applicant
       owner
       agent

       trademark_image
       last_updated
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

    if ($json->{status} ne 'OK') {
	$self->error(1);
	$self->status($json->{status});

    } elsif ($json->{search_results}) {
	# multiple search results
	push @aj, @{$json->{search_results}};
	$self->result_count($json->{result_count});
	$self->total_result_count($json->{total_result_count});

    } elsif ($json->{key_info}) {
	# single application id, return key info only
	my $res                 = $json->{key_info};
	$res->{trademark_image} = $json->{trademark_image};
	$res->{last_updated}    = $json->{last_updated};
	push @aj, $res;
	$self->result_count(1);
	$self->total_result_count(1);
    }
    
    #print STDERR "key_info: ", Dumper \@aj;

    # Check entry array for supported keys
    # set a warning if some are not expected
    foreach my $ej (@aj) {
	foreach my $k (keys %$ej) {
	    unless ($self->can($k)) {
		$self->status($self->status . "JSON data key entry not expected: $k\n");
		$self->warning(1);
	    }
	}
	my $eo = NOLookup::Patent::Entry->new($ej);
	push @ao, $eo;
    }
    
    # return a ref to the data array
    return \@ao;
 }    

=pod

=encoding ISO-8859-1

=head1 NAME

NOLookup::Patent::Entry - Map a Patentstyret json data structure element
to a NOLookup::Patent::Entry data objects.

=head1 DESCRIPTION

Map the json data to data objects.

Return a reference to an array of NOLookup::Patent::Entry objects.

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

Map the JSON data structure from Brreg to NOLookup::Patent::Entry 
data objects.

Returns a ref. to an array of NOLookup::Patent::Entry data objects.

=head3 result_count

The count of data entries in this page.

=head3 total_result_count

The total count of data entries for all pages matching the search.


=head2 Accessor methods

Data elements are available through acessors in the
NOLookup::Patent::Entry object. This is the possible JSON data methods,
which are the accessor methods that can be used to find the returned
data elements.

The accessor methods are listed in the @json_data_methods array.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>(nospam)info(at)norid.noE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

C<NOLookup::Patent::DataLookup>

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
