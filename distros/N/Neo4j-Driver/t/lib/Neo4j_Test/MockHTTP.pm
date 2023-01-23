use strict;
use warnings;
package Neo4j_Test::MockHTTP;

use parent 'Neo4j::Driver::Plugin';

use JSON::MaybeXS;
use Neo4j::Driver::Net::HTTP::LWP;

sub new {
	my ($class, %params) = @_;
	my $self = bless {}, $class;
	$self->response_for('/', 'GET' => {
		json => {
			neo4j_version => $params{neo4j_version} // '5.1.0',
			transaction => 'http://localhost:7474/db/{databaseName}/tx',
		},
	});
	$self->response_for('/db/system/tx/commit', 'SHOW DEFAULT DATABASE' => { jolt => [
		{ header => { fields => ['name'] } },
		{ data => [ $self->default_db ] },
		{ summary => {} },
		{ info => {} },
	]}) unless $params{no_default_db};
	return $self;
}

sub register {
	my ($self, $manager) = @_;
	
	$manager->add_handler(
		http_adapter_factory => sub {
			my ($continue, $driver) = @_;
			$self->{base} = $driver->{uri};
			return $self;
		},
	);
}

my $coder = JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1);
sub json_coder { $coder }

sub default_db { 'dummy' }

sub response_for {
	my ($self, $url, $query, $response) = @_;
	$url //= '/db/' . $self->default_db . '/tx/commit';
	$self->{res}{$url}{$query} = $self->_prep_response($response);
}

sub _prep_response {
	my ($self, $r) = @_;
	{
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
	}
	return $r;
}

# Return the appropriate response (or a 501 if none could be found).
sub _r {
	my $self = shift;
	my $url = $self->{url};
	my $key = $self->{method} eq 'GET'
		? "GET"
		: $self->{request}{statements}[0]{statement} // '';
	my $response = $self->{res}{$url}{$key} // $self->res($url, $key);
	return $response // {
		content_type => 'text/plain',
		status => '501',
		content => 'response unimplemented',
	};
}

sub res {}

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

sub uri { shift->{base} }


1;

__END__

This is a small plugin that allows injecting tailored Jolt
or JSON responses into the driver. Users can provide the actual
response content that would have been received from Neo4j as a
string. They can also provide a Perl hashref or arrayref, in
which case the response content will be assembled automatically.
The relevant HTTP headers will be populated automatically, but
can also be specified individually. This allows for easy offline
testing of _all_ parts of the driver's result parsing logic.

Basic usage example:

use Neo4j_Test::MockHTTP;
my $mock_plugin = Neo4j_Test::MockHTTP->new;

$mock_plugin->response_for( undef, 'working jolt' => { jolt => [
	{ header => { fields => ['greeting'] } },
	{ data => [ { 'U' => 'hello' } ] },
	{ summary => {} },
	{ info => {} },
]});

$mock_plugin->response_for( undef, 'broken json' => { json => <<END });
:-[ this ain't json
END

use Neo4j::Driver;
use Test::More;
use Test::Exception;

my $s = Neo4j::Driver->new('http:')
        ->plugin($mock_plugin)
        ->session(database => 'dummy');

lives_and { is $s->run('working jolt')->single->get(0), 'hello' };
throws_ok { $s->run('broken json') } qr/malformed JSON/;
done_testing;
