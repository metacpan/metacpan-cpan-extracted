use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Net::Async::Kubernetes;
use Net::Async::Kubernetes::Watcher;
use MockTransport;

# karr k51: a watch stream that ends at once without delivering a single
# event, or right after an ERROR event other than 410 Gone, is no watch cycle
# that ran its course - reconnecting at once would hammer the API server in a
# tight loop. It is a failed attempt like a failed request (t/29): the same
# backoff, the same WatchFailed report, counted for max_retries. A quiet
# stream that ran past min_watch_duration still reconnects at once, and an
# event on a stream resets the backoff. Mock mode only.

my $loop = IO::Async::Loop->new;

# Virtual time. The watcher reads its clock through _now; every reconnect
# delay and every mocked stream delay (MockTransport's delay => N) goes
# through the loop's delay_future, replaced here by a manual timer that
# advances the clock by its delay when the test fires it. No real time passes.
my $NOW = 1_000_000;
my @timers;
{
    no strict 'refs';
    no warnings 'redefine';
    *Net::Async::Kubernetes::Watcher::_now = sub { $NOW };
    my $loop_class = ref $loop;
    *{"${loop_class}::delay_future"} = sub {
        my ($self, %args) = @_;
        my $f = $self->new_future;
        push @timers, { after => $args{after}, future => $f };
        return $f;
    };
}

my $PATH = '/api/v1/namespaces/default/pods';

my $added_event = { type => 'ADDED', object => {
    kind => 'Pod', apiVersion => 'v1',
    metadata => { name => 'pod-1', namespace => 'default', resourceVersion => '10' },
    spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
    status => {},
}};

sub error_event {
    my ($code, $reason, $message) = @_;
    return { type => 'ERROR', object => {
        kind => 'Status', apiVersion => 'v1', status => 'Failure',
        code => $code, reason => $reason, message => $message,
    }};
}

sub make_kube {
    MockTransport::reset();
    @timers = ();
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
    );
    MockTransport::install($kube);
    $loop->add($kube);
    return $kube;
}

# A watcher on $PATH collecting its reports; no jitter (karr k52), so the
# delays are exact.
sub watch {
    my ($kube, $errors, %args) = @_;
    return $kube->watcher('Pod',
        namespace        => 'default',
        reconnect_jitter => 0,
        on_added         => sub {},
        on_error         => sub { push @$errors, $_[0] },
        %args,
    );
}

# Run what the mock deferred with $loop->later.
sub settle { $loop->loop_once(0) for 1 .. 3 }

sub watch_requests { scalar grep { $_->{streaming} } MockTransport::request_log() }

sub pending { grep { !$_->{future}->is_ready } @timers }

# Fire the newest pending timer of $after seconds, advancing the clock by it.
sub fire {
    my ($after) = @_;
    my ($timer) = grep { $_->{after} == $after } reverse pending();
    return fail("a pending timer of ${after}s") unless $timer;
    $NOW += $after;
    $timer->{future}->done;
    settle();
    return 1;
}

# The reconnect delays scheduled so far - the timers the mock did not ask for.
sub delays {
    my (@stream_delays) = @_;
    my %stream = map { $_ => 1 } @stream_delays;
    return [ map { $_->{after} } grep { !$stream{ $_->{after} } } @timers ];
}

subtest 'a stream that ends at once without an event is a failed attempt' => sub {
    my $kube = make_kube();
    MockTransport::mock_watch_events($PATH, [], { complete => 1 });

    my @errors;
    my $watcher = watch($kube, \@errors);
    settle();

    is(watch_requests(), 1, 'no immediate reconnect');
    is(scalar @errors, 1, 'the empty stream is reported');
    my $error = $errors[0] || {};
    is($error->{reason}, 'WatchFailed', 'as a failed watch');
    is($error->{code}, 0, 'code 0: no error status arrived');
    like($error->{message},
        qr/^watch Pod failed, retrying in 1s: stream closed after 0\.0s without an event\z/,
        'message says the stream closed without an event, and how soon');
    is($error->{details}{retryAfterSeconds}, 1, 'retryAfterSeconds carries the delay');
    is_deeply(delays(), [1], 'retried after reconnect_delay');

    fire(1);
    is(watch_requests(), 2, 'the reconnect sends the watch request again');
    is_deeply(delays(), [1, 2], 'a second empty stream doubles the delay');
    like($errors[-1]{message}, qr/retrying in 2s: stream closed after 0\.0s without an event/,
        'and is reported with it');
    $watcher->stop;
};

