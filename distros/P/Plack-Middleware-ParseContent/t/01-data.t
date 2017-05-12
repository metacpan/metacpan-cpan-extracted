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
	use_ok( 'Plack::Middleware::ParseContent' ) || print "Bail out!\n";
}

my $make_app = sub {
	sub {
		my $env = shift;

		my $test;
		if ( exists $env->{'parsecontent.data'} ){
			if (ref $env->{'parsecontent.data'} eq 'HASH'){
				$test = $env->{'parsecontent.data'}->{test};
			}else{
				$test = $env->{'parsecontent.data'};
			}
		}

		return [ 200, [ 'Content-Type' => 'text/plain' ], [ $test ] ];
	};
};

my $app1 = $make_app->();

my $app = builder {
		enable 'ParseContent', xyz => sub{ return {test => $_[1]} };
		mount "/" => $app1
};

test_psgi app => $app, client => sub {
	my $cb = shift;

# Json
	my $h = HTTP::Headers->new(
		'Content-Type' => 'application/json'
	);
	my $m = '{"test":"test"}';
	my $req = HTTP::Request->new('POST', "http://localhost/", $h, $m);

	my $res = $cb->($req);
	is $res->content, 'test';

# Yaml
	$h = HTTP::Headers->new(
		'Content-Type' => 'text/yaml'
	);
	$m = "---\n\ntest: test";
	$req = HTTP::Request->new('POST', "http://localhost/", $h, $m);

	$res = $cb->($req);
	is $res->content, 'test';

# Text
	$h = HTTP::Headers->new(
		'Content-Type' => 'text/plain'
	);
	$m = "test";
	$req = HTTP::Request->new('POST', "http://localhost/", $h, $m);

	$res = $cb->($req);
	is $res->content, 'test';

# Own
	$h = HTTP::Headers->new(
		'Content-Type' => 'xyz'
	);
	$m = "test";
	$req = HTTP::Request->new('POST', "http://localhost/", $h, $m);

	$res = $cb->($req);
	is $res->content, 'test';

};

done_testing;

package Test::Root;

sub GET {
	return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'app/root' ] ];
}
