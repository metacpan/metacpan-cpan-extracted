use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Net::Async::Kubernetes;
use MockTransport;

my $loop = IO::Async::Loop->new;

sub make_kube {
    MockTransport::reset();
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
    );
    MockTransport::install($kube);
    $loop->add($kube);
    return $kube;
}

subtest 'one-shot log returns full text' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET', '/api/v1/namespaces/default/pods/nginx/log', "line 1\nline 2\n");

    my $text = $kube->log('Pod', 'nginx', namespace => 'default')->get;
    is($text, "line 1\nline 2\n", 'full log text returned');

    my $req = MockTransport::last_request();
    is($req->{method}, 'GET', 'used GET');
    like($req->{path}, qr{/api/v1/namespaces/default/pods/nginx/log}, 'uses pod log path');
};

subtest 'streaming log emits LogEvent lines and resolves' => sub {
    my $kube = make_kube();

    MockTransport::mock_stream_chunks('/api/v1/namespaces/default/pods/nginx/log', [
        "line 1\nline",
        " 2\nline 3",
    ]);

    my @lines;
    my @classes;

    my $f = $kube->log('Pod', 'nginx',
        namespace => 'default',
        follow    => 1,
        on_line   => sub {
            my ($event) = @_;
            push @classes, ref($event);
            push @lines, $event->line;
        },
    );

    $f->on_ready(sub { $loop->stop; });
    $loop->watch_time(after => 2, code => sub {
        fail('timeout waiting for streaming log');
        $loop->stop;
    });
    $loop->run;

    ok($f->is_done, 'streaming future resolved');
    is_deeply(\@lines, ['line 1', 'line 2', 'line 3'], 'received chunked + trailing partial line');
    is($classes[0], 'Kubernetes::REST::LogEvent', 'on_line receives LogEvent objects');
};

subtest 'log query parameters are sent' => sub {
    my $kube = make_kube();

    MockTransport::mock_stream_chunks('/api/v1/namespaces/default/pods/nginx/log', [
        "ok\n",
    ]);

    my $f = $kube->log('Pod', 'nginx',
        namespace    => 'default',
        container    => 'sidecar',
        follow       => 1,
        tailLines    => 10,
        sinceSeconds => 30,
        timestamps   => 1,
        previous     => 1,
        limitBytes   => 2048,
        on_line      => sub {},
    );

    $f->on_ready(sub { $loop->stop; });
    $loop->watch_time(after => 2, code => sub {
        fail('timeout waiting for streaming log with params');
        $loop->stop;
    });
    $loop->run;

    my $req = MockTransport::last_request();
    like($req->{url}, qr/container=sidecar/, 'container param');
    like($req->{url}, qr/follow=true/, 'follow param');
    like($req->{url}, qr/tailLines=10/, 'tailLines param');
    like($req->{url}, qr/sinceSeconds=30/, 'sinceSeconds param');
    like($req->{url}, qr/timestamps=true/, 'timestamps param');
    like($req->{url}, qr/previous=true/, 'previous param');
    like($req->{url}, qr/limitBytes=2048/, 'limitBytes param');
};

subtest 'one-shot log propagates HTTP errors' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET', '/api/v1/namespaces/default/pods/missing/log', {
        kind    => 'Status',
        status  => 'Failure',
        message => 'pods "missing" not found',
        code    => 404,
    }, 404);

    eval { $kube->log('Pod', 'missing', namespace => 'default')->get };
    like($@, qr/error|404|Failure/i, 'one-shot log failure propagated');
};

subtest 'streaming log propagates HTTP errors' => sub {
    my $kube = make_kube();

    MockTransport::mock_stream_chunks('/api/v1/namespaces/default/pods/missing/log', [], {
        status => 404,
    });

    my $f = $kube->log('Pod', 'missing',
        namespace => 'default',
        follow    => 1,
        on_line   => sub {},
    );

    my $failed = 0;
    $f->on_fail(sub { $failed = 1; $loop->stop; });
    $f->on_done(sub { $loop->stop; });
    $loop->watch_time(after => 2, code => sub {
        fail('timeout waiting for streaming log error');
        $loop->stop;
    });
    $loop->run;

    ok($failed, 'streaming failure propagated');
};

subtest 'log argument validation' => sub {
    my $kube = make_kube();

    my $f1 = $kube->log('Pod', namespace => 'default');
    ok($f1->is_failed, 'missing name returns failed future');
    like($f1->failure, qr/name required for log/, 'missing name message');

    my $f2 = $kube->log('Pod', 'nginx', 'orphan');
    ok($f2->is_failed, 'invalid args return failed future');
    like($f2->failure, qr/Invalid arguments to log\(\)/, 'invalid args message');
};

done_testing;