subtest 'max_retries counts empty streams' => sub {
    my $kube = make_kube();
    MockTransport::mock_watch_events($PATH, [], { complete => 1 });

    my @errors;
    my $watcher = watch($kube, \@errors, max_retries => 1);
    settle();
    fire(1);

    is(watch_requests(), 2, 'the first attempt plus one retry');
    like($errors[-1]{message}, qr/^watch Pod failed, giving up after 1 retry: stream closed/,
        'the watcher gives up');
    settle();
    is(watch_requests(), 2, 'and stays stopped');
};

subtest 'a quiet stream that ran past min_watch_duration is a watch cycle' => sub {
    my $kube = make_kube();
    MockTransport::mock_watch_events($PATH, [], { complete => 1 });

    my @errors;
    my $watcher = watch($kube, \@errors);
    settle();
    is_deeply(delays(), [1], 'one empty stream: 1s');

    # The server-side timeout: 300 quiet seconds, then a clean end.
    MockTransport::mock_watch_events($PATH, [], { complete => 1, delay => 300 });
    fire(1);
    is(watch_requests(), 2, 'the reconnect is sent');
    MockTransport::mock_watch_events($PATH, [], { fail => 'Connection refused' });
    fire(300);
    is(watch_requests(), 3, 'a quiet stream that ran its course reconnects at once');
    is(scalar @errors, 2, 'the quiet stream itself is not reported');
    is_deeply(delays(300), [1, 1], 'and the next failure starts the backoff over');
    $watcher->stop;
};

subtest 'min_watch_duration is configurable, 0 turns the check off' => sub {
    my $kube = make_kube();
    MockTransport::mock_watch_events($PATH, [], { complete => 1, delay => 3 });

    my @errors;
    my $watcher = watch($kube, \@errors, min_watch_duration => 5);
    is($watcher->min_watch_duration, 5, 'accessor');
    fire(3);
    is(scalar @errors, 1, 'a stream shorter than min_watch_duration is a failure');
    like($errors[0]{message}, qr/stream closed after 3\.0s without an event/,
        'naming how long it ran');
    $watcher->stop;

    my $kube2 = make_kube();
    MockTransport::mock_watch_events($PATH, [], { complete => 1 });
    my @errors2;
    my $unchecked = watch($kube2, \@errors2, min_watch_duration => 0);
    settle();
    ok(watch_requests() >= 2, 'with 0 an empty stream reconnects at once');
    is_deeply(\@errors2, [], 'and is not reported');
    $unchecked->stop;

    is(Net::Async::Kubernetes::Watcher->new(resource => 'Pod')->min_watch_duration, 1,
        'min_watch_duration defaults to 1');
    for my $bad ([1, 2], -1, 'soon', undef) {
        my $shown = !defined $bad ? 'undef' : ref $bad ? 'an arrayref' : "'$bad'";
        eval { Net::Async::Kubernetes::Watcher->new(resource => 'Pod', min_watch_duration => $bad) };
        like($@, qr/^min_watch_duration must be a non-negative number of seconds/,
            "min_watch_duration rejects $shown");
    }
};

