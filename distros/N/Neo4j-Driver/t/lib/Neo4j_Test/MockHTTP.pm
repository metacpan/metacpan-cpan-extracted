use strict;
use warnings;
package Neo4j_Test::MockHTTP;

use JSON::MaybeXS;
use Neo4j::Driver::Net::HTTP::LWP;

sub new {
	my ($class, $driver) = @_;
	bless { base => $driver->{uri} }, $class;
}

my $coder = JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1);
sub json_coder { $coder }

our @res = (
	{
		method => 'GET',  # Discovery API (the only GET request)
		json => {
			neo4j_version => '4.2.5',
			transaction => 'http://localhost:7474/db/{databaseName}/tx',
		},
	},
);

sub response_for {
    my ($query, $response) = @_;
    $response->{query} = $query;
    push @res, $response;
}

sub _prep_responses {
	for my $r (@res) {
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
	}
}

# Return the appropriate response (or a 501 if none could be found).
sub _r {
	my $self = shift;
	$self->_prep_responses;
	for my $r (@res) {
		return $r if $self->{method} eq 'GET' && $r->{method} eq 'GET';
		return $r if ($self->{request}{statements}[0]{statement} // '') eq ($r->{query} // "\0");
	}
	return {
		content_type => 'text/plain',
		status => '501',
		content => 'response unimplemented',
	};
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

sub protocol { 'MockHTTP' }

sub result_handlers { }

sub uri { shift->{base} }


1;

__END__

This is a small net_module that allows injecting tailored Jolt
or JSON responses into the driver. Users can provide the actual
response content that would have been received from Neo4j as a
string. They can also provide a Perl hashref or arrayref, in
which case the response content will be assembled automatically.
The relevant HTTP headers will be populated automatically, but
can also be specified individually. This allows for easy offline
testing of _all_ parts of the driver's result parsing logic.

Basic usage example:

package Neo4j_Test::Foo;
use parent 'Neo4j_Test::MockHTTP';
sub response_for { &Neo4j_Test::MockHTTP::response_for }

response_for 'working jolt' => { jolt => [
	{ header => { fields => ['greeting'] } },
	{ data => [ { 'U' => 'hello' } ] },
	{ summary => {} },
	{ info => {} },
]};

response_for 'broken json' => { json => <<END };
:-[ this ain't json
END

use Neo4j::Driver;
use Test::More;
use Test::Exception;

my $s = Neo4j::Driver->new('http:')
        ->config(net_module => 'Neo4j_Test::Foo')
        ->session(database => 'dummy');

lives_and { is $s->run('working jolt')->single->get(0), 'hello' };
throws_ok { $s->run('broken json') } qr/malformed JSON/;
done_testing;
