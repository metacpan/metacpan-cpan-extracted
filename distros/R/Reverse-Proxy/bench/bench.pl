#!/usr/bin/env perl
# Throughput / overhead benchmark for Reverse::Proxy.
#
# The whole point of a reverse proxy is that it sits in front of a backend and
# forwards, so the interesting number is not raw req/s but the OVERHEAD the
# proxy adds over talking to the backend directly. We stand up two real
# Hyperman servers - a plaintext backend and a Reverse::Proxy in front of it -
# and drive both with Fetch as the load client, timing an identical GET
# workload four ways:
#
#   direct  sequential  - Fetch -> backend, one at a time      (baseline)
#   direct  concurrent   - Fetch -> backend, CONC in flight     (baseline)
#   proxy   sequential  - Fetch -> proxy -> backend, one at a time
#   proxy   concurrent   - Fetch -> proxy -> backend, CONC in flight
#
# The proxy runs under Hyperman on the non-blocking path, so the concurrent
# column shows its workers fanning many in-flight requests out to the backend
# on their own loops. We print req/s and the added latency / throughput cost of
# the extra hop.
#
# Everything is co-resident on this box (client, proxy and backend share
# cores), so the numbers are RELATIVE - good for tracking proxy overhead here,
# not for absolute headline figures. In particular the proxy concurrent phase
# lights up BACKEND + PROXY workers at once (each proxied request drives a
# backend request), so with equal worker counts twice as many workers contend
# for cores as in the direct phase. Run from the dist root after `make`:
#   perl -Mblib bench/bench.pl [REQUESTS] [CONCURRENCY] [BACKEND-WORKERS] [PROXY-WORKERS]
# PROXY-WORKERS defaults to BACKEND-WORKERS.

use 5.008003;
use strict;
use warnings;
use FindBin ();
use IO::Socket::INET;
use Time::HiRes qw(time);

# ---- locate the sibling Semantic dists in a dev layout -------------------
# Reverse-Proxy, Fetch and Hyperman sit side by side in Semantic/. Prefer an
# installed copy; fall back to each sibling's blib so the bench runs from a
# freshly-built checkout without installing anything.
BEGIN {
    for my $mod (qw(Fetch Hyperman)) {
        next if eval "require $mod; 1";
        (my $dir = $mod) =~ s/::/-/g;
        my $sib = "$FindBin::Bin/../../$dir";
        unshift @INC, "$sib/blib/lib", "$sib/blib/arch";
        eval "require $mod; 1" or die
            "bench needs $mod (install it, or build the sibling "
          . "Semantic/$dir and re-run): $@\n";
    }
}
use Fetch;
use Reverse::Proxy;

my $N        = shift || 5000;
my $CONC     = shift || 100;
my $WORKERS  = shift || 4;
my $PWORKERS = shift || $WORKERS;   # proxy workers; default = backend workers
my $BODY     = 'x' x 256;

# ---- make room for the concurrent phase ----------------------------------
# The concurrent run keeps CONC client sockets live at once, and each proxied
# request opens a second socket (proxy -> backend), so the proxy worker needs
# room for ~CONC upstream connections too. Perl core cannot setrlimit, so
# re-exec once through the shell (which can raise the soft limit toward the
# hard cap), preserving the blib paths (-Mblib) and our arguments. Guarded by
# an env flag so it happens at most once.
unless ($ENV{RP_BENCH_FDS}) {
    $ENV{RP_BENCH_FDS} = 1;
    my $want = 2 * $CONC + 256;
    my @inc  = grep { m{[\\/]blib[\\/]} } @INC;      # keep -Mblib's effect
    my @perl = ($^X, (map { "-I$_" } @inc), $0, $N, $CONC, $WORKERS, $PWORKERS);
    my $sh   = 'h=$(ulimit -Hn); '
             . 'case "$h" in '
             .   'unlimited) ulimit -n ' . $want . ' 2>/dev/null ;; '
             .   '*) t=' . $want . '; [ "$t" -gt "$h" ] && t="$h"; '
             .      'ulimit -n "$t" 2>/dev/null ;; '
             . 'esac; exec "$@"';
    { exec '/bin/sh', '-c', $sh, 'sh', @perl }       # replaces this process
    warn "bench: could not re-exec to raise the fd limit ($!); "
       . "continuing at the current limit\n";
}
chomp(my $FDLIMIT = `sh -c 'ulimit -n' 2>/dev/null` || '?');

