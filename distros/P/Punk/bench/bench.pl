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
            Hyperman->run(app => $app, host => $HOST, port => $port,
                          workers => $WORKERS);
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
    my $out = `wrk -t4 -c$CONNS -d${SECONDS}s http://$HOST:$port$path 2>&1`;
    kill 'TERM', $pid;
    waitpid $pid, 0;
    my ($rps) = $out =~ /Requests\/sec:\s+([\d.]+)/;
    return $rps || 0;
}

require IO::Socket::INET;

my %rps;
for my $name (@APPS) {
    $rps{$name} = bench_one($name);
    printf "%-16s %10.0f req/s\n", $name, $rps{$name};
}
if ($rps{bare}) {
    print "\nrelative to bare:\n";
    for my $name (grep { $_ ne 'bare' } @APPS) {
        printf "%-16s %6.1f%%\n", $name, 100 * $rps{$name} / $rps{bare};
    }
}
