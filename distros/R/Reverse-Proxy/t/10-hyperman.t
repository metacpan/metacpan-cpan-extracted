use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Time::HiRes qw(time);

# The non-blocking path: proxying under Hyperman must forward with Fetch on the
# worker's own loop, so a SINGLE proxy worker serves many concurrent requests
# at once. We put a deliberately slow backend behind the proxy and fire N
# requests through it concurrently: if the proxy is non-blocking the total time
# is ~one backend delay; if it blocked, it would be ~N delays.

BEGIN {
	plan skip_all => 'Hyperman required for the async proxy test'
		unless eval { require Hyperman; 1 };
	plan skip_all => 'Fetch required'
		unless eval { require Fetch; 1 };
}
use Reverse::Proxy;

my $DELAY = 0.2;   # backend think-time per request
my $N     = 8;     # concurrent requests through the proxy

sub free_port {
	my $s = IO::Socket::INET->new(LocalHost=>'127.0.0.1', LocalPort=>0,
		Listen=>1, ReuseAddr=>1) or die "listen: $!";
	my $p = $s->sockport; close $s; return $p;
}
sub wait_up {
	my ($port) = @_;
	for (1..100) { return 1 if IO::Socket::INET->new(PeerAddr=>"127.0.0.1:$port");
		select undef,undef,undef,0.1; }
	return 0;
}

# ---- slow backend (Hyperman, async delay) --------------------------------
my $bport = free_port();
my $bpid  = fork // die "fork: $!";
if (!$bpid) {
	open STDERR, '>', '/dev/null';
	Hyperman->run(
		app => sub {
			Hyperman->timer($DELAY)->then(sub {
				[ 200, [ 'Content-Type' => 'text/plain' ], [ 'backend-ok' ] ];
			});
		},
		host => '127.0.0.1', port => $bport, workers => 2,
	);
	exit 0;
}

# ---- the proxy, under Hyperman with a SINGLE worker ----------------------
my $pport = free_port();
my $ppid  = fork // die "fork: $!";
if (!$ppid) {
	open STDERR, '>', '/dev/null';
	my $app = Reverse::Proxy->new(upstream => "http://127.0.0.1:$bport")->to_app;
	Hyperman->run(app => $app, host => '127.0.0.1', port => $pport, workers => 1);
	exit 0;
}

if (!wait_up($bport) || !wait_up($pport)) {
	kill 'TERM', $bpid, $ppid; waitpid $bpid, 0; waitpid $ppid, 0;
	plan skip_all => 'backend/proxy did not start';
}

# ---- fire N concurrent requests through the proxy ------------------------
my $ua = Fetch->new(pool_size => $N);
my @f  = map { $ua->get("http://127.0.0.1:$pport/") } 1 .. $N;
my $t0 = time;
Fetch::Future->needs_all(@f)->get;
my $elapsed = time - $t0;

my $ok = grep { $_->get->status == 200 && $_->get->content eq 'backend-ok' } @f;
is($ok, $N, "all $N requests proxied successfully");

# concurrent: ~1 delay; serialized on one worker would be ~$N delays.
cmp_ok($elapsed, '<', $DELAY * $N / 2,
	sprintf('one proxy worker served %d concurrent requests non-blocking (%.2fs, serial would be ~%.1fs)',
		$N, $elapsed, $DELAY * $N));

END {
	local $?;
	for my $pid ($bpid, $ppid) { next unless $pid; kill 'TERM', $pid; waitpid $pid, 0 }
}

done_testing();
