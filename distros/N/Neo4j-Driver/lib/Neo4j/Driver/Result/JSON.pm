use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Result::JSON;
# ABSTRACT: JSON/REST result handler
$Neo4j::Driver::Result::JSON::VERSION = '0.41';

# This package is not part of the public Neo4j::Driver API.


use parent 'Neo4j::Driver::Result';

use Carp qw(carp croak);
our @CARP_NOT = qw(Neo4j::Driver::Net::HTTP);
use Try::Tiny;

use URI 1.31;

use Neo4j::Error;


my ($TRUE, $FALSE);

my $MEDIA_TYPE = "application/json";
my $ACCEPT_HEADER = "$MEDIA_TYPE";
my $ACCEPT_HEADER_POST = "$MEDIA_TYPE;q=0.5";


sub new {
	# uncoverable pod (private method)
	my ($class, $params) = @_;
	
	($TRUE, $FALSE) = @{ $params->{http_agent}->json_coder->decode('[true,false]') } unless $TRUE;
	
	my $json = $class->_parse_json($params);
	
	my @results = ();
	@results = @{ $json->{results} } if ref $json->{results} eq 'ARRAY';
	@results = map { $class->_new_result($_, $json, $params) } @results;
	$results[$_]->{statement} = $params->{statements}->[$_] for (0 .. $#results);
	
	if (@results == 1) {
		$results[0]->{json} = $json;  # for _info()
		return $results[0];
	}
	
	# If the number of Cypher statements run wasn't exactly one, provide
	# a dummy result containing the raw JSON so that callers can do their
	# own parsing. Also, provide a list of all results so that callers
	# get a uniform interface for all of them.
	return bless {
		json => $json,
		attached => 0,
		exhausted => 1,
		buffer => [],
		server_info => $params->{server_info},
		result_list => @results ? \@results : undef,
	}, $class;
}


sub _new_result {
	my ($class, $result, $json, $params) = @_;
	
	my $self = {
		attached => 0,   # 1: unbuffered records may exist on the stream
		exhausted => 0,  # 1: all records read by the client; fetch() will fail
		result => $result,
		buffer => [],
		columns => undef,
		summary => undef,
		cypher_types => $params->{cypher_types},
		notifications => $json->{notifications},
		server_info => $params->{server_info},
	};
	bless $self, $class;
	
	return $self->_as_fully_buffered;
}


sub _parse_json {
	my (undef, $params) = @_;
	
	my $response = $params->{http_agent}->fetch_all;
	my $error = 'Neo4j::Error';
	my $json;
	try {
		$json = $params->{http_agent}->json_coder->decode($response);
	}
	catch {
		$error = $error->append_new( Internal => {
			as_string => "$_",
			raw => $response,
		});
	};
	if (ref $json->{errors} eq 'ARRAY') {
		$error = $error->append_new( Server => $_ ) for @{$json->{errors}};
	}
	if ($json->{message}) {
		$error = $error->append_new( Internal => $json->{message} );
		# can happen when the Jersey ServletContainer intercepts the request
	}
	if (! $params->{http_header}->{success}) {
		$error = $error->append_new( Network => {
			code => $params->{http_header}->{status},
			as_string => sprintf( "HTTP error: %s %s on %s to %s",
				$params->{http_header}->{status}, $params->{http_agent}->http_reason, $params->{http_method}, $params->{http_path} ),
		});
	}
	
	$json->{_error} = $error if ref $error;
	
	return $json;
}


# Return the full list of results this object represents.
sub _results {
	my ($self) = @_;
	
	return @{ $self->{result_list} } if $self->{result_list};
	return ($self);
}


# Return the raw JSON response (if available).
sub _json {
	my ($self) = @_;
	return $self->{json};
}


# Return transaction status information (if available).
sub _info {
	my ($self) = @_;
	return $self->{json};
}


# Bless and initialise the given reference as a Record.
sub _init_record {
	my ($self, $record) = @_;
	
	$record->{column_keys} = $self->{columns};
	$self->_deep_bless( $record->{row}, $record->{meta}, $record->{rest} );
	return bless $record, 'Neo4j::Driver::Record';
}


sub _deep_bless {
	my ($self, $data, $meta, $rest) = @_;
	my $cypher_types = $self->{cypher_types};
	
	# "meta" is broken, so we primarily use "rest", see neo4j #12306
	
	if (ref $data eq 'HASH' && ref $rest eq 'HASH' && ref $rest->{metadata} eq 'HASH' && $rest->{self} && $rest->{self} =~ m|/db/[^/]+/node/|) {  # node
		my $node = bless \$data, $cypher_types->{node};
		$data->{_meta} = $rest->{metadata};
		$data->{_meta}->{deleted} = $meta->{deleted} if ref $meta eq 'HASH';
		$cypher_types->{init}->($node) if $cypher_types->{init};
		return $node;
	}
	if (ref $data eq 'HASH' && ref $rest eq 'HASH' && ref $rest->{metadata} eq 'HASH' && $rest->{self} && $rest->{self} =~ m|/db/[^/]+/relationship/|) {  # relationship
		my $rel = bless \$data, $cypher_types->{relationship};
		$data->{_meta} = $rest->{metadata};
		$rest->{start} =~ m|/([0-9]+)$|;
		$data->{_meta}->{start} = 0 + $1;
		$rest->{end} =~ m|/([0-9]+)$|;
		$data->{_meta}->{end} = 0 + $1;
		$data->{_meta}->{deleted} = $meta->{deleted} if ref $meta eq 'HASH';
		$cypher_types->{init}->($rel) if $cypher_types->{init};
		return $rel;
	}
	
	if (ref $data eq 'ARRAY' && ref $rest eq 'HASH') {  # path
		die "Assertion failed: path length mismatch: ".(scalar @$data).">>1/$rest->{length}" if @$data >> 1 != $rest->{length};  # uncoverable branch true
		my $path = [];
		for my $n ( 0 .. $#{ $rest->{nodes} } ) {
			my $i = $n * 2;
			my $uri = $rest->{nodes}->[$n];
			$uri =~ m|/([0-9]+)$|;
			$data->[$i]->{_meta} = { id => 0 + $1 };
			$data->[$i]->{_meta}->{deleted} = $meta->[$i]->{deleted} if ref $meta eq 'ARRAY';
			$path->[$i] = bless \( $data->[$i] ), $cypher_types->{node};
		}
		for my $r ( 0 .. $#{ $rest->{relationships} } ) {
			my $i = $r * 2 + 1;
			my $uri = $rest->{relationships}->[$r];
			$uri =~ m|/([0-9]+)$|;
			$data->[$i]->{_meta} = { id => 0 + $1 };
			my $rev = $rest->{directions}->[$r] eq '<-' ? -1 : 1;
			$data->[$i]->{_meta}->{start} = $data->[$i - 1 * $rev]->{_meta}->{id};
			$data->[$i]->{_meta}->{end} =   $data->[$i + 1 * $rev]->{_meta}->{id};
			$data->[$i]->{_meta}->{deleted} = $meta->[$i]->{deleted} if ref $meta eq 'ARRAY';
			$path->[$i] = bless \( $data->[$i] ), $cypher_types->{relationship};
		}
		$path = bless { path => $path }, $cypher_types->{path};
		$cypher_types->{init}->($_) for $cypher_types->{init} ? ( @$path, $path ) : ();
		return $path;
	}
	
	if (ref $data eq 'HASH' && ref $rest eq 'HASH' && ref $rest->{crs} eq 'HASH') {  # spatial
		bless $rest, $cypher_types->{point};
		$cypher_types->{init}->($data) if $cypher_types->{init};
		return $rest;
	}
	if (ref $data eq '' && ref $rest eq '' && ref $meta eq 'HASH' && $meta->{type} && $meta->{type} =~ m/date|time|duration/) {  # temporal (depends on meta => doesn't always work)
		$data = bless { data => $data, type => $meta->{type} }, $cypher_types->{temporal};
		$cypher_types->{init}->($data) if $cypher_types->{init};
		return $data;
	}
	
	if (ref $data eq 'ARRAY' && ref $rest eq 'ARRAY') {  # array
		die "Assertion failed: array rest size mismatch" if @$data != @$rest;  # uncoverable branch true
		$meta = [] if ref $meta ne 'ARRAY' || @$data != @$meta;  # handle neo4j #12306
		foreach my $i ( 0 .. $#{$data} ) {
			$data->[$i] = $self->_deep_bless( $data->[$i], $meta->[$i], $rest->[$i] );
		}
		return $data;
	}
	if (ref $data eq 'HASH' && ref $rest eq 'HASH') {  # and neither node nor relationship nor spatial ==> map
		die "Assertion failed: map rest size mismatch" if (scalar keys %$data) != (scalar keys %$rest);  # uncoverable branch true
		die "Assertion failed: map rest keys mismatch" if (join '', sort keys %$data) ne (join '', sort keys %$rest);  # uncoverable branch true
		$meta = {} if ref $meta ne 'HASH' || (scalar keys %$data) != (scalar keys %$meta);  # handle neo4j #12306
		foreach my $key ( keys %$data ) {
			$data->{$key} = $self->_deep_bless( $data->{$key}, $meta->{$key}, $rest->{$key} );
		}
		return $data;
	}
	
	if (ref $data eq '' && ref $rest eq '') {  # scalar
		return $data;
	}
	if ( $data == $TRUE && $rest == $TRUE || $data == $FALSE && $rest == $FALSE ) {  # boolean
		return $data;
	}
	
	die "Assertion failed: unexpected type combo: " . ref($data) . "/" . ref($rest);  # uncoverable statement
}


# Return a list of the media types this module can handle, fit for
# use in an HTTP Accept header field.
sub _accept_header {
	my (undef, $want_jolt, $method) = @_;
	
	# 'v1' is used as an internal marker for Neo4j 4
	# Note: Neo4j < 4.2 doesn't fail gracefully if Jolt is the only acceptable response type.
	return if $want_jolt && $want_jolt ne 'v1';
	
	return ($ACCEPT_HEADER_POST) if $method eq 'POST';
	return ($ACCEPT_HEADER);
}


# Whether the given media type can be handled by this module.
sub _acceptable {
	my (undef, $content_type) = @_;
	
	return $content_type =~ m/^$MEDIA_TYPE\b/i;
}


1;
