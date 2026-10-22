use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Net::Async::Kubernetes;
use Net::Async::Kubernetes::Watcher;
use MockTransport;

# karr k73: a watch started without a resourceVersion first gets the initial
# ADDED events, each with its own resourceVersion. A quiet stream then ends
# at the server timeout and the reconnect must not resume at the version of
# the last of them (older than the state the watch started from: the server
# replays history). The watch asks for BOOKMARK events and takes only their
# resourceVersion; they reach no callback. Mock mode only.

my $loop = IO::Async::Loop->new;

my $PATH = '/api/v1/namespaces/default/pods';

sub pod_event {
    my ($type, $name, $rv) = @_;
    return { type => $type, object => {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => $name, namespace => 'default', resourceVersion => $rv },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status => {},
    }};
}

# What a server sends for an allowed bookmark: the kind, no name, only the
# resourceVersion.
sub bookmark {
    my ($rv) = @_;
    return { type => 'BOOKMARK', object => {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { resourceVersion => $rv },
    }};
}

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

# Run the loop until $count watch requests were made (or a watchdog fires).
sub await_requests {
    my ($count) = @_;
    my $deadline = time + 5;
    $loop->loop_once(0.01) while @{[ watch_requests() ]} < $count && time < $deadline;
}

sub settle { $loop->loop_once(0) for 1 .. 3 }

subtest 'the reconnect resumes at the bookmark, not the last initial event' => sub {
    my $kube = make_kube();
    MockTransport::mock_watch_events($PATH, [
        pod_event(ADDED => 'a', '10'),
        pod_event(ADDED => 'b', '20'),
        bookmark('50'),
    ], { complete => 1 });

    my (@events, @errors);
    my $watcher = $kube->watcher('Pod',
        namespace        => 'default',
        reconnect_jitter => 0,
        on_event         => sub { push @events, $_[0]->type },
        on_error         => sub { push @errors, $_[0] },
    );
    await_requests(2);
    $watcher->stop;
    settle();

    my @requests = watch_requests();
    cmp_ok(scalar @requests, '>=', 2, 'the stream ended and the watcher reconnected');
    like($requests[0]{url}, qr/[?&]allowWatchBookmarks=true(?:&|\z)/,
        'the first request asks for bookmarks');
    unlike($requests[0]{url}, qr/resourceVersion=/, 'the first request has no resourceVersion');
    like($requests[1]{url}, qr/[?&]resourceVersion=50(?:&|\z)/,
        'the reconnect resumes at the bookmark version');
    unlike($requests[1]{url}, qr/resourceVersion=20/, 'not at the last initial event');
    like($requests[1]{url}, qr/[?&]allowWatchBookmarks=true(?:&|\z)/,
        'and asks for bookmarks again');

    is((scalar grep { $_ eq 'BOOKMARK' } @events), 0, 'a BOOKMARK does not reach on_event');
    ok((scalar grep { $_ eq 'ADDED' } @events) >= 2, 'the ADDED events do');
    is(scalar @errors, 0, 'nothing is reported');
};

subtest 'a bookmark is no event for names, event_types or the typed callbacks' => sub {
    my $kube = make_kube();
    MockTransport::mock_watch_events($PATH, [
        pod_event(ADDED => 'a', '10'),
        bookmark('50'),
    ], { complete => 1 });

    my (@added, @events);
    my $watcher = $kube->watcher('Pod',
        namespace        => 'default',
        reconnect_jitter => 0,
        event_types      => [qw(ADDED BOOKMARK)],
        on_added         => sub { push @added, $_[0]->metadata->name },
        on_event         => sub { push @events, $_[0]->type },
    );
    await_requests(2);
    $watcher->stop;
    settle();

    is((scalar grep { $_ eq 'BOOKMARK' } @events), 0,
        'not even with BOOKMARK in event_types');
    is_deeply([ grep { $_ ne 'a' } @added ], [], 'only the pod reaches on_added');
};

subtest 'a stream with only a bookmark reconnects at once, without a report' => sub {
    my $kube = make_kube();
    MockTransport::mock_watch_events($PATH, [ bookmark('70') ], { complete => 1 });

    my @errors;
    my $watcher = $kube->watcher('Pod',
        namespace        => 'default',
        reconnect_jitter => 0,
        on_added         => sub {},
        on_error         => sub { push @errors, $_[0] },
    );
    await_requests(2);
    $watcher->stop;
    settle();

    my @requests = watch_requests();
    cmp_ok(scalar @requests, '>=', 2, 'it reconnected without a backoff delay');
    like($requests[1]{url}, qr/[?&]resourceVersion=70(?:&|\z)/, 'at the bookmark version');
    is(scalar @errors, 0, 'no WatchFailed report');
};

done_testing;
