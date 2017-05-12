#!perl

use strict;
use warnings;

use Test::Most;
use Plack::Test;
use Cache::MemoryCache;
use HTTP::Request::Common;

use Plack::Middleware::StaticShared;

my $m = Plack::Middleware::StaticShared->new({
	cache => Cache::MemoryCache->new,
	base  => 't/static/',
	verifier => sub {
		my ($version, $prefix) = @_;
		/v\d/
	},
	binds => [
		{
			prefix       => '/.shared.js',
			content_type => 'text/javascript; charset=utf8',
		},
		{
			prefix       => '/.shared.css',
			content_type => 'text/css; charset=utf8',
		}
	]
});

$m->wrap(sub {
	[200, [ 'Content-Type' => 'text/plain' ], [ 'app' ]  ]
});

test_psgi $m => sub { my $server = shift;
	subtest "ok" => sub {
		my $res = $server->(GET '/.shared.js:v1:/js/a.js,/js/b.js,/js/c.js');

		is $res->code, 200;
		is $res->header('Content-Type'), 'text/javascript; charset=utf8';
		ok $res->header('ETag');
		is $res->content, "aaajs\nbbbjs\ncccjs\n";

		done_testing;
	};

	subtest "ng" => sub {
		my $res = $server->(GET '/.shared.js:XXX:/js/a.js,/js/b.js,/js/c.js');

		is $res->code, 400;

		done_testing;
	};
};

done_testing;

