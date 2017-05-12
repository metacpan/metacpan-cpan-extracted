#!perl

use strict;
use warnings;

use Test::Most;
use Plack::Test;
use Cache::MemoryCache;
use HTTP::Request::Common;

use Plack::Middleware::StaticShared;

my $filtered;
my $m = Plack::Middleware::StaticShared->new({
	cache => Cache::MemoryCache->new,
	base  => 't/static/',
	binds => [
		{
			prefix       => '/.shared.js',
			content_type => 'text/javascript; charset=utf8',
			filter       => sub {
				$filtered++;
				s/replace/foobar/;
				$_;
			}
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
	subtest "js" => sub {
		my $res = $server->(GET '/.shared.js:v1:/js/a.js,/js/b.js,/js/c.js');

		SKIP: {
			skip "can't test on forked server", 1 unless $Plack::Test::Impl eq 'MockHTTP';
			is $filtered, 1;
		};
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/javascript; charset=utf8';
		ok $res->header('ETag');
		is $res->content, "aaajs\nbbbjs\ncccjs\n";

		done_testing;
	};

	subtest "js (second)" => sub {
		my $res = $server->(GET '/.shared.js:v1:/js/a.js,/js/b.js,/js/c.js');
		SKIP: {
			skip "can't test on forked server", 1 unless $Plack::Test::Impl eq 'MockHTTP';
			is $filtered, 1, 'cache';
		};
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/javascript; charset=utf8';
		ok $res->header('ETag');
		is $res->content, "aaajs\nbbbjs\ncccjs\n";

		done_testing;
	};

	subtest "css" => sub {
		my $res = $server->(GET '/.shared.css:v1:/css/a.css,/css/b.css,/css/c.css');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/css; charset=utf8';
		ok $res->header('ETag');
		is $res->content, "aaacss\nbbbcss\nccccss\n";

		done_testing;
	};

	subtest "filter" => sub {
		my $res = $server->(GET '/.shared.js:v1:/js/a.js,/js/b.js,/js/c.js,/js/replace.js');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/javascript; charset=utf8';
		ok $res->header('ETag');
		is $res->content, "aaajs\nbbbjs\ncccjs\nXXX foobar XXX\n";

		done_testing;
	};

	subtest "fallback" => sub {
		my $res = $server->(GET '/');
		is $res->code, 200;
		is $res->content, 'app';

		done_testing;
	};

	subtest "key length" => sub {
		{
			my $key = 'x' x 33;
			my $res = $server->(GET "/.shared.js:$key:/js/a.js,/js/b.js,/js/c.js,/js/replace.js");
			is $res->code, 200;
			is $res->content, 'app';
		};

		{
			my $key = 'x' x 32;
			my $res = $server->(GET "/.shared.js:$key:/js/a.js,/js/b.js,/js/c.js,/js/replace.js");
			is $res->code, 200;
			is $res->header('Content-Type'), 'text/javascript; charset=utf8';
			ok $res->header('ETag');
			is $res->content, "aaajs\nbbbjs\ncccjs\nXXX foobar XXX\n";
		};
		done_testing;
	};


	subtest "upper directory" => sub {
		my $res = $server->(GET '/.shared.css:v1:/css/a.css,../00_compile.t');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/css; charset=utf8';
		ok $res->header('ETag');
		is $res->content, "aaacss\n";

		done_testing;
	};

	subtest "contain not exist file" => sub {
		my $res = $server->(GET "/.shared.js:v1:/js/a.js,/js/b.js,/js/not-exist.js");
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/javascript; charset=utf8';
		ok $res->header('ETag');
		is $res->content, "aaajs\nbbbjs\n";
		done_testing;
	};
};

done_testing;

