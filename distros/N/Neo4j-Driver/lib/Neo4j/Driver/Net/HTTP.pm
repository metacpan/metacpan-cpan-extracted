use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Net::HTTP;
# ABSTRACT: Network controller for Neo4j HTTP
$Neo4j::Driver::Net::HTTP::VERSION = '0.51';

# This package is not part of the public Neo4j::Driver API.


use Carp qw(carp croak);
our @CARP_NOT = qw(Neo4j::Driver::Transaction Neo4j::Driver::Transaction::HTTP);

use Time::Piece 1.20 qw();
use URI 1.31;

use Neo4j::Driver::Net::HTTP::LWP;
use Neo4j::Driver::Result::Jolt;
use Neo4j::Driver::Result::JSON;
use Neo4j::Driver::Result::Text;
use Neo4j::Driver::ServerInfo;


my $DISCOVERY_ENDPOINT = '/';
my $COMMIT_ENDPOINT = 'commit';

my @RESULT_MODULES = qw( Neo4j::Driver::Result::Jolt Neo4j::Driver::Result::JSON );
my $RESULT_FALLBACK = 'Neo4j::Driver::Result::Text';

my $RFC5322_DATE = '%a, %d %b %Y %H:%M:%S %z';  # strftime(3)


sub new {
	# uncoverable pod
	my ($class, $driver) = @_;
	
	$driver->{plugins}->{default_handlers}->{http_adapter_factory} //= sub {
		my $net_module = $driver->config('net_module') || 'Neo4j::Driver::Net::HTTP::LWP';
		return $net_module->new($driver);
	};
	my $http_adapter = $driver->{plugins}->trigger('http_adapter_factory', $driver);
	
	my $self = bless {
		events => $driver->{plugins},
		cypher_types => $driver->config('cypher_types'),
		server_info => $driver->{server_info},
		http_agent => $http_adapter,
		want_jolt => $driver->config('jolt'),
		want_concurrent => $driver->config('concurrent_tx') // 0,
		active_tx => {},
	}, $class;
	
	return $self;
}


# Use Neo4j Discovery API to obtain both ServerInfo and the
# transaction endpoint templates.
sub _server {
	my ($self) = @_;
	
	my ($neo4j_version, $tx_endpoint);
	my @discovery_queue = ($DISCOVERY_ENDPOINT);
	while (@discovery_queue) {
		my $events = $self->{events};
		my $tx = {
			error_handler => sub { $events->trigger(error => shift) },
			transaction_endpoint => shift @discovery_queue,
		};
		my $service = $self->_request($tx, 'GET')->_json;
		
		$neo4j_version = $service->{neo4j_version};
		$tx_endpoint = $service->{transaction};
		last if $neo4j_version && $tx_endpoint;
		
		# a different discovery endpoint existed in Neo4j < 4.0
		if ($service->{data}) {
			push @discovery_queue, URI->new( $service->{data} )->path;
		}
	}
	
	croak "Neo4j server not found (ServerInfo discovery failed)" unless $neo4j_version;
	
	my $date = $self->{http_agent}->date_header;
	$date =~ s/ GMT$/ +0000/;
	$date = $date ? Time::Piece->strptime($date, $RFC5322_DATE) : Time::Piece->new;
	
	$self->{server_info} = Neo4j::Driver::ServerInfo->new({
		uri => $self->{http_agent}->uri,
		version => "Neo4j/$neo4j_version",
		time_diff => Time::Piece->new - $date,
		tx_endpoint => $tx_endpoint,
	});
	
	return $self->{server_info};
}


# Update requested database name based on transaction endpoint templates.
sub _set_database {
	my ($self, $database) = @_;
	
	my $tx_endpoint = $self->{server_info}->{tx_endpoint};
	$self->{endpoints} = {
		new_transaction => "$tx_endpoint",
		new_commit => "$tx_endpoint/$COMMIT_ENDPOINT",
	} if $tx_endpoint;
	
	return unless defined $database;
	$database = URI::Escape::uri_escape_utf8 $database;
	$self->{endpoints}->{new_transaction} =~ s/\{databaseName}/$database/;
	$self->{endpoints}->{new_commit} =~ s/\{databaseName}/$database/;
}


# Send statements to the Neo4j server and return a list of all results.
sub _run {
	my ($self, $tx, @statements) = @_;
	
	if ( %{$self->{active_tx}} && ! $self->{want_concurrent} ) {
		my $is_concurrent = ! defined $tx->{commit_endpoint} || keys %{$self->{active_tx}} > 1;
		$is_concurrent and carp "Concurrent transactions for HTTP are disabled; use multiple sessions or enable the concurrent_tx config option (this warning will be fatal in Neo4j::Driver 1.xx)";
	}
	
	my $json = { statements => \@statements };
	return $self->_request($tx, 'POST', $json)->_results;
}


