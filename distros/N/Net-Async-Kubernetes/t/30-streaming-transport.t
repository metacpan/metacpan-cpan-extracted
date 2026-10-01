use strict;
use warnings;
use Test::More;

use IO::Async::Loop;
use IO::Async::Listener;
use Future;

use Net::Async::Kubernetes;

# The real streaming transport (_do_streaming_request, which MockTransport
# replaces) against a plain HTTP server on the loopback interface - no
# cluster. Each connection is answered with the next canned response and
# closed, so every request, a watch reconnect included, takes the next one.

my $loop = IO::Async::Loop->new;

my %reason = (200 => 'OK', 403 => 'Forbidden', 404 => 'Not Found');
my @responses;    # [ $status, $body ], taken one per request
my @requests;     # request lines, in order

my $listener = IO::Async::Listener->new(
    on_stream => sub {
        my (undef, $stream) = @_;
        $stream->configure(
            on_read => sub {
                my ($s, $buffref) = @_;
                return 0 unless $$buffref =~ s/\A(.*?)\r\n\r\n//s;
                push @requests, (split /\r\n/, $1)[0];
                my ($status, $body) = @{ shift(@responses) // [404, "{}\n"] };
                $s->write(join "\r\n",
                    "HTTP/1.1 $status " . ($reason{$status} // 'Status'),
                    'Content-Type: application/json',
                    'Content-Length: ' . length($body),
                    'Connection: close',
                    '',
                    $body,
                );
                $s->close_when_empty;
                return 0;
            },
        );
        $loop->add($stream);
    },
);
$loop->add($listener);
$listener->listen(
    addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 },
)->get;
my $port = $listener->read_handle->sockport;

sub make_kube {
    @responses = ();
    @requests = ();
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => "http://127.0.0.1:$port" },
        credentials => { token => 'test-token' },
        resource_map_from_cluster => 0,
    );
    $loop->add($kube);
    return $kube;
}

# Wait for $f, failing it after a few seconds instead of hanging the test.
sub await_f {
    my ($f) = @_;
    my $timeout = $loop->watch_time(after => 5, code => sub {
        $f->fail('test timed out') unless $f->is_ready;
    });
    $loop->await($f);
    $loop->unwatch_time($timeout);
    return $f;
}

sub event_line {
    my ($type, $name, $rv) = @_;
    return qq({"type":"$type","object":{"kind":"Pod","apiVersion":"v1","metadata":)
        . qq({"name":"$name","namespace":"default","resourceVersion":"$rv"}}}\n);
}

my $forbidden = qq({"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure",)
    . qq("message":"pods is forbidden: User \\"test\\" cannot watch resource \\"pods\\"",)
    . qq("reason":"Forbidden","code":403}\n);

my $not_found = qq({"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure",)
    . qq("message":"pods \\"p1\\" not found","reason":"NotFound","code":404}\n);

subtest 'a completed stream resolves with its status' => sub {
    my $kube = make_kube();
    @responses = ([200, event_line(ADDED => 'p1', 5) . event_line(MODIFIED => 'p1', 6)]);

    my $req = $kube->rest->prepare_request('GET', '/api/v1/namespaces/default/pods',
        parameters => { watch => 'true' });
    my $body = '';
    my $f = await_f($kube->_do_streaming_request($req, sub { $body .= $_[0] }));

    ok($f->is_done, 'the request Future is done, not failed')
        or diag('failure: ' . ($f->failure)[0]);
    is($f->is_done && $f->result->status, 200, 'it resolves with the HTTP status');
    is($f->is_done && $f->result->content, '', 'a streamed body is not repeated as content');
    is($body, event_line(ADDED => 'p1', 5) . event_line(MODIFIED => 'p1', 6),
        'the body went to the chunk callback');
};

subtest 'an error response is not streamed' => sub {
    my $kube = make_kube();
    @responses = ([403, $forbidden]);

    my $req = $kube->rest->prepare_request('GET', '/api/v1/namespaces/default/pods',
        parameters => { watch => 'true' });
    my @chunks;
    my $f = await_f($kube->_do_streaming_request($req, sub { push @chunks, $_[0] }));

    ok($f->is_done, 'the request Future is done, not failed')
        or diag('failure: ' . ($f->failure)[0]);
    is($f->is_done && $f->result->status, 403, 'it resolves with the error status');
    is($f->is_done && $f->result->content, $forbidden, 'the Status body comes back as content');
    is_deeply(\@chunks, [], 'the chunk callback never saw the error body');
};

subtest 'log with on_line resolves when the stream ends' => sub {
    my $kube = make_kube();
    @responses = ([200, "first line\nsecond line\n"]);

    my @lines;
    my $f = await_f($kube->log('Pod', 'p1',
        namespace => 'default',
        follow    => 1,
        on_line   => sub { push @lines, $_[0]->line },
    ));

    ok($f->is_done, 'the log Future is done, not failed')
        or diag('failure: ' . ($f->failure)[0]);
    is_deeply(\@lines, ['first line', 'second line'], 'every line was delivered');
};

subtest 'log with on_line fails with the API error and delivers no line' => sub {
    my $kube = make_kube();
    @responses = ([404, $not_found]);

    my @lines;
    my $f = await_f($kube->log('Pod', 'p1',
        namespace => 'default',
        on_line   => sub { push @lines, $_[0]->line },
    ));

    ok($f->is_failed, 'the log Future failed');
    like($f->is_failed && ($f->failure)[0], qr/Kubernetes API error \(log Pod\): 404 .*not found/,
        'with the API error and the server message');
    is_deeply(\@lines, [], 'the error body was not delivered as a log line');
};

subtest 'watcher: a clean end reconnects, a rejection is reported with its message' => sub {
    my $kube = make_kube();
    @responses = (
        [200, event_line(ADDED => 'p1', 5)],
        [403, $forbidden],
    );

    my (@added, @errors, $watcher);
    $watcher = $kube->watcher('Pod',
        namespace       => 'default',
        reconnect_delay => 60,
        on_added        => sub { push @added, $_[0]->metadata->name },
        on_error        => sub {
            push @errors, $_[0];
            $watcher->stop;
            $loop->stop;
        },
    );
    my $timeout = $loop->watch_time(after => 5, code => sub { $watcher->stop; $loop->stop });
    $loop->run;
    $loop->unwatch_time($timeout);

    is_deeply(\@added, ['p1'], 'the event of the first cycle was delivered');
    is(scalar @requests, 2, 'the clean end was followed by an immediate reconnect');
    like($requests[1] // '', qr/resourceVersion=5/, 'resuming at the last resourceVersion');
    is(scalar @errors, 1, 'only the rejection was reported');
    is($errors[0] && $errors[0]{code}, 403, 'with its HTTP status');
    like($errors[0] && $errors[0]{message}, qr/pods is forbidden/, 'and the server message');
};

done_testing;
