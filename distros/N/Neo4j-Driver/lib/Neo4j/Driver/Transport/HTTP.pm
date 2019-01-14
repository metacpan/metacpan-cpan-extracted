use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Transport::HTTP;
# ABSTRACT: Adapter for the Neo4j Transactional HTTP API
$Neo4j::Driver::Transport::HTTP::VERSION = '0.11';

use Carp qw(carp croak);
our @CARP_NOT = qw(Neo4j::Driver::Transaction);
use Try::Tiny;

use URI 1.25;
use REST::Client 134;
use JSON::PP qw();
use Cpanel::JSON::XS 3.0201;

use Neo4j::Driver::ResultSummary;
use Neo4j::Driver::StatementResult;


# https://neo4j.com/docs/http-api/current/
our $TRANSACTION_ENDPOINT = '/db/data/transaction';
our $COMMIT_ENDPOINT = '/db/data/transaction/commit';
our $CONTENT_TYPE = 'application/json; charset=UTF-8';

# https://neo4j.com/docs/rest-docs/current/#rest-api-service-root
our $SERVICE_ROOT_ENDPOINT = '/db/data/';


sub new {
	my ($class, $driver) = @_;
	
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
	$client->addHeader('Accept', $CONTENT_TYPE);
	$client->addHeader('Content-Type', $CONTENT_TYPE);
	$client->addHeader('X-Stream', 'true');
	
	return bless {
		client => $client,
		die_on_error => $driver->{die_on_error},
	}, $class;
}


# Prepare query statement, including parameters. When multiple statements
# are to be combined in a single server communication, this method allows
# preparing each statement individually.
sub prepare {
	my ($self, $tx, $query, $parameters) = @_;
	
	my $json = { statement => '' . $query };
	$json->{resultDataContents} = [ "row", "graph" ] if $self->{return_graph};
	$json->{includeStats} = JSON::PP::true if $self->{return_stats};
	$json->{parameters} = $parameters if defined $parameters;
	
	return $json;
}


# Send statements to the Neo4j server and return all results. Will either
# continue to use the existing open server transaction or create a new one
# (iff the server transaction is not yet open).
sub run {
	my ($self, $tx, @statements) = @_;
	
	my $request = { statements => \@statements };
	
	# TIMTOWTDI: REST::Neo4p::Query uses Tie::IxHash and JSON::XS, which may be faster than sorting
	my $coder = JSON::PP->new->utf8;
	$coder = $coder->pretty->sort_by(sub {
		return -1 if $JSON::PP::a eq 'statements';
		return 1 if $JSON::PP::b eq 'statements';
		return 0;  # $JSON::PP::a cmp $JSON::PP::b;
	});
	
	my $response = $self->_request($tx, 'POST', $coder->encode($request));
	
	my @results = ();
	my $result_count = defined $response->{results} ? @{$response->{results}} : 0;
	for (my $i = 0; $i < $result_count; $i++) {
		my $result = $response->{results}->[$i];
		my $summary = Neo4j::Driver::ResultSummary->new( $result, $response, $statements[$i] );
		push @results, Neo4j::Driver::StatementResult->new( $result, $summary );
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
			$response = decode_json $client->responseContent();
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
	
	my $json = $self->{client}->GET( $SERVICE_ROOT_ENDPOINT )->responseContent();
	my $neo4j_version = decode_json($json)->{neo4j_version};
	return "Neo4j/$neo4j_version";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Transport::HTTP - Adapter for the Neo4j Transactional HTTP API

=head1 VERSION

version 0.11

=head1 DESCRIPTION

The L<Neo4j::Driver::Transport::HTTP> package is not part of the
public L<Neo4j::Driver> API.

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2019 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
