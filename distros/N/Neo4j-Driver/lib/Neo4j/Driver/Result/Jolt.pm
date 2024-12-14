use v5.12;
use warnings;

package Neo4j::Driver::Result::Jolt 1.02;
# ABSTRACT: Jolt result handler


# This package is not part of the public Neo4j::Driver API.


use parent 'Neo4j::Driver::Result';

use Carp qw(croak);
our @CARP_NOT = qw(Neo4j::Driver::Net::HTTP Neo4j::Driver::Result);
use JSON::MaybeXS 1.002004 ();

use Neo4j::Driver::Type::Bytes;
use Neo4j::Driver::Type::DateTime;
use Neo4j::Driver::Type::Duration;
use Neo4j::Driver::Type::Node;
use Neo4j::Driver::Type::Path;
use Neo4j::Driver::Type::Point;
use Neo4j::Driver::Type::Relationship;
use Neo4j::Driver::Type::V1::Node;
use Neo4j::Driver::Type::V1::Relationship;
use Neo4j::Error;

my ($FALSE, $TRUE) = Neo4j::Driver::Result->_bool_values;

my $MEDIA_TYPE = "application/vnd.neo4j.jolt";
my $ACCEPT_HEADER = "$MEDIA_TYPE-v2+json-seq";
my $ACCEPT_HEADER_V1 = "$MEDIA_TYPE+json-seq";
my $ACCEPT_HEADER_STRICT = "$MEDIA_TYPE+json-seq;strict=true";
my $ACCEPT_HEADER_SPARSE = "$MEDIA_TYPE+json-seq;strict=false";
my $ACCEPT_HEADER_NDJSON = "$MEDIA_TYPE";

my @CYPHER_TYPES = (
	{  # Types with legacy numeric ID (Jolt v1)
		node => 'Neo4j::Driver::Type::V1::Node',
		relationship => 'Neo4j::Driver::Type::V1::Relationship',
	},
	{  # Types with element ID (Jolt v2)
		node => 'Neo4j::Driver::Type::Node',
		relationship => 'Neo4j::Driver::Type::Relationship',
	},
);


our $gather_results = 1;  # 1: detach from the stream immediately (yields JSON-style result; used for testing)


sub new {
	# uncoverable pod (private method)
	my ($class, $params) = @_;
	
	my $jolt_v2 = $params->{http_header}->{content_type} =~ m/^\Q$MEDIA_TYPE\E-v2\b/i;
	my $self = {
		attached => 1,   # 1: unbuffered records may exist on the stream
		exhausted => 0,  # 1: all records read by the client; fetch() will fail
		buffer => [],
		server_info => $params->{server_info},
		json_coder => $params->{http_agent}->json_coder,
		http_agent => $params->{http_agent},
		jolt_v2 => $jolt_v2,
	};
	bless $self, $class;
	
	return $self->_gather_results($params) if $gather_results;
	
	die "Unimplemented";  # $gather_results 0
}


