#!perl
use v5.12;
use warnings;
use lib qw(./lib t/lib);

use Test2::V0;
$ENV{AUTHOR_TESTING} and eval q{ require Test2::Plugin::NoWarnings; 1 }
	|| warn "Can't load Test2::Plugin::NoWarnings: $@";


# Unit tests for Neo4j::Driver::Net::HTTP::Tiny

plan 13;

use Neo4j::Driver::Net::HTTP::Tiny;
use JSON::MaybeXS qw(encode_json);
use URI;

my $test2_mock = mock 'HTTP::Tiny' => (
    override => [
		request => sub { +{
			method => $_[1],
			url => $_[2],
			headers => $_[3]->{headers},
			content => $_[3]->{content},
		}},
    ],
);

sub new_driver_config ($) { +{ config => shift } }

my $base = URI->new('http://net.test/');
my $auth = { scheme => 'basic', principal => 'user%name', credentials => "pass:\@/word\x{100}" };
my $userinfo = 'user%25name:pass%3A%40%2Fword%C4%80';
my $uri = 'http://'.$userinfo.'@net.test/';

my $driver = new_driver_config({ uri => $base, auth => $auth });
my $m = Neo4j::Driver::Net::HTTP::Tiny->new($driver);


subtest 'static' => sub {
	plan 6;
	isa_ok $m->{http}, 'HTTP::Tiny';
	like $m->{http}->agent(), qr|\bNeo4j-Driver(/\S+)? Perl HTTP-Tiny/|, 'ver User-Agent';
	like $m->uri(), qr/\Q$uri\E/i, 'uri';
	is [eval { $m->result_handlers }], [], 'result_handlers';
	my $coder;
	$coder = $m->json_coder;
	ok $coder->can('decode'), 'json_coder';
	is $m->json_coder(), $coder, 'json_coder cached';
};


subtest 'get request' => sub {
	plan 4;
	$m->request('GET', '/get', undef, 'application/json');
	my $rq = $m->{response};
	is $rq->{method}, 'GET', 'method get';
	like $rq->{url}, qr/\Q$uri\Eget/i, 'uri get';
	is $rq->{headers}->{Accept}, 'application/json', 'accept json';
	ok ! length $rq->{content}, 'content empty';
};


subtest 'delete request' => sub {
	plan 4;
	$m->request('DELETE', '//del.test', undef, '*/*');
	my $rq = $m->{response};
	is $rq->{method}, 'DELETE', 'method delete';
	is $rq->{url}, 'http://del.test', 'scheme rel uri';
	is $rq->{headers}->{Accept}, '*/*', 'accept any';
	ok ! length $rq->{content}, 'content empty';
};


subtest 'post request' => sub {
	plan 5;
	my $json = { answer => 42 };
	$m->request('POST', '/post', $json, 'application/vnd.neo4j.jolt');
	my $rq = $m->{response};
	is $rq->{method}, 'POST', 'method post';
	like $rq->{url}, qr/\Q$uri\Epost/i, 'uri post';
	is $rq->{headers}->{'Accept'}, 'application/vnd.neo4j.jolt', 'accept jolt';
	is $rq->{headers}->{'Access-Mode'}, undef, 'no mode';
	is $rq->{content}, encode_json($json), 'content json';
};


subtest 'request modes' => sub {
	plan 2;
	my $rq;
	$m->request('POST', '/post', {}, 'application/vnd.neo4j.jolt', 'WRITE');
	$rq = $m->{response};
	is $rq->{headers}->{'Access-Mode'}, 'WRITE', 'write mode';
	$m->request('POST', '/post', {}, 'application/vnd.neo4j.jolt', 'READ');
	$rq = $m->{response};
	is $rq->{headers}->{'Access-Mode'}, 'READ', 'read mode';
};


subtest 'response' => sub {
	plan 7;
	$m->{response} = {
		success => !!1,
		status => '200',
		reason => 'OK',
		content => (my $content = '42'),
		headers => {
			'date' => 'Thu, 01 Jan 1970 00:00:00 -0000',
			'location' => 'http://net.test/42',
			'content-type' => 'text/plain; charset=UTF-8',
		},
	};
	is $m->fetch_all(), $content, 'fetch_all';
	is $m->date_header(), $m->{response}{headers}{'date'}, 'date';
	is $m->http_header->{content_type}, $m->{response}{headers}{'content-type'}, 'content_type';
	is $m->http_header->{location}, $m->{response}{headers}{'location'}, 'location';
	is $m->http_header->{status}, '200', 'status';
	ok $m->http_header->{success}, 'success';
	is $m->http_reason(), 'OK', 'reason';
};


subtest 'response error' => sub {
	plan 7;
	$m->{response} = {
		success => !!0,
		status => '300',
		reason => '',
		content => '',
		headers => {},
	};
	is $m->fetch_all(), '', 'fetch_all empty';
	is $m->date_header(), '', 'date empty';
	is $m->http_header->{content_type}, '', 'content_type empty';
	is $m->http_header->{location}, '', 'location empty';
	is $m->http_header->{status}, '300', 'status error';
	ok ! $m->http_header->{success}, 'no success';
	is $m->http_reason(), '', 'reason no default';
};


