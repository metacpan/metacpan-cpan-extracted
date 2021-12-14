
package NOLookup::Patent::DataLookup;

use warnings;
use strict;
use base qw(Class::Accessor::Chained); ## Provides a new() method
use POSIX qw(locale_h);
use NOLookup::Patent::Entry;
use WWW::Mechanize;
use JSON;
use URI::Encode qw(uri_encode);
use Data::Dumper;
$Data::Dumper::Indent=1;

my $PATENT_TIMEOUT = 60; # secs (default is 180 secs but we want shorter time).

# Free text search gives too many hits, so use the trademark-text-search
my $PATENT_SEARCH = "http://ws.patentstyret.no/search/json/reply/search/trademark/?trademarktext";
my $PATENT_ID     = "http://ws.patentstyret.no/search/json/reply/DetailedInfoRequest/trademark/detailedinfo/?ApplicationNumber";

my @module_methods = qw /

    lookup_tm_text
    lookup_tm_applid

    status
    error
    warning

    data
    size
    total_size

    raw_json_decoded
   /;

# The new method and also the accessor methods
__PACKAGE__->mk_accessors( 
    @module_methods 
);

######## L o o k u p

sub lookup_tm_text {
    my ($self, $tm_text, $max_no_pages, $page_ix) = @_;

    die "mandatory parameter 'tm_text' not specified" unless ($tm_text);

    my $max_pg_to_fetch = $max_no_pages   || 10;
    my $pg_ix           = $page_ix        || 1;

    # Use a fixed 100 on number of elements on page, to be consistent
    # with brreg_difi API, which does not support setting of this
    # parameter.
    my $max_pg_elems = 100;
    
    my $tmt_e = uri_encode($tm_text, {encode_reserved => 1});

    # set size and total size so we get the first lookup
    $self->size(0);
    $self->total_size(1);
    my $bsize = -1;
 
    # Fetch the requested pages
    my $pix  = $pg_ix;
    my $pcnt = 1;
    
    while ($pcnt <= $max_pg_to_fetch && $bsize < $self->size && $self->size < $self->total_size) {
	#print STDERR "Patent page count is: $pcnt of $max_pg_to_fetch, fetching page $pix...\n";

	# Remember size before next lookup. If size has not increased, stop the loop.
	$bsize = $self->size;

	#print STDERR ("$PATENT_SEARCH=$tmt_e&page=$pix&MaximumSearchResults=$max_pg_elems\n");
	$self->_lookup_tm_entries("$PATENT_SEARCH=$tmt_e&page=$pix&MaximumSearchResults=$max_pg_elems");
	++$pcnt;
	++$pix;
    }
}

sub lookup_tm_applid {
    my ($self, $applid) = @_;

    $self->_lookup_tm_entries(uri_encode("$PATENT_ID=$applid"));
    
}

#####
# The lookup itself, internal method only.

sub _lookup_tm_entries {
    my ($self, $URL) = @_;

    #print STDERR "URL: $URL\n";
    
    my $mech = WWW::Mechanize->new(
        timeout => $PATENT_TIMEOUT,
        autocheck => 0
	);
    
    my $resp = $mech->get($URL);

    unless ($mech->success) {
	$self->status($resp->status_line);
	$self->error(1);
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
	my $eo = NOLookup::Patent::Entry->new;
	my $entries = $eo->map_json_entries($json);

	# Collect any accumulated problems
	$self->status($eo->status) if ($eo->status);
	$self->warning($eo->warning) if ($eo->warning);
	$self->error($eo->error) if ($eo->error);

	# Save the found data
	if (@$entries) {
	    push @{$self->{data}}, @$entries;
	    $self->size($self->size + $eo->result_count);
	    $self->total_size($eo->total_result_count);
	}
    }
    return $self;
}

=pod

=encoding ISO-8859-1

=head1 NAME

NOLookup::Patent::DataLookup - Lookup Patentstyret trademark data from the JSON
formatted service offered by the JSON API.

=head1 DESCRIPTION

Use WWW::Mechanize and JSON to lookup data from the JSON API.
Use NOLookup::Patent::Entry module to map the resulting json data structure
to a NOLookup::Patent::Entry objects.

The timeout period $PATENT_TIMEOUT is used to 
trap and return the call if lookup is hanging for some reason.

=head1 METHODS

The module provides the below methods.

=head3 lookup_tm_text()

Lookup based on a complete or part of a trademark text.

Mandatory parameters are:
   $tm_text: the trademark text (or part of) to search for

Optional parameters are:
   $max_no_pages: max. number of pages to return, default 10.
   $page_ix     : index to the first page to fetch, default 1.

Returns 0 entries if none found.

Returns an array of NOLookup::Patent::Entry objects in the data 
when matches are found.

=head3 lookup_applid()

Lookup based on an application id.

Returns 0 entries if none found, or some error.

Returns an array of on single NOLookup::Patent::Entry object in the data
when matches are found.

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

Found data, an array of NOLookup::Patent::Entry data objects.

See doc. for C<NOLookup::Patent::Entry> for details.

=head3 size()

The number of objects in data().

=head3 total_size()

The total number of matches for the search.  So, if size() is less
than total_size(), there is more data which is not fetched.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>(nospam)info(at)norid.noE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

C<NOLookup::Patent::Entry>
L<http://www.patentstyret.no>
L<http://ws.patentstyret.no/search>
L<https://dbsearch2.patentstyret.no/AdvancedSearch.aspx?Category=Mark>

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