sub _gather_results {
	my ($self, $params) = @_;
	
	my $error = 'Neo4j::Error';
	my @results = ();
	my $columns = undef;
	my @data = ();
	$self->{result} = {};
	my ($state, $prev) = (0, 'in first place');
	my ($type, $event);
	while ( ($type, $event) = $self->_next_event ) {
		if ($type eq 'header') {  # StatementStartEvent
			croak "Jolt error: unexpected header event $prev" unless $state == 0 || $state == 3;
			croak "Jolt error: expected reference to HASH, received " . (ref $event ? "reference to " . ref $event : "scalar") . " in $type event $prev" unless ref $event eq 'HASH';
			$state = 1;
			$columns = $event->{fields};
		}
		elsif ($type eq 'data') {  # RecordEvent
			croak "Jolt error: unexpected data event $prev" unless $state == 1 || $state == 2;
			croak "Jolt error: expected reference to ARRAY, received " . (ref $event ? "reference to " . ref $event : "scalar") . " in $type event $prev" unless ref $event eq 'ARRAY';
			$state = 2;
			push @data, { row => $event };
		}
		elsif ($type eq 'summary') {  # StatementEndEvent
			croak "Jolt error: unexpected summary event $prev" unless $state == 1 || $state == 2;
			croak "Jolt error: expected reference to HASH, received " . (ref $event ? "reference to " . ref $event : "scalar") . " in $type event $prev" unless ref $event eq 'HASH';
			$state = 3;
			push @results, {
				data => [@data],
				stats => $event->{stats},
				plan => $event->{plan},
				columns => $columns,
			};
			@data = ();
			$columns = undef;
		}
		elsif ($type eq 'info') {  # TransactionInfoEvent
			croak "Jolt error: unexpected info event $prev" unless $state == 0 || $state == 3 || $state == 4;
			croak "Jolt error: expected reference to HASH, received " . (ref $event ? "reference to " . ref $event : "scalar") . " in $type event $prev" unless ref $event eq 'HASH';
			$state += 10;
			$self->{info} = $event;
			$self->{notifications} = $event->{notifications};
		}
		elsif ($type eq 'error') {  # FailureEvent
			# If a rollback caused by a failure fails as well,
			# two failure events may appear on the Jolt stream.
			# Otherwise, there is always one at most.
			croak "Jolt error: expected reference to HASH, received " . (ref $event ? "reference to " . ref $event : "scalar") . " in $type event $prev" unless ref $event eq 'HASH';
			$state = 4;
			$error = $error->append_new(Internal => "Jolt error: Jolt $type event with 0 errors $prev") unless @{$event->{errors}};
			$error = $error->append_new(Server => $_) for @{$event->{errors}};
		}
		else {
			croak "Jolt error: unsupported $type event $prev";
		}
		$prev = "after $type event";
	}
	croak "Jolt error: unexpected end of event stream $prev" unless $state >= 10;
	
	if (! $params->{http_header}->{success}) {
		$error = $error->append_new(Network => {
			code => $params->{http_header}->{status},
			as_string => sprintf("HTTP error: %s %s on %s to %s", $params->{http_header}->{status}, $params->{http_agent}->http_reason, $params->{http_method}, $params->{http_path}),
		});
	}
	
	$self->{info}->{_error} = $error if ref $error;
	$self->{http_agent} = undef;
	
	if (@results == 1) {
		$self->{result} = $results[0];
		$self->{query} = $params->{queries}->[0];
		return $self->_as_fully_buffered;
	}
	
	# If the number of Cypher queries run wasn't exactly one, provide a list
	# of all results so that callers get a uniform interface for all of them.
	@results = map { __PACKAGE__->_new_result($_, undef, $params) } @results;
	$results[$_]->{query} = $params->{queries}->[$_] for (0 .. $#results);
	$self->{attached} = 0;
	$self->{exhausted} = 1;
	$self->{result_list} = \@results if @results;
	return $self;
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
		server_info => $params->{server_info},
		jolt_v2 => $params->{jolt_v2},
	};
	bless $self, $class;
	
	return $self->_as_fully_buffered;
}


sub _next_event {
	my ($self) = @_;
	
	my $line = $self->{http_agent}->fetch_event;
	return unless length $line;
	
	my $json = $self->{json_coder}->decode($line);
	
	my @events = keys %$json;
	croak "Jolt error: expected exactly 1 event, received " . scalar @events unless @events == 1;
	
	return ( $events[0], $json->{$events[0]} );
}


# Return the full list of results this object represents.
sub _results {
	my ($self) = @_;
	
	return @{ $self->{result_list} } if $self->{result_list};
	return ($self);
}


# Return transaction status information (if available).
sub _info {
	my ($self) = @_;
	return $self->{info};
}


# Bless and initialise the given reference as a Record.
sub _init_record {
	my ($self, $record) = @_;
	
	$record->{field_names_cache} = $self->{field_names_cache};
	$self->_deep_bless( $record->{row} );
	return bless $record, 'Neo4j::Driver::Record';
}


