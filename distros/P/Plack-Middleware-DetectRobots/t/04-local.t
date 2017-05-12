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
	enable 'DetectRobots', local_regexp => qr/maxthon/i, basic_check => 0;
	$app;
};

my %tests = (
	'Mozilla/5.0 (X11; Linux x86_64; rv:26.0) Gecko/20100101 Firefox/26.0' =>
		'REGULAR CLIENT DETECTED',
	'Opera/3.7 (Windows 2000 2.3; )' => 'REGULAR CLIENT DETECTED',
	'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; Maxthon; .NET CLR 2.0.50727)' =>
		'ROBOT CLIENT DETECTED',
);

foreach my $ua ( keys %tests ) {
	test_psgi(
		app    => $app_with_plugin,
		client => sub {
			my $cb = shift;
			my $req = HTTP::Request->new( GET => "http://localhost/" );
			$req->header( 'User-Agent' => $ua );
			my $res    = $cb->($req);
			my $expect = $tests{$ua};
			like $res->content, qr/$expect/, $ua;
		}
	);
}

done_testing;

