#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Config;
use IO::Socket::INET;

# Boot the shipped Hyperman example and make one real HTTP request.
# Skips cleanly when Hyperman is not available (it is a sibling dev
# dist, not a CPAN dependency).

my @hyperman_inc;
for my $base ('../Hyperman', "$ENV{HOME}/Semantic/Hyperman") {
    if (-d "$base/blib/arch/auto/Hyperman") {
        @hyperman_inc = ("-I$base/blib/lib", "-I$base/blib/arch");
        last;
    }
}
plan skip_all => 'Hyperman not built alongside' unless @hyperman_inc;

my $perl = $Config{perlpath};
system($perl, @hyperman_inc, '-e', 'require Hyperman') == 0
    or plan skip_all => 'Hyperman does not load';

# ephemeral port
my $probe = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1',
                                  LocalPort => 0)
    or plan skip_all => "no sockets: $!";
my $port = $probe->sockport;
close $probe;

my $pid = fork;
die "fork: $!" unless defined $pid;
if (!$pid) {
    $ENV{STENCIL_PORT}    = $port;
    $ENV{STENCIL_WORKERS} = 1;   # in-process dev mode, easy to kill
    exec $perl, '-Mblib', @hyperman_inc, 'examples/hyperman.pl';
    die "exec: $!";
}

my $sock;
for (1 .. 50) {
    $sock = IO::Socket::INET->new(PeerAddr => '127.0.0.1',
                                  PeerPort => $port, Timeout => 1);
    last if $sock;
    select undef, undef, undef, 0.1;
}
unless ($sock) {
    kill 'TERM', $pid;
    waitpid $pid, 0;
    plan skip_all => 'server did not come up';
}

print $sock "GET / HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n";
my $resp = do { local $/; <$sock> };
close $sock;
kill 'TERM', $pid;
waitpid $pid, 0;

like($resp, qr{^HTTP/1\.[01] 200}, '200 from Hyperman');
like($resp, qr{Content-Type: text/html}i, 'content type');
like($resp, qr{<h1>STENCIL ON HYPERMAN</h1>}, 'rendered body');
like($resp, qr{hello, worker \d+}, 'per-worker engine rendered');
like($resp, qr{class="first"}, 'loop rendered');

done_testing;
