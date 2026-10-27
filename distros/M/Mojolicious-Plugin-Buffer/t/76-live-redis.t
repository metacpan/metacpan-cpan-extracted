use strict;
use warnings;

use Test::More;
use IO::Handle ();
use POSIX ();
use Time::HiRes ();

use Mojolicious::Plugin::Buffer::Lock::Redis;

# Optional live integration test.  It is deliberately outside the normal
# unit tests so a checkout without Redis does not fail:
#
#     MPB_REDIS_URL=redis://127.0.0.1:6379 prove -Ilib t/76-live-redis.t
#
# REDIS_SERVER is accepted as a fallback for environments that already set it.
# Either a URL or a bare host:port is understood.  Either Redis or Redis::Fast
# can drive the client side.  MPB_REDIS_TTL raises the lock TTL used by the
# crash test on a heavily loaded machine.
#
# Either variable names a server for this test, so a server that cannot be
# reached is a failure: a checkout that looks configured for a live Redis but
# silently skips would hide a Redis that is down or a variable pointing at the
# wrong place.  Unset both variables to skip the file.
my ($url, $source);
for my $name (qw(MPB_REDIS_URL REDIS_SERVER)) {
	next unless defined($ENV{$name}) && length($ENV{$name});
	($url, $source) = ($ENV{$name}, $name);
	last;
}
plan skip_all => 'set MPB_REDIS_URL or REDIS_SERVER to a running Redis server'
	unless defined($url);

my $client_class;
for my $module (qw(Redis Redis::Fast)) {
	(my $file = "$module.pm") =~ s{::}{/}g;
	next unless eval { require $file; 1 };
	$client_class = $module;
	last;
}
plan skip_all => 'install Redis or Redis::Fast to run the live Redis test'
	unless $client_class;

# CI checks this line to prove which client ran, so keep it in that shape
diag("the live Redis test is using $client_class");

