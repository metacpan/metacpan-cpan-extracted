use strict;
use warnings;
package Neo4j_Test::EchoHTTP;

use parent 'Neo4j_Test::MockHTTP';

sub new {
	my ($class, %params) = @_;
	return bless {
		neo4j_version => $params{neo4j_version} // '5.1.0',
		force_echo    => $params{force_echo} // '',
		req_callback  => $params{req_callback} // sub {
			shift->{statements}[0]
		},
	}, $class;
}

# Return the appropriate response.
sub _r {
	my $self = shift;
	return $self->{r} if $self->{r};
	
	if ( $self->{force_echo} ne 'GET' && $self->{method} eq 'GET' ) {
		# Discovery API (the only GET request)
		return $self->_prep_response({ json => {
			neo4j_version => $self->{neo4j_version},
			transaction => 'http://localhost:7474/db/{databaseName}/tx',
		}});
	}
	
	if ( $self->{force_echo} ne 'SHOW DEFAULT DATABASE'
			&& ref $self->{request} eq 'HASH'
			&& defined $self->{request}{statements}[0]{statement}
			&& $self->{request}{statements}[0]{statement} eq 'SHOW DEFAULT DATABASE' ) {
		return $self->_prep_response({ jolt => [
			{ header => { fields => ['name'] } },
			{ data => ['echo'] },
			{ summary => {} },
			{ info => {} },
		]});
	}
	
	my $request = $self->{request};
	$request = $self->{req_callback}->($request) if $self->{req_callback};
	return $self->_prep_response({ jolt => [
		{ header => { fields => [qw( method url accept mode query )] } },
		{ data => [
			{ 'U' => $self->{method} },
			{ 'U' => $self->{url} },
			{ 'U' => $self->{accept} },
			{ 'U' => $self->{mode} },
			# This works because U is the sigil for a string in strict Jolt
			# and the Jolt result parser leaves strings unchanged:
			{ 'U' => $request },
		] },
		{ summary => {} },
		{ info => {
			# Transaction functions require the tx to remain open.
			commit => "http://localhost:7474/db/echo/tx/echo/commit",
			transaction => { expires => 'Tue, 1 Jan 2999 00:00:00 GMT' },
		}},
	]});
}

sub request {
	my $self = shift;
	$self->SUPER::request(@_);
	$self->{r} = undef;   # response cache
}


1;

__END__

This is a small plugin that causes any statements the client tries
to run on the server to be echoed back as a synthesised response.
Allows testing that the HTTP adapter is called correctly.

The plugin has special handling for the Discovery API and for the
default database request to simplify regular tests. Additionally,
it assumes that only a single request is sent to the server.
The plugin constructor accepts named parameters to change this
behaviour.

Basic usage example:

use Neo4j_Test::EchoHTTP;
use Neo4j::Driver;
use JSON::PP;
use Test::More;

my $plugin = Neo4j_Test::EchoHTTP->new;
my $d = Neo4j::Driver->new('http:')->plugin( $plugin );
my $r = $d->session->run( 'ECHO TEST {param}', param => \1 )->single;

is $r->get('method'), 'POST';
is $r->get('url'),    '/db/echo/tx/commit';
is $r->get('accept'), 'application/vnd.neo4j.jolt+json-seq, application/json;q=0.5';

is $r->get('query')->{statement}, 'ECHO TEST {param}';
ok $r->get('query')->{includeStats};
is_deeply $r->get('query')->{parameters}, { param => JSON::PP->true };
done_testing;
