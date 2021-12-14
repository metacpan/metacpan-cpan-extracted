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
my $MAX_PAGES     = 10;  # max pages to fetch if no max is specified
my $MAX_SIZE      = 100; # max size to ask for in each request

# API service URLs
my $BRREG            = "https://data.brreg.no/enhetsregisteret/api";
my $BRREG_UPD        = "https://data.brreg.no/enhetsregisteret/api/oppdateringer";

###
# API version selection.
# It is possible to specify a specific version of the API,
# and we use that to get a more stable API.
#
# Version is signalled by use of the http accept_header in request,
# with the below header strings. 

my $use_header = 1;    # Set to 0 for no header, 1 to use header

# Only v1 supported for now, as it is the only one that exists.
my $hver              = "v1"; # Set to "v1" for version 1, etc.

my $AC_COMMON = "application/vnd.brreg.enhetsregisteret";
    
my $AC_HEADER_E       = "$AC_COMMON.enhet.$hver+json";
my $AC_HEADER_UE      = "$AC_COMMON.underenhet.$hver+json";
my $AC_HEADER_E_UPD   = "$AC_COMMON.oppdatering.enhet.$hver+json";
my $AC_HEADER_UE_UPD  = "$AC_COMMON.oppdatering.underenhet.$hver+json";

my @module_methods = qw /

    lookup_orgno
    lookup_orgname
    lookup_reg_dates
    lookup_update_dates

    orgno_ok

    status
    error
    warning

    data
    size
    total_size

    cur_page
    next_page
    prev_page
    total_page_count

    raw_json_decoded
   /;

# The new method and also the accessor methods
__PACKAGE__->mk_accessors( 
    @module_methods 
);


######## L o o k u p

sub _init_lookup {
    my ($self, $sok_underenheter, $sok_updates) = @_;
    
    my $ENHETER   = "enheter";
    my $AC_HEADER = $AC_HEADER_E;
    if ($sok_updates) {
	$AC_HEADER = $AC_HEADER_E_UPD;
    }
    if ($sok_underenheter) {
        $ENHETER   = "under" . $ENHETER;
	$AC_HEADER = $AC_HEADER_UE;
	if ($sok_updates) {
	    $AC_HEADER = $AC_HEADER_UE_UPD;
	}
    }
    return ($ENHETER, $AC_HEADER);

}

sub lookup_orgno {
    my ($self, $orgno, $sok_underenheter) = @_;

    unless ($orgno) {
        $self->status("mandatory parameter 'orgno' not specified");
        $self->error(1);
	return 0;
    }

    # validate the organizaton number
    unless ($self->orgno_ok($orgno)) {
	# errno has already been set
        return $self;
    }

    my ($ENHETER, $AC_HEADER) = $self->_init_lookup($sok_underenheter);
    
    ##
    # Use the orgno as key to brreg.
    # Match is only found if number does exist.
    $self->size(0);
    $self->_lookup_org_entries("$BRREG/$ENHETER/$orgno", $AC_HEADER);

}

sub lookup_orgname {
    my ($self, $orgname, $max_no_pages, $page_ix, $sok_underenheter) = @_;
    
    unless ($orgname) {
        $self->status("mandatory parameter 'orgname' not specified");
        $self->error(1);
	return 0;
    }

    my ($ENHETER, $AC_HEADER) = $self->_init_lookup($sok_underenheter);

    # Use the orgname as filter in search to brreg
    my $onm_e = uri_encode($orgname, {encode_reserved => 1});

    my $BR = "$BRREG/$ENHETER/?size=$MAX_SIZE&navn=$onm_e";

    $self->_fetch_pages($BR, $max_no_pages, $page_ix, $AC_HEADER);
}

sub lookup_reg_dates {
    my ($self, $from_date, $to_date, $max_no_pages, $page_ix, $sok_underenheter) = @_;
    
    unless ($from_date || $to_date) {
	$self->status("mandatory parameter 'from_date or to_date' not specified");
	$self->error(1);
	return 0;
    }

    my ($ENHETER, $AC_HEADER) = $self->_init_lookup($sok_underenheter);
    
    # Use the from / to dates as filter for lookup on 
    # registration dates
    my $rdateF = "fraRegistreringsdatoEnhetsregisteret";
    my $rdateT = "tilRegistreringsdatoEnhetsregisteret";

    my $dateFilter;

    if ($from_date && !$to_date) {
        $dateFilter = "$rdateF=$from_date";
    } elsif (!$from_date && $to_date) {
        $dateFilter = "$rdateT=$to_date";
    } else {
        $dateFilter = "$rdateF=$from_date&$rdateT=$to_date";
    }
    
    my $BR = "$BRREG/$ENHETER/?size=$MAX_SIZE&$dateFilter";
    
    $self->_fetch_pages($BR, $max_no_pages, $page_ix, $AC_HEADER);

}