my $server = $url;
$server =~ s{^redis://}{};

# Redis::Fast takes the same constructor options in current releases, but
# older ones may not, so fall back to the connection string alone rather than
# failing the whole file
sub new_client {
	# Generous socket timeouts: a busy machine can delay a Redis round trip, and
	# a spurious timeout would look like a lock failure
	my $client = eval {
		$client_class->new(
			server        => $server,
			cnx_timeout   => 5,
			read_timeout  => 5,
			write_timeout => 5,
		);
	};
	return $client if ref($client);

	return $client_class->new(server => $server);
}

my $redis = eval { new_client() };
if (my $error = $@) {
	chomp($error);
	die "Cannot create a $client_class client for $url (from $source): $error\n";
}

my $pong = eval { $redis->ping };
if (my $error = $@) {
	chomp($error);
	die "Cannot reach Redis at $url (from $source): $error\n";
}
is($pong, 'PONG', 'the live Redis server is reachable');

my $namespace = 'mpb:live:' . $$ . ':' . int(rand(1_000_000)) . ':';
my @keys;

END {
	for my $key (@keys) {
		eval { $redis->del($key) };
	}
}

my $lock = Mojolicious::Plugin::Buffer::Lock::Redis->new(
	redis     => $redis,
	namespace => $namespace,
	ttl       => 5,
);

my ($guard, $error) = $lock->acquire('live-key');
ok($guard, 'the live Redis lock is acquired');
ok(!defined($error), 'no error acquiring the live lock');
push @keys, $guard->{key} if $guard;

if ($guard) {
	my ($blocked, $blocked_error) = $lock->acquire('live-key');
	ok(!$blocked, 'a second live acquisition is blocked');
	ok(!defined($blocked_error), 'a held live lock is not an error');

	my ($released, $release_error) = $lock->release($guard);
	ok($released, 'the live lock is released');
	ok(!defined($release_error), 'no error releasing the live lock');

	my ($again) = $lock->acquire('live-key');
	ok($again, 'the live lock can be acquired again');
	$lock->release($again) if $again;
}

my ($token_guard) = $lock->acquire('token-key');
ok($token_guard, 'a second live lock is acquired for the token test');
if ($token_guard) {
	my $key = $token_guard->{key};
	push @keys, $key;

	# Simulate the lock expiring and another owner taking it.  Releasing
	# the old guard must not delete the other owner's token.
	$redis->set($key, 'another-owner');
	my ($released, $release_error) = $lock->release($token_guard);
	ok($released, 'releasing a stale live guard does not fail');
	ok(!defined($release_error), 'no error releasing the stale live guard');
	is($redis->get($key), 'another-owner', 'the other owner\'s token survived the stale release');
	$redis->del($key);
}

my $short_lock = Mojolicious::Plugin::Buffer::Lock::Redis->new(
	redis     => $redis,
	namespace => $namespace,
	ttl       => 0.4,
);

my ($expiring) = $short_lock->acquire('ttl-key');
ok($expiring, 'a short-lived live lock is acquired');
push @keys, $expiring->{key} if $expiring;

Time::HiRes::sleep(0.6);

my ($after_expiry) = $short_lock->acquire('ttl-key');
ok($after_expiry, 'the live lock expires after its TTL');
$short_lock->release($after_expiry) if $after_expiry;

subtest 'a worker killed while holding the lock lets the key expire' => sub {
	plan skip_all => 'requires fork' if $^O eq 'MSWin32';

	my $key = 'dead-owner-key';

	# The TTL has to outlast the checks below even on a loaded machine, and a
	# slow box can raise it with MPB_REDIS_TTL; it only costs wall time
	my $ttl = $ENV{MPB_REDIS_TTL} // 2;
	die "MPB_REDIS_TTL must be a positive number of seconds\n"
		unless !ref($ttl) && ($ttl =~ /^\d+(?:\.\d+)?$/) && ($ttl > 0);

	# Every process needs its own connection: a client opened before the fork
	# would be shared, and two processes cannot read one Redis socket
	my $new_lock = sub {
		return Mojolicious::Plugin::Buffer::Lock::Redis->new(
			redis => sub { return new_client() },
			namespace => $namespace,
			ttl       => $ttl,
		);
	};

	# A worker that takes the lock and is then killed, as hypnotoad would do
	pipe(my $holder_reader, my $holder_writer) or die "Cannot create a pipe: $!";
	my $holder_pid = fork;
	defined($holder_pid) or die "Cannot fork: $!";

	if (!$holder_pid) {
		close($holder_reader);
		$holder_writer->autoflush(1);

		my ($child_guard) = $new_lock->()->acquire($key);
		print {$holder_writer}
			($child_guard ? "$child_guard->{key} $child_guard->{token}\n" : "failed\n");
		close($holder_writer);

		# No cleanup runs, so only the TTL can free this lock
		kill('KILL', $$) if $child_guard;
		POSIX::_exit(1);
	}

	close($holder_writer);
	my $holder_line = <$holder_reader>;
	close($holder_reader);
	waitpid($holder_pid, 0);

	ok(defined($holder_line) && ($holder_line =~ /^(\S+) (\S+)\s*$/),
		'the killed worker reported the lock it held') or return;
	my ($lock_key, $dead_token) = ($1, $2);
	push @keys, $lock_key;

	is($redis->get($lock_key), $dead_token, 'the dead worker\'s lock is still in Redis');

	my $owner_lock = $new_lock->();
	my ($blocked, $blocked_error) = $owner_lock->acquire($key);
	ok(!$blocked, 'another process is blocked while the dead worker\'s TTL lasts');
	ok(!defined($blocked_error), 'a lock left by a dead worker is not an error');

	# Wait for the TTL to run out instead of sleeping a fixed margin: the
	# deadline is generous, so a slow machine only makes this take longer
	my $deadline = Time::HiRes::time() + $ttl + 5;
	my ($takeover, $takeover_error);
	while (1) {
		($takeover, $takeover_error) = $owner_lock->acquire($key);
		last if $takeover || defined($takeover_error) || (Time::HiRes::time() >= $deadline);
		Time::HiRes::sleep(0.05);
	}

	ok($takeover, "the lock can be taken over once the $ttl second TTL expires")
		or diag(defined($takeover_error)
			? "Redis error: $takeover_error"
			: 'the lock was still held at the deadline');
	ok(!defined($takeover_error), 'no error taking over the expired lock');
	return unless $takeover;

	# A third process proves the takeover is exclusive across processes, and
	# that it inherits the lock as soon as this one lets go
	pipe(my $taker_reader, my $taker_writer) or die "Cannot create a pipe: $!";
	my $taker_pid = fork;
	defined($taker_pid) or die "Cannot fork: $!";

	if (!$taker_pid) {
		close($taker_reader);
		$taker_writer->autoflush(1);

		my $child_lock = $new_lock->();
		my ($child_guard) = $child_lock->acquire($key);
		print {$taker_writer} ($child_guard ? "acquired\n" : "blocked\n");

		# The parent releases almost at once; a long ceiling only matters when
		# the scheduler is starved, and costs nothing on the normal path
		my $deadline = time + 30;
		while (!$child_guard && (time < $deadline)) {
			select(undef, undef, undef, 0.05);
			($child_guard) = $child_lock->acquire($key);
		}

		print {$taker_writer} ($child_guard ? "acquired\n" : "gave up\n");
		$child_lock->release($child_guard) if $child_guard;
		close($taker_writer);
		POSIX::_exit($child_guard ? 0 : 1);
	}

	close($taker_writer);
	is(scalar(<$taker_reader>), "blocked\n", 'a third process is blocked while the takeover holds the lock');

	# The dead worker's guard must not remove the new owner's token
	my ($stale_released, $stale_error) = $owner_lock->release({key => $lock_key, token => $dead_token});
	ok($stale_released, 'releasing the dead worker\'s guard does not fail');
	ok(!defined($stale_error), 'no error releasing the dead guard');
	is($redis->get($lock_key), $takeover->{token}, 'the live owner\'s token survived the dead guard\'s release');

	my ($still_held) = $owner_lock->acquire($key);
	ok(!$still_held, 'the takeover still holds the lock after the dead guard was released');

	$owner_lock->release($takeover);

	is(scalar(<$taker_reader>), "acquired\n", 'the third process takes the lock over after the release');
	close($taker_reader);
	waitpid($taker_pid, 0);
};

done_testing();
