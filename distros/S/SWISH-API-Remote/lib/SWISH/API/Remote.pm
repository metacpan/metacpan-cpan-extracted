package SWISH::API::Remote;
use SWISH::API::Remote::Results;
use SWISH::API::Remote::Result;
use SWISH::API::Remote::Header;
use SWISH::API::Remote::MetaName;
use SWISH::API::Remote::FunctionGenerator;

use strict;
use warnings;
use Data::Dumper;

use fields qw( uri index debug timeout );
use URI::Escape; # for uri_(un)escape
use LWP::UserAgent;

our $VERSION = '0.10'; 	# this is the version strings

use constant DEFAULT_PROPERTIES => "swishrank,swishdocpath,swishtitle,swishdocsize";

############################################
# new( $proto, $uri, $index, $opts_hash)
# returns a newly created SWISH::API::Remote object, which
# is modelled on SWISH::API::Remote
sub new {
	my ($proto, $uri, $index, $opts_hash) = @_;
	$opts_hash = {} unless defined($opts_hash);
	my $class = ref($proto) || $proto;
	my $self  = {};
	bless ($self, $class);
	my %opts = %$opts_hash;	# make a copy, which we delete keys from
	$self->{uri} = $uri;
	$self->{index} = $index || "DEFAULT";
	$self->{debug} = $opts{DEBUG} || 0;
	delete ($opts{DEBUG});
	$self->{timeout} = $opts{TIMEOUT} || 3;
	delete ($opts{TIMEOUT});
	# any keys left in %opts are not understood.
	if (keys %opts) {
		die "0: Don't understand options: " . join(", ", keys( %opts )) . "\n";
	}
	return $self;
} 

############################################
# $remote->IndexNames()
#  to match SWISH::API::IndexNames
# returns list of index names
#  we already know the indexnames, so we just return them. Note they're not
# filenames, they're index names like "DEFAULT" 
# PLEASE NOTE THAT ALTHOUGH THIS RETURNS A LIST, WE CURRENTLY ONLY SUPPORT ONE INDEX <=> ONE INDEXFILE
sub IndexNames {	
	my $self = shift;
	return ($self->{index});	# list of one element, for now we don't allow searching on multiple
								# indexes (SWISHED might map 'DEFAULT' to two indexes, but the client won't 									# know that.)
}

############################################
# $remote->MetaList( $index_name )
# to match SWISH::API::MetaList
# returns a list of hashes of (Name=>name, ID=>idnum; Type->type)
# requires round-trip to SWISHED as implemented
sub MetaList {
	my ($self, $index_name) = @_;
	my $uri = $self->{uri} . "?f=" . $self->{index} . "&M=1";
	my $content = $self->_Fetch_Url( $uri );
	my($results, $headers, $props, $metas) = $self->_ParseContent( $content );
	return @$metas;
}
############################################
# to match SWISH::API::PropertyList( $index_name )
# returns a list of hashes of (Name=>name; ID=>idnum; Type->type)
# requires round-trip to SWISHED as implemented
sub PropertyList {
	my ($self, $index_name) = @_;
	my $uri = $self->{uri} . "?f=" . $self->{index} . "&P=1";
	my $content = $self->_Fetch_Url( $uri );
	my($results, $headers, $props, $metas) = $self->_ParseContent( $content );
	return @$props;
}

############################################
# THERE IS NO CORRESPONDING SWISH::API::HeaderList( $index_name )
# returns a list of hashes of (Name=>name; Value=>value)
# requires round-trip to SWISHED as implemented
sub HeaderList {
	my ($self, $index_name) = @_;
	my $uri = $self->{uri} . "?f=" . $self->{index} . "&h=1";
	my $content = $self->_Fetch_Url( $uri );
	my($results, $headers, $props, $metas) = $self->_ParseContent( $content );
	return @$headers;
}

############################################
# $remote->Execute( $query )
# to match SWISH::API::Execute
# requires round-trip to SWISHED
# each qs 'name' is based on the swish-e exe's corresponding command line flag
sub Execute {
	my $self = shift;
	my $query = shift || "";
	my $searchopts = shift || {};
	my $uri = $self->{uri} . "?f=" . $self->{index};
	if (defined($query)) {				# like -w
		$uri .= "&w=" . uri_escape($query);
	}	
    if (exists($searchopts->{HEADERS})  && $searchopts->{HEADERS}) { 	# new HEADERS option
        $uri .= "&h=1";
	}
	if (exists($searchopts->{PROPERTIES}) && $searchopts->{PROPERTIES}) {
		$uri .= "&p=" . uri_escape($searchopts->{PROPERTIES});
	} else {
		$uri .= "&p=" . DEFAULT_PROPERTIES;
	}
	if (exists($searchopts->{BEGIN})) {
		$uri .= "&b=" . uri_escape($searchopts->{BEGIN});
	}
	if (exists($searchopts->{MAX})) {
		$uri .= "&m=" . uri_escape($searchopts->{MAX});
	}
	my $content = $self->_Fetch_Url( $uri );	# fetch the content from the SWISHED server
	my($results, $headers, $props, $metas) = $self->_ParseContent( $content );
		# if we parsed this line-by-line, we could start showing things faster
	return $results;	# we don't expect any props or metas back
}

############################################ 
# $self->_Fetch_Url( $uri )
# returns the $content; prints an e: line if there's an error.
# intended to be private. 
sub _Fetch_Url {
	my ($self, $uri) = @_;
	print "Fetching $uri\n" if ($self->{debug});

	my $ua = LWP::UserAgent->new;
	$ua->timeout( $self->{timeout} );	
	print "Setting timeout to $self->{timeout}\n" if $self->{debug};
	#$ua->env_proxy; 
	my $response = $ua->get( $uri );
	my $content = "";
	if ($response->is_success) {
		$content = $response->content;
		print "Got: $content\n" if $self->{debug};
	} else {
		$content = "e: Couldn't connect: " . $response->status_line . "\n";
		print "Error: Couldn't connect.\n" if $self->{debug};
	}  	
	return $content;
}

