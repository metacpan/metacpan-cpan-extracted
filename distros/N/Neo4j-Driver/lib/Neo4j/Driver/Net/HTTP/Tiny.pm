use v5.14;
use warnings;

package Neo4j::Driver::Net::HTTP::Tiny 1.02;
# ABSTRACT: HTTP network adapter for HTTP::Tiny


# For documentation, see Neo4j::Driver::Plugin.


use Carp qw(croak);
our @CARP_NOT = qw(Neo4j::Driver::Net::HTTP);

use HTTP::Tiny 0.034 ();
use JSON::MaybeXS 1.003003 ();
use URI 1.25 ();
use URI::Escape 3.26 ();

my %DEFAULT_HEADERS = (
	'Content-Type' => 'application/json',
	'X-Stream' => 'true',
);

# User-Agent: Neo4j-Driver/1.00 Perl HTTP-Tiny/0.090
my $AGENT = __PACKAGE__->VERSION;
$AGENT = sprintf "Neo4j-Driver%s Perl ", $AGENT ? "/$AGENT" : "";


sub new {
	# uncoverable pod
	my ($class, $driver) = @_;
	
	my $config = $driver->{config};
	my $self = bless {
		json_coder => JSON::MaybeXS->new( utf8 => 1, allow_nonref => 0 ),
	}, $class;
	
	my $uri = $config->{uri};
	if ( defined $config->{auth} ) {
		croak "Only HTTP Basic Authentication is supported"
			if $config->{auth}->{scheme} ne 'basic';
		my $userid = URI::Escape::uri_escape_utf8 $config->{auth}->{principal}   // '';
		my $passwd = URI::Escape::uri_escape_utf8 $config->{auth}->{credentials} // '';
		$uri = $uri->clone;
		$uri->userinfo("$userid:$passwd");
	}
	$self->{uri_base} = $uri;
	
	my %http_attributes = (
		agent => $AGENT,
		default_headers => \%DEFAULT_HEADERS,
		timeout => $config->{timeout},
	);
	
	if ( $uri->scheme eq 'https' ) {
		croak "HTTPS does not support unencrypted communication; use HTTP"
			if defined $config->{encrypted} && ! $config->{encrypted};
		$http_attributes{verify_SSL} = 1;
		if ( defined $config->{trust_ca} ) {
			croak sprintf "trust_ca file '%s' can't be used: %s", $config->{trust_ca}, $!
				unless open my $fh, '<', $config->{trust_ca};
			$http_attributes{SSL_options}->{SSL_ca_file} = $config->{trust_ca};
		}
	}
	else {
		croak "HTTP does not support encrypted communication; use HTTPS"
			if $config->{encrypted};
	}
	
	$self->{http} = HTTP::Tiny->new( %http_attributes );
	
	return $self;
}


# Return server base URL as string or URI object (for ServerInfo).
sub uri {
	# uncoverable pod
	my $self = shift;
	
	return $self->{uri_base};
}


# Return a JSON:XS-compatible coder object (for result parsers).
sub json_coder {
	# uncoverable pod
	my $self = shift;
	
	return $self->{json_coder};
}


# Return the HTTP Date header from the last response.
sub date_header {
	# uncoverable pod
	my $response = shift->{response};
	
	return $response->{headers}->{date} // '';
}


# Return a hashref with the following entries, representing
# headers and status of the last response:
# - content_type  (eg "application/json")
# - location      (URI reference)
# - status        (eg "404")
# - success       (truthy for 2xx status)
sub http_header {
	# uncoverable pod
	my $response = shift->{response};
	
	my %header = (
		content_type => $response->{headers}->{'content-type'} // '',
		location     => $response->{headers}->{location} // '',
		status       => $response->{status},
		success      => $response->{success},
	);
	if ( $response->{status} eq '599' ) {  # Internal Exception
		$header{content_type} = '';
		$header{status}       = '';
	}
	return \%header;
}


# Return the HTTP reason phrase (eg "Not Found"), or the error
# message for HTTP::Tiny internal exceptions.
sub http_reason {
	# uncoverable pod
	my $response = shift->{response};
	
	if ( $response->{status} eq '599' ) {
		return $response->{content} =~ s/\s+$//ra;
	}
	return $response->{reason};
}


# Return the next Jolt event from the response to the last network
# request as a string. When there are no further Jolt events on the
# response buffer, this method returns an empty string.
# This algorithm is not strictly compliant with the json-seq RFC 7464.
# Instead, it's an ndjson parser that accounts for leading RS bytes,
# which is what works best for all versions of Neo4j.
sub fetch_event {
	# uncoverable pod
	my $response = shift->{response};
	
	# Jolt always uses LF as event separator. When there is no LF,
	# return the entire buffer to terminate the event loop.
	my $length = 1 + index $response->{content}, chr 0x0a;
	$length ||= length $response->{content};
	
	# Chop the event off the front of the buffer and drop the RS byte.
	my $event = substr $response->{content}, 0, $length, '';
	substr $event, 0, 1, '' if ord $event == 0x1e;
	return $event;
}


# Return the entire remaining content of the response buffer.
sub fetch_all {
	# uncoverable pod
	my $response = shift->{response};
	
	return $response->{content};
}


# Perform an HTTP request on the network and store the response.
# Will always block until the entire response has been received.
# The following positional parameters are given:
# - method  (HTTP method, e. g. "POST")
# - url     (string with request URL, relative to base)
# - json    (reference to hash of JSON object, or undef)
# - accept  (string with value for the Accept header)
# - mode    (string with value for the Access-Mode header)
sub request {
	# uncoverable pod
	my ($self, $method, $url, $json, $accept, $mode) = @_;
	
	$url = URI->new_abs( $url, $self->{uri_base} );
	if ( defined $json ) {
		my %options = (
			content => $self->{json_coder}->encode($json),
			headers => { Accept => $accept },
		);
		$options{headers}->{'Access-Mode'} = $mode if defined $mode;
		$self->{response} = $self->{http}->request( $method, $url, \%options );
	}
	else {
		my %options = (
			headers => { Accept => $accept },
		);
		$self->{response} = $self->{http}->request( $method, $url, \%options );
	}
}


1;
