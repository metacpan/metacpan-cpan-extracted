use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Result::Jolt;
# ABSTRACT: Jolt result handler
$Neo4j::Driver::Result::Jolt::VERSION = '0.21';

use parent 'Neo4j::Driver::Result';

use Carp qw(carp croak);
our @CARP_NOT = qw(Neo4j::Driver::Net::HTTP Neo4j::Driver::Result);

use JSON::MaybeXS 1.003003 ();


our $MEDIA_TYPE = "application/vnd.neo4j.jolt+json-seq";
our $ACCEPT_HEADER = "$MEDIA_TYPE";
our $ACCEPT_HEADER_STRICT = "$MEDIA_TYPE;strict=true";
our $ACCEPT_HEADER_SPARSE = "$MEDIA_TYPE;strict=false";


our $gather_results = 1;  # 1: detach from the stream immediately (yields JSON-style result; used for testing)


sub new {
	my ($class, $params) = @_;
	
	my $self = {
		attached => 1,   # 1: unbuffered records may exist on the stream
		exhausted => 0,  # 1: all records read by the client; fetch() will fail
		buffer => [],
		server_info => $params->{server_info},
		json_coder => $params->{http_agent}->json_coder,
		http_agent => $params->{http_agent},
		cypher_types => $params->{cypher_types},
	};
	bless $self, $class;
	
	return $self->_gather_results($params) if $gather_results;
	
	die "Unimplemented";  # $gather_results 0
}


sub _gather_results {
	my ($self, $params) = @_;
	
	my @errors = ();
	if (! $params->{http_header}->{success}) {
		my $reason_phrase = $params->{http_agent}->http_reason;
		push @errors, "HTTP error: $params->{http_header}->{status} $reason_phrase on $params->{http_method} to $params->{http_path}";
	}
	
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
			push @data, { row => $event, meta => [] };
		}
		elsif ($type eq 'summary') {  # StatementEndEvent
			croak "Jolt error: unexpected summary event $prev" unless $state == 1 || $state == 2;
			croak "Jolt error: expected reference to HASH, received " . (ref $event ? "reference to " . ref $event : "scalar") . " in $type event $prev" unless ref $event eq 'HASH';
			$state = 3;
			push @results, {
				data => [@data],
				stats => $event->{stats},
				plan => $event->{plan},
				columns => $columns // [],
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
			carp "Jolt error: unexpected error event $prev" unless $state == 0 || $state == 3;
			croak "Jolt error: expected reference to HASH, received " . (ref $event ? "reference to " . ref $event : "scalar") . " in $type event $prev" unless ref $event eq 'HASH';
			$state = 4;
			push @errors, "Jolt error: Jolt $type event with 0 errors $prev" unless @{$event->{errors}};
			push @errors, map {"$_->{code}: $_->{message}"} @{$event->{errors}};
		}
		else {
			croak "Jolt error: unsupported $type event $prev";
		}
		$prev = "after $type event";
	}
	croak "Jolt error: unexpected end of event stream $prev" unless $state >= 10;
	croak join "\n", @errors if @errors;
	$self->{http_agent} = undef;
	
	if (@results == 1) {
		$self->{result} = $results[0];
		$self->{statement} = $params->{statements}->[0];
		return $self->_as_fully_buffered;
	}
	
	# If the number of Cypher statements run wasn't exactly one, provide a list
	# of all results so that callers get a uniform interface for all of them.
	@results = map { __PACKAGE__->_new_result($_, undef, $params) } @results;
	$results[$_]->{statement} = $params->{statements}->[$_] for (0 .. $#results);
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
		columns => undef,
		summary => undef,
		cypher_types => $params->{cypher_types},
		server_info => $params->{server_info},
	};
	bless $self, $class;
	
	return $self->_as_fully_buffered;
}


sub _next_event {
	my ($self) = @_;
	
	my $line = $self->{http_agent}->fetch_event;
	return unless defined $line;
	
	my $json = $self->{json_coder}->decode($line);
	croak "Jolt error: expected reference to HASH, received " . (ref $json ? "reference to " . ref $json : "scalar") unless ref $json eq 'HASH';
	
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
	
	$record->{column_keys} = $self->{columns};
	$self->_deep_bless( $record->{row} );
	return bless $record, 'Neo4j::Driver::Record';
}


