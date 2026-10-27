use strict;
use warnings;

use Test::More;
use Mojo::Util qw(gunzip);
use Mojolicious;
use Test::Mojo;

{
	package TestCache;

	sub new { bless {data => {}, sets => 0, removes => 0, durations => []}, shift }

	sub get {
		my ($self, $key) = @_;
		return $self->{data}{$key};
	}

	sub set {
		my ($self, $key, $value, $duration) = @_;
		$self->{data}{$key} = $value;
		$self->{sets}++;
		push @{$self->{durations}}, $duration;
		return 1;
	}

	sub remove {
		my ($self, $key) = @_;
		delete $self->{data}{$key};
		$self->{removes}++;
		return 1;
	}
}

sub build_app {
	my (%options) = @_;

	my $app = Mojolicious->new;
	$app->log->level('error');
	$app->plugin('Buffer', %options);
	$app->{runs} = 0;

	my $render = sub {
		my ($c, $label) = @_;
		$app->{runs}++;
		return $label . ' run ' . $app->{runs} . ' query=' . $c->req->url->query->to_string;
	};

	$app->routes->get('/page' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		$c->render(text => $render->($c, 'page'));
	});
	$app->routes->post('/submit' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		$c->render(text => $render->($c, 'submit'));
	});
	$app->routes->get('/other' => sub {
		my $c = shift;
		$c->render(text => $render->($c, 'other'));
	});
	$app->routes->get('/cookie' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		$c->cookie(test => 'yes');
		$c->render(text => $render->($c, 'cookie'));
	});
	$app->routes->get('/private' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		$c->res->headers->cache_control('no-store');
		$c->render(text => $render->($c, 'private'));
	});
	$app->routes->get('/vary' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		$c->res->headers->vary('Accept-Language');
		$c->render(text => $render->($c, 'vary'));
	});
	$app->routes->get('/long' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		$app->{runs}++;
		$c->render(text => ('The quick brown fox jumps over the lazy dog. ' x 10)
			. 'run ' . $app->{runs} . ' query=' . $c->req->url->query->to_string);
	});
	$app->routes->get('/missing' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		$c->render(text => $render->($c, 'missing'), status => 404);
	});
	$app->routes->get('/broken' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		$c->render(text => $render->($c, 'broken'), status => 500);
	});
	$app->routes->get('/header' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		$c->res->headers->header('X-Page' => 'yes');
		$c->render(text => $render->($c, 'header'));
	});
	$app->routes->get('/keyed' => sub {
		my $c = shift;
		$c->stash(buffer => {cache_key => 'shared-key'});
		return if $c->buffer_is_cached;
		$c->render(text => $render->($c, 'keyed'));
	});
	$app->routes->get('/off' => sub {
		my $c = shift;
		$c->stash(buffer => {cache => undef});
		return if $c->buffer_is_cached;
		$c->render(text => $render->($c, 'off'));
	});
	$app->routes->get('/all-off' => sub {
		my $c = shift;
		$c->stash(buffer => 0);
		return if $c->buffer_is_cached;
		$c->render(text => $render->($c, 'all-off'));
	});

	return $app;
}

sub new_test {
	my (%options) = @_;
	my $cache = $options{cache};
	my $app = build_app(%options);
	my $t = Test::Mojo->new($app);
	$t->ua->transactor->compressed(0);
	return ($app, $t, $cache);
}

subtest 'miss then hit' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache);

	$t->get_ok('/page')->status_is(200)->header_is('X-Cache' => 'MISS');
	my $first = $t->tx->res->body;
	like($first, qr/^page run 1 /, 'the action ran');
	is($app->{runs}, 1, 'one run');
	is($cache->{sets}, 1, 'the response was cached');

	$t->get_ok('/page')->status_is(200)->header_is('X-Cache' => 'HIT');
	is($t->tx->res->body, $first, 'the cached body was replayed');
	is($app->{runs}, 1, 'the action did not run again');
	is($cache->{sets}, 1, 'the hit did not reset the entry');
};

subtest 'the key includes the query string' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache);

	$t->get_ok('/page?x=1')->status_is(200)->header_is('X-Cache' => 'MISS');
	my $one = $t->tx->res->body;
	$t->get_ok('/page?x=2')->status_is(200)->header_is('X-Cache' => 'MISS');
	my $two = $t->tx->res->body;
	isnt($one, $two, 'different queries are different entries');
	is($app->{runs}, 2, 'both queries ran the action');

	$t->get_ok('/page?x=1')->status_is(200)->header_is('X-Cache' => 'HIT');
	is($t->tx->res->body, $one, 'the first query hit its own entry');
};

subtest 'cookies are part of the key by default' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache);

	$t->get_ok('/page' => {Cookie => 'session=one'})->status_is(200)->header_is('X-Cache' => 'MISS');
	my $one = $t->tx->res->body;
	$t->get_ok('/page' => {Cookie => 'session=two'})->status_is(200)->header_is('X-Cache' => 'MISS');
	isnt($t->tx->res->body, $one, 'a different session does not see the first one');
	is($app->{runs}, 2, 'both sessions ran the action');

	$t->get_ok('/page' => {Cookie => 'session=one'})->status_is(200)->header_is('X-Cache' => 'HIT');
	is($t->tx->res->body, $one, 'the first session hits its own entry');
};

