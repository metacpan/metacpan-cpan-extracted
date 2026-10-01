package MockTransport;
# Mock HTTP transport for Net::Async::Kubernetes tests.
# Overrides _do_request and _do_streaming_request to return
# pre-configured responses without needing a real cluster.

use strict;
use warnings;
use Future;
use JSON::MaybeXS;
use Kubernetes::REST::HTTPResponse;

my $json = JSON::MaybeXS->new(utf8 => 1, convert_blessed => 1);

my %responses;
my %response_queues;
my @request_log;
my %watch_events;
my %watch_opts;
my %stream_chunks;
my %stream_opts;
my $duplex_session;

sub reset {
    %responses = ();
    %response_queues = ();
    @request_log = ();
    %watch_events = ();
    %watch_opts = ();
    %stream_chunks = ();
    %stream_opts = ();
    $duplex_session = undef;
}

sub request_log { @request_log }

sub last_request { $request_log[-1] }

# Register a mock response for a method+path combo
# mock_response('GET', '/api/v1/namespaces', { kind => 'NamespaceList', ... });
# mock_response('GET', '/api/v1/namespaces', { ... }, 404);
#
# An optional \%opts 5th argument supports delay => 1, which resolves the
# request one loop tick later (via $loop->later) instead of immediately.
# Needed to make async orchestration bugs (e.g. issuing several requests
# concurrently instead of one after another) observable in request_log --
# with everything resolving synchronously, a wrongly-parallel implementation
# and a correctly-sequential one produce the exact same request order.
sub mock_response {
    my ($method, $path, $data, $status, $opts) = @_;
    $status //= 200;
    $opts //= {};
    my $key = uc($method) . ' ' . $path;
    $responses{$key} = {
        status  => $status,
        content => ref($data) ? $json->encode($data) : ($data // ''),
        delay   => $opts->{delay} ? 1 : 0,
    };
}

# Register a sequence of responses for a method+path combo, consumed one per
# request in order (FIFO) -- for retry scenarios where the same endpoint is
# hit repeatedly with a different response each time (e.g. a 409 conflict
# followed by success on refetch). Once the queue is exhausted, further
# requests to that method+path fall back to a plain mock_response for the
# same key, or the default synthetic 404 if none was registered.
#
# mock_response_queue('GET', $path, [$data1, $status1], [$data2, $status2]);
sub mock_response_queue {
    my ($method, $path, @entries) = @_;
    my $key = uc($method) . ' ' . $path;
    $response_queues{$key} = [ map {
        my ($data, $status) = @$_;
        {
            status  => $status // 200,
            content => ref($data) ? $json->encode($data) : ($data // ''),
        };
    } @entries ];
}

# Register mock watch events for a path
# mock_watch_events('/api/v1/pods', [ { type => 'ADDED', object => {...} }, ... ]);
# mock_watch_events('/api/v1/pods', [...], { complete => 1 });       # resolve after events
# mock_watch_events('/api/v1/pods', [...], { fail => 'some error' }); # fail after events
# mock_watch_events('/api/v1/pods', [...], { status => 403 });       # rejected, see below
# mock_watch_events('/api/v1/pods', [...], { complete => 1, delay => 300 });
#
# delay => $seconds delivers the events - and completes or fails - that many
# seconds after the request instead of one tick later, through the loop's
# delay_future: a watch cycle that runs until the server-side timeout. A test
# that replaces delay_future with a manual timer decides when that is.
#
# An error status (>= 400) is a rejected request, as the real
# _do_streaming_request has it since karr k33: nothing is streamed - the
# registered events are not delivered - and the request resolves, with or
# without complete, with that status and a Status error body for
# check_response - or the body option: a string as it is, a hashref as JSON.
# fail still fails it instead.

sub mock_watch_events {
    my ($path, $events, $opts) = @_;
    $watch_events{$path} = $events;
    $watch_opts{$path} = $opts // {};
}

# Register mock streaming chunks for a path (e.g. Pod logs)
# mock_stream_chunks('/api/v1/namespaces/default/pods/x/log', [ "line1\n", "line2\n" ]);
# mock_stream_chunks('/api/v1/namespaces/default/pods/x/log', [...], { complete => 1 });
# mock_stream_chunks('/api/v1/namespaces/default/pods/x/log', [...], { fail => 'some error' });
# mock_stream_chunks('/api/v1/namespaces/default/pods/x/log', [...], { status => 404 });
# An error status streams no chunks either, as for mock_watch_events.
sub mock_stream_chunks {
    my ($path, $chunks, $opts) = @_;
    $stream_chunks{$path} = $chunks;
    $stream_opts{$path} = $opts // {};
}

sub mock_duplex_session {
    my ($session) = @_;
    $duplex_session = $session;
}

# A streaming request the API server rejected with $status: one tick later
# $f resolves with that status and $body (a string as it is, a hashref as
# JSON; default a Status error body) - nothing reaches the chunk callback, as
# with the real transport - or fails with $fail.
sub _rejected_stream {
    my ($kube, $f, $path, $status, $fail, $body) = @_;
    $body //= {
        kind => 'Status', apiVersion => 'v1', status => 'Failure',
        message => "Mock: $path answers $status",
        code => $status,
    };
    $kube->loop->later(sub {
        return if $f->is_cancelled;
        return $f->fail($fail) if $fail;
        $f->done(Kubernetes::REST::HTTPResponse->new(
            status  => $status,
            content => ref $body ? $json->encode($body) : $body,
        ));
    });
    return $f;
}

# Install the mock transport on a Net::Async::Kubernetes instance.
# Replaces _do_request and _do_streaming_request with mock versions.
sub install {
    my ($kube) = @_;

    no warnings 'redefine';

    my $class = ref($kube) || $kube;

    # Override _do_request
    no strict 'refs';
    *{"${class}::_do_request"} = sub {
        my ($self, $req) = @_;
        my $method = $req->method;
        my $url = $req->url;

        # Strip the server prefix to get the path
        my $path = $url;
        $path =~ s{^https?://[^/]+}{};

        push @request_log, {
            method  => $method,
            url     => $url,
            path    => $path,
            headers => $req->headers,
            content => $req->content,
        };

        my $key = uc($method) . ' ' . $path;

        # A queued sequence takes priority and is consumed FIFO; once
        # exhausted, later requests to the same key fall back to a plain
        # mock_response (checked below).
        my $resp;
        if (my $queue = $response_queues{$key}) {
            $resp = shift @$queue;
            delete $response_queues{$key} unless @$queue;
        }
        $resp //= $responses{$key};

        if ($resp) {
            my $result = Kubernetes::REST::HTTPResponse->new(
                status  => $resp->{status},
                content => $resp->{content},
            );
            if ($resp->{delay}) {
                my $f = $self->loop->new_future;
                $self->loop->later(sub { $f->done($result) unless $f->is_cancelled });
                return $f;
            }
            return Future->done($result);
        }

        # Not found
        return Future->done(Kubernetes::REST::HTTPResponse->new(
            status  => 404,
            content => $json->encode({
                kind => 'Status', status => 'Failure',
                message => "Mock: no response for $key",
                code => 404,
            }),
        ));
    };

    # Override _do_streaming_request
    # Events are delivered asynchronously via the event loop so that
    # $watcher has been assigned in the test closure before callbacks fire.
    # Returns a pending Future that stays open (like a real watch connection);
    # the test calls $watcher->stop to cancel it.
    *{"${class}::_do_streaming_request"} = sub {
        my ($self, $req, $on_chunk) = @_;
        my $url = $req->url;
        my $path = $url;
        $path =~ s{^https?://[^/]+}{};
        $path =~ s{\?.*}{};  # Strip query params

        push @request_log, {
            method  => $req->method,
            url     => $url,
            path    => $path,
            streaming => 1,
        };

        if (my $events = $watch_events{$path}) {
            my $f = $self->loop->new_future;
            my $opts = $watch_opts{$path} || {};
            my $status = $opts->{status} // 200;

            return _rejected_stream($self, $f, $path, $status, $opts->{fail}, $opts->{body})
                if $status >= 400;

            if (@$events || $opts->{complete} || $opts->{fail}) {
                # Deliver all events in one tick (like a real chunked response).
                # Don't check cancellation between events - the watcher's chunk
                # callback can handle events even after stop() is called.
                my $deliver = sub {
                    for my $event (@$events) {
                        my $line = $json->encode($event) . "\n";
                        $on_chunk->($line);
                    }
                    # Optionally complete or fail after delivering events
                    if ($opts->{fail}) {
                        $f->fail($opts->{fail}) unless $f->is_cancelled;
                    } elsif ($opts->{complete}) {
                        $f->done(Kubernetes::REST::HTTPResponse->new(
                            status  => $status,
                            content => '',
                        )) unless $f->is_cancelled;
                    }
                };
                if (my $delay = $opts->{delay}) {
                    my $timer = $self->loop->delay_future(after => $delay)
                        ->on_done(sub { $deliver->() });
                    $f->on_cancel(sub { $timer->cancel });
                } else {
                    $self->loop->later($deliver);
                }
            }

            # Return pending future - will be cancelled when stop() is called
            return $f;
        }

        if (my $chunks = $stream_chunks{$path}) {
            my $f = $self->loop->new_future;
            my $opts = $stream_opts{$path} || {};
            my $status = $opts->{status} // 200;

            return _rejected_stream($self, $f, $path, $status, $opts->{fail})
                if $status >= 400;

            $self->loop->later(sub {
                for my $chunk (@$chunks) {
                    $on_chunk->($chunk);
                }
                if ($opts->{fail}) {
                    $f->fail($opts->{fail}) unless $f->is_cancelled;
                } else {
                    $f->done(Kubernetes::REST::HTTPResponse->new(
                        status  => $status,
                        content => '',
                    )) unless $f->is_cancelled;
                }
            });

            return $f;
        }

        return Future->fail("Mock: no watch events for $path");
    };

    # Override _do_duplex_request
    *{"${class}::_do_duplex_request"} = sub {
        my ($self, $req, %callbacks) = @_;
        my $url = $req->url;
        my $path = $url;
        $path =~ s{^https?://[^/]+}{};
        $path =~ s{\?.*}{};

        push @request_log, {
            method   => $req->method,
            url      => $url,
            path     => $path,
            duplex   => 1,
            callbacks => {
                on_open  => ref($callbacks{on_open})  eq 'CODE' ? 1 : 0,
                on_frame => ref($callbacks{on_frame}) eq 'CODE' ? 1 : 0,
                on_close => ref($callbacks{on_close}) eq 'CODE' ? 1 : 0,
                on_error => ref($callbacks{on_error}) eq 'CODE' ? 1 : 0,
            },
        };

        return Future->done($duplex_session // { ok => 1, type => 'mock-duplex-session' });
    };

    # Override _add_to_loop to skip adding Net::Async::HTTP
    *{"${class}::_add_to_loop"} = sub { };
}

1;