############################################################################################
# if we parsed this line-by-line, we could start showing things faster
# (though it wouldn't necessarily be faster overall)
# intended to be private. Parses the returned content into members
# returns ($results, $headers, $props, $metas)
sub _ParseContent { 	
	my ($self, $content) = @_;
	#warn "Got content $content\n\n";
	my @results = ();
	my @resultprops = ();
	my $results = SWISH::API::Remote::Results->new();
	my @indexheaders;
	my @indexmetas;
	my @indexprops;
	#my @lines = split(/\n/, $content);
	#for my $line (@lines) {
	for my $line (split(/\n/, $content)) {
        # this is kind of ugly. We should remove the L: part at the same time, but we do.
		next unless $line;
		if ($line =~ s/^k:\s*//) {	  # the 'key'
			@resultprops = map { (split(/=/, $_))[1] } (split (/&/, $line));
			#print Data::Dumper::Dumper(\@resultprops);
		}
		elsif ($line =~ s/^r:\s*//) {
			my $result = SWISH::API::Remote::Result::New_From_Query_String( $line, \@resultprops );
			$results->AddResult($result);
		} 
		elsif ($line =~ s/^e:\s*//) {
			$results->AddError($line);
			print "Added error: $line\n" if $self->{debug};
		} 
		elsif ($line =~ s/^d:\s*//) {
			$results->AddDebug($line);	# add the 'debug' line returned from the server
			print "Added debug: $line\n" if $self->{debug};
		} 
		elsif ($line =~ s/^h:\s*//) {
			#print "PARSING: h: $line\n" if $self->{debug};
			@indexheaders = SWISH::API::Remote::Header::Parse_Headers_From_Query_String( $line );
			#print "GOT HEADERS: " . Dumper( \@indexheaders ) if ($self->{debug});
		}
		elsif ($line =~ s/^M:\s*//) {
			#print "PARSING: M: $line\n";
			@indexmetas = SWISH::API::Remote::MetaName::Parse_MetaNames_From_Query_String( $line );
			#print "GOT METAS: " . Dumper( \@indexmetas ) if $self->{debug};
		}
		elsif ($line =~ s/^P:\s*//) {
			#print "PARSING: p: $line\n" if $self->{debug};
			@indexprops = SWISH::API::Remote::MetaName::Parse_MetaNames_From_Query_String( $line );
			#print "GOT PROPS: " . Dumper( \@indexprops ) if $self->{debug};
		}
		elsif ($line =~ s/^m:\s*.*hits=(\d+)//) {	
			# TODO: in the future we'll probably parse more from this Meta line
			# for example, As of swished 0.09, there is also a swished_version
			# like "0.09" (or "0.09n" if dev version) passed back too
			$results->Hits($1);
        } else {
			# don't know what to do with this line. TODO: error?
			$results->AddError( "Don't know what to do with line: $line" );
		}
		
	} 
	return ($results, \@indexheaders, \@indexprops, \@indexmetas);
} 
############################################
## make uri and index accessors
SWISH::API::Remote::FunctionGenerator::makeaccessors(
	__PACKAGE__, qw ( uri index )
);


1;
__END__

=head1 NAME

SWISH::API::Remote - Perl module to perform searches on a swished daemon server

=head1 SYNOPSIS

	use SWISH::API::Remote;
	my $index = "DEFAULT";	# use the default index
	my %options = ( TIMEOUT => 4, DEBUG => 0 );
	my $sw = SWISH::API::Remote->new( 'http://localhost/swished', $index, \%options);
		# params to SWISH::API::Remote::new are URL, INDEXNAME, and OPTIONSHASHREF
		# set the url to your swished server!
	my $w = "foo OR bar";	# your search here
	my $results = $sw->Execute( $w );	
	printf("Fetched %d of %d hits for search on '%s'\n",
		$results->Fetched(), $results->Hits(), $w);
	while ( my $r = $results->NextResult() ) {	# loop over results and show properties
		print join(" ", map { $r->Property($_) } ($r->Properties()) ) . "\n";
	}
	if ($results->Error()) {
		die $results->ErrorString();
	}

=head1 DESCRIPTION

Performs searches on a remote swished server using an interface similar to SWISH::API

=over 4

=item my $remote = SWISH::API::Remote->new( "http://yourserv.com/swished", ["INDEX", \%remote_options]);

Creates a SWISH::API::Remote object. The first parameter is the url of the swished server,
(which gets appended with '?' and an appropriate query string). 
If not passed, INDEX is set to DEFAULT. If remote_options are used, 
$options{DEBUG} and $options{TIMEOUT} (which is used as the timeout
for the swishedserver and defaults to 3 seconds) are the only recognized keys of %options so far.

=item my $results = $remote->Execute( $search, \%search_options);

Performs a search using SWISH::API::Remote and returns a SWISH::API::Results
object. Recognized search_options are:
	MAX:        the maximum number of hits to fetch (default 10)
	BEGIN:      which hit to start at               (default  0)
	PROPERTIES: comma delimited list of properties to fetch           
				(default "swishrank,swishdocpath,swishtitle,swishdocsize")
    HEADERS:    return all index headers            (default  0)
    CHARS:      return character information        (default  0)
    META:       return Metadata from index          (default  0) 

=back

=head1 SEE ALSO

L<SWISH::API::Remote::Results>, L<SWISH::API::Remote::Result>

=head1 AUTHOR

Josh Rabinowitz, E<lt>joshr@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2006 by Josh Rabinowitz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
