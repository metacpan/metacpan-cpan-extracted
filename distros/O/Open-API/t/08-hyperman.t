#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use IO::Socket::INET;
use Time::HiRes qw(time);
use Test::More;

# The app on a real Hyperman server, with a handler returning a Future
# (Hyperman->timer(...)->then(...)): N concurrent delayed requests must be
# served in ~one delay, proving the Future pass-through keeps the worker
# non-blocking. Plus a validation error and auto-JSON over real HTTP.

plan skip_all => 'Hyperman not installed'
    unless eval { require Hyperman; 1 };
plan skip_all => 'Fetch not installed'
    unless eval { require Fetch; 1 };

my $DELAY = 0.2;
my $N     = 8;

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

my $port = free_port();
my $pid  = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';
    require Open::API;
    require Open::API::Plack;
    require File::Raw::JSON;
    my $api = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");
    my $app = Open::API::Plack->new(api => $api, handlers => {
        listPets => sub { [ { id => 1, name => 'rex' } ] },
        getPet   => sub {
            my ($p) = @_;
            my $id = $p->{path}{petId};
            Hyperman->timer($DELAY)->then(sub {
                [ 200, [ 'Content-Type' => 'application/json' ],
                  [ File::Raw::JSON::file_json_encode({ id => $id, name => "pet$id" }) ] ];
            });
        },
    })->to_app;
    Hyperman->run(app => $app, host => '127.0.0.1', port => $port, workers => 1);
    exit 0;
}
END { local $?; if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }

wait_up($port) or die "server did not start";
plan tests => 6;

my $ua   = Fetch->new;
my $base = "http://127.0.0.1:$port";

# ---- plain request over HTTP -------------------------------------------------
{
    my $res = $ua->get("$base/pets")->get;
    is($res->status, 200, 'listPets over HTTP');
    like($res->content, qr/"name":"rex"/, 'auto-JSON body');
}

# ---- validation error over HTTP -----------------------------------------------
{
    my $res = $ua->get("$base/pets/abc")->get;
    is($res->status, 400, 'bad param 400 over HTTP');
    like($res->content, qr/"in":"path"/, 'error body shape');
}

# ---- N concurrent delayed requests overlap on ONE worker -----------------------
{
    my $t0 = time;
    my @f  = map { $ua->get("$base/pets/$_") } 1 .. $N;
    Fetch::Future->needs_all(@f)->get;
    my $elapsed = time - $t0;
    my $okall = 1;
    for my $i (1 .. $N) {
        my $r = $f[$i - 1]->get;
        $okall &&= $r->status == 200 && $r->content =~ /"name":"pet$i"/;
    }
    ok($okall, 'all delayed responses correct');
    cmp_ok($elapsed, '<', $DELAY * $N / 2,
        sprintf('%d x %.1fs requests served in %.2fs (non-blocking)',
                $N, $DELAY, $elapsed));
}
