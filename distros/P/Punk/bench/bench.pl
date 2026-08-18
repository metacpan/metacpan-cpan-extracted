#!/usr/bin/env perl
use strict;
use warnings;

# Punk bench gates: each app in bench/apps/ is hosted on Hyperman and
# driven with wrk; requests/sec are reported relative to bare.psgi.
# Server and client share this box, so the numbers are RELATIVE - good
# for the phase gates, not absolute headlines.
#
# Usage: perl bench/bench.pl [WORKERS] [SECONDS] [CONNECTIONS] [apps...]
#   e.g. perl bench/bench.pl 2 5 64
#        perl bench/bench.pl 2 5 64 bare punk-hello

use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch",
        "$FindBin::Bin/../lib";
# Prefer a sibling Hyperman build when there is one, the way t/43-ratelimit.t
# does: server-side features land there first and an installed copy is
# usually a release behind, which shows up here as a server that croaks on an
# unknown option and a silent 0 req/s.
use lib "$FindBin::Bin/../../Hyperman/blib/lib",
        "$FindBin::Bin/../../Hyperman/blib/arch";
use Socket ();
use Time::HiRes ();

my $HOST     = '127.0.0.1';
my $WORKERS  = $ARGV[0] || 2;
my $SECONDS  = $ARGV[1] || 5;
my $CONNS    = $ARGV[2] || 64;
my @APPS     = @ARGV[3 .. $#ARGV];
# The host server. Hyperman by default; PUNK_BENCH_SERVER=Starman (or any
# Plack::Handler name) hosts the same apps elsewhere, which is how you tell
# a framework's cost apart from its server's.
my $SERVER   = $ENV{PUNK_BENCH_SERVER} || 'Hyperman';

if ($SERVER eq 'Hyperman') {
    eval { require Hyperman; 1 } or die "Hyperman required for the bench\n";
}
else {
    require Plack::Loader;
}
system('wrk --version >/dev/null 2>&1') == 0
    or `wrk --help 2>&1` =~ /Usage/ or die "wrk required for the bench\n";

unless (@APPS) {
    opendir my $dh, "$FindBin::Bin/apps" or die $!;
    @APPS = sort map { s/\.psgi\z//r } grep { /\.psgi\z/ } readdir $dh;
    # bare first: it is the denominator
    @APPS = ('bare', grep { $_ ne 'bare' } @APPS);
}

sub free_port {
    socket(my $s, Socket::PF_INET(), Socket::SOCK_STREAM(), 0) or die $!;
    setsockopt($s, Socket::SOL_SOCKET(), Socket::SO_REUSEADDR(), 1);
    bind($s, Socket::pack_sockaddr_in(0, Socket::inet_aton($HOST))) or die $!;
    my $port = (Socket::unpack_sockaddr_in(getsockname $s))[0];
    close $s;
    return $port;
}

# Per-app request path: an app whose route under test is not '/'
# declares it with a "# BENCH-PATH: /some/path" comment.
sub bench_path {
    my ($file) = @_;
    open my $fh, '<', $file or return '/';
    while (<$fh>) { return $1 if /^#\s*BENCH-PATH:\s*(\S+)/ }
    return '/';
}

sub bench_one {
    my ($name) = @_;
    my $file = "$FindBin::Bin/apps/$name.psgi";
    my $path = bench_path($file);
    my $port = free_port();
    # The app is loaded in the child, so no framework an app pulls in can
    # leak into the next one's interpreter.
    my $pid  = fork // die "fork: $!";
    if (!$pid) {
        my $app = do $file;
        die "$file did not compile: " . ($@ || $!) . "\n"
            unless ref $app eq 'CODE';
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        if ($SERVER eq 'Hyperman') {
            # PUNK_BENCH_COMPRESS=1 turns the server's response compression
            # on for the whole run, which is the only way to measure what it
            # costs. Read the bytes-on-wire column alongside the rate: a
            # throughput drop that buys a much smaller response is a pass.
            Hyperman->run(app => $app, host => $HOST, port => $port,
                          workers => $WORKERS,
                          ($ENV{PUNK_BENCH_COMPRESS} ? (compress => 1) : ()));
        }
        else {
            Plack::Loader->load($SERVER, host => $HOST, port => $port,
                                workers => $WORKERS)->run($app);
        }
        exit 0;
    }
    for (1 .. 100) {
        last if IO::Socket::INET->new(PeerAddr => "$HOST:$port");
        Time::HiRes::sleep(0.05);
    }
    # -H Accept-Encoding only when we are measuring compression: wrk sends
    # none by default, so without this the compressed run would measure the
    # uncompressed path and report a flattering non-result.
    my $hdr = $ENV{PUNK_BENCH_COMPRESS} ? q{-H 'Accept-Encoding: gzip'} : '';
    my $out = `wrk -t4 -c$CONNS -d${SECONDS}s $hdr http://$HOST:$port$path 2>&1`;
    kill 'TERM', $pid;
    waitpid $pid, 0;
    my ($rps) = $out =~ /Requests\/sec:\s+([\d.]+)/;
    # bytes on the wire per request: the other half of the compression trade
    my ($xfer) = $out =~ /Transfer\/sec:\s+([\d.]+)(\w+)/ ? "$1$2" : '';
    my ($reqs, $bytes) = ($out =~ /(\d+) requests in [\d.]+\w+, ([\d.]+\w+) read/);
    return ($rps || 0, $reqs && $bytes ? "$bytes/$reqs reqs" : $xfer);
}

require IO::Socket::INET;

my %rps;
for my $name (@APPS) {
    my ($r, $wire) = bench_one($name);
    $rps{$name} = $r;
    printf "%-16s %10.0f req/s%s\n", $name, $r,
           (length $wire ? "   [$wire on the wire]" : '');
}
if ($rps{bare}) {
    print "\nrelative to bare:\n";
    for my $name (grep { $_ ne 'bare' } @APPS) {
        printf "%-16s %6.1f%%\n", $name, 100 * $rps{$name} / $rps{bare};
    }
}
