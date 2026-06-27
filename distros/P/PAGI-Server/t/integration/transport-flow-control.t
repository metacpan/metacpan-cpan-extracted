use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use IO::Async::Loop;
use HTTP::Request;
use FindBin;
use lib "$FindBin::Bin/../../lib";

use PAGI::Server;

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';
BEGIN {
    eval { require Net::Async::HTTP; require Net::Async::WebSocket::Client; 1 }
        or plan skip_all => 'Net::Async::HTTP + Net::Async::WebSocket::Client required';
}

# Proves the pagi.transport handle is wired into the real h1 http, websocket,
# and sse scopes, with working buffered_amount / high_water_mark /
# low_water_mark reads. (Watermarks default to 64KB/16KB in the Connection.)

my $loop = IO::Async::Loop->new;

# Per-scope-type capture of the transport handle's readings.
my %seen;
my $capture = sub {
    my ($type, $scope) = @_;
    my $t = $scope->{'pagi.transport'};
    $seen{$type} = {
        isa      => (ref $t || ''),
        high     => ($t ? $t->high_water_mark : undef),
        low      => ($t ? $t->low_water_mark  : undef),
        buffered => ($t ? $t->buffered_amount : undef),
    };
};

my $app = async sub {
    my ($scope, $receive, $send) = @_;
    my $type = $scope->{type};

    if ($type eq 'lifespan') {
        while (1) {
            my $e = await $receive->();
            if    ($e->{type} eq 'lifespan.startup')  { await $send->({ type => 'lifespan.startup.complete' }); }
            elsif ($e->{type} eq 'lifespan.shutdown') { await $send->({ type => 'lifespan.shutdown.complete' }); last; }
        }
        return;
    }

    if ($type eq 'http') {
        $capture->('http', $scope);
        await $send->({ type => 'http.response.start', status => 200, headers => [['content-type', 'text/plain']] });
        await $send->({ type => 'http.response.body', body => 'ok', more => 0 });
        return;
    }

    if ($type eq 'websocket') {
        await $send->({ type => 'websocket.accept' });
        $capture->('websocket', $scope);   # after accept: websocket_mode is on
        while (1) {
            my $e = await $receive->();
            last if $e->{type} eq 'websocket.disconnect';
        }
        return;
    }

    if ($type eq 'sse') {
        $capture->('sse', $scope);
        await $send->({ type => 'sse.start' });
        await $send->({ type => 'sse.send', data => 'hi' });
        while (1) {
            my $e = await $receive->();
            last if $e->{type} eq 'sse.disconnect';
        }
        return;
    }
};

my $server = PAGI::Server->new(app => $app, host => '127.0.0.1', port => 0, quiet => 1);
$loop->add($server);
$server->listen->get;
my $port = $server->port;

sub assert_transport {
    my ($type) = @_;
    my $s = $seen{$type};
    ok($s, "$type handler ran and captured the scope") or return;
    is($s->{isa}, 'PAGI::Server::TransportState', "$type scope carries pagi.transport");
    is($s->{high}, 65536, "$type high_water_mark is the configured ceiling");
    is($s->{low},  16384, "$type low_water_mark is the configured floor");
    like($s->{buffered}, qr/^\d+$/, "$type buffered_amount is a non-negative integer");
}

subtest 'http scope' => sub {
    my $http = Net::Async::HTTP->new;
    $loop->add($http);
    $http->GET("http://127.0.0.1:$port/")->get;
    $loop->loop_once(0) for 1 .. 3;
    assert_transport('http');
    $loop->remove($http);
};

subtest 'websocket scope' => sub {
    my $client = Net::Async::WebSocket::Client->new;
    $loop->add($client);
    $client->connect(url => "ws://127.0.0.1:$port/")->get;
    my $deadline = time + 2;
    $loop->loop_once(0.02) while !$seen{websocket} && time < $deadline;
    assert_transport('websocket');
    eval { $client->close };
    eval { $loop->remove($client) };
};

subtest 'sse scope' => sub {
    my $http = Net::Async::HTTP->new;
    $loop->add($http);
    # SSE is detected via the Accept header; streams indefinitely, so fire the
    # request without awaiting it and poll for the capture.
    my $req = HTTP::Request->new(
        GET => "http://127.0.0.1:$port/sse",
        ['Accept' => 'text/event-stream'],
    );
    my $f = $http->do_request(request => $req);
    my $deadline = time + 2;
    $loop->loop_once(0.02) while !$seen{sse} && time < $deadline;
    assert_transport('sse');
    $f->cancel if !$f->is_ready;
    eval { $loop->remove($http) };
};

$server->shutdown->get;
$loop->remove($server);

done_testing;
