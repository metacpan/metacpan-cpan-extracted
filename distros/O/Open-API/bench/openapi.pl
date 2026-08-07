#!/usr/bin/env perl
# Open::API overhead benchmark.
#
# The interesting number is the COST OF THE SPEC: what a fully validated,
# routed OpenAPI operation costs against the ceiling of a bare hand-rolled
# PSGI app returning the same canned JSON from the same Hyperman setup. Two
# servers, identical workload, driven by wrk. Then the client side: calls/sec
# through Open::API::Client (validated, URL built from the spec) vs raw Fetch
# GETs of the same URL.
#
# Everything is co-resident (client, servers share cores), so the numbers are
# relative - good for tracking overhead, not absolute headlines. Run from the
# dist root after `make`:
#   perl -Mblib bench/openapi.pl [DURATION] [CONNECTIONS] [WORKERS]

use 5.008003;
use strict;
use warnings;
use FindBin ();
use IO::Socket::INET;
use Time::HiRes qw(time);

BEGIN {
    for my $mod (qw(JSON::Schema::Fast Fetch Hyperman)) {
        next if eval "require $mod; 1";
        (my $dir = $mod) =~ s/::/-/g;
        my $sib = "$FindBin::Bin/../../$dir";
        unshift @INC, "$sib/blib/lib", "$sib/blib/arch";
        eval "require $mod; 1" or die "bench needs $mod: $@\n";
    }
}
use Open::API;
use Open::API::Plack;
use Open::API::Client;
use File::Raw::JSON ();

my $DUR     = shift || 10;
my $CONN    = shift || 64;
my $WORKERS = shift || 2;

my $WRK = _which('wrk') or die "need wrk on PATH\n";
sub _which { my $n = shift; for (split /:/, $ENV{PATH} || '') { return "$_/$n" if -x "$_/$n" } undef }

my $SPEC = "$FindBin::Bin/../t/spec/petstore.json";
my $PET  = File::Raw::JSON::file_json_encode({ id => 42, name => 'rex', tag => 'dog' });

sub free_port {
    my $s = IO::Socket::INET->new(LocalHost => '127.0.0.1', LocalPort => 0,
        Listen => 1, ReuseAddr => 1) or die $!;
    my $p = $s->sockport; close $s; $p;
}
sub wait_up {
    my ($p) = @_;
    for (1 .. 100) {
        return 1 if IO::Socket::INET->new(PeerAddr => "127.0.0.1:$p");
        select undef, undef, undef, 0.1;
    }
    0;
}

# ---- bare PSGI ceiling: same response, no routing/validation ----------------
my $bare_port = free_port();
my $bare_pid  = fork // die;
if (!$bare_pid) {
    open STDERR, '>', '/dev/null';
    Hyperman->run(
        app => sub { [ 200, ['Content-Type' => 'application/json'], [$PET] ] },
        host => '127.0.0.1', port => $bare_port, workers => $WORKERS,
    );
    exit 0;
}

# ---- the spec-driven app: routed + path param validated + response built ----
my $oa_port = free_port();
my $oa_pid  = fork // die;
if (!$oa_pid) {
    open STDERR, '>', '/dev/null';
    my $api = Open::API->new(spec => $SPEC);
    my $app = Open::API::Plack->new(api => $api, handlers => {
        listPets  => sub { [ { id => 42, name => 'rex', tag => 'dog' } ] },
        getPet    => sub { [ 200, ['Content-Type' => 'application/json'], [$PET] ] },
        createPet => sub { $_[0]->{body} },
        deletePet => sub { [ 204, [], [''] ] },
    })->to_app;
    Hyperman->run(app => $app, host => '127.0.0.1', port => $oa_port,
                  workers => $WORKERS);
    exit 0;
}

END {
    local $?;
    for my $pid ($bare_pid, $oa_pid) {
        next unless $pid;
        kill 'TERM', $pid; waitpid $pid, 0;
    }
}

wait_up($bare_port) && wait_up($oa_port) or die "servers did not start";

printf "servers : Hyperman x%d workers - bare :%d, Open::API :%d\n",
    $WORKERS, $bare_port, $oa_port;
printf "wrk     : %d conns, %ds\n\n", $CONN, $DUR;

sub run_wrk {
    my ($label, $url) = @_;
    my $out = qx{$WRK -t4 -c$CONN -d${DUR}s --latency $url 2>&1};
    my ($rps) = $out =~ /Requests\/sec:\s+([\d.]+)/;
    my ($p50) = $out =~ /50%\s+([\d.]+\w+)/;
    my ($p99) = $out =~ /99%\s+([\d.]+\w+)/;
    my ($err) = $out =~ /Non-2xx or 3xx responses:\s+(\d+)/;
    printf "%-34s %12s req/s   p50 %-8s p99 %-8s%s\n",
        $label, $rps // '?', $p50 // '-', $p99 // '-',
        $err ? "  [$err non-2xx]" : '';
    return $rps || 0;
}

my $bare = run_wrk('bare PSGI (ceiling)',        "http://127.0.0.1:$bare_port/pets/42");
my $oa   = run_wrk('Open::API (route+validate)', "http://127.0.0.1:$oa_port/pets/42");
printf "\nspec cost: %.1f%% of the bare ceiling\n\n", 100 * $oa / $bare if $bare;

# ---- client: validated spec-driven calls vs raw Fetch GETs -------------------
my $N = 5000;
{
    my $client = Open::API::Client->new(
        spec => $SPEC, base_url => "http://127.0.0.1:$oa_port");
    $client->getPet(petId => 42)->get;               # warm
    my $t0 = time;
    for (1 .. $N) {
        my $r = $client->getPet(petId => 42)->get;
        die "bad status $r->{status}" unless $r->{status} == 200;
    }
    my $dt = time - $t0;
    printf "client  Open::API::Client        %12.0f calls/s  (validated, %d sync calls)\n",
        $N / $dt, $N;
}
{
    my $ua  = Fetch->new;
    my $url = "http://127.0.0.1:$oa_port/pets/42";
    $ua->get($url)->get;                             # warm
    my $t0 = time;
    for (1 .. $N) {
        my $r = $ua->get($url)->get;
        die 'bad status' unless $r->status == 200;
    }
    my $dt = time - $t0;
    printf "client  raw Fetch                %12.0f calls/s  (same URL, no validation)\n",
        $N / $dt;
}
