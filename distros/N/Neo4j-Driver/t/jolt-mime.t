#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.94;
use Test::Exception;
use Test::Warnings;

use Neo4j_Test::EchoHTTP;
use Neo4j_Test::MockHTTP;


# Confirm that the Jolt MIME type logic works correctly.

use Neo4j::Driver;

plan tests => 5 + 1;


my $mock_plugin = Neo4j_Test::MockHTTP->new;
sub response_for { $mock_plugin->response_for(undef, @_) }

my %empty_json = ( json => {
	results => [],
	errors => [],
});
my %empty_jolt = ( jolt => [
	{ header => {} },
	{ summary => {} },
	{ info => {} },
]);
response_for 'json' => {
	content_type => 'application/json',
	%empty_json,
};
response_for 'json params' => {
	content_type => 'application/json;foo=bar',
	%empty_json,
};
response_for 'jolt v1 explicit' => {
	content_type => 'application/vnd.neo4j.jolt-v1+json-seq',
	%empty_jolt,
};
response_for 'jolt v1 ndjson' => {
	content_type => 'application/vnd.neo4j.jolt',
	%empty_jolt,
};
response_for 'jolt v2 sparse' => {
	content_type => 'application/vnd.neo4j.jolt-v2+json-seq;strict=false',
	%empty_jolt,
};
response_for 'jolt v2 strict' => {
	content_type => 'application/vnd.neo4j.jolt-v2+json-seq;strict=true',
	%empty_jolt,
};
response_for 'jolt v2' => {
	content_type => 'application/vnd.neo4j.jolt-v2+json-seq',
	%empty_jolt,
};
response_for 'text' => {
	content_type => 'text/plain',
	content => 'hey',
};
response_for 'html' => {
	content_type => 'text/html',
	content => '<title>foo</title><p>bar',
};
response_for 'xhtml' => {
	content_type => 'application/xhtml+xml',
	content => '<html><title>foo</title></html>',
};
response_for 'untitled html' => {
	content_type => 'text/html',
	content => '<h1>foo</h1>',
};
response_for 'binary' => {
	content_type => 'application/octet-stream',
	content => 'foobar',
};


sub driver_accept {
	my (%params) = @_;
	my $echo_plugin = Neo4j_Test::EchoHTTP->new(neo4j_version => $params{neo4j_version});
	my $d = Neo4j::Driver->new('http:')->plugin($echo_plugin);
	$d->{jolt} = $params{jolt};  # deprecated/internal option
	my $r = $d->session->run('echo')->single;
	my @accept = split m/\s*,\s*/, $r->get('accept');
}


sub in_or_diag {
	my ($mime_type, $accept, $test, $negate) = @_;
	$mime_type = qr/^\Q$mime_type\E(?:;.*)?$/ unless (ref $mime_type) =~ m/Regexp/i;
	my $result = grep(m/$mime_type/, @$accept);
	$result = ! $result if $negate;
	ok $result, $test;
	diag explain $accept if ! $result;
}
sub not_or_diag { in_or_diag @_[0..2], 'negate' }


subtest 'accept json' => sub {
	plan tests => 4 * 1;
	my @accept;
	@accept = driver_accept( neo4j_version => '2.3.12' );
	in_or_diag 'application/json', \@accept, 'accept json 2.3';
	@accept = driver_accept( neo4j_version => '3.5.35' );
	in_or_diag 'application/json', \@accept, 'accept json 3.5';
	@accept = driver_accept( neo4j_version => '4.0.0' );
	in_or_diag 'application/json', \@accept, 'accept json 4.0';
	@accept = driver_accept( neo4j_version => '4.1.0' );
	in_or_diag 'application/json', \@accept, 'accept json 4.1';
};


subtest 'accept json + jolt v1' => sub {
	plan tests => 2 * 3;
	my @accept;
	@accept = driver_accept( neo4j_version => '4.2.0' );
	in_or_diag 'application/json', \@accept, 'accept json 4.2';
	in_or_diag 'application/vnd.neo4j.jolt+json-seq', \@accept, 'accept jolt v1 4.2';
	not_or_diag 'application/vnd.neo4j.jolt-v2+json-seq', \@accept, 'no accept jolt v2 4.2';
	@accept = driver_accept( neo4j_version => '4.4.15' );
	in_or_diag 'application/json', \@accept, 'accept json 4.4';
	in_or_diag 'application/vnd.neo4j.jolt+json-seq', \@accept, 'accept jolt v1 4.4';
	not_or_diag 'application/vnd.neo4j.jolt-v2+json-seq', \@accept, 'no accept jolt v2 4.4';
};


