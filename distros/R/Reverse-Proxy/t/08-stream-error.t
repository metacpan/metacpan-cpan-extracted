use strict;
use warnings;
use Test::More;
use IO::Socket::INET;

# Streaming mode, upstream failure. On the non-blocking (loop) path a refused
# upstream drives the streaming on_done(ok=0) callback, which must still emit a
# 502 through the psgi.streaming responder/writer rather than leaving the client
# hanging. (On a blocking server Fetch raises the transport error instead, so
# this path is only exercised under an event loop - hence Hyperman here.)

BEGIN {
	plan skip_all => 'Hyperman required for the async streaming-error test'
		unless eval { require Hyperman; 1 };
	plan skip_all => 'Fetch required'
		unless eval { require Fetch; 1 };
}
use Reverse::Proxy;

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

# A dead upstream: reserve a port then release it, so connecting is refused.
my $dead = free_port();

# ---- the proxy (streaming) under Hyperman --------------------------------
my $pport = free_port();
my $ppid  = fork // die "fork: $!";
if (!$ppid) {
	open STDERR, '>', '/dev/null';
	my $app = Reverse::Proxy->new(
		upstream => "http://127.0.0.1:$dead", stream => 1, timeout => 3,
	)->to_app;
	Hyperman->run(app => $app, host => '127.0.0.1', port => $pport, workers => 1);
	exit 0;
}

if (!wait_up($pport)) {
	kill 'TERM', $ppid; waitpid $ppid, 0;
	plan skip_all => 'proxy did not start';
}

# ---- request through the proxy: the dead upstream must surface as a 502 ----
my $ua  = Fetch->new;
my $res = $ua->get("http://127.0.0.1:$pport/")->get;

is($res->status, 502, 'streaming request to a dead upstream yields 502 to the client');
like($res->content, qr/Bad Gateway/, '502 body written through the streaming writer');

END {
	local $?;
	if ($ppid) { kill 'TERM', $ppid; waitpid $ppid, 0 }
}

done_testing();
