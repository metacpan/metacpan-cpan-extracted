use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Transport::HTTP;
# ABSTRACT: Adapter for the Neo4j Transactional HTTP API
$Neo4j::Driver::Transport::HTTP::VERSION = '0.15';

use Carp qw(carp croak);
our @CARP_NOT = qw(Neo4j::Driver::Transaction);
use Try::Tiny;

use URI 1.25;
use REST::Client 134;
use JSON::MaybeXS qw();

use Neo4j::Driver::ResultSummary;
use Neo4j::Driver::StatementResult;


our $JSON_CODER;
BEGIN { $JSON_CODER = sub {
	return JSON::MaybeXS->new(utf8 => 1, allow_nonref => 0);
}}

# https://neo4j.com/docs/http-api/current/
our $TRANSACTION_ENDPOINT = '/db/data/transaction';
our $COMMIT_ENDPOINT = '/db/data/transaction/commit';
our $CONTENT_TYPE = 'application/json';

# https://neo4j.com/docs/rest-docs/current/#rest-api-service-root
our $SERVICE_ROOT_ENDPOINT = '/db/data/';

# use 'rest' in place of broken 'meta', see neo4j #12306
our $RESULT_DATA_CONTENTS = ['row', 'rest'];
our $RESULT_DATA_CONTENTS_GRAPH = ['row', 'rest', 'graph'];

our $detach_stream = 1;  # set to 0 to have StatementResult simulate an attached stream (used for testing)


sub new {
	my ($class, $driver) = @_;
	
	my $self = bless {
		die_on_error => $driver->{die_on_error},
		cypher_types => $driver->{cypher_types},
		cypher_filter => $driver->{cypher_filter},
	}, $class;
	
	my $uri = $driver->{uri};
	if ($driver->{auth}) {
		croak "Only HTTP Basic Authentication is supported" if $driver->{auth}->{scheme} ne 'basic';
		$uri = $uri->clone;
		$uri->userinfo( $driver->{auth}->{principal} . ':' . $driver->{auth}->{credentials} );
	}
	
	my $client = REST::Client->new({
		host => "$uri",
		timeout => $driver->{http_timeout},
		follow => 1,
	});
	if ($uri->scheme eq 'https') {
		$client->setCa($driver->{tls_ca});
		croak "HTTPS does not support unencrypted communication; use HTTP" if defined $driver->{tls} && ! $driver->{tls};
	}
	else {
		croak "HTTP does not support encrypted communication; use HTTPS" if $driver->{tls};
	}
	$client->addHeader('Accept', $CONTENT_TYPE);
	$client->addHeader('Content-Type', $CONTENT_TYPE);
	$client->addHeader('X-Stream', 'true');
	$self->{client} = $client;
	
	$self->{json_coder} = $JSON_CODER->();
	
	$driver->{client_factory}->($self) if $driver->{client_factory};  # used for testing
	
	return $self;
}


# Prepare query statement, including parameters. When multiple statements
# are to be combined in a single server communication, this method allows
# preparing each statement individually.
sub prepare {
	my ($self, $tx, $query, $parameters) = @_;
	
	if ($self->{cypher_filter}) {
		croak "Unimplemented cypher filter '$self->{cypher_filter}'" if $self->{cypher_filter} ne 'params';
		if (defined $parameters) {
			my $params = join '|', keys %$parameters;
			$query =~ s/{($params)}/\$$1/g;
		}
	}
	
	my $json = { statement => '' . $query };
	$json->{resultDataContents} = $RESULT_DATA_CONTENTS;
	$json->{resultDataContents} = $RESULT_DATA_CONTENTS_GRAPH if $self->{return_graph};
	$json->{includeStats} = JSON::MaybeXS::true if $self->{return_stats};
	$json->{parameters} = $parameters if defined $parameters;
	
	return $json;
}