sub _deep_bless {
	my ($self, $data) = @_;
	my $cypher_types = $self->{cypher_types};
	
	if (ref $data eq 'ARRAY') {  # List (sparse)
		$data->[$_] = $self->_deep_bless($data->[$_]) for 0 .. $#{$data};
		return $data;
	}
	if (ref $data eq '') {  # Integer (sparse) or String (sparse)
		return $data;
	}
	if (JSON::MaybeXS::is_bool $data) {  # Boolean (sparse)
		return $data;
	}
	
	die "Assertion failed: unexpected type: " . ref $data unless ref $data eq 'HASH';
	die "Assertion failed: sigil count: " . scalar keys %$data if scalar keys %$data != 1;
	my $sigil = (keys %$data)[0];
	my $value = $data->{$sigil};
	
	if ($sigil eq '?') {  # Boolean (strict)
		# TODO: check if this is supported by early JSON::MaybeXS versions with all backends
		return $self->{json_coder}->true if $value eq 'true';
		return $self->{json_coder}->false if $value eq 'false';
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
		die "Assertion failed: unexpected list type: " . ref $value unless ref $value eq 'ARRAY';
		$value->[$_] = $self->_deep_bless($value->[$_]) for 0 .. $#{$value};
		return $value;
	}
	if ($sigil eq '{}') {  # Map
		die "Assertion failed: unexpected map type: " . ref $value unless ref $value eq 'HASH';
		delete $data->{'{}'};
		$data->{$_} = $self->_deep_bless($value->{$_}) for keys %$value;
		return $data;
	}
	if ($sigil eq '()') {  # Node
		die "Assertion failed: unexpected node type: " . ref $value unless ref $value eq 'ARRAY';
		die "Assertion failed: unexpected node fields: " . scalar @$value unless @$value == 3;
		die "Assertion failed: unexpected prop type: " . ref $value->[2] unless ref $value->[2] eq 'HASH';
		my $props = $value->[2];
		$props->{$_} = $self->_deep_bless($props->{$_}) for keys %$props;
		my $node = \( $props );
		bless $node, $cypher_types->{node};
		$$node->{_meta} = {
			id => $value->[0],
			labels => $value->[1],
		};
		$cypher_types->{init}->($node) if $cypher_types->{init};
		return $node;
	}
	if ($sigil eq '->' || $sigil eq '<-') {  # Relationship
		die "Assertion failed: unexpected rel type: " . ref $value unless ref $value eq 'ARRAY';
		die "Assertion failed: unexpected rel fields: " . scalar @$value unless @$value == 5;
		die "Assertion failed: unexpected prop type: " . ref $value->[4] unless ref $value->[4] eq 'HASH';
		my $props = $value->[4];
		$props->{$_} = $self->_deep_bless($props->{$_}) for keys %$props;
		my $rel = \( $props );
		bless $rel, $cypher_types->{relationship};
		$$rel->{_meta} = {
			id => $value->[0],
			type => $value->[2],
			start => $sigil eq '->' ? $value->[1] : $value->[3],
			end => $sigil eq '->' ? $value->[3] : $value->[1],
		};
		$cypher_types->{init}->($rel) if $cypher_types->{init};
		return $rel;
	}
	if ($sigil eq '..') {  # Path
		die "Assertion failed: unexpected path type: " . ref $value unless ref $value eq 'ARRAY';
		die "Assertion failed: unexpected path fields: " . scalar @$value unless @$value & 1;
		$value->[$_] = $self->_deep_bless($value->[$_]) for 0 .. $#{$value};
		my $path = bless { path => $value }, $cypher_types->{path};
		$cypher_types->{init}->($path) if $cypher_types->{init};
		return $path;
	}
	if ($sigil eq '@') {  # Spatial
		# TODO
		bless $data, $cypher_types->{point};
		return $data;
	}
	if ($sigil eq 'T') {  # Temporal
		# TODO
		bless $data, $cypher_types->{temporal};
		return $data;
	}
	if ($sigil eq '#') {  # Bytes
		$value =~ tr/ //d;  # spaces were allowed in the Jolt draft, but aren't actually implemented in Neo4j 4.2's jolt.JoltModule
		$value = pack 'H*', $value;  # see neo4j#12660
		utf8::downgrade($value);  # UTF8 flag should be off already, but let's make sure
		return $value;
	}
	
	die "Assertion failed: unexpected sigil: " . $sigil;
	
}


sub _accept_header {
	my ($class, $request_jolt, $method) = @_;
	
	return unless $method eq 'POST';  # work around Neo4j HTTP Content Negotiation bug #12644
	
	if (defined $request_jolt) {
		return if ! $request_jolt;
		return ($ACCEPT_HEADER_STRICT) if $request_jolt eq 'strict';
		return ($ACCEPT_HEADER_SPARSE) if $request_jolt eq 'sparse';
	}
	return ($ACCEPT_HEADER);
}


sub _acceptable {
	my ($class, $content_type) = @_;
	
	return $content_type =~ m/^\Q$MEDIA_TYPE\E\b/i;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Result::Jolt - Jolt result handler

=head1 VERSION

version 0.21

=head1 DESCRIPTION

The L<Neo4j::Driver::Result::Jolt> package is not part of the
public L<Neo4j::Driver> API.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver::Net>

=item * L<Neo4j::Driver::Result>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2021 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
