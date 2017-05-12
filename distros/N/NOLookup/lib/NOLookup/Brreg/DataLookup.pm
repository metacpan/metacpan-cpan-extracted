package NOLookup::Brreg::DataLookup;

use warnings;
use strict;
use base qw(Class::Accessor::Chained); ## Provides a new() method
use POSIX qw(locale_h);
use NOLookup::Brreg::Entry;
use WWW::Mechanize;
use JSON;
use URI::Encode qw(uri_encode);
use Data::Dumper;
$Data::Dumper::Indent=1;

my $BRREG_TIMEOUT = 60; # secs (default is 180 secs but we want shorter time).

my $BRREG = "http://data.brreg.no/enhetsregisteret";

my @module_methods = qw /

    lookup_orgno
    lookup_orgname
    lookup_reg_dates
    orgno_ok

    status
    error
    warning

    data
    size
    total_size
    next_page

    raw_json_decoded
   /;

# The new method and also the accessor methods
__PACKAGE__->mk_accessors( 
    @module_methods 
);



######## L o o k u p

sub lookup_orgno {
    my ($self, $orgno) = @_;

    # validate the organizaton number
    unless (orgno_ok($self, $orgno)) {
	return $self;
    }
    ##
    # Use the orgno as key to brreg.
    # Match is only found if number does exist.
    $self->_lookup_org_entries("$BRREG/enhet/$orgno.json");

}

sub lookup_orgname {
    my ($self, $orgname) = @_;

    # Use the orgname as filter in search to brreg
    # Note a limitation in the brreg API service that 
    # that only names starting with $orgname is supported,
    # ref. the 'startswith' filter in the URL.
    # We should've liked a 'contains' instead. 

    my $onm_e = uri_encode($orgname, {encode_reserved => 1});

    my $BR = "$BRREG/enhet.json?size=100&\$filter=startswith(navn,'$onm_e')";

    # First page is 0
    my $pcnt = 0;
    $self->size(0);
    $self->next_page(1); # force the first lookup

    # Fetch max 5 pages
    while ($self->next_page && $pcnt < 5) {
	#print STDERR "Page count is: $pcnt, fetching next page...\n";
	$self->_lookup_org_entries("$BR&page=$pcnt");
	++$pcnt;
    }
}

sub lookup_reg_dates {
    my ($self, $from_date, $to_date) = @_;

    # Use the from / to dates as filter for lookup on 
    # registration dates
    my $rdateF = "registreringsdatoEnhetsregisteret";
    my $ztime = "T00:00";
    my $dateFilter;
    if ($from_date && !$to_date) {
	$from_date .= $ztime;
	$dateFilter = "$rdateF ge datetime'$from_date'";
    } elsif (!$from_date && $to_date) {
	$to_date .= $ztime;
	$dateFilter = "$rdateF le datetime'$to_date'";
    } else {
	$from_date .= $ztime;
	$to_date .= $ztime;
	
	$dateFilter = "$rdateF ge datetime'$from_date' and $rdateF le datetime'$to_date'";
    }
    
    my $df = uri_encode($dateFilter, {encode_reserved => 1});
    my $BR = "$BRREG/enhet.json?size=100&\$filter=$df";
      
    # First page is 0
    my $pcnt = 0;
    $self->size(0);
    $self->next_page(1); # force the first lookup

    # Fetch max 5 pages
    while ($self->next_page && $pcnt < 5) {
	#print STDERR "Page count is: $pcnt, fetching next page...\n";
	$self->_lookup_org_entries("$BR&page=$pcnt");
	++$pcnt;
    }
}


sub orgno_ok {
    my ($self, $orgno) = @_;

    # remove any white spaces
    $orgno =~ s/\s+//g;

    if ($orgno eq "000000000") {
	$self->status("Invalid orgno: $orgno");
	$self->error(1);
	return 0;
    }
    unless ($orgno =~ m/\d{9}/) {
	$self->status("Organization number $orgno must be 9 digits");
	$self->error(1);
	return 0;
    }    
    return 1;
}

#####
# The lookup itself, internal method only.

