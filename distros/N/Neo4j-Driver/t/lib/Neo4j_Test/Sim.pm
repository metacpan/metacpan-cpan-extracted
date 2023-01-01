package Neo4j_Test::Sim;
use strict;
use warnings;

use Carp qw(croak);
use JSON::PP qw(decode_json);
use Digest::MD5;
use File::Basename qw(dirname);
use File::Slurp;
use URI;
use Neo4j_Test;

my $path = (dirname dirname dirname __FILE__) . "/simulator";
my $hash_url = 0;  # not 100% sure if 0 produces correct results, but it might increase maintainability ... and it _looks_ okay!


sub new {
	my ($class, $options) = @_;
	$options->{cypher_params_v2} = 1;  # sim uses old param syntax
	return $class if ref $class;  # if the net_module is an object, it'll a pre-configured Neo4j_Test::Sim
	my $self = bless {
		auth => $options->{auth} // 1,
	}, $class;
	return $self;
}


sub result_handlers {}


sub request {
	my ($self, $method, $url, $content) = @_;
	
	$content = $self->json_coder->encode($content) if $content;
	$url = "$url";
	
	return $self->not_authenticated() unless $self->{auth};
	if ($method eq 'DELETE') {
		$self->{status} = 204;  # HTTP: No Content
		return $self;
	}
	return $self->GET($url) if $method eq 'GET';
	return $self->not_implemented($method, $url) unless $method eq 'POST';
	return $self->not_found($url) if $url !~ m(^/db/(?:data|neo4j|system)/(?:transaction|tx)\b);
	
	my $hash = request_hash($url, $content);
	my $file = "$path/$hash.json";
	if (! -f $file || ! -r $file) {
		return $self->not_implemented($method, $url, $file);
	}
	$self->{json} = File::Slurp::read_file $file;
	$self->{status} = 201;  # HTTP: Created
	# always use 201 so that the Location header is picked up by the Transaction
}


sub GET {
	my ($self, $url, $headers) = @_;
	if ($url ne '/') {
		return $self->not_implemented('GET', $url);
	}
	my $neo4j_version = '"neo4j_version":"0.0.0"';
	my $transaction = '"transaction":"/db/data/transaction"';
	$self->{json} = "{$neo4j_version,$transaction}";
	$self->{status} = 200;  # HTTP: OK
}


sub not_found {
	my ($self, $url) = @_;
	$self->{json} = "{\"error\":\"$url not found in Neo4j simulator.\"}";
	$self->{status} = 404;  # HTTP: Not Found
}


sub not_authenticated {
	my ($self, $method, $url, $file) = @_;
	$self->{json} = "{\"error\":\"Neo4j simulator unauthenticated.\"}";
	$self->{status} = 401;  # HTTP: Unauthorized
}


sub not_implemented {
	my ($self, $method, $url, $file) = @_;
	$self->{json} = "{\"error\":\"$method to $url not implemented in Neo4j simulator.\"}";
	$self->{json} = "{\"error\":\"Query not implemented (file '$file' not found).\"}" if $file;
	$self->{status} = 501;  # HTTP: Not Implemented
}


sub fetch_all {
	my ($self) = @_;
	return $self->{json};
}


sub http_header {
	my ($self) = @_;
	my $loc = '';
	eval { $loc = decode_json($self->{json})->{commit} // '' };
	$loc =~ s|/commit$||;
	return {
		content_type => 'application/json',
		location => $loc,
		status => $self->{status},
		success => scalar $self->{status} =~ m/^2/,
	};
}


sub date_header {
	return '';
}


sub uri {
	return "http://localhost:7474";
}


sub store {
	my (undef, $url, $request, $response, $write_txt) = @_;
	return if $Neo4j_Test::sim;  # don't overwrite the files while we're reading from them
	
	$request = json_coder()->encode($request);
	my $hash = request_hash("$url", $request);
	$response //= '';
	$response =~ s/{"expires":"[A-Za-z0-9 :,+-]+"}/{"expires":"Tue, 01 Jan 2999 00:00:00 +0000"}/;
	File::Slurp::write_file "$path/$hash.txt", "$url\n\n\n$request" if $write_txt;  # useful for debugging
	File::Slurp::write_file "$path/$hash.json", $response;
}


sub request_hash ($$) {
	my ($url, $content) = @_;
	return Digest::MD5::md5_hex $url . ($content // '') if $hash_url;
	return Digest::MD5::md5_hex $content // '';
}


sub json_coder {
	return shift->{json_coder} //= json_coder() if @_;
	return JSON::PP->new->utf8->pretty->sort_by(sub {
		return -1 if $JSON::PP::a eq 'statements';
		return 1 if $JSON::PP::b eq 'statements';
		return $JSON::PP::a cmp $JSON::PP::b;
	});
}


sub http_reason {
	my $status = shift->{status};
	return "Bad Request" if $status == 400;
	return "Unauthorized" if $status == 401;
	return "Not Found" if $status == 404;
	return "Not Implemented";
}


sub protocol {
	return "Neo4j_Test::Sim";
}


package Neo4j_Test::Sim::Store;
use parent 'Neo4j::Driver::Net::HTTP::LWP';
sub new {
	my ($class, $driver) = @_;
	$driver->{jolt} = 0;  # sim currently only supports JSON
	$driver->{cypher_params_v2} = 1;  # sim uses old param syntax
	return $class->SUPER::new($driver);
}
sub request {
	my ($self, $method, $url, $json, $accept) = @_;
	$self->SUPER::request($method, $url, $json, $accept);
	Neo4j_Test::Sim->store($url, $json, $self->fetch_all, 0) if $method eq 'POST';
}


1;

__END__

This module implements enough parts of the net_module interface that it can
be used to simulate an active transactional HTTP connection to a Neo4j server.
To do so, it replays canned copies of earlier real responses from a live Neo4j
server that have been stored in a repository.

To populate the repository of canned responses used by the simulator,
run the following command once against a live Neo4j 4 server:

TEST_NEO4J_NETMODULE=Neo4j_Test::Sim::Store prove


The simulator operates most efficiently when repeated identical queries are
reused for multiple _autocommit_ transactions. The tests should be tailored
accordingly.

When writing tests, care must be taken to not repeat identical queries
on _explicit_ transactions. While some of these cases are handled by the
simulator when the $hash_url option is turned on, frequently the wrong
response is returned by mistake, which leads to test failures being reported
that can be difficult to debug.
