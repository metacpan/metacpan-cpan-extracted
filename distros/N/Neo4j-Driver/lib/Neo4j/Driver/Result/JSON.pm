use v5.14;
use warnings;

package Neo4j::Driver::Result::JSON 1.02;
# ABSTRACT: JSON/REST result handler


# This package is not part of the public Neo4j::Driver API.


use parent 'Neo4j::Driver::Result';

use Carp qw(croak);
our @CARP_NOT = qw(Neo4j::Driver::Net::HTTP);
use Feature::Compat::Try;
use JSON::MaybeXS 1.002004 ();

use Neo4j::Driver::Type::Bytes;
use Neo4j::Driver::Type::DateTime;
use Neo4j::Driver::Type::Duration;
use Neo4j::Driver::Type::Path;
use Neo4j::Driver::Type::Point;
use Neo4j::Driver::Type::V1::Node;
use Neo4j::Driver::Type::V1::Relationship;
use Neo4j::Error;


my ($FALSE, $TRUE) = Neo4j::Driver::Result->_bool_values;

my $MEDIA_TYPE = "application/json";
my $ACCEPT_HEADER = "$MEDIA_TYPE";
my $ACCEPT_HEADER_POST = "$MEDIA_TYPE;q=0.5";


sub new {
	# uncoverable pod (private method)
	my ($class, $params) = @_;
	
	my $json = $class->_parse_json($params);
	
	my @results = ();
	@results = @{ $json->{results} } if ref $json->{results} eq 'ARRAY';
	@results = map { $class->_new_result($_, $json, $params) } @results;
	$results[$_]->{query} = $params->{queries}->[$_] for (0 .. $#results);
	
	if (@results == 1) {
		$results[0]->{json} = $json;  # for _info()
		return $results[0];
	}
	
	# If the number of Cypher queries run wasn't exactly one, provide
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
		field_names_cache => undef,
		summary => undef,
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
	catch ($e) {
		$error = $error->append_new( Internal => {
			as_string => "$e",
			raw => $response,
		});
	}
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
	
	$record->{field_names_cache} = $self->{field_names_cache};
	$self->_deep_bless( $record->{row}, $record->{meta}, $record->{rest} );
	delete $record->{meta};
	delete $record->{rest};
	return bless $record, 'Neo4j::Driver::Record';
}


sub _deep_bless {
	my ($self, $data, $meta, $rest) = @_;
	
	# "meta" is broken, so we primarily use "rest", see neo4j #12306
	
	if (ref $data eq 'HASH' && ref $rest eq 'HASH' && ref $rest->{metadata} eq 'HASH' && $rest->{self} && $rest->{self} =~ m|/db/[^/]+/node/|) {  # node
		return bless [
			$rest->{metadata}->{id},
			$rest->{metadata}->{labels} // [],
			$data,
		], 'Neo4j::Driver::Type::V1::Node';
	}
	if (ref $data eq 'HASH' && ref $rest eq 'HASH' && ref $rest->{metadata} eq 'HASH' && $rest->{self} && $rest->{self} =~ m|/db/[^/]+/relationship/|) {  # relationship
		return bless [
			$rest->{metadata}->{id},
			do { $rest->{start} =~ m/(\d+)$/a; 0 + $1 },
			$rest->{metadata}->{type},
			do { $rest->{end} =~ m/(\d+)$/a; 0 + $1 },
			$data,
		], 'Neo4j::Driver::Type::V1::Relationship';
	}
	
	if (ref $data eq 'ARRAY' && ref $rest eq 'HASH') {  # path
		die "Assertion failed: path length mismatch: ".(scalar @$data).">>1/$rest->{length}" if @$data >> 1 != $rest->{length};  # uncoverable branch true
		my $path = [];
		for my $n ( 0 .. $#{ $rest->{nodes} } ) {
			my $i = $n * 2;
			$path->[$i] = bless [
				do { $rest->{nodes}->[$n] =~ m/(\d+)$/a; 0 + $1 },
				[],  # see neo4j#12613
				$data->[$i],
			], 'Neo4j::Driver::Type::V1::Node';
		}
		for my $r ( 0 .. $#{ $rest->{relationships} } ) {
			my $i = $r * 2 + 1;
			my $dir = $rest->{directions}->[$r] eq '->' ? 1 : -1;
			$path->[$i] = bless [
				do { $rest->{relationships}->[$r] =~ m/(\d+)$/a; 0 + $1 },
				$path->[$i - 1 * $dir]->[0],
				undef,  # see neo4j#12613
				$path->[$i + 1 * $dir]->[0],
				$data->[$i],
			], 'Neo4j::Driver::Type::V1::Relationship';
		}
		return bless { '..' => $path }, 'Neo4j::Driver::Type::Path';
	}
	
	if (ref $data eq 'HASH' && ref $rest eq 'HASH' && ref $rest->{crs} eq 'HASH') {  # spatial
		$rest->{srid} = $rest->{crs}->{srid};
		return bless $rest, 'Neo4j::Driver::Type::Point';
	}
	if (ref $data eq '' && ref $rest eq '' && ref $meta eq 'HASH' && $meta->{type} && $meta->{type} =~ m/date|time|duration/) {  # temporal (depends on meta => doesn't always work)
		return bless { T => $data }, $meta->{type} eq 'duration'
			? 'Neo4j::Driver::Type::Duration'
			: 'Neo4j::Driver::Type::DateTime';
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
	
	if (JSON::MaybeXS::is_bool($data) && JSON::MaybeXS::is_bool($rest)) {  # boolean
		return $data ? $TRUE : $FALSE;
	}
	if (ref $data eq '' && ref $rest eq '') {  # scalar
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
