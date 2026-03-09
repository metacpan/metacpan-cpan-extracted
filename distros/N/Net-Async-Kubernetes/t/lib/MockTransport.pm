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
my @request_log;
my %watch_events;
my %watch_opts;
my %stream_chunks;
my %stream_opts;
my $duplex_session;

sub reset {
    %responses = ();
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
sub mock_response {
    my ($method, $path, $data, $status) = @_;
    $status //= 200;
    my $key = uc($method) . ' ' . $path;
    $responses{$key} = {
        status => $status,
        content => ref($data) ? $json->encode($data) : ($data // ''),
    };
}

# Register mock watch events for a path
# mock_watch_events('/api/v1/pods', [ { type => 'ADDED', object => {...} }, ... ]);
# mock_watch_events('/api/v1/pods', [...], { complete => 1 });       # resolve after events
# mock_watch_events('/api/v1/pods', [...], { fail => 'some error' }); # fail after events

sub mock_watch_events {
    my ($path, $events, $opts) = @_;
    $watch_events{$path} = $events;
    $watch_opts{$path} = $opts // {};
}

# Register mock streaming chunks for a path (e.g. Pod logs)
# mock_stream_chunks('/api/v1/namespaces/default/pods/x/log', [ "line1\n", "line2\n" ]);
# mock_stream_chunks('/api/v1/namespaces/default/pods/x/log', [...], { complete => 1 });
# mock_stream_chunks('/api/v1/namespaces/default/pods/x/log', [...], { fail => 'some error' });
sub mock_stream_chunks {
    my ($path, $chunks, $opts) = @_;
    $stream_chunks{$path} = $chunks;
    $stream_opts{$path} = $opts // {};
}

sub mock_duplex_session {
    my ($session) = @_;
    $duplex_session = $session;
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

        if (my $resp = $responses{$key}) {
            return Future->done(Kubernetes::REST::HTTPResponse->new(
                status  => $resp->{status},
                content => $resp->{content},
            ));
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

            if (@$events || $opts->{complete} || $opts->{fail}) {
                # Deliver all events in one tick (like a real chunked response).
                # Don't check cancellation between events - the watcher's chunk
                # callback can handle events even after stop() is called.
                $self->loop->later(sub {
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
                });
            }

            # Return pending future - will be cancelled when stop() is called
            return $f;
        }

        if (my $chunks = $stream_chunks{$path}) {
            my $f = $self->loop->new_future;
            my $opts = $stream_opts{$path} || {};
            my $status = $opts->{status} // 200;

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