sub _lookup_org_entries {
    my ($self, $URL) = @_;

    #print STDERR "URL: $URL\n";
    
    my $mech = WWW::Mechanize->new(
        timeout => $BRREG_TIMEOUT,
        autocheck => 0
	);
    
    my $resp = $mech->get($URL);

    unless ($mech->success) {
	$self->status($resp->status_line);
	$self->error(1);
	$self->next_page(undef);
	return $self;
    }

    my $json = decode_json($mech->text);

    if ($json) {
	$self->raw_json_decoded($json);
	
	# Map the json data structure to 
	# internal entry objects
	my $eo = NOLookup::Brreg::Entry->new;
	my $entries = $eo->map_json_entries($json);

	# Collect any accumulated problems
	$self->status($eo->status) if ($eo->status);
	$self->warning($eo->warning) if ($eo->warning);
	$self->error($eo->error) if ($eo->error);

	# Save the found data
	if (@$entries) {
	    push @{$self->{data}}, @$entries;
	    $self->size($self->size + scalar @$entries);

	    if ($eo->next_page) {
		# more pages are available.
		$self->next_page($eo->next_page);
	    } else {
		# No more pages, all results are returned,
		# and we know the total_size (=size)
		# Only if total_size is set, the user can assume
		# that all data has been fetched.
		$self->total_size($self->size);
		$self->next_page(undef);
	    }
	} else {
	    $self->next_page(undef);
	}
    }
    return $self;
}

=pod

=encoding ISO-8859-1

=head1 NAME

NOLookup::Brreg::DataLookup - Lookup Brreg basic organization data from
the JSON formatted service offered by the Brreg data API via
http://data.brreg.no/oppslag/enhetsregisteret/enheter.xhtml

(Brreg is a short name for 'Brønnysundregistrene, the Norwegian
Central Organization Registry).

=head1 DESCRIPTION

Use WWW::Mechanize and JSON to lookup data from the JSON API at brreg.
Use NOLookup::Brreg::Entry module to map the resulting json data
structure to a NOLookup::Brreg::Entry objects.

The timeout period $BRREG_TIMEOUT is used to trap and return the call
if Brreg lookup is hanging for some reason.

=head1 METHODS

The module provides the below methods.

=head3 lookup_orgno()

Lookup based on a complete organization number.

Returns an array of one single NOLookup::Brreg::Entry object in the data 
when a match is found.

=head3 lookup_orgname()

Lookup based on a complete or part of an organization name.

Returns 0 entries if none found.

Returns an array of NOLookup::Brreg::Entry objects in the data 
when matches are found.

Note: A maximum of 5 pages are fetched, each of 100 entries.

=head3 lookup_reg_dates()

Lookup based on registration dates.
A from_date and/or a to_date can be specified.

The lookup will find registrations performed after midnight starting
the from date, and until midnight at the end of the to date.

Returns 0 entries if none found.

Returns an array of NOLookup::Brreg::Entry objects in the data 
when matches are found.

Note: A maximum of 5 pages are fetched, each of 100 entries.


=head3 orgno_ok()

Check if org. number basic syntax is OK, i.e. 9 digits.
Note that Brreg may reject the number due to stricter 
requirements, like checksum etc.

=head3 raw_json_decoded()

The raw JSON data structure, as returned by the JSON service,
and then decoded to a perl data structure with decode_json().

=head3 error()

Set if an error has occured. 
On errors, the lookup terminates, with more info 
in the status().

=head3 warning()

Set if a warning has occured.
On warnings, the lookup continues, but warnings
are accumulated in the status().

=head3 status()

Further description of error/warning situations.

=head3 data()

Found data, an array of NOLookup::Brreg::Entry data objects.

See doc. for NOLookup::Brreg::Entry for details.

=head3 size()

The number of objects in data().

=head3 total_size()

The total number of objects in data().

Only set if all data has been fetched.

Only if total_size is set, the user can assume
that all data has been fetched.

=head3 next_page()

If more pages (of 100 elements) can be fetched,
this method gives the URL to that page.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>(nospam)info(at)norid.noE<gt>

Please also see the README file in the distribution.

=head1 SEE ALSO

http://www.brreg.no
http://data.brreg.no/oppslag/enhetsregisteret/enheter.xhtml

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