sub lookup_update_dates {
    my ($self, $from_date, $update_id, $max_no_pages, $page_ix, $sok_underenheter) = @_;

    unless ($from_date || $update_id) {
	$self->status("mandatory parameter 'update from_date or update_id' not specified");
	$self->error(1);
	return 0;
    }

    my ($ENHETER, $AC_HEADER) = $self->_init_lookup($sok_underenheter, 1);

    # Use the from / to dates as filter for lookup on 
    # update date
    my $updFilter;
    my $midnight = "T00:00:00.000Z";
          
    if ($from_date && !$update_id) {
        $updFilter = "dato=$from_date$midnight";
    } elsif (!$from_date && $update_id) {
        $updFilter = "oppdateringsid=$update_id";
    } else {
        $updFilter = "dato=$from_date$midnight&oppdateringsid=$update_id";
    }
    
    my $BR = "$BRREG_UPD/$ENHETER/?size=$MAX_SIZE&$updFilter";
    
    $self->_fetch_pages($BR, $max_no_pages, $page_ix, $AC_HEADER);

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

sub _fetch_pages {
    my ($self, $BR, $max_no_pages, $page_ix, $accept_header) = @_;
	
    # Fetch the requested pages
    # First page is 0
    # Set size and total size so we get the first lookup

    my $max_pg_to_fetch = $max_no_pages || $MAX_PAGES;
    my $pg_ix           = $page_ix      || 0;

    my $pix   = $pg_ix;
    my $pcnt  = 1;
    my $bsize = -1;

    $self->size(0);  
    $self->total_size(1);
    $self->next_page(1); # force the first lookup

    while ($pcnt <= $max_pg_to_fetch && $bsize < $self->size && $self->size < $self->total_size) {
	# Remember size before next lookup. If size has not increased, stop the loop.
	$bsize = $self->size;

        $self->_lookup_org_entries("$BR&page=$pix", $accept_header);
        ++$pcnt;
	++$pix;
    }
}

sub _lookup_org_entries {
    my ($self, $URL, $accept_header) = @_;

    #print STDERR "URL: $URL\n";
    
    my $mech = WWW::Mechanize->new(
        timeout => $BRREG_TIMEOUT,
        autocheck => 0,
        );

    # Specify API version to use
    #https://data.brreg.no/enhetsregisteret/api/docs/index.html#_hvordan_velger_jeg_versjon
    if ($use_header) {
	$mech->add_header( Accept  => $accept_header);
	$mech->add_header( Charset => "UTF-8");
    }
        
    my $resp = $mech->get($URL);

    unless ($mech->success) {
        $self->status($resp->status_line);
        $self->error(1);
        $self->next_page(undef);
        return $self;
    }
	
    my $json;
    {
	local $@; # protect existing $@
	eval {
	    $json = decode_json($mech->content(format=>'text'));
	};
	if ($@) {
	    # Some error
	    $self->status("Invalid response");
	    $self->error(1);
	    $self->next_page(undef);
	    return $self;
	}
    }

    if ($json) {
        $self->raw_json_decoded($json);
        
        # Map the json data structure to 
        # internal entry objects
        my $eo = NOLookup::Brreg::Entry->new;
        my $entries = $eo->map_json_entries($json);

        #print STDERR "eo: ", Dumper $eo;

        # Collect any accumulated problems
        $self->status($eo->status) if ($eo->status);
        $self->warning($eo->warning) if ($eo->warning);
        $self->error($eo->error) if ($eo->error);

        # Save the found data
        if (@$entries) {
            push @{$self->{data}}, @$entries;

            $self->size($self->size + scalar @$entries);
	    $self->total_size($eo->total_result_count);  

	    $self->total_page_count($eo->total_page_count);

	    $self->cur_page($eo->cur_page);
	    $self->next_page($eo->next_page);
	    $self->prev_page($eo->prev_page);
	}
    }

    #print STDERR Dumper $self;
    
    return $self;
}

=pod

=encoding ISO-8859-1

=head1 NAME

NOLookup::Brreg::DataLookup - Lookup Brreg basic organization data from
the JSON formatted service offered by the Brreg data API via
https://data.brreg.no/enhetsregisteret/oppslag/enheter
https://data.brreg.no/enhetsregisteret/api/docs/index.html

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

=head3 _init_lookup

Common init method.

- Set seach URLs.
- Returns URL and accept header.

    
=head3 lookup_orgno()

Lookup based on a complete organization number.

Returns an array of one single NOLookup::Brreg::Entry object in the data 
when a match is found.

=head3 lookup_orgname()

Lookup based on a complete or part of an organization name.

Returns 0 entries if none found.

Returns an array of NOLookup::Brreg::Entry objects in the data 
when matches are found.

A maximum of $max_no_pages pages are fetched, each of 100 entries.

=head3 lookup_reg_dates()

Lookup based on registration dates.
A from_date and/or a to_date can be specified.

The lookup will find registrations performed after midnight starting
the from date, and until midnight at the end of the to date.

Returns 0 entries if none found.

Returns an array of NOLookup::Brreg::Entry objects in the data 
when matches are found.

A maximum of $max_no_pages pages are fetched, each of 100 entries.


=head3 lookup_update_dates()

Lookup based on update date and update id.

The lookup will find updated organizations performed after midnight
starting on the from date. The minimum update id can also be set.

Returns 0 entries if none found.

Returns an array of NOLookup::Brreg::Entry objects in the data 
when matches are found.

A maximum of $max_no_pages pages are fetched, each of 100 entries.


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

The found data, an array of NOLookup::Brreg::Entry data objects.

See doc. for NOLookup::Brreg::Entry for details.

=head3 size()

The number of objects found in a page lookup

=head3 total_size()

The total number of objects found by the search.

Only set if all data has been fetched.

Only if total_size is set, the user can assume that all data has been
fetched.

=head3 cur_page()/prev_page()/next_page()

If more pages can be fetched, those methods give the URL to that page

=head3 total_page_count()

Count of total nuber of pages matching the search

=head3 result_count()

Count of total results for the search


=head1 SUPPORT

For now, support questions should be sent to:

E<lt>(nospam)info(at)norid.noE<gt>

Please also see the README file in the distribution.

=head1 SEE ALSO

https://www.brreg.no
https://data.brreg.no/enhetsregisteret/oppslag/enheter

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

=head1 TODO

Perhaps add an address object to contain the address info.

=cut
    
1;
