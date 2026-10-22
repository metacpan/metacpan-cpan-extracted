use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Net::Async::Kubernetes;
use Net::Async::Kubernetes::Watcher;
use MockTransport;

# karr k78: 410 Gone is handled for the ERROR event on the stream (t/08). An
# API server that answers the watch request itself with HTTP 410 (aggregated
# API servers, proxies) must be met the same way: the expired resourceVersion
# is dropped and the watch starts over at once, silently. A 410 to a request
# that carried no resourceVersion has nothing to drop: that is a failed
# attempt with backoff, never a tight loop. Mock mode only.

my $loop = IO::Async::Loop->new;

my $PATH = '/api/v1/namespaces/default/pods';

my $added = { type => 'ADDED', object => {
    kind => 'Pod', apiVersion => 'v1',
    metadata => { name => 'pod-1', namespace => 'default', resourceVersion => '10' },
    spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
    status => {},
}};

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

sub watch_requests { grep { $_->{streaming} } MockTransport::request_log() }

sub await_requests {
    my ($count) = @_;
    my $deadline = time + 5;
    $loop->loop_once(0.01) while @{[ watch_requests() ]} < $count && time < $deadline;
}

sub settle { $loop->loop_once(0) for 1 .. 3 }

# A watcher whose first stream delivers pod-1 (resourceVersion 10) and ends;
# the server then answers 410 to the reconnect. The long backoff keeps a
# wrongly timed retry out of the test's few ticks.
sub start_watcher {
    my ($kube, $errors) = @_;
    MockTransport::mock_watch_events($PATH, [$added], { complete => 1 });
    return $kube->watcher('Pod',
        namespace          => 'default',
        reconnect_jitter   => 0,
        reconnect_delay    => 30,
        max_reconnect_delay => 30,
        on_added           => sub {
            MockTransport::mock_watch_events($PATH, [], { status => 410 });
        },
        on_error           => sub { push @$errors, $_[0] },
    );
}

subtest 'HTTP 410 on a request with a resourceVersion restarts without it' => sub {
    my $kube = make_kube();
    my @errors;
    my $watcher = start_watcher($kube, \@errors);

    await_requests(2);
    # The 410 resolves one tick later; what answers the restart is set now.
    MockTransport::mock_watch_events($PATH, [], {});
    await_requests(3);
    settle();
    $watcher->stop;
    settle();

    my @requests = watch_requests();
    is(scalar @requests, 3, 'the restart came at once, no backoff in between');
    unlike($requests[0]{url}, qr/resourceVersion=/, 'first request has no resourceVersion');
    like($requests[1]{url}, qr/[?&]resourceVersion=10(?:&|\z)/, 'the reconnect resumes at 10');
    unlike($requests[2]{url}, qr/resourceVersion=/, 'the restart after the 410 has none');
    is(scalar @errors, 0, 'the 410 is no failure and is not reported');
};

subtest 'HTTP 410 on a request without a resourceVersion is a failed attempt' => sub {
    my $kube = make_kube();
    my @errors;
    my $watcher = start_watcher($kube, \@errors);

    # Request 2 (rv=10) and 3 (none) both answer 410.
    await_requests(3);
    settle();
    my $count = scalar(my @requests = watch_requests());
    $watcher->stop;
    settle();

    is($count, 3, 'no fourth request: the retry waits out the backoff');
    unlike($requests[2]{url}, qr/resourceVersion=/, 'the third request had none');
    is(scalar @errors, 1, 'exactly one report, for the request without a version');
    my $error = $errors[0] || {};
    is($error->{reason}, 'WatchFailed', 'a failed watch attempt');
    is($error->{code}, 410, 'with the HTTP status');
    is($error->{details}{retryAfterSeconds}, 30, 'retried with the backoff delay');
};

done_testing;
