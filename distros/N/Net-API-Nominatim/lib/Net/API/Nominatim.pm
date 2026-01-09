package Net::API::Nominatim;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.03';

## NOTE: both url/socket need to have the query string
## url-encoded (percent format, e.g. %C3) if unicode.

use Encode;
use URI::Escape;
use Mojo::Log;
use File::Basename;
use LWP::UserAgent;
use HTTP::CookieJar::LWP;
use HTTP::Cookies;
use HTTP::Request;
use IO::Socket::UNIX qw/SOCK_STREAM SOMAXCONN/;
use Hash::Merge;
use Cookies::Roundtrip qw/lwpuseragent_load_cookies/;
use Storable qw/dclone/;
use Data::Roundtrip qw/perl2dump json2perl no-unicode-escape-permanently/;

use Net::API::Nominatim::Model::Address;

my $__DEFAULT_USERAGENT_STRING = 'Net::API::Nominatim Perl Client v'.$VERSION.' by bliako@cpan.org (thank you OSM)';

sub	new {
	my $class = $_[0];
	my $params = $_[1] // {};
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# we are deleting items from user-specified params HASH_REF
	# we must clone it BUT there is a problem with objects (e.g. the logger)
	# we do not want to clone them but Clone::clone creates new objects
	# and Storable::dclone complains, so fo.
	#my $params = Storable::dclone($_params);

	my $self = {
	  '_private' => {
		  'log' => {
			'logger-object' => undef,
		  },
		  'lwpuseragent' => {
			'lwpuseragent-object' => undef,
			'cookies-object' => undef,
		  },
	  },
	  'options' => {
		'server' => {
			# we need one of 'url' or 'unix-socket'
			# on init a 'method' will be created holding 'url' or 'unix-socket'
			# do not set any
			#'url' => 'https://nominatim.openstreetmap.org',
			# fullpath to local unix socket:
			#'unix-socket' => 'unix-socket-path', # let the user set it
		},
		'lwpuseragent' => {
			'cookies-filename' => undef,
			# Nominatim's terms of usage requires a unique UA string to identify the client:
			# we also force this if the user specifies a ready-made UA object
			# sorry, I hate to interfere on user-specified objects
			'useragent-string' => $__DEFAULT_USERAGENT_STRING,
		},
		'debug' => {
			'verbosity' => 1,
			'cleanup' => 0,
		},
		'log' => {
			'logger-file' => undef,
		},
	  }
	};
	bless $self => $class;

	if( exists($params->{'verbosity'}) && defined($params->{'verbosity'}) ){
		$self->{'options'}->{'verbosity'} = $params->{'verbosity'}
	}
	my $verbosity = $self->verbosity();

	# WARNING: we are deleting items from user-supplie $params here, so we clone it

	# do we have a logger specified in params?
	if( exists($params->{'log'}->{'logger-file'}) && defined($params->{'log'}->{'logger-file'}) ){
		my $adir = File::Basename::dirname($params->{'log'}->{'logger-file'});
		if( ! -d $adir ){ make_path($adir); if( ! -d $adir ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, logfile directory '$adir' is not a dir or failed to be created.\n"; return undef } }
		$self->{'_private'}->{'log'}->{'logger-object'} = Mojo::Log->new(path => $params->{'log'}->{'logger-file'});
		delete $params->{'log'}->{'logger-file'};
	} elsif( exists($params->{'log'}->{'logger-object'}) && defined($params->{'log'}->{'logger-object'}) ){
		$self->{'_private'}->{'log'}->{'logger-object'} = $params->{'log'}->{'logger-object'};
		delete $params->{'log'}->{'logger-object'};
	} elsif( exists($self->{'options'}->{'log'}) && exists($self->{'options'}->{'logger-file'}) && defined($self->{'options'}->{'logger-file'}) ){
		my $adir = File::Basename::dirname($self->{'options'}->{'logger-file'});
		if( ! -d $adir ){ make_path($adir); if( ! -d $adir ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, logfile directory '$adir' is not a dir or failed to be created.\n"; return undef } }
		$self->{'_private'}->{'log'}->{'logger-object'} = Mojo::Log->new(path => $self->{'options'}->{'logger-file'});
		delete $self->{'options'}->{'log'};
	} else { $self->{'_private'}->{'log'}->{'logger-object'} = Mojo::Log->new() }

	# Now we have a logger
	my $log = $self->log();

	# any objects in params must be migrated now!
	if( exists($params->{'lwpuseragent'}->{'cookies-object'}) && defined($params->{'lwpuseragent'}->{'cookies-object'}) ){
		# NOTE: the cookiejar we pass will be cloned and will not have the same pointer
		$self->{'_private'}->{'lwpuseragent'}->{'cookies-object'} = $params->{'lwpuseragent'}->{'cookies-object'};
	}
	if( exists($params->{'lwpuseragent'}->{'lwpuseragent-object'}) && defined($params->{'lwpuseragent'}->{'lwpuseragent-object'}) ){
		$self->{'_private'}->{'lwpuseragent'}->{'lwpuseragent-object'} = $params->{'lwpuseragent'}->{'lwpuseragent-object'};
	}

	# and add more user-specified params into our self
	# right is our params, left the options
	my $hm = Hash::Merge->new('RIGHT_PRECEDENT');
	$hm->add_behavior_spec({
		'SCALAR' => {
		# left is scalar (above), right is one of these, what to do?:
		# we are only interested in SCALAR/SCALAR, ie left+right
		# can not be different types
		'SCALAR' => sub { defined($_[1]) ? $_[1] : $_[0] },
			'ARRAY'  => sub { if( defined($_[1]) ){  perl2dump($_[0])." and right: ".perl2dump($_[1])."unexpected type SCALAR/ARRAY" } else { $_[0] = $_[1] } },
			'HASH'   => sub { if( defined($_[1]) ){  perl2dump($_[0])." and right: ".perl2dump($_[1])."unexpected type SCALAR/HASH" } else { $_[0] = $_[1] } },
		},
		'ARRAY' => {
		# left is array (above), right is one of these, what to do?:
			'SCALAR' => sub { if( defined($_[1]) ){  perl2dump($_[0])." and right: ".perl2dump($_[1])."unexpected type ARRAY/SCALAR" } else { $_[0] = $_[1] } },
			'ARRAY'  => sub { [ defined($_[1]) ? @{ $_[1] } : @{ $_[0] } ] },
			'HASH'   => sub { if( defined($_[1]) ){  perl2dump($_[0])." and right: ".perl2dump($_[1])."unexpected type ARRAY/HASH" } else { $_[0] = $_[1] } },
		},
		'HASH' => {
		# left is hash (above), right is one of these, what to do?:
			'SCALAR' => sub { if( defined($_[1]) ){  perl2dump($_[0])." and right: ".perl2dump($_[1])."unexpected type HASH/SCALAR" } else { $_[0] = $_[1] } },
			'ARRAY'  => sub { if( defined($_[1]) ){  perl2dump($_[0])." and right: ".perl2dump($_[1])."unexpected type HASH/ARRAY" } else { $_[0] = $_[1] } },
			'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
		},
	}, 'My Behavior');
	for my $k (sort keys %{ $self->{'options'} }){
		next unless exists $params->{$k};
		if( ! defined($self->{'options'}->{$k} = $hm->merge(
			$self->{'options'}->{$k},
			$params->{$k},
		)) ){ $log->error("${whoami} (via ${parent}), line ".__LINE__." : error, call to ".'hm->merge()'." has failed for parameter '$k'."); return undef }
	}

	# do some sanity checks and deduce the method we access the service:
	# it will add a 'method' key under 'options'->'server' to be either
	# 'url' or 'unix-socket'.
	my $s;
	if( ! exists($self->{'options'}->{'server'}) || ! defined($s=$self->{'options'}->{'server'}) || (ref($self->{'options'}->{'server'})ne'HASH') ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, parameter 'options'->'server' is missing from the constructor parameters or it is not a HASH_REF."); return undef }
	for ('url', 'unix-socket'){
		if( exists($s->{$_}) && defined($s->{$_}) ){ $s->{'method'} = $_; last }
	}
	if( ! exists $s->{'method'} ){ $log->error(perl2dump($s)."${whoami} (via ${parent}), line ".__LINE__." : error, expected parameter under key 'server' must be 'url' (for HTTP/GET server access) or 'unix-socket' for local UNIX socket access but none was specified. See above."); return undef }

	if( $self->_init_lwpuseragent() != 0 ){ $log->error("${whoami} (via ${parent}), line ".__LINE__." : error, call to ".'_init_lwpuseragent()'." has failed."); return undef }
	# now we have lwp useragent set up and with cookies

	return $self;
}

# Do a Nominatim FORWARD search (specify address, get coordinates),
# with the user-specified 'search-method'
# (set via the constructor parameters during construction)
# The input parameters:
#   * $query_string : the q= of the freeform search, optional if $query_params contains a structured query
#   * $query_params : optionally specify other query params, like 'limit', 'format'
#                     and ALSO a structured query in case you do not specify a free-form $query_string.
#   * other params :
#         want-json : 1 or 0, if 1 it will return the raw JSON string received from nominatim
#                     and not process it to build Address objects.
#                     Otherwise it will return an array of Address objects.
# It returns raw JSON string or an array of
# Net::API::Nominatim::Model::Address objects, even if empty, for no results
# or undef on failure.
sub	search {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $VERBOSITY = $self->verbosity();
	my $log = $self->log;

	# any other params to the query other than lat,lon,
	# e.g. output format etc.
	my $query_params = (exists($params->{'query-params'}) && defined($params->{'query-params'})) ? $params->{'query-params'} : {};

	# the free-form query string to search, it can be any part of an address
	my $query_string = (exists($params->{'q'}) && defined($params->{'q'}))
		? {q=>$params->{'q'}} : undef
	;
	# alternatively do a structured query by specifying any/all of those:
	# NOTE: nominatim API says not to mix 'q' above with these below
	# should we check it?
	if( ! defined $query_string ){
		$query_string = {};
		for my $k (qw/amenity street city county state country postalcode/){
			if( exists($params->{$k}) && defined($params->{$k}) ){ $query_string->{$k} = $params->{$k} }
		}
	} else {
		# check if we have mixed 'q' and others from structured query
		# and complain
		for my $k (qw/amenity street city county state country postalcode/){
			if( exists($params->{$k}) && defined($params->{$k}) ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, free-form query (with parameter 'q') must not be mixed with structured query (any of these parameters: 'amenity street city county state country postalcode'). Use free-form or structured query but do not mix them."); return undef }
		}
	}
	if( ! defined($query_string) || (scalar(keys %$query_string)==0) ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, parameter 'q' is missing (for a free-form query) or any of 'amenity street city county state country postalcode' is missing for a structured query. You must either specify parameter 'q' or one or more search fields from the other group."); return undef }

	# we can return back an array of Addresses but also
	# we can return the raw JSON received from nominatim
	# and avoid all the processing.
	my $wantJSON = (exists($params->{'want-json'}) && defined($params->{'want-json'})) ? $params->{'want-json'} : 0;

	my ($request_string, $content);
	my $qs = '/search?';
	for my $k (keys %$query_string){
		$qs .= $k.'='.uri_escape_utf8($query_string->{$k}).'&';
	}
	for my $qk (sort keys %{ $query_params }){
		my $qv;
		if( defined($qv=$query_params->{$qk}) ){ $qs .= $qk.'='.$qv.'&' }
	}
	$qs =~ s/&$//;

	if( $self->method eq 'url' ){
	  $request_string = $self->{'options'}->{'server'}->{'url'} . $qs;
	  my $request = HTTP::Request->new(
		'GET' => $request_string,
		  [
			'Accept' => 'application/json',
			'Accept-Encoding' => 'gzip',
		  ]
	  );
	  if( ! defined $request ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, failed to create 'HTTP::Request' for url '$request_string'."); return undef }
	  if( $VERBOSITY > 0 ){ $log->info("${request_string}\n\n${whoami}, line ".__LINE__." (via $parent) : GETting above url ..."); }
	  my $response = $self->lwpuseragent->request($request);
	  if( ! defined $response ){ $log->error($request->as_string."\n${whoami}, line ".__LINE__." (via $parent) : error, failed to GET above request."); return undef }
	  if( ! $response->is_success ){ $log->error($request->as_string."\n${whoami}, line ".__LINE__." (via $parent) : error, failed to GET above request because result was not success, code was '".$response->code."' : ".$response->status_line.""); return undef }
	  $content = $response->decoded_content;
	  if( ! defined $content ){ $log->error($request->as_string."\n${whoami}, line ".__LINE__." (via $parent) : error, GET above request was successful but decoded_content is undef."); return undef }
	  $content = Encode::decode_utf8($content);
	  # some massage of the received content:
	  $content =~ s/\s+$//sm;
	####################

	} elsif( $self->method eq 'unix-socket' ){

	####################
	  if( $VERBOSITY > 0 ){ $log->info("${qs}\n\n${whoami}, line ".__LINE__." (via $parent) : uri_escape'd the query string as unicode, assuming it wasn't (and it shouldn't), as above.") }
	  
	  my $sockpath = (exists($self->{'options'}->{'server'}->{'unix-socket'}) && defined($self->{'options'}->{'server'}->{'unix-socket'})) ? $self->{'options'}->{'server'}->{'unix-socket'} : undef;
	  if( ! defined $sockpath ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, the parameter 'server'->'unix-socket' is missing, this is the full path to the unix socket. You must pass this parameter to the constructor."); return undef }
	  my $sock = IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => $sockpath,
	  );
	  if( ! defined $sock ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, failed to connect to socket '$sockpath': ".$!); return undef }
	  $request_string = "GET ${qs} HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n";
	  # printf 'GET /search?q=Thomas%20Sankaria&format=json HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' | nc -U '/run/nominatim/nominatim.sock
	  	  # returns this, you need to extract only the json:
#HTTP/1.1 200 OK
#date: ... GMT
#server: uvicorn
#content-type: application/json; charset=utf-8
#content-length: 822
#connection: close
# <<<newline here
#<json-array-of-hashes-here>

	  $sock->print($request_string);
	  if( $VERBOSITY > 0 ){ $log->info("${request_string}\n\n${whoami}, line ".__LINE__." (via $parent) : sent above data to socket '$sockpath' and now waiting for response ..."); }

	  my $_content;
	  { local $/ = undef; $_content = <$sock>; }
	  close $sock;
	  if( ! defined $_content ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, read undef from socket '$sockpath'."); return undef }
	  if( $_content =~ /Invalid HTTP request received/i ){ $log->error("${_content}\n\n${whoami}, line ".__LINE__." (via $parent) : error, the server complained about Invalid Request. This often happens when your input query is not properly uri-escaped (${query_string})."); return undef }
	  $content = Encode::decode_utf8($_content);
	  if( $VERBOSITY > 0 ){ $log->info("${content}\n\n${whoami}, line ".__LINE__." (via $parent) : got above response from socket '$sockpath' and now closing the connection ..."); }
	  # some massage of the received content because it echoes also
	  # our commands to the socket, like HTTP etc. by python idiots
	  # NOTE: we can also receive empty [] for no results,
	  $content =~ s/\s+$//sm;
	  if( $content !~ /(\[\{?.*?\}?\])\s*$/sm ){ $log->error("${content}\n\n${whoami}, line ".__LINE__." (via $parent) : error, failed to find and extract JSON part (usually the last item in all that python blabber) from above content received from Nominatim socket '$request_string' and socket '${sockpath}'."); return undef }
	  $content = $1;
	  if( $VERBOSITY > 0 ){ $log->info("${content}\n\n${whoami}, line ".__LINE__." (via $parent) : extracted above JSON from the response from socket '$sockpath' and now closing the connection ..."); }
	} else { $log->error("${whoami}, line ".__LINE__." (via $parent) : error, search method '".$self->method()."' is not known."); return undef }

	# now the response must be a JSON string representing an ARRAY,
	# which can be empty or it can contain one or MORE items.

	# I am not sure if the returned JSON can contain "error" (like with /reverse)
	# but check it anyway, lamely, warning this can cause a false positive:
	if( $content =~ /"error"/ ){ $log->error($content."\n${whoami}, line ".__LINE__." (via $parent) : error, server responded with error as above, your query has failed. This may be a false positive, if you believe this is true please report it (bliako at cpan dot org)."); return undef }

	# just JSON please
	return $content if $wantJSON;

	# return an array of Address objects after parsing the received JSON
	# NOTE: the received JSON is an ARRAY of 0, 1 or more address HASHes
	my $addresses = Net::API::Nominatim::Model::Address::fromJSONArray($content);
	if( ! defined $addresses ){ $log->error("${content}\n\n${whoami}, line ".__LINE__." (via $parent) : error, call to ".'Net::API::Nominatim::Model::Address::fromJSONHash()'." has failed for above received data obtained from searching with '$qs'."); return undef }
	return $addresses; # success, returning an array of Net::API::Nominatim::Model::Address
}

# Do a Nominatim REVERSE search (specify coordinates, get address)
# with the user-specified 'search-method'
# (set via the constructor parameters during construction)
# The input parameters:
#   * $query_string : the q= of the freeform search, optional if $query_params contains a structured query
#   * $query_params : optionally specify other query params, like 'limit', 'format'
#                     and ALSO a structured query in case you do not specify a free-form $query_string.
#   * other params :
#         want-json : 1 or 0, if 1 it will return the raw JSON string received from nominatim
#                     and not process it to build Address objects.
#                     Otherwise it will return an array of Address objects.
# It returns raw JSON string or an array of
# Net::API::Nominatim::Model::Address objects, even if empty, for no results
# or undef on failure.
sub	reverse {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $VERBOSITY = $self->verbosity();
	my $log = $self->log;

	# any other params to the query other than lat,lon,
	# e.g. output format etc.
	my $query_params = (exists($params->{'query-params'}) && defined($params->{'query-params'})) ? $params->{'query-params'} : {};

	# coordinates to get address:
	my $lat = (exists($params->{'lat'}) && defined($params->{'lat'})) ? $params->{'lat'} : undef;
	if( ! defined $lat ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, parameter 'lat' is missing."); return undef }
	my $lon = (exists($params->{'lon'}) && defined($params->{'lon'})) ? $params->{'lon'} : undef;
	if( ! defined $lon ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, parameter 'lon' is missing."); return undef }

	# we can return back an array of Addresses but also
	# we can return the raw JSON received from nominatim
	# and avoid all the processing.
	my $wantJSON = (exists($params->{'want-json'}) && defined($params->{'want-json'})) ? $params->{'want-json'} : 0;

	my ($request_string, $content);
	my $qs = '/reverse?lat='.$lat.'&lon='.$lon;
	for my $qk (sort keys %{ $query_params }){
		my $qv;
		if( defined($qv=$query_params->{$qk}) ){ $qs .= '&'.$qk.'='.$qv }
	}

	if( $self->method eq 'url' ){
	  $request_string = $self->{'options'}->{'server'}->{'url'} . $qs;
	  my $request = HTTP::Request->new(
		'GET' => $request_string,
		  [
			'Accept' => 'application/json',
			'Accept-Encoding' => 'gzip',
		  ]
	  );
	  if( ! defined $request ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, failed to create 'HTTP::Request' for url '$request_string'."); return undef }
	  if( $VERBOSITY > 0 ){ $log->info("${request_string}\n\n${whoami}, line ".__LINE__." (via $parent) : GETting above url ..."); }
	  my $response = $self->lwpuseragent->request($request);
	  if( ! defined $response ){ $log->error($request->as_string."\n${whoami}, line ".__LINE__." (via $parent) : error, failed to GET above request."); return undef }
	  if( ! $response->is_success ){ $log->error($request->as_string."\n${whoami}, line ".__LINE__." (via $parent) : error, failed to GET above request because result was not success, code was '".$response->code."' : ".$response->status_line.""); return undef }
	  $content = $response->decoded_content;
	  if( ! defined $content ){ $log->error($request->as_string."\n${whoami}, line ".__LINE__." (via $parent) : error, GET above request was successful but decoded_content is undef."); return undef }
	  $content = Encode::decode_utf8($content);
	  # some massage of the received content:
	  $content =~ s/\s+$//sm;
	####################

	} elsif( $self->method eq 'unix-socket' ){

	####################
	  if( $VERBOSITY > 0 ){ $log->info("${qs}\n\n${whoami}, line ".__LINE__." (via $parent) : uri_escape'd the query string as unicode, assuming it wasn't (and it shouldn't), as above.") }
	  
	  my $sockpath = (exists($self->{'options'}->{'server'}->{'unix-socket'}) && defined($self->{'options'}->{'server'}->{'unix-socket'})) ? $self->{'options'}->{'server'}->{'unix-socket'} : undef;
	  if( ! defined $sockpath ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, the parameter 'server'->'unix-socket' is missing, this is the full path to the unix socket. You must pass this parameter to the constructor."); return undef }
	  my $sock = IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => $sockpath,
	  );
	  if( ! defined $sock ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, failed to connect to socket '$sockpath': ".$!); return undef }
	  $request_string = "GET ${qs} HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n";
	  	  # returns this, you need to extract only the json:
#HTTP/1.1 200 OK
#date: ... GMT
#server: uvicorn
#content-type: application/json; charset=utf-8
#content-length: 822
#connection: close
# <<<newline here
#<json-hash-here>

	  $sock->print($request_string);
	  if( $VERBOSITY > 0 ){ $log->info("${request_string}\n\n${whoami}, line ".__LINE__." (via $parent) : sent above data to socket '$sockpath' and now waiting for response ..."); }

	  my $_content;
	  { local $/ = undef; $_content = <$sock>; }
	  close $sock;
	  if( ! defined $_content ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, read undef from socket '$sockpath'."); return undef }
	  if( $_content =~ /Invalid HTTP request received/i ){ $log->error("${_content}\n\n${whoami}, line ".__LINE__." (via $parent) : error, the server complained about Invalid Request for searching [${lat},${lon}]."); return undef }
	  $content = Encode::decode_utf8($_content);
	  if( $VERBOSITY > 0 ){ $log->info("${content}\n\n${whoami}, line ".__LINE__." (via $parent) : got above response from socket '$sockpath' and now closing the connection ..."); }
	  # some massage of the received content because it echoes also
	  # our commands to the socket, like HTTP etc. by python idiots
	  # NOTE: we receive a JSON HASH (not array of hashes as with search())
	  $content =~ s/\s+$//sm;
	  if( $content !~ /(\{.*\})\s*$/sm ){ $log->error("${content}\n\n${whoami}, line ".__LINE__." (via $parent) : error, failed to find and extract JSON part (usually the last item in all that python blabber) from above content received from Nominatim socket '$request_string' and socket '${sockpath}'."); return undef }
	  $content = $1;
	  if( $VERBOSITY > 0 ){ $log->info("${content}\n\n${whoami}, line ".__LINE__." (via $parent) : extracted above JSON from the response from socket '$sockpath' and now closing the connection ..."); }
	} else { $log->error("${whoami}, line ".__LINE__." (via $parent) : error, search method '".$self->method()."' is not known."); return undef }

	# now the response must be a JSON string containing a HASH
	# it can contain this: {"error":"Unable to geocode"}
	# (for lat=0.0, lon=0.0, this is tested)
	# and catch this here lamely but faster
	if( $content =~ /"error"\s*\:\s*"Unable to geocode"/ ){ $log->error($content."\n${whoami}, line ".__LINE__." (via $parent) : error, server responded with error as above, your query has failed."); return undef }
	
	# just JSON please
	return $content if $wantJSON;

	# return a SINGLE Address after parsing the received JSON
	# NOTE: the received JSON is a HASH representing a SINGLE address
	my $address = Net::API::Nominatim::Model::Address::fromJSONHash($content);
	if( ! defined $address ){ $log->error("${content}\n\n${whoami}, line ".__LINE__." (via $parent) : error, call to ".'Net::API::Nominatim::Model::Address::fromJSONHash()'." has failed for above received data obtained from searching with '$qs'."); return undef }
	return $address; # success, returning a single Net::API::Nominatim::Model::Address object
}

# get the status of the nominatim server
# it returns 0 for server down or 1 for server up
# or undef on failure (e.g. network access).
# NOTE: if the server is down then it may not be able to responde
# so we will consider some failures, e.g. getting the server url
# or not finding the unix socket as that the system is down
# and will return 0 (down) and not undef.
sub	status {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $VERBOSITY = $self->verbosity();
	my $log = $self->log;

	my $qs = '/status';
	my ($request_string, $content);
	if( $self->method eq 'url' ){
	  $request_string = $self->{'options'}->{'server'}->{'url'} . $qs;
	  my $request = HTTP::Request->new(
		'GET' => $request_string,
		  [
			'Accept' => 'application/json',
			'Accept-Encoding' => 'gzip',
		  ]
	  );
	  if( ! defined $request ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, failed to create 'HTTP::Request' for url '$request_string'."); return undef }
	  if( $VERBOSITY > 0 ){ $log->info("${request_string}\n\n${whoami}, line ".__LINE__." (via $parent) : GETting above url ..."); }
	  my $response = $self->lwpuseragent->request($request);
	  if( ! defined $response ){ $log->error($request->as_string."\n${whoami}, line ".__LINE__." (via $parent) : error, failed to GET above request."); return undef }
	  if( ! $response->is_success ){
		$log->warn($request->as_string."\n${whoami}, line ".__LINE__." (via $parent) : error, failed to GET above request because result was not success, assuming that the server is down, code was '".$response->code."' : ".$response->status_line."");
		return 0 # server down MOST LIKELY
	  }
	  $content = $response->decoded_content;
	  $content = Encode::decode_utf8($content);
	  if( ! defined $content ){ $log->error($request->as_string."\n${whoami}, line ".__LINE__." (via $parent) : error, GET above request was successful but decoded_content is undef."); return undef }
	####################

	} elsif( $self->method eq 'unix-socket' ){

	####################
	  my $sockpath = (exists($self->{'options'}->{'server'}->{'unix-socket'}) && defined($self->{'options'}->{'server'}->{'unix-socket'})) ? $self->{'options'}->{'server'}->{'unix-socket'} : undef;
	  if( ! defined $sockpath ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, the parameter 'server'->'unix-socket' is missing, this is the full path to the unix socket. You must pass this parameter to the constructor."); return undef }
	  my $sock = IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => $sockpath,
	  );
	  if( ! defined $sock ){
		$log->warn("${whoami}, line ".__LINE__." (via $parent) : warning, failed to connect to socket '$sockpath', assuming that the server is down: ".$!);
		return 0; # server is down MOST LIKELY
	  }
	  $request_string = "GET ${qs} HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n";
	  # printf 'GET /status HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' | nc -U '/run/nominatim/nominatim.sock
	  	  # returns this, you need to extract only the json:
#HTTP/1.1 200 OK
#date: ... GMT
#server: uvicorn
#content-type: application/json; charset=utf-8
#content-length: 822
#connection: close
# <<<newline here
#OK <<< for success it is just OK, don't know for failure

	  $sock->print($request_string);

	  if( $VERBOSITY > 0 ){ $log->info("${qs}\n\n${whoami}, line ".__LINE__." (via $parent) : sent above data to socket '$sockpath' and now waiting for response ..."); }

	  my $_content;
	  { local $/ = undef; $_content = <$sock>; }
	  close $sock;
	  if( ! defined $_content ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, read undef from socket '$sockpath'."); return undef }
	  $content = Encode::decode_utf8($_content);
	  if( $VERBOSITY > 0 ){ $log->info("${content}\n\n${whoami}, line ".__LINE__." (via $parent) : got above response from socket '$sockpath' and now closing the connection ..."); }
	  # some massage of the received content because it echoes also
	  # our commands to the socket, like HTTP etc. by python idiots
	  $content =~ s/\s+$//sm;
	  # Here we do not get JSON
	  if( $content !~ /date\:.+?\nConnection\:.+?\n+(.+?)$/sm ){ $log->error("${content}\n\n${whoami}, line ".__LINE__." (via $parent) : error, failed to find and extract JSON part (usually the last item in all that python blabber) from above content received from Nominatim socket '$request_string' and socket '${sockpath}'."); return undef }
	  $content = $1;
	  if( $VERBOSITY > 0 ){ $log->info("${content}\n\n${whoami}, line ".__LINE__." (via $parent) : extracted above JSON from the response from socket '$sockpath' and now closing the connection ..."); }
	} else { $log->error("${whoami}, line ".__LINE__." (via $parent) : error, search method '".$self->method()."' is not known."); return undef }

	$content =~ s/\s*$//m;
	# $content must be 'OK' or not
	if( $content eq 'OK' ){ return 1 }
	# return 1 if OK, 0 for anything else
	$log->warn("${whoami}, line ".__LINE__." (via $parent) : warning, server responded with '$content' assuming it is down, check this and then remove this warning.");
	return 0; # server down
}

sub method { return $_[0]->{'options'}->{'server'}->{'method'} }
sub verbosity { return $_[0]->{'options'}->{'debug'}->{'verbosity'} }
sub log { return $_[0]->{'_private'}->{'log'}->{'logger-object'} }
sub lwpuseragent { return $_[0]->{'_private'}->{'lwpuseragent'}->{'lwpuseragent-object'} }
sub cookies { return $_[0]->{'_private'}->{'lwpuseragent'}->{'cookies-object'} }

# Initialises the LWP with cookies and verbosity and all.
# It sets the LWP useragent in self->'_private' and
#  returns 1 on failure, 0 on success
sub _init_lwpuseragent {
	my $self = $_[0];
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $VERBOSITY = $self->verbosity();
	my $log = $self->log;
	my $skip_discarded_cookies = 0;

	my $lws = $self->{'_private'}->{'lwpuseragent'};

	# initialise the HTTP logger if debug > some value
	# this will be done every time we call this func but we already check if lwp exists above
	if( $VERBOSITY > 1 ){
		$log->info("${whoami}, line ".__LINE__." (via $parent) : importing 'LWP::ConsoleLogger::Easy' because of verbosity > 1 ...");
		eval {
			require LWP::ConsoleLogger::Easy;
			LWP::ConsoleLogger::Easy->import('debug_ua');
		};
		if( $@ ){ $log->error("${whoami}, line ".__LINE__." (via $parent) : error, importing 'LWP::ConsoleLogger::Easy' has failed: $@"); return 1 }
	}
	my $ua;
	my $userspecified_ua = 0;
	if( ! exists($lws->{'lwpuseragent-object'}) || ! defined($ua=$lws->{'lwpuseragent-object'}) || (ref($ua)ne'LWP::UserAgent') ){
		# LWP and Mech can take both HTTP::Cookies and HTTP::CookieJar cookiejar!
		$ua = LWP::UserAgent->new(
			'send_te' => '0',
			'cookie_jar_class' => 'HTTP::Cookies',
			'timeout' => 200, # seconds!
		);
		$lws->{'lwpuseragent-object'} = $ua;
		$userspecified_ua = 1;
	}
	if( $VERBOSITY > 5 ){
		# see https://github.com/oalders/lwp-consolelogger/issues/38
		# WARNING: this causes Wide characters when printing
		# the content/cookies/requests!!!!
		my $console_logger = debug_ua($ua);
		$console_logger->logger(
		  Log::Dispatch->new(
			outputs => [
				[ 'Screen', min_level => 'debug', newline => 1, utf8 => 0, ],
			],
		  )
		);
	}

	# if we have cookies object or filename then process it and set it
	my $cf;
	if( (exists($self->{'options'}->{'lwpuseragent'}->{'cookies-object'}) && defined($cf=$self->{'options'}->{'lwpuseragent'}->{'cookies-object'}))
	 || (exists($self->{'options'}->{'lwpuseragent'}->{'cookies-filename'}) && defined($cf=$self->{'options'}->{'lwpuseragent'}->{'cookies-filename'}))
	){
		my $cookobj = Cookies::Roundtrip::lwpuseragent_load_cookies($ua, $cf, $skip_discarded_cookies, $VERBOSITY);
		if( ! defined $cookobj ){ $log->error(Cookies::Roundtrip::as_string_cookies($cf)."${whoami}, line ".__LINE__." (via $parent): error, call to ".'Cookies::Roundtrip::lwpuseragent_load_cookies()'." has failed for cookie object above (it must be HTTP::Cookies type)."); return 1 }
		if( $VERBOSITY > 2 ){
			$log->info("--begin cookies:\n".Cookies::Roundtrip::as_string_cookies($cookobj)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): above cookies have been loaded into LWP::UserAgent.");
			$log->info("--begin cookies:\n".Cookies::Roundtrip::as_string_cookies($ua->cookie_jar)."\n--end cookies.\n\n"."${whoami}, line ".__LINE__." (via $parent): specified cookies have been loaded into LWP::UserAgent, all the cookies currently loaded into it are as above.");
		}
	} else {
		$ua->cookie_jar(HTTP::CookieJar::LWP->new);
	}
	$self->{'_private'}->{'lwpuseragent'}->{'cookies-object'} = $ua->cookie_jar;

	if( exists($self->{'options'}->{'lwpuseragent'}->{'useragent-string'}) && defined($cf=$self->{'options'}->{'lwpuseragent'}->{'useragent-string'}) ){
		$ua->agent($cf);
		if( ($VERBOSITY>0) || ($userspecified_ua>0) ){ $log->warn("${whoami}, line ".__LINE__." (via $parent): LWP::UserAgent object has now this userganet-string '".$ua->agent()."' ...") }
	}

	return 0; # success
}
# end, only pod below

=pod

=head1 NAME

Net::API::Nominatim - Perl client for local or public OpenStreetMap Nominatim Geocoding service. Open source, unrestricted and free.

=head1 VERSION

Version 0.03

=head1 !NOMINATIM!

L<Nominatim|https://nominatim.org/>
uses L<OpenStreetMap|https://www.openstreetmap.org>
data to find coordinates for locations on Earth by name and
address (geocoding). It can also do the reverse, find an address
for any location on the planet, given coordinates.

Nominatim provides a public, free and un-restricted service,
subject to fair usage, at L<https://nominatim.openstreetmap.org/ui/search.html>
for all of your geocoding needs.

Most importantly, a Nominatim server can be easily
installed locally if you intend to geocode heavily
or you do not have network access. Nominatim uses open source
geocoding data  provided by L<OpenStreetMap|https://www.openstreetmap.org>.
When you install Nominatim locally, you also install this geocoding data
locally. The data is broken into different geographical locations so you
can geocode for just your district, your country,
your continent or the whole planet
without relying on the closely guarded and
prohibitevely copyrighted (really?) data
provided by the usual big Capitalist players.

If you decided to install Nominatim locally for your own geocoding needs
it is also worth installing a Map Tile Server in order to
provide your own open source maps!
All the data open source, courtesy of L<OpenStreetMap|https://www.openstreetmap.org>.
Have a look at the guide at L<switch2osm.org||https://switch2osm.org/serving-tiles/> for how
to completely break free and never again have to rely on the usual
big Capitalist players.

For local installations, Nominatim can be accessed via a UNIX socket.
This should be the fastest method to geocode locally.
Unless you have implemented intermediate caching. Alternatively,
for local or public Nominatim service, you can make a simple
HTTP/GET query.

This module offers both local UNIX socket and
HTTP/GET queries.

Remember, Capitalism is changing really fast, to the uglier,
to the hungrier, to the scummier,
by the day.
Right now it is very hungry. It will become even more so.
It is not a matter of "immoral", "stupid", "greedy"
leaders "running" (yeah! right) the show, it is a matter
of processes. The processes will continue irrespective of leaders.
To the End.

As a matter of life or death, break away from Capitalism NOW.


=head1 SYNOPSIS

The current module provides functionality to query a Nominatim
server, either via a local UNIX socket, if Nominatim is installed
locally, or via HTTP/GET requests if you rely on the public Nominatim
service. The L<Nominatim API|https://nominatim.org/release-docs/develop/api/Overview>
is extensive. But the current module covers only basic forward and reverse
geocoding queries only with C</search>, C</reverse> and C</status>.

Example usage:

    use Net::API::Nominatim;

    my $cparams = {
        'server' => {
            'url' => 'https://nominatim.openstreetmap.org',
        },
        # optional debug
        'debug' => {
            'verbosity' => 666,
        },
        # optional logger
        'log' => {
            'logger-file' => Mojo::Log->new,
        }
    };

    my $client = Net::API::Nominatim->new($cparams);
    my $addresses = $client->search({
      q => 'Leika',
    });
    # we now have an ARRAY_REF of
    # Net::API::Nominatim::Model::Address objects back
    # these objects contain many useful things including
    # proper address, coordinates and bounding box!
    # Thank you OpenStreetMap!
    print $_->toString()."\n" for @$addresses;

    # or just get the JSON string back
    my $jsonresponse = $client->search({
      q => 'Leika',
      'want-json' => 1,
    });

    # You can be more specific with a structured query
    my $addresses = $client->search({
      street => 'Leika',
      city => 'Honolulu',
      # county, country, etc.
    });
    # a structured query allows you to search for amenities
    my $addresses = $client->search({
      amenity => 'restaurant',
      city => 'Honolulu',
      # county, country, etc.
    });

    # Reverse geo-coding: from coordinates to address
    my $address = $client->reverse({
      lon => '15.014879', # quote them, you never know with floats ...
      lat => '38.022967',
    });
    # it returns a single Net::API::Nominatim::Model::Address object
    print $address->toString()."\n";

    # server status
    print "alive!\n" if $client->status();


=head1 METHODS


=head2 C<new()>

The constructor.

The full list of arguments, provided as a hashref, is as follows:

=over 2

=item * C<server> : a HASH_REF with one of these keys:

=over 2

=item * C<url> : specify the Nominatim server URL, for example the public service is located at L<https://nominatim.openstreetmap.org/ui/search.html>.

=item * C<unix-socket> : alternatively, if you have installed Nominatim locally, you may want to
query it directly via its UNIX socket. This should then be the fullpath to the local UNIX socket
(which must have the appropriate permissions for the current user).

=back

=item * C<log> : a HASH_REF with one of these keys:

=over 2

=item * C<logger-file> : a filename to log into, or,

=item * C<logger-object> : an already existing logger object which implements methods C<info(string)>, C<warn(string)> and C<error(string)>.

=back

=item * C<lwpuseragent> : only applicable if doing HTTP queries (and not UNIX socket).
This is HASH_REF with some of these keys:

=over 2

=item * C<cookies-object> : specify a cookies object for loading and saving session cookies, optional and most likely unused,

=item * C<lwpuseragent-object> : specify an already existing L<LWP::UserAgent> object to use.
B<WARNING>: this object will have its UserAgent String altered to comply with Nominatim's
usage policy which states it must be a string to identify the client. So, this will be
our client's UserAgent String. If you intend to use the specified L<LWP::UserAgent> object
then save its agent string (C<my $oldstr = $ua-E<gt>agent;>) and reload it later
(C<$ua-E<gt>agent($oldstr);>).

=item * C<useragent-string> : DO NOT SPECIFY your own UserAgent String PLEASE. There is
already a default for this which identifies this current client uniquely. So, you do
not need to set this. But if you wish to do so, then nobody stops you.

=back

=back

The constructor will return C<undef> on failure (but will not die).

=head3 Caveat

The user-specified C<HASH_REF> of parameters into the constructor B<will be modified>.
Some fields will be added and some fields will be deleted. It would be ideal
if it was cloned but since it can contain OBJECT references I find it difficult
to tell L<Clone> or L<Storable> to skip cloning objects.



=head2 C<search()>

It does free-form or structured address search.
The full list of arguments, provided as a hashref, is as follows:

=over 2

=item * The search can be free-form or structured. In case of
free-form search you need to specify only C<q> as a free-form address string.
In case of a structured search you must NOT specify C<q> at all but specify some
of the other fields as specified below.
Note that all strings will be url-encoded internally, taking into
account if are unicode'd, do not url-encode them yourself.

=over 2

=item * C<q> : a free-form address string. It will be url-encoded when
making the query so do not encode it yourself.

=item * alternatively use some of these for a structured search: C<amenity>, C<street>, C<city>, C<county>, C<state>, C<country>, C<postalcode>.
See the structured search L<API|https://nominatim.org/release-docs/develop/api/Search/#structured-query>
for more details.

=back

=item * C<want-json> : optionally, specify whether you want to have the
raw server response back as a JSON string. This will save some time
decoding the JSON into L<Net::API::Nominatim::Model::Address> objects.

=item * C<query-params> : optionally specify extra query params to your search as
a C<HASH_REF>. See the Nominatim Search L<API|https://nominatim.org/release-docs/develop/api/Search/>
for what these parameters can be. By default, you do not need to specify any of these extra
parameters.

=back

It returns C<undef> on communication failure.

It returns back an C<ARRAY_REF> of zero, one or more L<Net::API::Nominatim::Model::Address>
objects on success. Unless the option C<want-json> was set to C<1>, in which case
the return will be a JSON (array-of-hashes) string of results.

=head3 Warning

Do not mix free-form query parameter (C<q>) with structured query
parameters (e.g. C<street>, C<country>, etc.).

A structured query can return many results depending on how specific
it is. For example, if you specify only C<amenity=restaurant> there can
be hundreds of results but the public Nominatim service has a default
limit of returning only 10 results with a hard-limit of 40.


=head2 C<reverse()>

It does a reverse geocoding search. That is, it returns
an address when coordinates are specified.

The full list of arguments, provided as a hashref, is as follows:

=over 2

=item * C<lat> : latitude

=item * C<lon> : longitude

=item * C<want-json> : optionally, specify whether you want to have the
raw server response back as a JSON string. This will save some time
decoding the JSON into L<Net::API::Nominatim::Model::Address> objects.

=item * C<query-params> : optionally specify extra query params to your search as
a C<HASH_REF>. See the Nominatim Search L<API|https://nominatim.org/release-docs/develop/api/Reverse/>
for what these parameters can be. By default, you do not need to specify any of these extra
parameters.

=back

It returns C<undef> on communication failure.

It returns back a single L<Net::API::Nominatim::Model::Address> object
on success. Unless the option C<want-json> was set to C<1>, in which case
the return will be a JSON (hash) string of results.

It differs from L<search()> in that it returns a single address object
and not an C<ARRAY_REF> of objects. The returned JSON will be a hash
containing a single address and not an array.

=head1 TODO

The L<Nominatim API|https://nominatim.org/release-docs/develop/api/Overview/>
contains a lot more "verbs" than the three implemented in this module. Feel
free to provide implementations if you find any of those useful and they will
be incorporated in this module.


=head1 CAVEATS

Queries can return many results depending on how specific
they are, especially the structured query.
For example, if you specify only C<amenity=restaurant> there can
be hundreds of results but the public Nominatim service has a default
limit of returning only 10 results with a hard-limit of 40.
This is specified in the L<Nominatim API|https://nominatim.org/release-docs/develop/api/Search>
under C<limit>.

=head1 RELATED OPEN SOURCE SOFTWARE

First of all, OpenStreetMap data is freely available
for downloading, for the whole planet or for
specific geographical areas from L<GeoFabrik|http://download.geofabrik.de/>
in the form of C<.osm.pbf> files. This data is understood by
Nominatim, the Map tile server and GeoDesk-Gol mentioned below.
This data can also be inserted into a L<PostGIS|https://postgis.net/>
database and make your own queries on it.

I have already mentioned in the L<INTRODUCTION>
that it is quite easy and, definetely, not discouraged to
host a Nominatim server locally. It will be totally self-sufficient
in the sense that it will not need to access any external
resources. All addresses for your geographical area or
the whole planet are stored in a local
L<PostGIS|https://postgis.net/>, powered by the amazing
elephant-in-the-server-room L<PostgreSQL|https://www.postgresql.org/>.
Check for what resources are required though. For small geographical
areas, resources are moderate.

You can also host your own map tiles and serve your own
high-quality maps, styled as you like,
without relying ever again on the big Capitalist players.
Have a look at the guide offered at L<Switch2osm|https://switch2osm.org>
for how you can get started with this, although far more resources are
needed and assembling the toolchain is more complicated
than with Nominatim. But it works, just follow the L<guide|https://switch2osm.org>.

Another open source project is L<GeoDesk|https://github.com/clarisma/geodesk>
and the command line query tool L<GeoDesk-Gol|https://github.com/clarisma/geodesk-gol>.
This tool takes OpenStreetMap data for any geographical location,
in the form of C<.osm.pbf> files (see above on where to download them from)
and constructs a portable, file-based database
(called Gol, as in scoring a goal!) which you can then enquire with
the provided command line tool. There is no need to create a L<PostGIS|https://postgis.net/>
database and insert data into it. The Gol file is all you need
for doing queries like, I<find all restaurants in this neighbourhood>,
I<list all street names in this district>, I<list all bus-stops>, etc.
It is pretty amazing and more so because it is portable, no database
setup is required. Of course it is open source and kudos to their
creator L<Clarisma|https://github.com/clarisma>, which by-the-way
I am not affiliated in any way, just a fan.


=head1 TESTING

Basic testing (C<make test>) does not require,
and, will not attempt online access. It tests instantiating the
client and the other auxiliary classes.

Live testing needs network access to a public Nominatim
server or a local installation of Nominatim. It comes in two flavours:

=over 2

=item * C<make livetesturl> : tests HTTP/GET queries to the public Nominatim server at
L<https://nominatim.openstreetmap.org/ui/search.html>.

=item * C<make livetestlocal> : tests socket queries to a local Nominatim installation
via its local UNIX socket whose path can be set in all the test files in directory
C<xt/live/local-socket/> via the C<$sockpath> variable,
currently pointing to C</run/nominatim/nominatim.sock>.

=back

=head1 RESPONSIBLE USE

Be responsible in using the public Nominatim service and please
observe their usage policy, summarised as

=over 2

=item * Uniquely and persistently identify your client.

=item * No more than one request per second.

=back

The first clause we observe here by setting the default User-Agent string.

The second clause is up to you. Please be responsible and do not forget
that if you are going to do a lot of geocoding install your own Nominatim
server locally. Then you can query it to your heart's content.


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-api-nominatim at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-API-Nominatim>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::API::Nominatim


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-API-Nominatim>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-API-Nominatim>

=item * Search CPAN

L<https://metacpan.org/release/Net-API-Nominatim>

=item * PerlMonks!

L<https://perlmonks.org/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::API::Nominatim