# Send statements to the Neo4j server and return all results. Will either
# continue to use the existing open server transaction or create a new one
# (iff the server transaction is not yet open).
sub run {
	my ($self, $tx, @statements) = @_;
	
	# The ordering of the $request hash's keys is significant: Neo4j
	# requires 'statements' to be the first member in the JSON object.
	# Luckily, in recent versions of Neo4j, it is also the only member.
	my $request = { statements => \@statements };
	
	my $json = $self->{json_coder}->encode($request);
	my $response = $self->_request($tx, 'POST', $json);
	
	my @results = ();
	my $result_count = defined $response->{results} ? @{$response->{results}} : 0;
	for (my $i = 0; $i < $result_count; $i++) {
		push @results, Neo4j::Driver::StatementResult->new({
			json => $response->{results}->[$i],
			notifications => $response->{notifications},
			statement => $statements[$i],
			deep_bless => \&_deep_bless,
			detach_stream => $detach_stream,
			cypher_types => $self->{cypher_types},
		});
	}
	return @results;
}


sub _request {
	my ($self, $tx, $method, $content) = @_;
	
	my $client = $self->{client};
	
	my $tx_endpoint = $tx->{transaction_endpoint} // URI->new( $TRANSACTION_ENDPOINT );
	$client->request( $method, "$tx_endpoint", $content );
	
	my $content_type = $client->responseHeader('Content-Type');
	my $response;
	my @errors = ();
	if ($client->responseCode() =~ m/^[^2]\d\d$/) {
		push @errors, 'Network error: ' . $client->{_res}->status_line;  # there is no other way than using {_res} to get the error message
		if ($content_type && $content_type =~ m|^text/plain\b|) {
			push @errors, $client->responseContent();
		}
		elsif ($self->{die_on_error}) {
			croak $errors[0];
		}
	}
	if ($content_type && $content_type =~ m|^application/json\b|) {
		try {
			$response = $self->{json_coder}->decode( $client->responseContent() );
			$tx->{commit_endpoint} = URI->new($response->{commit})->path_query if $response->{commit};
			$tx->{commit_endpoint} = undef unless $response->{transaction};
			$tx->{open} = 0 unless $tx->{commit_endpoint};
		}
		catch {
			push @errors, $_;
		};
	}
	else {
		push @errors, "Received " . ($content_type ? $content_type : "empty") . " content from database server; skipping JSON decode";
	}
	foreach my $error (@{$response->{errors}}) {
		push @errors, "$error->{code}:\n$error->{message}";
	}
	if (@errors) {
		my $errors = join "\n", @errors;
		croak $errors if $self->{die_on_error};
		carp $errors;
	}
	
	if ($client->responseCode() eq '201') {  # Created
		my $location = $client->responseHeader('Location');
		$tx->{transaction_endpoint} = URI->new($location)->path_query if $location;
	}
	return $response;
}


# Declare that the specified transaction should be treated as an explicit
# transaction (i. e. it is opened at this time and will be closed by
# explicit command from the client).
sub begin {
}


# Declare that the specified transaction should be treated as an autocommit
# transaction (i. e. it should automatically close successfully when the
# next statement is run).
sub autocommit {
	my ($self, $tx) = @_;
	
	$tx->{transaction_endpoint} = $tx->{commit_endpoint} // URI->new( $COMMIT_ENDPOINT );
}


# Mark the specified server transaction as successful and close it.
sub commit {
	my ($self, $tx) = @_;
	
	$self->autocommit($tx);
	$tx->run;
}


# Mark the specified server transaction as failed and close it.
sub rollback {
	my ($self, $tx) = @_;
	
	# Explicitly marking this transaction as closed by removing the commit
	# URL is only necessary for transactions that never have been used.
	# These would initially contact the server's root transaction endpoint,
	# DELETE'ing which fails (as it should). But calling rollback on an
	# open transaction should never fail. Hence we need to special-case
	# this scenario here.
	$self->_request($tx, 'DELETE') if $tx->{transaction_endpoint};
}


sub server_info {
	my ($self) = @_;
	
	# That the ServerInfo is provided by the same object
	# is an implementation detail that might change in future.
	return $self;
}


# server_info->
sub address {
	my ($self) = @_;
	
	return URI->new( $self->{client}->getHost() )->host_port;
}