# ---- helpers -------------------------------------------------------------
sub free_port {
    my $s = IO::Socket::INET->new(LocalHost => '127.0.0.1', LocalPort => 0,
        Listen => 1, ReuseAddr => 1) or die "cannot pick a port: $!";
    my $p = $s->sockport; close $s; return $p;
}
sub wait_up {
    my ($port) = @_;
    for (1 .. 100) {
        return 1 if IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
        select undef, undef, undef, 0.1;
    }
    return 0;
}
sub rate { my ($n, $dt) = @_; sprintf "%8.0f req/s  (%.2fs)", $n / $dt, $dt }

# ---- launch the backend (plaintext) --------------------------------------
my $bport = free_port();
my $bpid  = fork // die "fork: $!";
if (!$bpid) {
    open STDERR, '>', '/dev/null';
    Hyperman->run(
        app => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ $BODY ] ] },
        host => '127.0.0.1', port => $bport, workers => $WORKERS,
    );
    exit 0;
}

# ---- launch the proxy in front of it, single non-blocking worker ---------
my $pport = free_port();
my $ppid  = fork // die "fork: $!";
if (!$ppid) {
    open STDERR, '>', '/dev/null';
    my $app = Reverse::Proxy->new(upstream => "http://127.0.0.1:$bport")->to_app;
    Hyperman->run(app => $app, host => '127.0.0.1', port => $pport, workers => $PWORKERS);
    exit 0;
}

END {
    local $?;
    for my $pid ($bpid, $ppid) { next unless $pid; kill 'TERM', $pid; waitpid $pid, 0 }
}

unless (wait_up($bport) && wait_up($pport)) {
    die "bench: backend/proxy did not start\n";
}

my $direct = "http://127.0.0.1:$bport/";
my $proxy  = "http://127.0.0.1:$pport/";

printf "backend : Hyperman (%d workers) on :%d\n", $WORKERS, $bport;
printf "proxy   : Hyperman (%d worker%s, non-blocking) on :%d -> :%d\n",
    $PWORKERS, ($PWORKERS == 1 ? '' : 's'), $pport, $bport;
printf "workload: %d GETs, %d-byte body, concurrency %d  (fd limit %s)\n\n",
    $N, length $BODY, $CONC, $FDLIMIT;

# ---- one Fetch client, reused for every phase ----------------------------
# Size the keep-alive pool to the in-flight set: with CONC connections live at
# once a smaller pool would park only a few and close+reopen the rest each
# wave, churning ephemeral ports instead of reusing connections.
my $loop = Hyperman::Loop->new;
my $ua   = Fetch->new(simple_response => 1, loop => $loop, pool_size => $CONC);

sub run_sequential {
    my ($url) = @_;
    $ua->get($url)->get;                             # warm
    my $t0 = time;
    for (1 .. $N) {
        my $r = $ua->get($url)->get;
        die "bad status $r->{status}" unless $r->{status} == 200;
    }
    return time - $t0;
}

sub run_concurrent {
    my ($url) = @_;
    $ua->get($url)->get;                             # warm
    my $t0   = time;
    my ($sent, $done) = (0, 0);
    my @live;
    my $launch = sub {
        return if $sent >= $N;
        $sent++;
        my $f = $ua->get($url);
        $f->on_ready(sub { $done++ });
        push @live, $f;
    };
    $launch->() for 1 .. $CONC;                       # prime CONC in flight
    # drive the loop until all N complete, topping up the in-flight set
    while ($done < $N) {
        Fetch::Future->needs_all(@live)->get;
        @live = ();
        $launch->() for 1 .. $CONC;
    }
    return time - $t0;
}

# ---- run the four phases -------------------------------------------------
my $ds = run_sequential($direct);
my $ps = run_sequential($proxy);
my $dc = run_concurrent($direct);
my $pc = run_concurrent($proxy);

printf "direct  sequential : %s\n", rate($N, $ds);
printf "proxy   sequential : %s\n", rate($N, $ps);
printf "direct  concurrent : %s  (concurrency %d)\n", rate($N, $dc), $CONC;
printf "proxy   concurrent : %s  (concurrency %d)\n", rate($N, $pc), $CONC;
print  "\n";

# per-request overhead the extra hop adds, and the throughput it costs
printf "overhead sequential: %+.3f ms/req  (%.1f%% throughput)\n",
    ($ps - $ds) / $N * 1000, 100 * ($ds / $ps);
printf "overhead concurrent: %+.3f ms/req  (%.1f%% throughput)\n",
    ($pc - $dc) / $N * 1000, 100 * ($dc / $pc);