sub _deep_bless {
	my ($self, $data) = @_;
	
	if (JSON::MaybeXS::is_bool $data) {  # Boolean (sparse)
		return $data ? $TRUE : $FALSE;
	}
	if (ref $data eq 'ARRAY') {  # List (sparse)
		$_ = $self->_deep_bless($_) for @$data;
		return $data;
	}
	if (ref $data eq '') {  # Null or Integer (sparse) or String (sparse)
		return $data;
	}
	
	die "Assertion failed: sigil count: " . scalar keys %$data if scalar keys %$data != 1;
	my $sigil = (keys %$data)[0];
	my $value = $data->{$sigil};
	
	if ($sigil eq '?') {  # Boolean (strict)
		return $TRUE  if $value eq 'true';
		return $FALSE if $value eq 'false';
		die "Assertion failed: unexpected bool value: " . $value;
	}
	if ($sigil eq 'Z') {  # Integer (strict)
		return 0 + $value;
	}
	if ($sigil eq 'R') {  # Float
		return 0 + $value;
	}
	if ($sigil eq 'U') {  # String (strict)
		return $value;
	}
	if ($sigil eq '[]') {  # List (strict)
		$_ = $self->_deep_bless($_) for @$value;
		return $value;
	}
	if ($sigil eq '{}') {  # Map
		$_ = $self->_deep_bless($_) for values %$value;
		return $value;
	}
	if ($sigil eq '()') {  # Node
		die "Assertion failed: unexpected node fields: " . scalar @$value unless @$value == 3;
		$_ = $self->_deep_bless($_) for values %{ $value->[2] };
		return bless $value, $CYPHER_TYPES[ $self->{jolt_v2} ]->{node};
	}
	if ($sigil eq '->' || $sigil eq '<-') {  # Relationship
		die "Assertion failed: unexpected rel fields: " . scalar @$value unless @$value == 5;
		$_ = $self->_deep_bless($_) for values %{ $value->[4] };
		@{$value}[ 3, 1 ] = @{$value}[ 1, 3 ] if $sigil eq '<-';
		return bless $value, $CYPHER_TYPES[ $self->{jolt_v2} ]->{relationship};
	}
	if ($sigil eq '..') {  # Path
		die "Assertion failed: unexpected path fields: " . scalar @$value unless @$value & 1;
		$_ = $self->_deep_bless($_) for @$value;
		return bless $data, 'Neo4j::Driver::Type::Path';
	}
	if ($sigil eq '@') {  # Spatial
		return bless $data, 'Neo4j::Driver::Type::Point';
	}
	if ($sigil eq 'T') {  # Temporal
		return bless $data, $value =~ m/^-?P/
			? 'Neo4j::Driver::Type::Duration'
			: 'Neo4j::Driver::Type::DateTime';
	}
	if ($sigil eq '#') {  # Bytes
		$value =~ tr/ //d;  # spaces were allowed in the Jolt draft, but aren't actually implemented in Neo4j 4.2's jolt.JoltModule
		$value = pack 'H*', $value;  # see neo4j#12660
		return bless \$value, 'Neo4j::Driver::Type::Bytes';
	}
	
	die "Assertion failed: unexpected sigil: " . $sigil;
	
}


sub _accept_header {
	my (undef, $want_jolt, $method) = @_;
	
	return unless $method eq 'POST';  # work around Neo4j HTTP Content Negotiation bug #12644
	
	if (defined $want_jolt) {
		return if ! $want_jolt;
		return ($ACCEPT_HEADER_V1) if $want_jolt eq 'v1';
		return ($ACCEPT_HEADER_STRICT) if $want_jolt eq 'strict';
		return ($ACCEPT_HEADER_SPARSE) if $want_jolt eq 'sparse';
		return ($ACCEPT_HEADER_NDJSON) if $want_jolt eq 'ndjson';
	}
	return ($ACCEPT_HEADER);
}


sub _acceptable {
	my (undef, $content_type) = @_;
	
	return $content_type =~ m/^\Q$MEDIA_TYPE\E\b/i;
}


1;