subtest 'an event makes a short stream a watch cycle and resets the backoff' => sub {
    my $kube = make_kube();
    MockTransport::mock_watch_events($PATH, [], { complete => 1 });

    my @errors;
    my @added;
    my $watcher = watch($kube, \@errors, on_added => sub { push @added, $_[0]->metadata->name });
    settle();
    fire(1);
    is_deeply(delays(), [1, 2], 'two empty streams: 2s');

    MockTransport::mock_watch_events($PATH, [$added_event], { complete => 1 });
    fire(2);
    MockTransport::mock_watch_events($PATH, [], { complete => 1 });
    settle();

    ok(scalar @added >= 1, 'the event was delivered');
    is_deeply(delays(), [1, 2, 1], 'the next empty stream starts the backoff over');
    is(scalar @errors, 3, 'the stream with the event was not reported');
    $watcher->stop;
};

subtest 'a stream that ends right after an ERROR event is a failed attempt' => sub {
    my $kube = make_kube();
    my $error_event = error_event(500, 'InternalError', 'etcdserver: request timed out');
    MockTransport::mock_watch_events($PATH, [$error_event], { complete => 1 });

    my @errors;
    my $watcher = watch($kube, \@errors);
    settle();

    is(watch_requests(), 1, 'no immediate reconnect');
    is(scalar @errors, 2, 'the ERROR event and the failure are both reported');
    is($errors[0]{reason}, 'InternalError', 'first the raw ERROR event');
    my $failure = $errors[1] || {};
    is($failure->{reason}, 'WatchFailed', 'then the failed watch');
    is($failure->{code}, 500, 'code is the code of the ERROR event');
    like($failure->{message},
        qr/^watch Pod failed, retrying in 1s: stream closed after an ERROR event \(500 InternalError\): etcdserver: request timed out\z/,
        'message carries the ERROR event');
    is_deeply(delays(), [1], 'retried after reconnect_delay');

    fire(1);
    is_deeply(delays(), [1, 2], 'an ERROR event does not reset the backoff');
    $watcher->stop;

    my $kube2 = make_kube();
    MockTransport::mock_watch_events($PATH, [$added_event, $error_event],
        { complete => 1, delay => 300 });
    my @errors2;
    my $late = watch($kube2, \@errors2);
    fire(300);
    is(scalar @errors2, 2, 'also after a long stream with events');
    is($errors2[-1]{reason}, 'WatchFailed', 'the end after the ERROR event is a failure');
    is_deeply(delays(300), [1], 'at reconnect_delay: the event before it reset the backoff');
    $late->stop;
};

subtest 'an ERROR event followed by another event is no failure' => sub {
    my $kube = make_kube();
    MockTransport::mock_watch_events($PATH,
        [ error_event(500, 'InternalError', 'transient'), $added_event ], { complete => 1 });

    my @errors;
    my $watcher = watch($kube, \@errors);
    settle();
    ok(watch_requests() >= 2, 'the stream ended after an ordinary event: reconnect at once');
    is_deeply([ grep { $_->{reason} eq 'WatchFailed' } @errors ], [], 'no failure reported');
    $watcher->stop;
};

subtest 'a stream ending after 410 Gone reconnects at once, without resourceVersion' => sub {
    my $kube = make_kube();
    MockTransport::mock_watch_events($PATH, [$added_event], { complete => 1, delay => 300 });

    my @errors;
    my $watcher = watch($kube, \@errors);
    # Half a second, under min_watch_duration: the 410 is the stream's only
    # event, and an event it is.
    MockTransport::mock_watch_events($PATH, [ error_event(410, 'Expired', 'too old resource version') ],
        { complete => 1, delay => 0.5 });
    fire(300);
    MockTransport::mock_watch_events($PATH, []);
    fire(0.5);

    my @urls = map { $_->{url} } grep { $_->{streaming} } MockTransport::request_log();
    is(scalar @urls, 3, 'the 410 stream reconnected at once');
    like($urls[1], qr/resourceVersion=10/, 'the stream that got 410 resumed from the event');
    unlike($urls[2], qr/resourceVersion=/, 'the reconnect after 410 starts over');
    is_deeply(\@errors, [], '410 is neither an ERROR report nor a failure');
    is_deeply(delays(300, 0.5), [], 'nothing waits');
    $watcher->stop;
};

done_testing;