subtest 'pages that do not call the helper are not cached' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache);

	$t->get_ok('/other')->status_is(200);
	my $first = $t->tx->res->body;
	$t->get_ok('/other')->status_is(200);
	isnt($t->tx->res->body, $first, 'the action ran again');
	is($app->{runs}, 2, 'two runs');
	is($cache->{sets}, 0, 'nothing was stored');
	ok(!defined($t->tx->res->headers->header('X-Cache')), 'no cache header');
};

subtest 'requests that must bypass the cache' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache);

	$t->get_ok('/page' => {'Cache-Control' => 'no-cache'})->status_is(200);
	my $first = $t->tx->res->body;
	$t->get_ok('/page' => {'Cache-Control' => 'no-cache'})->status_is(200);
	isnt($t->tx->res->body, $first, 'no-cache always runs the action');
	is($cache->{sets}, 0, 'no-cache is not stored');

	$t->get_ok('/page' => {Authorization => 'Basic abc'})->status_is(200);
	my $auth = $t->tx->res->body;
	$t->get_ok('/page' => {Authorization => 'Basic abc'})->status_is(200);
	isnt($t->tx->res->body, $auth, 'an authorized request is not cached');
	is($cache->{sets}, 0, 'nothing was stored');

	$t->post_ok('/submit' => form => {a => 1})->status_is(200);
	my $posted = $t->tx->res->body;
	$t->post_ok('/submit' => form => {a => 1})->status_is(200);
	isnt($t->tx->res->body, $posted, 'POST is not cached');
};

# Cache-Control is parsed as a list of directives, not searched with a
# regular expression, so a directive is only recognised by its exact name
subtest 'Cache-Control directives are parsed, not pattern matched' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache);

	for my $control ('max-age=0', 'MAX-AGE = 0', 'public, no-store', 'private="X-Foo"') {
		$t->get_ok('/page' => {'Cache-Control' => $control})->status_is(200);
		$t->header_isnt('X-Cache' => 'HIT', "'$control' bypasses the cache");
	}
	is($cache->{sets}, 0, 'none of those was stored');

	# A directive that merely starts with a forbidding name is someone
	# else's extension, and a non-zero max-age is ordinary revalidation
	$t->get_ok('/page' => {'Cache-Control' => 'no-cache-extension'})->status_is(200)
		->header_is('X-Cache' => 'MISS');
	$t->get_ok('/page' => {'Cache-Control' => 'max-age=60'})->status_is(200)
		->header_is('X-Cache' => 'HIT', 'max-age=60 may use the entry');
};

subtest 'responses that must not be stored' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache);

	$t->get_ok('/cookie')->status_is(200);
	my $cookie = $t->tx->res->body;
	$t->get_ok('/cookie')->status_is(200);
	isnt($t->tx->res->body, $cookie, 'a response that sets a cookie is not stored');

	$t->get_ok('/private')->status_is(200);
	my $private = $t->tx->res->body;
	$t->get_ok('/private')->status_is(200);
	isnt($t->tx->res->body, $private, 'Cache-Control: no-store is not stored');

	$t->get_ok('/vary')->status_is(200);
	my $vary = $t->tx->res->body;
	$t->get_ok('/vary')->status_is(200);
	isnt($t->tx->res->body, $vary, 'Vary on a header that is not in the key is not stored');

	# Only 200 responses are stored: an error page must not stick, or a
	# page that was missing for a moment would stay missing until expiry
	for my $error ([missing => 404], [broken => 500]) {
		my ($path, $status) = @{$error};
		$t->get_ok("/$path")->status_is($status);
		my $first = $t->tx->res->body;
		ok(!defined($t->tx->res->headers->etag), "a $status response has no ETag");
		$t->get_ok("/$path")->status_is($status);
		isnt($t->tx->res->body, $first, "a $status response is not stored");
	}

	is($cache->{sets}, 0, 'nothing was stored');
};

subtest 'vary_by makes a response with Vary cacheable' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache, vary_by => ['cookie', 'accept-language']);

	$t->get_ok('/vary' => {'Accept-Language' => 'en'})->status_is(200)->header_is('X-Cache' => 'MISS');
	my $english = $t->tx->res->body;

	$t->get_ok('/vary' => {'Accept-Language' => 'fr'})->status_is(200)->header_is('X-Cache' => 'MISS');
	isnt($t->tx->res->body, $english, 'a different language gets a different entry');

	$t->get_ok('/vary' => {'Accept-Language' => 'en'})->status_is(200)->header_is('X-Cache' => 'HIT');
	is($t->tx->res->body, $english, 'the first language hits its own entry');
	like($t->tx->res->headers->vary // '', qr/Accept-Language/, 'the response Vary header is replayed');
	is($app->{runs}, 2, 'two runs');
};

