use strict;
use warnings;
package Neo4j_Test::EchoHTTP;

use parent 'Neo4j::Driver::Plugin';

use JSON::MaybeXS;
use Neo4j::Driver::Net::HTTP::LWP;

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

sub register {
	my ($self, $manager) = @_;
	
	$manager->add_event_handler(
		http_adapter_factory => sub {
			my ($continue, $driver) = @_;
			$self->{base} = $driver->{uri};
			return $self;
		},
	);
}

my $coder = JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1);
sub json_coder { $coder }

sub _prep_response {
	my ($self, $r) = @_;
	unless (defined $r->{content}) {
		if ($r->{json}) {
			if ('HASH' eq ref $r->{json}) {
				$r->{content} = encode_json $r->{json};
			}
			else {
				$r->{content} = $r->{json};
			}
		}
		if ($r->{jolt}) {
			if ('ARRAY' eq ref $r->{jolt}) {
				my @json_texts = map { 'HASH' eq ref $_ ? encode_json $_ : $_ } @{$r->{jolt}};
				$r->{content} = join '', map { "\x{1e}$_\x{0a}" } @json_texts;
				# https://tools.ietf.org/html/rfc7464#section-2.2
			}
			else {
				$r->{content} = $r->{jolt};
			}
		}
	}
	$r->{content_type} //= 'application/json' if $r->{json};
	$r->{content_type} //= 'application/vnd.neo4j.jolt+json-seq' if $r->{jolt};
	$r->{content_type} //= 'application/octet-stream';
	$r->{content} //= '';
	$r->{status} //= '200';
	$r->{success} //= $r->{status} =~ m/^2/;
	$r->{method} //= 'POST';
	return $self->{r} = $r;
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
			&& ref $self->{request}{statements} eq 'ARRAY'
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
		{ header => { fields => [qw( method url accept query )] } },
		{ data => [
			{ 'U' => $self->{method} },
			{ 'U' => $self->{url} },
			{ 'U' => $self->{accept} },
			# This works because U is the sigil for a string in strict Jolt
			# and the Jolt result parser leaves strings unchanged:
			{ 'U' => $request },
		] },
		{ summary => {} },
		{ info => {} },
	]});
}

sub fetch_all { '' . shift->_r->{content} }

# Use the exact same Jolt split implementation that is
# normally used, so that we get to test that one, too.
sub fetch_event { &Neo4j::Driver::Net::HTTP::LWP::fetch_event }

sub request {
	my ($self, $method, $url, $json, $accept) = @_;
	$self->{method}  = $method;
	$self->{url}     = $url;
	$self->{request} = $json;
	$self->{accept}  = $accept;
	$self->{buffer}  = undef;   # for ::LWP::fetch_event
	$self->{r}       = undef;   # response cache
}

sub date_header { shift->_r->{date} || '' }

sub http_header {
	my $r = shift->_r;
	return {
		content_type => $r->{content_type} // '',
		location => $r->{location} // '',
		status => $r->{status} // '',
		success => $r->{success} // '',
	}
}

sub http_reason { shift->_r->{reason} // '' }

sub protocol { 'EchoHTTP' }

sub uri { shift->{base} }


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
