use strict;
use warnings;

use Plack::Test;
use Plack::Builder;
use Test::More tests => 25;
use HTTP::Request::Common;

my $did_run;
my $app = sub { $did_run = 1; [ 200, [ 'Content-Type' => 'text/plain' ], [ $_[0]{'PATH_INFO'} ] ] };

my $xhtml = 'application/xhtml+xml';

$app = builder {
	enable 'Rewrite', request => sub {
		return [301]
			if s{^/foo/?$}{/bar/};

		return [201]
			if $_ eq '/favicon.ico';

		return [404, [ 'Content-Type' => 'text/plain' ], [ 'Goodbye Web' ] ]
			if $_ eq '/die';

		return [302, [ Location => 'http://localhost/correct' ], [] ]
			if m{^/psgi-redirect};

		return [302, [ qw( Content-Length 0 ) ], [] ]
			if s{^/nobody/?$}{/somebody/};

		return [303]
			if s{^/fate/?$}{/tempted<'&">badly/};

		return []
			if m{^/empty-array};

		s{^/baz$}{/quux};
	};
	$app;
};

test_psgi app => $app, client => sub {
	my $_cb = shift;
	my $cb = sub { $did_run = 0; &$_cb };

	my $res;

	$res = $cb->( GET 'http://localhost/' );
	is $did_run, 1, 'Pass-through works';
	is $res->code, 200, '... and leaves status alone';
	is $res->content, '/', '... as well as the the body';
	is $res->header( 'Content-Type' ), 'text/plain', '... and existing headers';
	ok !$res->header( 'Location' ), '... without adding any';

	$res = $cb->( GET 'http://localhost/favicon.ico' );
	is $did_run, 0, 'Intercepts prevent execution of the wrapped app';

	$res = $cb->( GET 'http://localhost/baz' );
	is $res->content, '/quux', 'Internal rewrites affect the wrapped app';
	ok !$res->header( 'Location' ), '... without redirecting';

	{ my $t = 'http://localhost/bar/';
	$res = $cb->( GET 'http://localhost/foo' );
	is $did_run, 0, 'Redirects prevent execution of the wrapped app';
	is $res->code, 301, '... and change the status';
	is $res->header( 'Location' ), $t, '... and produce the right Location';
	is $res->header( 'Content-Type' ), 'text/html', '... with a proper Content-Type';
	like $res->content, qr!<a href="\Q$t\E">!, '... for the stub body';
	}

	$res = $cb->( GET 'http://localhost/fate' );
	like $res->content, qr!<a href="http://localhost/tempted(?i:(?:&lt;|%3c)(?:&#39;|%27)(?:&amp;|%26)(?:&quot;|%22)(?:&gt;|%3e))badly/">!, '... which is XSS-safe';

	$res = $cb->( GET 'http://localhost/favicon.ico' );
	is $res->code, 201, 'Body-less statuses are recognized';
	ok !$res->content, '... and no body generated for them';

	$res = $cb->( GET 'http://localhost/foo?q=baz' );
	is $res->header( 'Location' ), 'http://localhost/bar/?q=baz', 'Query strings are untouched';

	$res = $cb->( GET 'http://localhost/die' );
	is $res->code, 404, 'Responses can be wholly fabricated';
	is $res->header( 'Content-Type' ), 'text/plain', '... with headers';
	is $res->content, 'Goodbye Web', '... body, and all.';

	$res = $cb->( GET 'http://localhost/psgi-redirect' );
	is $res->code, 302, 'Fabricated responses can be redirects';
	is $res->header( 'Location' ), 'http://localhost/correct', '... with proper destination';

	$res = $cb->( GET 'http://localhost/nobody' );
	ok !$res->content, '... and can eschew the auto-generated body';

	$res = $cb->( GET 'http://localhost/empty-array' );
	is $did_run, 0, '... but must contain *some*thing in order to be recognized';
};

test_psgi app => builder {
	enable 'Rewrite', request => sub {};
	sub { [ 301, [ qw( Location http://localhost/ ) ], [] ] };
}, client => sub {
	my $cb = shift;
	my $res = $cb->( GET 'http://localhost/' );
	ok !$res->content, 'Redirects from the wrapped app are passed through untouched';
};
