use strict;
use warnings;

use Test::More;
use File::Temp ();
use Mojo::IOLoop;
use Mojolicious;
use Test::Mojo;

use Mojolicious::Plugin::Buffer::Lock::File;
use Mojolicious::Plugin::Buffer::Lock::Redis;

{
	package TestCache;

	sub new { bless {data => {}, sets => 0, gets => 0}, shift }

	sub get {
		my ($self, $key) = @_;
		$self->{gets}++;
		return $self->{data}{$key};
	}

	sub set {
		my ($self, $key, $value, $duration) = @_;
		$self->{data}{$key} = $value;
		$self->{sets}++;
		return 1;
	}

	sub remove {
		my ($self, $key) = @_;
		delete $self->{data}{$key};
		return 1;
	}
}

# A stand-in for Redis or Redis::Fast.  It implements the two Lua scripts and
# enough of SET NX PX semantics to test the backend without a server.
{
	package TestRedis;

	sub new { bless {data => {}, calls => [], error => undef}, shift }

	sub fail {
		my ($self, $error) = @_;
		$self->{error} = $error;
		return $self;
	}

	sub eval {
		my ($self, $script, $numkeys, @args) = @_;
		push @{$self->{calls}}, {script => $script, numkeys => $numkeys, args => [@args]};
		die $self->{error} if defined($self->{error});

		my ($key, $token, $ttl) = @args;
		if ($script =~ /redis\.call\('set'/) {
			return 0 if exists($self->{data}{$key});
			$self->{data}{$key} = $token;
			$self->{ttls}{$key}  = $ttl;
			return 1;
		}
		if ($script =~ /redis\.call\('get'/) {
			return 0 unless defined($self->{data}{$key}) && $self->{data}{$key} eq $token;
			delete($self->{data}{$key});
			return 1;
		}

		die "unexpected script";
	}
}

{
	package AutoloadRedis;

	# CPAN Redis has no eval() method; commands such as eval are dispatched
	# through AUTOLOAD.  The backend must accept that kind of client.
	our $AUTOLOAD;

	sub new { bless {}, shift }
	sub DESTROY { }
	sub AUTOLOAD { die "unexpected command $AUTOLOAD" }
}

{
	package FailingLock;

	sub new { bless {}, shift }
	sub acquire { return (undef, 'redis unavailable') }
	sub release { return (1, undef) }
}

{
	package DyingLock;

	sub new { bless {}, shift }
	sub acquire { die "connection refused\n" }
	sub release { return (1, undef) }
}

sub build_app {
	my (%options) = @_;

	my $app = Mojolicious->new;
	$app->log->level('fatal');
	$app->plugin('Buffer', %options);
	$app->{runs} = 0;

	$app->routes->get('/shared' => sub {
		my $c = shift;
		$c->stash(buffer => {cache_key => 'shared-key'});
		return if $c->buffer_is_cached;
		$app->{runs}++;
		$c->render(text => 'local run');
	});

	return $app;
}

sub redis_lock {
	my (%options) = @_;
	return Mojolicious::Plugin::Buffer::Lock::Redis->new(
		redis     => $options{redis} // TestRedis->new,
		namespace => $options{namespace} // 'test:buffer:',
		ttl       => $options{ttl} // 5,
	);
}

subtest 'the Redis backend acquires and releases one lock' => sub {
	my $redis = TestRedis->new;
	my $lock  = redis_lock(redis => $redis);

	my ($first, $error) = $lock->acquire('shared-key');
	ok($first, 'the first acquisition succeeds');
	ok(!defined($error), 'no error');

	my ($second, $second_error) = $lock->acquire('shared-key');
	ok(!$second, 'the second acquisition is blocked');
	ok(!defined($second_error), 'a held lock is not an error');

	my ($released, $release_error) = $lock->release($first);
	ok($released, 'the lock is released');
	ok(!defined($release_error), 'release did not fail');

	my ($third) = $lock->acquire('shared-key');
	ok($third, 'the lock can be acquired again');
	$lock->release($third);

	my $call = $redis->{calls}[0];
	is($call->{numkeys}, 1, 'one Redis key');
	like($call->{args}[0], qr/^test:buffer:[0-9a-f]{32}$/, 'the key is namespaced and digested');
	is($call->{args}[2], 5000, 'the TTL is sent in milliseconds');
	like($call->{script}, qr/'NX', 'PX'/, 'the acquisition is atomic');
};

subtest 'release only removes its own token' => sub {
	my $redis = TestRedis->new;
	my $lock  = redis_lock(redis => $redis);

	my ($guard) = $lock->acquire('shared-key');
	my ($released, $error) = $lock->release({%$guard, token => 'someone else'});
	ok($released, 'a release with the wrong token is a no-op');
	ok(!defined($error), 'no error');

	my ($still_held) = $lock->acquire('shared-key');
	ok(!$still_held, 'the lock is still held');

	$lock->release($guard);
	my ($free) = $lock->acquire('shared-key');
	ok($free, 'the real owner can release it');
	$lock->release($free);

	my ($invalid, $invalid_error) = $lock->release({});
	ok(!$invalid, 'an invalid guard is rejected');
	like($invalid_error, qr/invalid lock guard/, 'the error explains why');
};

subtest 'Redis errors are reported' => sub {
	my $redis = TestRedis->new;
	my $lock  = redis_lock(redis => $redis);

	$redis->fail("connection lost\n");
	my ($guard, $error) = $lock->acquire('shared-key');
	ok(!$guard, 'no guard on a Redis failure');
	like($error, qr/Redis lock failed: connection lost/, 'the Redis error is preserved');

	$redis->fail(undef);
	($guard) = $lock->acquire('shared-key');
	ok($guard, 'the lock works again');

	$redis->fail("write failed\n");
	my ($released, $release_error) = $lock->release($guard);
	ok(!$released, 'release reports a Redis failure');
	like($release_error, qr/Redis unlock failed: write failed/, 'the release error is preserved');
};

subtest 'a Redis client factory is called lazily' => sub {
	my $calls = 0;
	my $lock  = Mojolicious::Plugin::Buffer::Lock::Redis->new(
		redis => sub {
			$calls++;
			return TestRedis->new;
		},
		ttl => 5,
	);

	is($calls, 0, 'the factory is not called while the plugin starts');
	my ($guard) = $lock->acquire('factory-key');
	ok($guard, 'the lock is acquired');
	is($calls, 1, 'the factory was called once');

	$lock->release($guard);
	is($calls, 1, 'release reuses the same client');

	my ($again) = $lock->acquire('factory-key');
	ok($again, 'the lock can be acquired again');
	is($calls, 1, 'the client is cached for the worker');
	$lock->release($again);

	my $broken = Mojolicious::Plugin::Buffer::Lock::Redis->new(
		redis => sub { die "no client\n" },
		ttl   => 5,
	);
	my ($none, $error) = $broken->acquire('factory-key');
	ok(!$none, 'a failing factory does not return a lock');
	like($error, qr/Redis lock failed: no client/, 'the factory exception is reported');
};

subtest 'the plugin waits for a pluggable backend lock' => sub {
	my $cache = TestCache->new;
	my $lock  = redis_lock();
	my $t     = Test::Mojo->new(build_app(
		cache              => $cache,
		cache_lock         => $lock,
		cache_lock_timeout => 2,
	));

	my ($guard) = $lock->acquire('shared-key');
	ok($guard, 'another worker holds the Redis lock');

	# Fill the entry only once the request has joined the wait, so the shared
	# lock path is exercised instead of the first lookup finding an entry.
	# The first cache read is the initial lookup, the second is the first poll.
	my $release_timer;
	$release_timer = Mojo::IOLoop->recurring(0.05 => sub {
		return unless $cache->{gets} >= 2;
		Mojo::IOLoop->remove($release_timer);
		$cache->set('shared-key', {
			body    => 'from another worker',
			status  => 200,
			created => time,
			headers => [['Content-Type', 'text/html;charset=UTF-8']],
		}, '1 minute');
		$lock->release($guard);
	});

	$t->get_ok('/shared')->status_is(200)->header_is('X-Cache' => 'HIT');
	Mojo::IOLoop->remove($release_timer) if $release_timer;
	is($t->tx->res->body, 'from another worker', 'the waiter got the other worker\'s entry');
	is($t->app->{runs}, 0, 'the local action did not run');

	my ($free) = $lock->acquire('shared-key');
	ok($free, 'the Redis lock is free after the wait');
	$lock->release($free);
};

subtest 'a backend failure falls back to a local build' => sub {
	my $cache = TestCache->new;
	my $t     = Test::Mojo->new(build_app(
		cache              => $cache,
		cache_lock         => FailingLock->new,
		cache_lock_timeout => 1,
	));

	$t->get_ok('/shared')->status_is(200)->header_is('X-Cache' => 'MISS');
	is($t->tx->res->body, 'local run', 'the action still ran');
	is($t->app->{runs}, 1, 'one local build');
	is($cache->{sets}, 1, 'the response was cached');
};

subtest 'a dying backend does not break the request' => sub {
	my $cache = TestCache->new;
	my $t     = Test::Mojo->new(build_app(
		cache              => $cache,
		cache_lock         => DyingLock->new,
		cache_lock_timeout => 1,
	));

	$t->get_ok('/shared')->status_is(200)->header_is('X-Cache' => 'MISS');
	is($t->tx->res->body, 'local run', 'the action still ran');
	is($t->app->{runs}, 1, 'one local build');
	is($cache->{sets}, 1, 'the response was cached');
};

# md5_sum dies on characters above 255.  The backends used to hash the key
# directly, so a custom cache_key holding an emoji made every acquire fail and
# quietly fell back to a per-worker build.
subtest 'keys with wide characters can be locked' => sub {
	my $emoji = "page-\x{1F600}";

	my $dir  = File::Temp->newdir;
	my $file = Mojolicious::Plugin::Buffer::Lock::File->new(dir => "$dir");
	my ($guard, $error) = $file->acquire($emoji);
	ok($guard, 'the file backend locks an emoji key') or diag($error);
	my ($blocked) = $file->acquire($emoji);
	ok(!$blocked, 'and the same key is then held');
	$file->release($guard);

	# The same characters must name the same lock however Perl stores them
	my $narrow = "caf\x{e9}";
	my $wide = "caf\x{e9}";
	utf8::upgrade($wide);
	my ($first) = $file->acquire($narrow);
	my ($second) = $file->acquire($wide);
	ok($first && !$second, 'an upgraded and a downgraded string share one lock file');
	$file->release($first);

	my $redis = redis_lock();
	($guard, $error) = $redis->acquire($emoji);
	ok($guard, 'the Redis backend locks an emoji key') or diag($error);
	$redis->release($guard);

	my $app = Mojolicious->new;
	my $log = '';
	open(my $fh, '>', \$log) or die $!;
	$app->log->handle($fh)->level('error');
	$app->plugin('Buffer', cache => TestCache->new, cache_lock_dir => "$dir", cache_key => $emoji);
	$app->routes->get('/' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		$c->render(text => 'built');
	});
	my $t = Test::Mojo->new($app);
	$t->get_ok('/')->status_is(200)->content_is('built');
	unlike($log, qr/shared cache lock failed/, 'the plugin takes the shared lock for an emoji cache_key');
	$t->get_ok('/')->status_is(200)->header_is('X-Cache' => 'HIT');
};

subtest 'cache_lock is validated' => sub {
	eval { Mojolicious->new->plugin('Buffer', cache_lock => {}) };
	like($@, qr/cache_lock must be an object with acquire\(\) and release\(\)/, 'a plain hash is rejected');

	eval { Mojolicious->new->plugin('Buffer', cache_lock => bless({}, 'NoLockMethods')) };
	like($@, qr/cache_lock must be an object with acquire\(\) and release\(\)/, 'the methods are required');

	my $dir = File::Temp->newdir;
	eval {
		Mojolicious->new->plugin('Buffer',
			cache_lock     => redis_lock(),
			cache_lock_dir => "$dir",
		);
	};
	like($@, qr/cache_lock and cache_lock_dir cannot be combined/, 'the two backends are exclusive');

	eval { Mojolicious::Plugin::Buffer::Lock::Redis->new(redis => {}) };
	like($@, qr/redis must be an object with an eval\(\) method or a code reference/, 'a Redis client is required');

	ok(eval { redis_lock(redis => AutoloadRedis->new); 1 },
		'a client that dispatches commands through AUTOLOAD is accepted');

	eval { Mojolicious::Plugin::Buffer::Lock::Redis->new(redis => TestRedis->new, ttl => 0) };
	like($@, qr/ttl must be a positive number/, 'the TTL must be positive');

	my @warnings;
	{
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		eval { Mojolicious::Plugin::Buffer::Lock::Redis->new(redis => TestRedis->new, ttl => undef) };
	}
	like($@, qr/ttl must be a positive number/, 'an undefined TTL is rejected');
	is(scalar(@warnings), 0, 'without an uninitialized-value warning') or diag(@warnings);

	eval { Mojolicious::Plugin::Buffer::Lock::Redis->new(redis => TestRedis->new, namespace => '') };
	like($@, qr/namespace must be a non-empty string/, 'the namespace cannot be empty');
};

done_testing();
