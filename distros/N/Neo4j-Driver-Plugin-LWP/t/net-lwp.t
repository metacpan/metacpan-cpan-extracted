#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.94;
use Test::Exception;
use Test::Warnings 0.010 qw(warning :no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

use Mock::Quick;


# Unit tests for Neo4j::Driver::Net::HTTP::LWP

plan tests => 1 + 13 + $no_warnings;

use Neo4j::Driver::Net::HTTP::LWP;
use HTTP::Headers;
use HTTP::Response;
use JSON::MaybeXS;
use URI;

my $qcontrol = qtakeover( 'LWP::UserAgent',
	request => sub { $_[1] },
);


my ($m, $ua, $rq);

my $base = URI->new('http://net.test/');
my $auth = { scheme => 'basic', principal => 'user%name', credentials => "pass:\@/word\x{100}" };
my $userinfo = 'user%25name:pass%3A%40%2Fword%C4%80';
my $uri = 'http://'.$userinfo.'@net.test/';
my $driver;

$driver = Neo4j_Test::DriverConfig->new({ uri => $base, auth => $auth });
lives_ok { $m = Neo4j::Driver::Net::HTTP::LWP->new($driver) } 'new';


subtest 'static' => sub {
	plan tests => 5;
	lives_and { like $m->uri(), qr/\Q$uri\E/i } 'uri';
	is_deeply [eval { $m->result_handlers }], [], 'result_handlers';
	my $coder;
	lives_ok { $coder = $m->json_coder } 'json_coder lives';
	lives_and { ok $coder->can('decode') } 'json_coder';
	lives_and { is $m->json_coder(), $coder } 'json_coder cached';
};


subtest 'agent' => sub {
	plan tests => 8;
	dies_ok { $m->agent() } 'agent renamed to ua';
	lives_ok { $ua = 0; $ua = $m->ua() } 'ua';
	isa_ok $ua, 'LWP::UserAgent', 'ua type';
	lives_and { ok $ua->default_header('X-Stream') } 'X-Stream';
	my $mver;
	local $Neo4j::Driver::Net::HTTP::LWP::VERSION = '0.00';
	lives_ok { $mver = Neo4j::Driver::Net::HTTP::LWP->new($driver) } 'ver lives';
	lives_and { like $mver->ua->agent(), qr|\bNeo4j-Driver/0\.00 libwww-perl\b| } 'ver User-Agent';
	local $Neo4j::Driver::Net::HTTP::LWP::VERSION = undef;
	lives_ok { $mver = Neo4j::Driver::Net::HTTP::LWP->new($driver) } 'no ver lives';
	lives_and { like $mver->ua->agent(), qr|\bNeo4j-Driver libwww-perl\b| } 'no ver User-Agent';
};


subtest 'get request' => sub {
	plan tests => 5;
	lives_ok { $m->request('GET', '/get', undef, 'application/json') } 'request get';
	$rq = $m->{response};
	lives_and { is $rq->method(), 'GET' } 'method get';
	lives_and { like $rq->uri(), qr/\Q$uri\Eget/i } 'uri get';
	lives_and { is $rq->header('Accept'), 'application/json' } 'accept json';
	lives_and { ok ! length $rq->content } 'content empty';
};


subtest 'delete request' => sub {
	plan tests => 5;
	lives_ok { $m->request('DELETE', '//del.test', undef, '*/*') } 'request delete';
	$rq = $m->{response};
	lives_and { is $rq->method(), 'DELETE' } 'method delete';
	lives_and { is $rq->uri(), 'http://del.test' } 'scheme rel uri';
	lives_and { is $rq->header('Accept'), '*/*' } 'accept any';
	lives_and { ok ! length $rq->content } 'content empty';
};


subtest 'post request' => sub {
	plan tests => 6;
	my $json = { answer => 42 };
	lives_ok { $m->request('POST', '/post', $json, 'application/vnd.neo4j.jolt') } 'request post';
	$rq = $m->{response};
	lives_and { is $rq->method(), 'POST' } 'method post';
	lives_and { like $rq->uri(), qr/\Q$uri\Epost/i } 'uri post';
	lives_and { is $rq->header('Accept'), 'application/vnd.neo4j.jolt' } 'accept jolt';
	lives_and { is $rq->header('Access-Mode'), undef } 'no mode';
	lives_and { is $rq->content(), encode_json($json) } 'content json';
};


subtest 'request modes' => sub {
	plan tests => 4;
	lives_ok { $m->request('POST', '/post', {}, 'application/vnd.neo4j.jolt', 'WRITE') } 'request write';
	$rq = $m->{response};
	lives_and { is $rq->header('Access-Mode'), 'WRITE' } 'write mode';
	lives_ok { $m->request('POST', '/post', {}, 'application/vnd.neo4j.jolt', 'READ') } 'request read';
	$rq = $m->{response};
	lives_and { is $rq->header('Access-Mode'), 'READ' } 'read mode';
};


subtest 'response' => sub {
	plan tests => 8;
	my $content = "42";
	my $hdr = HTTP::Headers->new(
		Date => 'Thu, 01 Jan 1970 00:00:00 -0000',
		Location => 'http://net.test/42',
		Content_Type => 'text/plain; charset=UTF-8',
	);
	$m->{response} = HTTP::Response->new( '200', 'OK', $hdr, $content );
	$m->{response}->protocol('HTTP/1.1');
	lives_and { is $m->fetch_all(), $content } 'fetch_all';
	lives_and { is $m->date_header(), $hdr->header('Date') } 'date';
	lives_and { is $m->http_header->{content_type}, $hdr->header('Content-Type') } 'content_type';
	lives_and { is $m->http_header->{location}, $hdr->header('Location') } 'location';
	lives_and { is $m->http_header->{status}, '200' } 'status';
	lives_and { ok $m->http_header->{success} } 'success';
	lives_and { is $m->http_reason(), 'OK' } 'reason';
	dies_ok { $m->protocol() } 'protocol removed';
};


subtest 'response error' => sub {
	plan tests => 11;
	$m->{response} = HTTP::Response->new('300');
	lives_and { is $m->fetch_all(), '' } 'fetch_all empty';
	lives_and { is $m->date_header(), '' } 'date empty';
	lives_and { is $m->http_header->{content_type}, '' } 'content_type empty';
	lives_and { is $m->http_header->{location}, '' } 'location empty';
	lives_and { is $m->http_header->{status}, '300' } 'status error';
	lives_and { ok ! $m->http_header->{success} } 'no success';
	lives_and { is $m->http_reason(), '' } 'reason no default';
	dies_ok { $m->protocol() } 'protocol removed';
	$m->{response} = HTTP::Response->new;
	SKIP: { skip "(HTTP::Status too old)", 2 if $HTTP::Headers::VERSION lt '6.12';
		lives_and { is $m->http_header->{status}, '' } 'status empty';
		lives_and { ok ! $m->http_header->{success} } 'no success empty';
	}
	lives_and { is $m->http_reason(), '' } 'reason empty';
};


subtest 'libwww-perl error' => sub {
	plan tests => 4;
	my $msg = "No towel!";
	my $hdr = HTTP::Headers->new(
		Content_Type => 'text/plain',
		Client_Warning => 'Internal response',
	);
	$m->{response} = HTTP::Response->new( '500', $msg, $hdr, "$msg in content" );
	lives_and { is $m->fetch_all(), "$msg in content" } 'fetch_all unaffected';
	lives_and { is $m->http_header->{content_type}, '' } 'content_type empty';
	lives_and { is $m->http_header->{status}, '' } 'status empty';
	lives_and { is $m->http_reason(), $msg } 'reason message';
};


subtest 'response jolt' => sub {
	plan tests => 3;
	$m->{response} = HTTP::Response->new;
	$m->{response}->content(join "\n", qw( {"header":{"fields":["0"]}} {"data":[1]} {"data":[2]} ));
	lives_and { is $m->fetch_event(), '{"header":{"fields":["0"]}}' } 'fetch_event 0';
	lives_and { is $m->fetch_event(), '{"data":[1]}' } 'fetch_event 1';
	lives_and { is $m->fetch_event(), '{"data":[2]}' } 'fetch_event 2';
};


subtest 'auth variations' => sub {
	plan tests => 9;
	my $clone = $base->clone;
	$clone->userinfo($userinfo);
	my $config;
	$config = { uri => $clone };
	$driver = Neo4j_Test::DriverConfig->new($config);
	lives_ok { $m = Neo4j::Driver::Net::HTTP::LWP->new($driver) } 'new with userinfo';
	lives_and { like $m->uri(), qr/\Q$uri\E/i } 'uri with userinfo';
	# ^ Since 0.2602, the "uri with userinfo" case can no longer occur
	#   because such URIs are tidied in Neo4j::Driver::_check_uri().
	$config = { uri => $base, auth => { scheme => 'basic', principal => "\xc4\x80" } };
	$driver = Neo4j_Test::DriverConfig->new($config);
	lives_ok { $m = Neo4j::Driver::Net::HTTP::LWP->new($driver) } 'new with latin1 userid';
	lives_and { like $m->uri(), qr|//%C3%84%C2%80:@|i } 'latin1 userid after utf8::encode';
	$config = { uri => $base, auth => { scheme => 'basic', credentials => "\x{100}" } };
	$driver = Neo4j_Test::DriverConfig->new($config);
	lives_ok { $m = Neo4j::Driver::Net::HTTP::LWP->new($driver) } 'new with utf8 passwd';
	lives_and { like $m->uri(), qr|//:%C4%80@|i } 'uri with utf8 passwd';
	$config = { uri => $base };
	$driver = Neo4j_Test::DriverConfig->new($config);
	lives_ok { $m = Neo4j::Driver::Net::HTTP::LWP->new($driver) } 'new no auth';
	lives_and { is $m->uri(), 'http://net.test/' } 'uri no auth';
	$config = { uri => $base, auth => { scheme => 'blackmagic' } };
	$driver = Neo4j_Test::DriverConfig->new($config);
	throws_ok { Neo4j::Driver::Net::HTTP::LWP->new($driver) } qr/\bBasic Auth/i, 'new custom auth croaks';
};


subtest 'tls' => sub {
	plan skip_all => "(LWP::Protocol::https unavailable)" unless eval 'require LWP::Protocol::https; 1';
	plan tests => 8;
	my $config;
	lives_ok {
		$config = { uri => URI->new('https://e.net.test/'), encrypted => 1 };
		$driver = Neo4j_Test::DriverConfig->new($config);
		$m = Neo4j::Driver::Net::HTTP::LWP->new($driver);
	} 'encrypted https';
	lives_and { like $m->uri(), qr|^https://e|i } 'encrypted https uri';
	lives_ok {
		$config = { uri => URI->new('https://d.net.test/'), encrypted => undef };
		$driver = Neo4j_Test::DriverConfig->new($config);
		$m = Neo4j::Driver::Net::HTTP::LWP->new($driver);
	} 'https';
	lives_and { like $m->uri(), qr|^https://d|i } 'https uri';
	my $ca_file = eval 'require Mozilla::CA; Mozilla::CA::SSL_ca_file()';
	SKIP: {
		skip "(Mozilla::CA unavailable)", 4 unless $ca_file;
		lives_ok {
			$config = { uri => URI->new('https://c.net.test/'), trust_ca => $ca_file };
			$driver = Neo4j_Test::DriverConfig->new($config);
			$m = Neo4j::Driver::Net::HTTP::LWP->new($driver);
		} 'https ca_file lives';
		lives_and { like $m->uri(), qr|^https://c|i } 'https ca_file uri';
		lives_and { is $m->ua->ssl_opts('SSL_ca_file'), $ca_file } 'https ca_file';
		lives_and { ok $m->ua->ssl_opts('verify_hostname') } 'https verify_hostname';
	}
};


subtest 'tls config errors' => sub {
	plan tests => 2;
	my $config;
	throws_ok {
		$config = { uri => $base, encrypted => 1 };
		$driver = Neo4j_Test::DriverConfig->new($config);
		Neo4j::Driver::Net::HTTP::LWP->new($driver);
	} qr/\bHTTP does not support encrypted communication\b/i, 'no encrypted http';
	SKIP: {
		skip "(LWP::Protocol::https unavailable)", 1 unless eval 'require LWP::Protocol::https; 1';
		throws_ok {
			$config = { uri => URI->new('https://net.test/'), encrypted => 0 };
			$driver = Neo4j_Test::DriverConfig->new($config);
			Neo4j::Driver::Net::HTTP::LWP->new($driver);
		} qr/\bHTTPS does not support unencrypted communication\b/i, 'no unencrypted https';
	}
};


done_testing;


package Neo4j_Test::DriverConfig;

sub config {
	my ($driver, $option) = @_;
	my %aliases = (
		timeout => 'http_timeout',
	);
	return $driver->{$aliases{$option}} if $aliases{$option};
	return $driver->{$option};
}

sub new {
	my ($class, $config) = @_;
	return bless $config, $class;
}