# Determine the Accept HTTP header that is appropriate for the specified
# request method. Accept headers are cached in $self->{accept_for}.
sub _accept_for {
	my ($self, $method) = @_;
	
	$self->{want_jolt} = 'v1' if ! defined $self->{want_jolt}
		&& $self->{server_info} && $self->{server_info}->{version} =~ m{^Neo4j/4\.[234]\.};
	
	# GET requests may fail if Neo4j sees clients that support Jolt, see neo4j #12644
	my @modules = @RESULT_MODULES;
	unshift @modules, $self->{http_agent}->result_handlers if $self->{http_agent}->can('result_handlers');
	my @accept = map { $_->_accept_header( $self->{want_jolt}, $method ) } @modules;
	return $self->{accept_for}->{$method} = join ', ', @accept;
}


# Determine a result handler module that is appropriate for the specified
# media type. Result handlers are cached in $self->{result_module_for}.
sub _result_module_for {
	my ($self, $content_type) = @_;
	
	my @modules = @RESULT_MODULES;
	unshift @modules, $self->{http_agent}->result_handlers if $self->{http_agent}->can('result_handlers');
	foreach my $module (@modules) {
		if ($module->_acceptable($content_type)) {
			return $self->{result_module_for}->{$content_type} = $module;
		}
	}
	return $RESULT_FALLBACK;
}


# Send a HTTP request to the Neo4j server and return a representation
# of the response.
sub _request {
	my ($self, $tx, $method, $json) = @_;
	
	if (! defined $tx->{transaction_endpoint}) {
		$tx->{transaction_endpoint} = URI->new( $self->{endpoints}->{new_transaction} )->path;
	}
	my $tx_endpoint = "$tx->{transaction_endpoint}";
	my $accept = $self->{accept_for}->{$method}
	             // $self->_accept_for($method);
	
	$self->{http_agent}->request($method, $tx_endpoint, $json, $accept, $tx->{mode});
	
	my $header = $self->{http_agent}->http_header;
	my $result_module = $self->{result_module_for}->{ $header->{content_type} }
	                    // $self->_result_module_for( $header->{content_type} );
	
	my $result = $result_module->new({
		http_agent => $self->{http_agent},
		http_method => $method,
		http_path => $tx_endpoint,
		http_header => $header,
		cypher_types => $self->{cypher_types},
		server_info => $self->{server_info},
		statements => $json ? $json->{statements} : [],
	});
	
	my $info = $result->_info;
	$self->_parse_tx_status($tx, $header, $info);
	$tx->{error_handler}->($info->{_error}) if $info->{_error};
	return $result;
}


# Update list of active transactions and update transaction endpoints.
sub _parse_tx_status {
	my ($self, $tx, $header, $info) = @_;
	
	# In case of errors, HTTP transaction status info is only reliable for
	# server errors that aren't reported as network errors. (neo4j #12651)
	if (my $error = $info->{_error}) {
		return if $error->source ne 'Server';
		do { return if $error->source eq 'Network' } while $error = $error->related;
	}
	
	$tx->{unused} = 0;
	$tx->{closed} = ! $info->{commit} || ! $info->{transaction};
	
	if ( $tx->{closed} ) {
		my $old_endpoint = $tx->{transaction_endpoint};
		$old_endpoint =~ s|/$COMMIT_ENDPOINT$||;  # both endpoints may be set to /commit (for autocommit), so we need to remove that here
		delete $self->{active_tx}->{ $old_endpoint };
		return;
	}
	if ( $header->{location} && $header->{status} eq '201' ) {  # Created
		my $new_commit = URI->new( $info->{commit} )->path_query;
		my $new_endpoint = URI->new( $header->{location} )->path_query;
		$tx->{commit_endpoint} = $new_commit;
		$tx->{transaction_endpoint} = $new_endpoint;
	}
	if ( my $expires = $info->{transaction}->{expires} ) {
		$expires =~ s/ GMT$/ +0000/;
		$expires = Time::Piece->strptime($expires, $RFC5322_DATE) + $self->{server_info}->{time_diff};
		$self->{active_tx}->{ $tx->{transaction_endpoint} } = $expires;
	}
}


# Query list of active transactions, removing expired ones.
sub _is_active_tx {
	my ($self, $tx) = @_;
	
	my $now = Time::Piece->new;
	foreach my $tx_key ( keys %{$self->{active_tx}} ) {
		my $expires = $self->{active_tx}->{$tx_key};
		delete $self->{active_tx}->{$tx_key} if $now > $expires;
	}
	
	my $tx_endpoint = $tx->{transaction_endpoint};
	$tx_endpoint =~ s|/$COMMIT_ENDPOINT$||;  # for tx in the (auto)commit state, both endpoints are set to commit
	return exists $self->{active_tx}->{ $tx_endpoint };
}


1;
