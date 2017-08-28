package NOLookup::BrregDifi::DataLookup;

use warnings;
use strict;
use base qw(Class::Accessor::Chained); ## Provides a new() method
use POSIX qw(locale_h);
use NOLookup::BrregDifi::Entry;
use WWW::Mechanize;
use JSON;
use URI::Encode qw(uri_encode);
use Data::Dumper;
$Data::Dumper::Indent=1;

my $BRREG_TIMEOUT = 60; # secs (default is 180 secs but we want shorter time).

# The query can be a name, or an orgnumber.
# In both cases an array of 0..n data elements are returned,
# each containing the same data.
my $BRREG         = "http://hotell.difi.no/api/json/brreg/enhetsregisteret";
my $BRREG_ORGNAME = "$BRREG?query";
my $BRREG_ORGNO   = "$BRREG?orgnr";
    
my @module_methods = qw /

    lookup_orgno
    lookup_orgname
    orgno_ok

    status
    error
    warning

    data
    size
    total_size

    total_page_count
    cur_page
    next_page
    prev_page

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
    $self->size(0);
    $self->_lookup_org_entries("$BRREG_ORGNO=$orgno");
}

sub lookup_orgname {
    my ($self, $orgname, $max_no_pages, $page_ix) = @_;
    
    die "mandatory parameter 'orgname' not specified" unless ($orgname);

    my $max_pg_to_fetch = $max_no_pages   || 10;
    my $pg_ix           = $page_ix        || 1;
    
    # Use the orgname as filter in search to brreg
    my $on_e = uri_encode($orgname, {encode_reserved => 1});

    # set size and total size so we get the first lookup
    $self->size(0);
    $self->total_size(1);
    my $bsize = -1;

    # Fetch the requested pages
    my $pix  = $pg_ix;
    my $pcnt = 1;

    while ($pcnt <= $max_pg_to_fetch && $bsize < $self->size && $self->size < $self->total_size) {
	#print STDERR " size: ", $self->size, "\n";
	#print STDERR "tsize: ", $self->total_size, "\n";
	#print STDERR "Page count is: $pcnt, fetching page $pix...\n";
	#print STDERR "$BRREG_ORGNAME=$on_e&page=$pix\n";

	# Remember size before next lookup. If size has not increased, stop the loop.
	$bsize = $self->size;

	$self->_lookup_org_entries("$BRREG_ORGNAME=$on_e&page=$pix");
	++$pcnt;
	++$pix;
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

	#print STDERR "ERR mech: ", Dumper $self;
	
	return $self;
    }

    my $json = decode_json($mech->text);

    if ($json) {
	$self->raw_json_decoded($json);
	
	# Map the json data structure to 
	# internal entry objects
	my $eo = NOLookup::BrregDifi::Entry->new;
	my $entries = $eo->map_json_entries($json);

	# Collect any accumulated problems
	$self->status($eo->status) if ($eo->status);
	$self->warning($eo->warning) if ($eo->warning);
	$self->error($eo->error) if ($eo->error);

	# Save the found data
	if (@$entries) {
	    push @{$self->{data}}, @$entries;

	    $self->size( $self->size + scalar @$entries);
	    $self->total_size($eo->total_result_count);  

	    $self->total_page_count($eo->total_page_count);  

	    $self->cur_page($eo->cur_page);
	    $self->next_page($eo->next_page);
	    $self->prev_page($eo->prev_page);
	}
    }
    return $self;
}

=pod

=encoding ISO-8859-1

=head1 NAME

NOLookup::BrregDifi::DataLookup - Lookup Brreg basic organization data from the JSON
formatted service offered by the Difi Brreg data API via
"http://hotell.difi.no/api/json/brreg/enhetsregisteret?query";

(Brreg is a short name for 'BrE<0xF8>nnE<0xF8>ysundregistrene, the Norwegian Central Organization Registry).

=head1 DESCRIPTION

Use WWW::Mechanize and JSON to lookup data from the JSON API at brreg.
Use NOLookup::BrregDifi::Entry module to map the resulting json data structure
to a NOLookup::BrregDifi::Entry objects.

The timeout period $BRREG_TIMEOUT is used to 
trap and return the call if Brreg lookup is hanging for some reason.

=head1 METHODS

The module provides the below methods.

=head3 lookup_orgno()

Lookup based on a complete organization number.

Returns an array of one single NOLookup::Brreg::Entry object in the data 
when a match is found.

=head3 lookup_orgname()

Lookup based on a complete or part of an organization name.

Mandatory parameters are:
   $orgname: the orgname (or part of) to search for

Optional parameters are:
   $max_no_pages: max. number of pages to return, default 10.
   $page_ix     : index to the first page to fetch, default 1.

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

Found data, an array of NOLookup::BrregDifi::Entry data objects.

See doc. for NOLookup::BrregDifi::Entry for details.

=head3 size()

The number of objects in data().

=head3 total_size()

The total number of objects in data[].

Only set if all data has been fetched.

Only if total_size is set, the user can assume
that all data has been fetched.

=head3 total_page_count()

The total number of pages that the query produces.
Only if all pages are fetched, you have it all.

=head3 cur_page()

The current page number.

=head3 next_page()

The next page number, if more exists.

=head3 prev_page()

The previous page number, unless you are on the first page.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>(nospam)info(at)norid.noE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://hotell.difi.no/?dataset=brreg/enhetsregisteret

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