# server_info->
sub version {
	my ($self) = @_;
	
	foreach my $endpoint ( '/', $SERVICE_ROOT_ENDPOINT ) {
		my $json = $self->{client}->GET( $endpoint )->responseContent();
		my $neo4j_version = $self->{json_coder}->decode($json)->{neo4j_version};
		return "Neo4j/$neo4j_version" if $neo4j_version;
	}
}


sub _deep_bless {
	my ($cypher_types, $data, $meta, $rest) = @_;
	
	# "meta" is broken, so we primarily use "rest", see neo4j #12306
	
	if (ref $data eq 'HASH' && ref $rest eq 'HASH' && ref $rest->{metadata} eq 'HASH' && $rest->{self} && $rest->{self} =~ m|/db/data/node/|) {  # node
		bless $data, $cypher_types->{node};
		$data->{_meta} = $rest->{metadata};
		$data->{_meta}->{deleted} = $meta->{deleted} if ref $meta eq 'HASH';
		$cypher_types->{init}->($data) if $cypher_types->{init};
		return $data;
	}
	if (ref $data eq 'HASH' && ref $rest eq 'HASH' && ref $rest->{metadata} eq 'HASH' && $rest->{self} && $rest->{self} =~ m|/db/data/relationship/|) {  # relationship
		bless $data, $cypher_types->{relationship};
		$data->{_meta} = $rest->{metadata};
		$rest->{start} =~ m|/([0-9]+)$|;
		$data->{_meta}->{start} = 0 + $1;
		$rest->{end} =~ m|/([0-9]+)$|;
		$data->{_meta}->{end} = 0 + $1;
		$data->{_meta}->{deleted} = $meta->{deleted} if ref $meta eq 'HASH';
		$cypher_types->{init}->($data) if $cypher_types->{init};
		return $data;
	}
	
	if (ref $data eq 'ARRAY' && ref $rest eq 'HASH') {  # path
		die "Assertion failed: path length mismatch: ".(scalar @$data).">>1/$rest->{length}" if @$data >> 1 != $rest->{length};  # uncoverable branch true
		for my $n ( 0 .. $#{ $rest->{nodes} } ) {
			my $i = $n * 2;
			my $uri = $rest->{nodes}->[$n];
			$uri =~ m|/([0-9]+)$|;
			$data->[$i]->{_meta} = { id => 0 + $1 };
			$data->[$i]->{_meta}->{deleted} = $meta->[$i]->{deleted} if ref $meta eq 'ARRAY';
			$data->[$i] = bless $data->[$i], 'Neo4j::Driver::Type::Node';
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
			$data->[$i] = bless $data->[$i], 'Neo4j::Driver::Type::Relationship';
		}
		bless $data, $cypher_types->{path};
		$cypher_types->{init}->($data) if $cypher_types->{init};
		return $data;
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
			$data->[$i] = _deep_bless($cypher_types, $data->[$i], $meta->[$i], $rest->[$i]);
		}
		return $data;
	}
	if (ref $data eq 'HASH' && ref $rest eq 'HASH') {  # and neither node nor relationship nor spatial ==> map
		die "Assertion failed: map rest size mismatch" if (scalar keys %$data) != (scalar keys %$rest);  # uncoverable branch true
		die "Assertion failed: map rest keys mismatch" if (join '', sort keys %$data) ne (join '', sort keys %$rest);  # uncoverable branch true
		$meta = {} if ref $meta ne 'HASH' || (scalar keys %$data) != (scalar keys %$meta);  # handle neo4j #12306
		foreach my $key ( keys %$data ) {
			$data->{$key} = _deep_bless($cypher_types, $data->{$key}, $meta->{$key}, $rest->{$key});
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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Transport::HTTP - Adapter for the Neo4j Transactional HTTP API

=head1 VERSION

version 0.15

=head1 DESCRIPTION

The L<Neo4j::Driver::Transport::HTTP> package is not part of the
public L<Neo4j::Driver> API.

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2020 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
