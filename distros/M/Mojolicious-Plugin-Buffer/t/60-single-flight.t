use strict;
use warnings;

use Test::More;
use Mojo::IOLoop;
use Mojo::Promise;
use Mojolicious;
use Test::Mojo;

{
	package TestCache;

	sub new { bless {data => {}, sets => 0, removes => 0}, shift }

	sub get {
		my ($self, $key) = @_;
		return $self->{data}{$key};
	}

	sub set {
		my ($self, $key, $value) = @_;
		$self->{data}{$key} = $value;
		$self->{sets}++;
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

	# An asynchronous action, so that a second request can arrive while the
	# first one is still working
	$app->routes->get('/slow' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		my $run = ++$app->{runs};
		$c->render_later;
		Mojo::IOLoop->timer(0.4 => sub { $c->render(text => "slow run $run") });
	});

	# The same, but the response sets a cookie and so cannot be cached
	$app->routes->get('/cookie' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		my $run = ++$app->{runs};
		$c->render_later;
		Mojo::IOLoop->timer(0.4 => sub {
			$c->cookie(flavour => 'test');
			$c->render(text => "cookie run $run");
		});
	});

	# Slower than the lock timeout
	$app->routes->get('/hang' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		my $run = ++$app->{runs};
		$c->render_later;
		Mojo::IOLoop->timer(0.8 => sub { $c->render(text => "hang run $run") });
	});

	return $app;
}

sub new_test {
	my (%options) = @_;
	return Test::Mojo->new(build_app(%options));
}

# Start all of the requests before any of them can finish, then wait for the
# lot.  Returns the transactions in the order the requests were made.
sub fetch_all {
	my ($ua, $headers, @urls) = @_;

	my @promises = map { defined($headers) ? $ua->get_p($_ => $headers) : $ua->get_p($_) } @urls;
	my @tx;
	Mojo::Promise->all(@promises)->then(sub {
		push @tx, map { $_->[0] } @_;
	})->wait;

	return @tx;
}

sub x_cache {
	my @values = map { $_->res->headers->header('X-Cache') // 'none' } @_;
	return join ',', sort @values;
}

subtest 'concurrent misses run the action once' => sub {
	my $cache = TestCache->new;
	my $t = new_test(cache => $cache, cache_lock_timeout => 2);

	my @tx = fetch_all($t->ua, undef, '/slow', '/slow', '/slow');

	is(scalar @tx, 3, 'all requests finished');
	is($t->app->{runs}, 1, 'the action ran once');
	is($tx[0]->res->code, 200, 'the first request succeeded');
	is($tx[1]->res->code, 200, 'the second request succeeded');
	is($tx[2]->res->code, 200, 'the third request succeeded');
	is($tx[1]->res->body, $tx[0]->res->body, 'the second request got the same page');
	is($tx[2]->res->body, $tx[0]->res->body, 'the third request got the same page');
	is(x_cache(@tx), 'HIT,HIT,MISS', 'one request built the entry, the others replayed it');
	is($cache->{sets}, 1, 'the entry was written once');

	my ($waiter) = grep { ($_->res->headers->header('X-Cache') // '') eq 'HIT' } @tx;
	my $etag = $waiter->res->headers->etag;
	ok(defined($etag), 'the waiting request still has an ETag');

	my @conditional = fetch_all($t->ua, {'If-None-Match' => $etag}, '/slow');
	is($conditional[0]->res->code, 304, 'a conditional request to the entry is not modified');
	like($conditional[0]->res->headers->header('X-Cache') // '', qr/^HIT$/, 'the conditional request hit the cache');
	is($t->app->{runs}, 1, 'the action still ran once');
};

subtest 'different keys do not wait for each other' => sub {
	my $cache = TestCache->new;
	my $t = new_test(cache => $cache, cache_lock_timeout => 2);

	my @tx = fetch_all($t->ua, undef, '/slow?a=1', '/slow?a=2');

	is($t->app->{runs}, 2, 'both keys ran the action');
	is(x_cache(@tx), 'MISS,MISS', 'both were misses');

	# Requests can be dispatched in either order, so do not tie a run number
	# to a particular transaction; each key must still get its own response.
	my @bodies = map { $_->res->body } @tx;
	isnt($bodies[0], $bodies[1], 'the two requests got different pages');
	is_deeply([sort @bodies], ['slow run 1', 'slow run 2'], 'each key ran its own action');
};

subtest 'single-flight can be turned off' => sub {
	my $cache = TestCache->new;
	my $t = new_test(cache => $cache, cache_single_flight => 0);

	my @tx = fetch_all($t->ua, undef, '/slow', '/slow');

	is($t->app->{runs}, 2, 'both requests ran the action');
	is(x_cache(@tx), 'MISS,MISS', 'neither request waited');
	is($cache->{sets}, 2, 'both responses were written');
};

subtest 'waiters are told to retry when the response cannot be cached' => sub {
	my $cache = TestCache->new;
	my $t = new_test(cache => $cache, cache_lock_timeout => 2);

	my @tx = fetch_all($t->ua, undef, '/cookie', '/cookie');

	is($t->app->{runs}, 1, 'the action ran once');
	is_deeply([sort map { $_->res->code } @tx], [200, 503], 'one response and one retry');

	my ($unavailable) = grep { $_->res->code == 503 } @tx;
	is($unavailable->res->headers->header('Retry-After'), 1, 'the retry response says when to come back');
	is($unavailable->res->headers->header('Cache-Control'), 'no-store', 'the retry response is not cacheable');
	is($cache->{sets}, 0, 'nothing was stored');
};

subtest 'waiters give up after the lock timeout' => sub {
	my $cache = TestCache->new;
	my $t = new_test(cache => $cache, cache_lock_timeout => 0.15);

	my @tx = fetch_all($t->ua, undef, '/hang', '/hang');

	is($t->app->{runs}, 1, 'the action ran once');
	is_deeply([sort map { $_->res->code } @tx], [200, 503], 'the waiter stopped waiting');
	is($cache->{sets}, 1, 'the slow response was still cached');

	my @after = fetch_all($t->ua, undef, '/hang');
	is($after[0]->res->headers->header('X-Cache'), 'HIT', 'the finished response is available afterwards');
	is($t->app->{runs}, 1, 'the action did not run again');
};

done_testing();