subtest 'custom headers are replayed' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache);

	$t->get_ok('/header')->status_is(200)->header_is('X-Page' => 'yes');
	$t->get_ok('/header')->status_is(200)->header_is('X-Cache' => 'HIT');
	$t->header_is('X-Page' => 'yes');
	$t->header_is('Content-Type' => 'text/html;charset=UTF-8');
};

subtest 'a cached page still supports conditional requests' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache);

	$t->get_ok('/page')->status_is(200);
	my $etag = $t->tx->res->headers->etag;
	ok(defined($etag), 'the first response has an ETag');

	$t->get_ok('/page' => {'If-None-Match' => $etag})->status_is(304)->header_is('X-Cache' => 'HIT');
	is($t->tx->res->body, '', '304 has no body');
};

subtest 'a cache hit is still compressed for the client' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache);

	$t->get_ok('/long' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	is($t->tx->res->headers->content_encoding, 'gzip', 'the miss is compressed');
	my $first = $t->tx->res->body;

	$t->get_ok('/long' => {'Accept-Encoding' => 'gzip'})->status_is(200)->header_is('X-Cache' => 'HIT');
	is($t->tx->res->headers->content_encoding, 'gzip', 'the hit is compressed');
	like(gunzip($t->tx->res->body), qr/run 1 query=/, 'the hit gunzips to the page');
	is(gunzip($t->tx->res->body), gunzip($first), 'the hit body matches the miss body');

	my ($entry) = values %{$cache->{data}};
	ok(!utf8::is_utf8($entry->{body}), 'the stored body is bytes');
	unlike($entry->{body}, qr/^\x1f\x8b/, 'the stored body is not compressed');
	ok(!grep({ lc($_->[0]) eq 'content-encoding' } @{$entry->{headers}}), 'no Content-Encoding is stored');
};

subtest 'cache_duration is passed to the cache' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache, cache_duration => 42);

	$t->get_ok('/page')->status_is(200);
	is_deeply($cache->{durations}, [42], 'the configured duration is used');

	my $default = TestCache->new;
	my ($app2, $t2) = new_test(cache => $default);
	$t2->get_ok('/page')->status_is(200);
	is_deeply($default->{durations}, ['10 minutes'], 'the default duration is used');
};

subtest 'cache_key overrides the generated key' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache);

	$t->get_ok('/keyed?a=1')->status_is(200)->header_is('X-Cache' => 'MISS');
	my $first = $t->tx->res->body;

	$t->get_ok('/keyed?a=2')->status_is(200)->header_is('X-Cache' => 'HIT');
	is($t->tx->res->body, $first, 'both URLs share one key');
	is($app->{runs}, 1, 'the action ran once');
};

subtest 'the cache can be disabled per response' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache);

	$t->get_ok('/off')->status_is(200);
	my $first = $t->tx->res->body;
	$t->get_ok('/off')->status_is(200);
	isnt($t->tx->res->body, $first, 'the action ran again');
	is($cache->{sets}, 0, 'nothing was stored');
	ok(!defined($t->tx->res->headers->header('X-Cache')), 'no cache header');

	$t->get_ok('/all-off')->status_is(200);
	my $all = $t->tx->res->body;
	$t->get_ok('/all-off')->status_is(200);
	isnt($t->tx->res->body, $all, 'buffer => 0 also disables the cache');
};

subtest 'entries older than the application are discarded' => sub {
	my $cache = TestCache->new;
	my ($app, $t) = new_test(cache => $cache);

	$t->get_ok('/page')->status_is(200)->header_is('X-Cache' => 'MISS');
	my $first = $t->tx->res->body;

	$_->{created} = 1 for values %{$cache->{data}};
	$t->get_ok('/page')->status_is(200)->header_is('X-Cache' => 'MISS');
	isnt($t->tx->res->body, $first, 'a stale entry is not used');
	is($cache->{removes}, 1, 'the stale entry was removed');
};

subtest 'no cache configured' => sub {
	my ($app, $t) = new_test();

	$t->get_ok('/page')->status_is(200);
	my $first = $t->tx->res->body;
	$t->get_ok('/page')->status_is(200);
	isnt($t->tx->res->body, $first, 'the helper is a no-op without a cache');
};

subtest 'works with CHI' => sub {
	eval { require CHI; 1 } or plan skip_all => 'CHI is required for this test';

	my $chi = CHI->new(driver => 'Memory', datastore => {});
	my ($app, $t) = new_test(cache => $chi);

	$t->get_ok('/page')->status_is(200)->header_is('X-Cache' => 'MISS');
	my $first = $t->tx->res->body;
	$t->get_ok('/page')->status_is(200)->header_is('X-Cache' => 'HIT');
	is($t->tx->res->body, $first, 'CHI serves the second request');
	is($app->{runs}, 1, 'the action ran once');
};

done_testing();
