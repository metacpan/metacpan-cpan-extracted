#!/usr/bin/env perl
use strict;
use warnings;

# The framework on its own: no sockets, no server, no client. Each app's
# PSGI coderef is called in a loop with a freshly built environment and its
# body is drained, so what is left is what the framework does per request.
#
# Every app is measured in its own child from a clean interpreter, and the
# best of REPS rounds is reported - the best round is the one least
# disturbed by the rest of the machine.
#
# Usage: perl bench/dispatch.pl [ITERATIONS] [REPS] [apps...]

use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch",
        "$FindBin::Bin/../lib";
use Time::HiRes ();

my $ITERS = $ARGV[0] || 20_000;
my $REPS  = $ARGV[1] || 5;
my @APPS  = @ARGV[2 .. $#ARGV];

unless (@APPS) {
    opendir my $dh, "$FindBin::Bin/apps" or die $!;
    @APPS = sort map { s/\.psgi\z//r } grep { /\.psgi\z/ } readdir $dh;
    @APPS = ('bare', grep { $_ ne 'bare' } @APPS);
}

sub bench_path {
    my ($file) = @_;
    open my $fh, '<', $file or return '/';
    while (<$fh>) { return $1 if /^#\s*BENCH-PATH:\s*(\S+)/ }
    return '/';
}

# A PSGI environment the way a server would hand one over: a new hash per
# request (frameworks cache things in it, so it must not be reused), over
# one shared empty input handle - opening one per iteration would cost more
# than the dispatch being measured.
my $EMPTY = '';
open my $IN, '<', \$EMPTY or die $!;
sub env_for {
    my ($path) = @_;
    my $in = $IN;
    seek $in, 0, 0;
    return {
        REQUEST_METHOD  => 'GET',   PATH_INFO       => $path,
        QUERY_STRING    => '',      SCRIPT_NAME     => '',
        SERVER_NAME     => '127.0.0.1', SERVER_PORT => 80,
        SERVER_PROTOCOL => 'HTTP/1.1',  HTTP_HOST   => '127.0.0.1',
        REMOTE_ADDR     => '127.0.0.1',
        HTTP_USER_AGENT => 'bench',
        HTTP_ACCEPT     => '*/*',
        'psgi.version'  => [1, 1], 'psgi.url_scheme' => 'http',
        'psgi.input'    => $in,    'psgi.errors'     => \*STDERR,
        'psgi.multithread' => 0,   'psgi.multiprocess' => 1,
        'psgi.run_once' => 0,      'psgi.nonblocking'  => 0,
        'psgi.streaming' => 1,
    };
}

# Drain whatever shape of body came back, counting bytes so that every
# framework is charged for producing the same response.
{
    package BenchWriter;
    sub new   { bless { n => $_[1] }, $_[0] }
    sub write { ${ $_[0]{n} } += length $_[1] }
    sub close { }
}

sub consume {
    my ($res) = @_;
    my $bytes = 0;
    if (ref $res eq 'CODE') {           # delayed / streaming response
        my $out;
        $res->(sub {
            my ($triplet) = @_;
            $out = $triplet;
            return BenchWriter->new(\$bytes) if @$triplet < 3;
            return;
        });
        $res = $out;
    }
    return $bytes unless defined $res->[2];
    return $bytes + length join '', @{ $res->[2] } if ref $res->[2] eq 'ARRAY';
    my $fh = $res->[2];
    while (defined(my $chunk = $fh->getline)) { $bytes += length $chunk }
    $fh->close if $fh->can('close');
    return $bytes;
}

sub run_one {
    my ($file, $path) = @_;
    pipe my $r, my $w or die $!;
    my $pid = fork // die $!;
    if (!$pid) {
        close $r;
        my $app = do $file;
        die "$file did not compile: " . ($@ || $!) . "\n"
            unless ref $app eq 'CODE';
        my $bytes = consume($app->(env_for($path)));   # warm the paths
        my $best;
        for (1 .. $REPS) {
            my $start = Time::HiRes::time();
            consume($app->(env_for($path))) for 1 .. $ITERS;
            my $secs = Time::HiRes::time() - $start;
            $best = $secs if !defined $best || $secs < $best;
        }
        print {$w} "$best $bytes\n";
        close $w;
        exit 0;
    }
    close $w;
    my $line = <$r>;
    waitpid $pid, 0;
    $line = '0 0' unless defined $line;
    chomp $line;
    my ($secs, $bytes) = split ' ', $line;
    return ($secs ? $ITERS / $secs : 0, $secs ? 1e6 * $secs / $ITERS : 0,
            $bytes);
}

my %rps;
printf "%-16s %12s %10s %8s\n", 'app', 'req/s', 'us/req', 'bytes';
for my $name (@APPS) {
    my $file = "$FindBin::Bin/apps/$name.psgi";
    my ($rps, $us, $bytes) = run_one($file, bench_path($file));
    $rps{$name} = $rps;
    printf "%-16s %12.0f %10.2f %8d\n", $name, $rps, $us, $bytes;
}
if ($rps{bare}) {
    print "\nrelative to bare:\n";
    for my $name (grep { $_ ne 'bare' } @APPS) {
        printf "%-16s %6.1f%%\n", $name, 100 * $rps{$name} / $rps{bare};
    }
}
