#!perl

use strict;
use warnings;

use Plack::Middleware::MCCS;
use Plack::Builder;
use Plack::Util;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;
use Test2::V0;

my $handler = builder {
	enable 'Plack::Middleware::MCCS',
		path => qr{^/style\.[^.]+$},
		root => 't/rootdir/example1.com';

	enable 'Plack::Middleware::MCCS',
		path => sub { s!^/rootdir!!},
		root => 't/rootdir/example1.com';

	sub {
		[200, ['Content-Type' => 'text/plain', 'Content-Length' => 2], ['ok']]
	};
};

test_psgi
	app => $handler,
	client => sub {
		my $cb  = shift;

		my $req = HTTP::Request->new(GET => '/style.css');
		my $res = $cb->($req);
		is $res->content, 'h1{font-size:1.5em;font-weight:bold}#something{text-decoration:underline;font-style:italic}img{width:auto;height:auto;border:0}a{outline:0}footer{display:none}';

		$req = HTTP::Request->new(GET => '/rootdir/style.css');
		$res = $cb->($req);
		is $res->content, 'h1{font-size:1.5em;font-weight:bold}#something{text-decoration:underline;font-style:italic}img{width:auto;height:auto;border:0}a{outline:0}footer{display:none}';

		$req = HTTP::Request->new(GET => '/something_else');
		$res = $cb->($req);
		is $res->content, 'ok';
	};

done_testing;
