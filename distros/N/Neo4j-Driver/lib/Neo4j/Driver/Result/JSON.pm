use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Result::JSON;
# ABSTRACT: JSON/REST result handler
$Neo4j::Driver::Result::JSON::VERSION = '0.23';

use parent 'Neo4j::Driver::Result';

use Carp qw(carp croak);
our @CARP_NOT = qw(Neo4j::Driver::Net::HTTP);
use Try::Tiny;

use JSON::MaybeXS 1.003003 ();
use URI 1.31;


our $MEDIA_TYPE = "application/json";
our $ACCEPT_HEADER = "$MEDIA_TYPE";


sub new {
	my ($class, $params) = @_;
	
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
	
	my @errors = ();
	if (! $params->{http_header}->{success}) {
		my $reason_phrase = $params->{http_agent}->http_reason;
		push @errors, "HTTP error: $params->{http_header}->{status} $reason_phrase on $params->{http_method} to $params->{http_path}";
	}
	
	my $json;
	try {
		$json = $params->{http_agent}->json_coder->decode($response);
	}
	catch {
		push @errors, $_;
		$json = {};
	};
	if (ref $json->{errors} eq 'ARRAY') {
		foreach my $error (@{$json->{errors}}) {
			$error = "$error->{code}: $error->{message}" if ref $error eq 'HASH';
			push @errors, $error;
		}
	}
	
	if (@errors) {
		croak join "\n", @errors if $params->{die_on_error};
		carp join "\n", @errors;
	}
	
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
	if ( JSON::MaybeXS::is_bool($data) && JSON::MaybeXS::is_bool($rest) ) {  # boolean
		return $data;
	}
	
	die "Assertion failed: unexpected type combo: " . ref($data) . "/" . ref($rest);  # uncoverable statement
}


# Return a list of the media types this module can handle, fit for
# use in an HTTP Accept header field.
sub _accept_header {
	my (undef, $want_jolt, $http_method) = @_;
	
	return if $want_jolt;
	return ($ACCEPT_HEADER);
}


# Whether the given media type can be handled by this module.
sub _acceptable {
	my (undef, $content_type) = @_;
	
	return $content_type =~ m/^$MEDIA_TYPE\b/i;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Result::JSON - JSON/REST result handler

=head1 VERSION

version 0.23

=head1 DESCRIPTION

The L<Neo4j::Driver::Result::JSON> package is not part of the
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
