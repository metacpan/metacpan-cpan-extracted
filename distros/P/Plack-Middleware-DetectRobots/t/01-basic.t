#!perl

use strict;
use warnings;

use Plack::Test;
use HTTP::Request;
use Plack::Builder;

use Test::More;

use lib qw(./t);
use pmdr_ua_strings;

my $key = 'robot_client';

# $key = 'psgix.robot_client';

my $app = sub {
	my $env = shift;

	my $response = '';

	if ( $env->{$key} ) {
		$response = "ROBOT CLIENT DETECTED";
	}
	else {
		$response = "REGULAR CLIENT DETECTED";
	}

	$response .= ' | ' . $env->{$key};
	return [ 200, [ 'Content-Type' => 'text/plain' ], [$response] ];
};

my $app_with_plugin = builder {
	enable 'DetectRobots';
	$app;
};

foreach my $ua ( pmdr_ua_strings::browser_ua() ) {
	test_psgi(
		app    => $app_with_plugin,
		client => sub {
			my $cb = shift;
			my $req = HTTP::Request->new( GET => "http://localhost/" );
			$req->header( 'User-Agent' => $ua );
			my $res = $cb->($req);
			like $res->content, qr/REGULAR CLIENT DETECTED/, $ua;
		}
	);
}

foreach my $ua ( pmdr_ua_strings::common_bot_ua() ) {
	test_psgi(
		app    => $app_with_plugin,
		client => sub {
			my $cb = shift;
			my $req = HTTP::Request->new( GET => "http://localhost/" );
			$req->header( 'User-Agent' => $ua );
			my $res = $cb->($req);
			like $res->content, qr/ROBOT CLIENT DETECTED/, $ua;
		}
	);
}

foreach my $ua ( pmdr_ua_strings::other_bot_ua() ) {
	test_psgi(
		app    => $app_with_plugin,
		client => sub {
			my $cb = shift;
			my $req = HTTP::Request->new( GET => "http://localhost/" );
			$req->header( 'User-Agent' => $ua );
			my $res = $cb->($req);
			like $res->content, qr/REGULAR CLIENT DETECTED/, $ua;
		}
	);
}

done_testing;

