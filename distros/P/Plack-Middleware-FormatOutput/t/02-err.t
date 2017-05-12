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

my $app_empty = sub {
	return [200, [], undef];
};

my $app_empty1 = sub {
	return [200, [], ''];
};

my $app_empty2 = sub {
	return [200, [], 'test'];
};

my $app = builder {
		enable 'FormatOutput';
		mount "/" => $app_empty;
		mount "/1" => $app_empty1;
		mount "/2" => $app_empty2;
};

test_psgi app => $app, client => sub {
	my $cb = shift;

# Empty Content
	my $h = HTTP::Headers->new(
		'Accept' => 'application/json'
	);
	my $req = HTTP::Request->new('GET', "http://localhost/", $h);

	my $res = $cb->($req);
	is $res->content, '';

# Empty string Content
	$h = HTTP::Headers->new(
		'Accept' => 'application/json'
	);
	$req = HTTP::Request->new('GET', "http://localhost/1", $h);

	$res = $cb->($req);
	is $res->content, '""';

# Bad accept
	$h = HTTP::Headers->new(
		'Accept' => 'application/jsonX'
	);
	$req = HTTP::Request->new('GET', "http://localhost/2", $h);

	$res = $cb->($req);
	is $res->content, '"test"';
};

done_testing;