subtest 'HTTP::Tiny error' => sub {
	plan 4;
	my $msg = "No towel!";
	$m->{response} = {
		success => !!0,
		status => '599',
		reason => 'Internal Exception',
		content => $msg,
		headers => {
			'content-type' => 'text/plain',
		},
	};
	is $m->fetch_all(), $msg, 'fetch_all';
	is $m->http_header->{content_type}, '', 'content_type empty';
	is $m->http_header->{status}, '', 'status empty';
	is $m->http_reason(), $msg, 'reason message';
};


subtest 'response jolt ndjson' => sub {
	plan 4;
	my @jolt = qw( {"header":{"fields":["0"]}} {"data":[1]} {"data":[2]} );
	$m->{response} = {
		content => ( join '', map { "$_\n" } @jolt ),
		headers => { 'content-type' => 'application/vnd.neo4j.jolt' },
	};
	is $m->fetch_event(), qq<{"header":{"fields":["0"]}}\n>, 'fetch_event 0';
	is $m->fetch_event(), qq<{"data":[1]}\n>, 'fetch_event 1';
	is $m->fetch_event(), qq<{"data":[2]}\n>, 'fetch_event 2';
	is $m->fetch_event(), qq<>, 'fetch_event 3 empty';
};


subtest 'response jolt json-seq' => sub {
	plan 3;
	my @jolt = qw( {"header":{"fields":["0"]}} {"info":{}} );
	$m->{response} = {
		content => ( "\x{1e}" . join "\n\x{1e}", @jolt ),
		headers => { 'content-type' => 'application/vnd.neo4j.jolt-v2+json-seq' },
	};
	is $m->fetch_event(), qq<{"header":{"fields":["0"]}}\n>, 'fetch_event 0';
	is $m->fetch_event(), qq<{"info":{}}>, 'fetch_event 1';
	is $m->fetch_event(), qq<>, 'fetch_event 2 empty';
};


subtest 'auth variations' => sub {
	plan 4;
	my $clone = $base->clone;
	$clone->userinfo($userinfo);
	my $config;
	$config = { uri => $base, auth => { scheme => 'basic', principal => "\xc4\x80" } };
	$m = Neo4j::Driver::Net::HTTP::Tiny->new( new_driver_config $config );
	like $m->uri(), qr|//%C3%84%C2%80:@|i, 'latin1 userid after utf8::encode';
	$config = { uri => $base, auth => { scheme => 'basic', credentials => "\x{100}" } };
	$m = Neo4j::Driver::Net::HTTP::Tiny->new( new_driver_config $config );
	like $m->uri(), qr|//:%C4%80@|i, 'uri with utf8 passwd';
	$config = { uri => $base };
	$m = Neo4j::Driver::Net::HTTP::Tiny->new( new_driver_config $config );
	is $m->uri(), 'http://net.test/', 'uri no auth';
	$config = { uri => $base, auth => { scheme => 'blackmagic' } };
	like dies {
		Neo4j::Driver::Net::HTTP::Tiny->new( new_driver_config $config );
	}, qr/\bBasic Auth/i, 'new custom auth croaks';
};


subtest 'tls' => sub {
	skip_all "(IO::Socket::SSL unavailable)" unless eval 'require IO::Socket::SSL; 1';
	skip_all "(Net::SSLeay unavailable)" unless eval 'require Net::SSLeay; 1';
	plan 8;
	my $config;
	try_ok {
		$config = { uri => URI->new('https://e.net.test/'), encrypted => 1 };
		$m = Neo4j::Driver::Net::HTTP::Tiny->new( new_driver_config $config );
	} 'encrypted https';
	like $m->uri(), qr|^https://e|i, 'encrypted https uri';
	try_ok {
		$config = { uri => URI->new('https://d.net.test/'), encrypted => undef };
		$m = Neo4j::Driver::Net::HTTP::Tiny->new( new_driver_config $config );
	} 'https';
	like $m->uri(), qr|^https://d|i, 'https uri';
	my $ca_file = eval { ({ IO::Socket::SSL::default_ca() })->{SSL_ca_file} };
	SKIP: {
		skip "(default CA file unavailable)", 4 unless $ca_file;
		try_ok {
			$config = { uri => URI->new('https://c.net.test/'), trust_ca => $ca_file };
			$m = Neo4j::Driver::Net::HTTP::Tiny->new( new_driver_config $config );
		} 'https trust_ca lives';
		like $m->uri(), qr|^https://c|i, 'https trust_ca uri';
		is $m->{http}->SSL_options->{SSL_ca_file}, $ca_file, 'https trust_ca';
		ok $m->{http}->verify_SSL, 'https verify_SSL';
	}
};


subtest 'tls config errors' => sub {
	plan 2;
	my $config;
	like dies {
		$config = { uri => $base, encrypted => 1 };
		Neo4j::Driver::Net::HTTP::Tiny->new( new_driver_config $config );
	}, qr/\bHTTP does not support encrypted communication\b/i, 'no encrypted http';
	SKIP: {
		skip "(IO::Socket::SSL unavailable)", 1 unless eval 'require IO::Socket::SSL; 1';
		skip "(Net::SSLeay unavailable)", 1 unless eval 'require Net::SSLeay; 1';
		like dies {
			$config = { uri => URI->new('https://net.test/'), encrypted => 0 };
			Neo4j::Driver::Net::HTTP::Tiny->new( new_driver_config $config );
		}, qr/\bHTTPS does not support unencrypted communication\b/i, 'no unencrypted https';
	}
};


done_testing;
