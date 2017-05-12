#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::URLMap;
use HTTP::Request;
use HTTP::Headers;

BEGIN {
	use_ok( 'Plack::Middleware::FormatOutput' ) || print "Bail out!\n";
}

my $app1 = 	sub {
		my $env = shift;
		return [200,[],{ data => 'test' }];
	};

my $app = builder {
		enable 'FormatOutput', mime_type => { xyz => sub{ return 'test' } };
		mount "/" => $app1
};

test_psgi app => $app, client => sub {
	my $cb = shift;

# Json
	my $h = HTTP::Headers->new(
		'Accept' => 'application/json'
	);
	my $req = HTTP::Request->new('GET', "http://localhost/", $h);

	my $res = $cb->($req);
	is $res->content, '{"data":"test"}';

# Yaml
	$h = HTTP::Headers->new(
		'Accept' => 'text/yaml'
	);
	$req = HTTP::Request->new('POST', "http://localhost/", $h);

	$res = $cb->($req);
	is $res->content, "--- \ndata: test\n";

# Text
	$h = HTTP::Headers->new(
		'Accept' => 'text/plain'
	);
	$req = HTTP::Request->new('POST', "http://localhost/", $h);

	$res = $cb->($req);
	is $res->content, "--- \ndata: test\n";

# Own
	$h = HTTP::Headers->new(
		'Accept' => 'xyz'
	);
	$req = HTTP::Request->new('POST', "http://localhost/", $h);

	$res = $cb->($req);
	is $res->content, 'test';

};

done_testing;