subtest 'accept json + jolt v2' => sub {
	plan tests => 2 * 3;
	my @accept;
	@accept = driver_accept( neo4j_version => '5.1.0' );
	in_or_diag 'application/json', \@accept, 'accept json 5.1';
	in_or_diag 'application/vnd.neo4j.jolt-v2+json-seq', \@accept, 'accept jolt v2 5.1';
	not_or_diag 'application/vnd.neo4j.jolt+json-seq', \@accept, 'no accept jolt v1 5.1';
	@accept = driver_accept( neo4j_version => '5.3.0' );
	in_or_diag 'application/json', \@accept, 'accept json 5.3';
	in_or_diag 'application/vnd.neo4j.jolt-v2+json-seq', \@accept, 'accept jolt v2 5.3';
	not_or_diag 'application/vnd.neo4j.jolt+json-seq', \@accept, 'no accept jolt v1 5.3';
};


subtest 'deprecated/internal jolt option' => sub {
	plan tests => 6 * 2;
	my @accept;
	@accept = driver_accept( jolt => 0 );
	not_or_diag qr{application/vnd\.neo4j\.jolt\b}, \@accept, 'jolt=0 no accept jolt';
	in_or_diag 'application/json', \@accept, 'jolt=0 accept json';
	@accept = driver_accept( jolt => 1 );
	in_or_diag qr{application/vnd\.neo4j\.jolt\b}, \@accept, 'jolt=1 accept jolt';
	not_or_diag 'application/json', \@accept, 'jolt=1 no accept json';
	@accept = driver_accept( jolt => 'strict' );
	in_or_diag qr{application/vnd\.neo4j\.jolt\b.*\bstrict=true\b}, \@accept, 'jolt=strict accept strict';
	not_or_diag 'application/json', \@accept, 'jolt=strict no accept json';
	@accept = driver_accept( jolt => 'sparse' );
	in_or_diag qr{application/vnd\.neo4j\.jolt\b.*\bstrict=false\b}, \@accept, 'jolt=sparse accept sparse';
	not_or_diag 'application/json', \@accept, 'jolt=sparse no accept json';
	@accept = driver_accept( jolt => 'ndjson' );
	in_or_diag 'application/vnd.neo4j.jolt', \@accept, 'jolt=ndjson accept ndjson';
	not_or_diag 'application/json', \@accept, 'jolt=ndjson no accept json';
	@accept = driver_accept( jolt => 'v1', neo4j_version => '4.2.4' );
	in_or_diag 'application/vnd.neo4j.jolt+json-seq', \@accept, 'jolt=v1 accept jolt v1 4.2';
	not_or_diag 'application/vnd.neo4j.jolt-v2+json-seq', \@accept, 'jolt=v1 no accept jolt v2 4.2';
};


subtest 'acceptable' => sub {
	plan tests => 7 + 6;
	my $s = Neo4j::Driver->new('http:')->plugin($mock_plugin)->session(database => 'dummy');
	lives_and { isa_ok $s->run('json'), 'Neo4j::Driver::Result::JSON' } 'json';
	lives_and { isa_ok $s->run('json params'), 'Neo4j::Driver::Result::JSON' } 'json params';
	lives_and { isa_ok $s->run('jolt v1 explicit'), 'Neo4j::Driver::Result::Jolt' } 'jolt v1 explicit';
	lives_and { isa_ok $s->run('jolt v1 ndjson'), 'Neo4j::Driver::Result::Jolt' } 'jolt v1 ndjson';
	lives_and { isa_ok $s->run('jolt v2 sparse'), 'Neo4j::Driver::Result::Jolt' } 'jolt v2 sparse';
	lives_and { isa_ok $s->run('jolt v2 strict'), 'Neo4j::Driver::Result::Jolt' } 'jolt v2 strict';
	lives_and { isa_ok $s->run('jolt v2'), 'Neo4j::Driver::Result::Jolt' } 'jolt';
	dies_ok { $s->run('text') } 'text dies';
	ok $@ !~ m/\bskipping result parsing\b/i, 'text parsed';
	throws_ok { $s->run('html') } qr/\bReceived HTML content\b.*\bfoo\b/i, 'html';
	throws_ok { $s->run('xhtml') } qr/\bReceived HTML content\b.*\bfoo\b/i, 'xhtml';
	throws_ok { $s->run('untitled html') } qr/\bReceived HTML content\b/i, 'untitled html';
	throws_ok { $s->run('binary') } qr/\bskipping result parsing\b/i, 'binary';
};


done_testing;
