#!perl

use strict;
use warnings;

use Plack::Test;
use HTTP::Request;
use Plack::Builder;

use Test::More;

my $key = 'mobile_client';
# $key = 'psgix.robot_client';

my $app = sub {
	my $env = shift;

	my $response = '';

	if ( $env->{$key} ) {
		$response = "MOBILE CLIENT DETECTED";
	}
	else {
		$response = "MOBILE CLIENT NOT DETECTED";
	}

	return [
		200,
		[ 'Content-Type' => 'text/plain' ],
		[ $response ]
	];
};

my $builder = Plack::Builder->new;
$builder->add_middleware('DetectMobileBrowsers');
my $app_with_plugin = $builder->wrap($app);

my $ua = '';

$ua = 'Mozilla/5.0 (Linux; Android 4.0.4; Galaxy Nexus Build/IMM76B) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.133 Mobile Safari/535.19';
test_psgi(
	app => $app_with_plugin,
	client => sub {
		my $cb  = shift;
		my $req = HTTP::Request->new(GET => "http://localhost/");
		$req->header( 'User-Agent' => $ua );
		my $res = $cb->($req);
		like $res->content, qr/MOBILE CLIENT DETECTED/, $ua;
	}
);

$ua = 'Mozilla/5.0 (Linux; Android 4.0.4; Galaxy Nexus Build/IMM76B) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.133 Safari/535.19';
test_psgi(
	app => $app_with_plugin,
	client => sub {
		my $cb  = shift;
		my $req = HTTP::Request->new(GET => "http://localhost/");
		$req->header( 'User-Agent' => $ua );
		my $res = $cb->($req);
		like $res->content, qr/MOBILE CLIENT NOT DETECTED/, $ua;
	}
);

$ua = 'Mozilla/5.0 (X11; Linux x86_64; rv:18.0) Gecko/20100101 Firefox/18.0';
test_psgi(
	app => $app_with_plugin,
	client => sub {
		my $cb  = shift;
		my $req = HTTP::Request->new(GET => "http://localhost/");
		$req->header( 'User-Agent' => $ua );
		my $res = $cb->($req);
		like $res->content, qr/MOBILE CLIENT NOT DETECTED/, $ua;
	}
);

done_testing;

