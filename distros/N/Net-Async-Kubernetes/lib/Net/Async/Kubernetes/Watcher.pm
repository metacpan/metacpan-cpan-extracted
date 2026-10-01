package Net::Async::Kubernetes::Watcher;
# ABSTRACT: Auto-reconnecting Kubernetes watch as IO::Async::Notifier
our $VERSION = '0.009';
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Carp qw(croak);
use Scalar::Util qw(blessed looks_like_number weaken);
use Kubernetes::REST::HTTPResponse;

sub configure {
    my ($self, %params) = @_;

    if (exists $params{kube}) {
        $self->{kube} = delete $params{kube};
        weaken($self->{kube});
    }
    # Checked here: anything else (a Controller-style arrayref of delays, a
    # word) numifies to a delay nobody asked for and the retries go quiet.
    for my $key (qw(reconnect_delay max_reconnect_delay min_watch_duration)) {
        next unless exists $params{$key};
        my $value = delete $params{$key};
        croak "$key must be a non-negative number of seconds"
            unless defined $value && !ref $value && looks_like_number($value) && $value >= 0;
        $self->{$key} = $value;
    }
    if (exists $params{reconnect_jitter}) {
        my $value = delete $params{reconnect_jitter};
        croak "reconnect_jitter must be a number from 0 to 1"
            unless defined $value && !ref $value && looks_like_number($value)
                && $value >= 0 && $value <= 1;
        $self->{reconnect_jitter} = $value;
    }
    if (exists $params{max_retries}) {
        my $value = delete $params{max_retries};
        croak "max_retries must be a non-negative integer, or undef for no limit"
            if defined $value && (ref $value || $value !~ /\A[0-9]+\z/);
        $self->{max_retries} = $value;
    }
    for my $key (qw(resource namespace timeout label_selector field_selector
                     names event_types
                     on_added on_modified on_deleted on_error on_event)) {
        if (exists $params{$key}) {
            $self->{$key} = delete $params{$key};
        }
    }

    $self->SUPER::configure(%params);
}


# Accessors
sub kube           { $_[0]->{kube} }


sub resource       { $_[0]->{resource} }


sub namespace      { $_[0]->{namespace} }


sub timeout        { $_[0]->{timeout} // 300 }


sub reconnect_delay     { $_[0]->{reconnect_delay} // 1 }


sub max_reconnect_delay { $_[0]->{max_reconnect_delay} // 30 }


sub reconnect_jitter    { $_[0]->{reconnect_jitter} // 0.2 }


sub max_retries         { $_[0]->{max_retries} }


sub min_watch_duration  { $_[0]->{min_watch_duration} // 1 }


sub label_selector { $_[0]->{label_selector} }


sub field_selector { $_[0]->{field_selector} }


sub names          { $_[0]->{names} }


sub event_types    { $_[0]->{event_types} }


sub on_added       { $_[0]->{on_added} }


sub on_modified    { $_[0]->{on_modified} }


sub on_deleted     { $_[0]->{on_deleted} }


sub on_error       { $_[0]->{on_error} }


sub on_event       { $_[0]->{on_event} }


sub _add_to_loop {
    my ($self, $loop) = @_;
    croak "kube is required" unless $self->{kube};
    croak "resource is required" unless $self->{resource};
    $self->start;
}

sub _remove_from_loop {
    my ($self, $loop) = @_;
    $self->stop;
}

sub start {
    my ($self) = @_;
    # Waiting out a reconnect delay is running too: starting now as well
    # would leave two watches once the pending reconnect fires.
    return if $self->{_watching} || $self->{_retry_future};
    $self->{_stopped} = 0;
    $self->{_failures} = 0;
    $self->_start_watch;
}


sub stop {
    my ($self) = @_;
    $self->{_stopped} = 1;
    $self->{_watching} = 0;
    if (my $retry = delete $self->{_retry_future}) {
        $retry->cancel;
    }
    if (my $f = delete $self->{_watch_future}) {
        return if $f->is_ready;
        # Defer cancel to next loop iteration to avoid closing the HTTP
        # connection from within its own on_read handler, which triggers
        # Net::Async::HTTP's "Spurious on_read of connection while idle".
        if (my $loop = $self->loop) {
            $loop->later(sub {
                $f->cancel if !$f->is_ready;
            });
        } else {
            $f->cancel;
        }
    }
}


sub _start_watch {
    my ($self) = @_;
    return if $self->{_stopped};
    return unless $self->{kube};

    $self->{_watching} = 1;
    $self->{_buffer} = '';

    my $rest = $self->kube->_rest;
    my ($class, $error) = $self->kube->_resolve_class($self->resource);
    croak $error unless defined $class;
    (my $path, $error) = $self->kube->_request_path($class, $self->resource,
        ($self->namespace ? (namespace => $self->namespace) : ()),
    );
    croak $error unless defined $path;

    my %params = (
        watch          => 'true',
        timeoutSeconds => $self->timeout,
    );
    $params{resourceVersion} = $self->{_resource_version}
        if defined $self->{_resource_version};
    $params{labelSelector} = $self->label_selector
        if defined $self->label_selector;
    $params{fieldSelector} = $self->field_selector
        if defined $self->field_selector;

    my $req = $rest->prepare_request('GET', $path, parameters => \%params);
    # The resolved class, handed over exactly (see the client's _exact_class).
    my $exact_class = $self->kube->_exact_class($class);

    # What tells a watch cycle that ran its course from a failed attempt
    # when this stream ends: when it started, whether any event came, and
    # the ERROR event it would end on.
    $self->{_stream_started} = $self->_now;
    $self->{_stream_events}  = 0;
    $self->{_stream_error}   = undef;

    weaken(my $weak_self = $self);

    my $f = $self->kube->_do_streaming_request($req, sub {
        my ($chunk) = @_;
        return unless $weak_self;

        my $buffer = $weak_self->{_buffer};
        for my $result ($rest->process_watch_chunk($exact_class, \$buffer, $chunk)) {
            $weak_self->{_buffer} = $buffer;

            if ($result->{resourceVersion}) {
                $weak_self->{_resource_version} = $result->{resourceVersion};
            }

            my $event = $result->{event};
            $weak_self->{_stream_events}++;

            if ($result->{is_error}) {
                if ($result->{error_code} == 410) {
                    $weak_self->{_resource_version} = undef;
                    $weak_self->{_stream_error} = undef;
                    return;
                }
                # Not reset by an ERROR event: a server that sends one and
                # closes, again and again, must meet a growing backoff.
                $weak_self->{_stream_error} = $event->object;
            } else {
                # An event: this attempt got through, so a failure after it
                # starts the backoff over.
                $weak_self->{_failures} = 0;
                $weak_self->{_stream_error} = undef;
            }

            $weak_self->_dispatch_event($event);
        }
        $weak_self->{_buffer} = $buffer;
    });

    $f->on_done(sub {
        my ($response) = @_;
        return unless $weak_self;
        return if $weak_self->{_stopped};
        $weak_self->{_watching} = 0;
        # A rejected request (401, 403, 5xx) resolves like any response. It
        # is a failed attempt, not a watch cycle that ran its course.
        if ($response->status >= 400) {
            my $cause = eval {
                $rest->check_response($response, 'watch ' . $weak_self->resource);
                1;
            } ? 'HTTP ' . $response->status : $@;
            return $weak_self->_watch_failed($cause, $response->status);
        }
        # So is a stream that ends on an ERROR event (other than 410 Gone,
        # which lets the reconnect start over), or at once without any.
        # Reconnecting at once would be a tight loop against the API server.
        if (my $error = $weak_self->{_stream_error}) {
            return $weak_self->_watch_failed($weak_self->_error_event_cause($error),
                ref $error eq 'HASH' ? $error->{code} : undef);
        }
        my $elapsed = $weak_self->_now - $weak_self->{_stream_started};
        if (!$weak_self->{_stream_events} && $elapsed < $weak_self->min_watch_duration) {
            return $weak_self->_watch_failed(
                sprintf('stream closed after %.1fs without an event', $elapsed));
        }
        $weak_self->{_failures} = 0;
        $weak_self->_start_watch;
    });

    $f->on_fail(sub {
        my ($error) = @_;
        return unless $weak_self;
        return if $weak_self->{_stopped};
        $weak_self->{_watching} = 0;
        $weak_self->_watch_failed($error);
    });

    $self->{_watch_future} = $f;
}

# The clock min_watch_duration is measured with: the loop's, which its
# timers use too. Tests replace it.
sub _now { $_[0]->loop->time }

# The random share of reconnect_jitter a delay is shortened by, from 0 up to
# (not including) 1. Tests replace it.
sub _random_fraction { rand() }

# The cause of a failure for a stream that ended on the ERROR event $error,
# the raw Status hashref: its code, reason and message.
sub _error_event_cause {
    my ($self, $error) = @_;
    return 'stream closed after an ERROR event' unless ref $error eq 'HASH';
    my $what = join ' ', grep { defined && length } @{$error}{qw(code reason)};
    return 'stream closed after an ERROR event'
        . (length $what ? " ($what)" : '')
        . (defined $error->{message} ? ': ' . $error->{message} : '');
}

# The cause of a failed watch attempt as its report words it, for humans: a
# Kubernetes::REST::APIError as "HTTP <code> <reason>: <message>" from its
# accessors (the body when it holds no Status), anything else as its text
# without the Perl location a croak or die ends in.
sub _cause_text {
    my ($self, $cause) = @_;
    return 'unknown error' unless defined $cause;
    if (blessed $cause && $cause->isa('Kubernetes::REST::APIError')) {
        my $text = join ' ', 'HTTP', $cause->code, grep { defined && length } $cause->reason;
        my $detail = $cause->message // $cause->body;
        $detail =~ s/\s+\z//;
        return length $detail ? $text . ': ' . $detail : $text;
    }
    my $text = "$cause";
    $text =~ s/\s+\z//;
    $text =~ s/ at \S+ line \d+\.\z//;
    return $text;
}

# A failed watch attempt: a request that failed outright, was rejected with
# HTTP status $code, or opened a stream that ended badly ($code then the
# ERROR event's, if any). Schedules the next attempt with exponential
# backoff - or, once max_retries consecutive failures have been retried,
# stops the watcher - and reports the failure either way: to on_error, else
# as a warning.
sub _watch_failed {
    my ($self, $cause, $code) = @_;
    my $failures = ++$self->{_failures};
    my $max_retries = $self->max_retries;
    $cause = $self->_cause_text($cause);

    my ($delay, $next);
    if (defined $max_retries && $failures > $max_retries) {
        # Stopped before the report, so an on_error that restarts the watcher
        # is not undone right after.
        $self->stop;
        $next = sprintf('giving up after %d %s',
            $max_retries, $max_retries == 1 ? 'retry' : 'retries');
    } else {
        # The exponent is bounded so a long outage cannot overflow it to inf,
        # which reconnect_delay => 0 would turn into a NaN delay.
        my $exponent = $failures - 1;
        $exponent = 64 if $exponent > 64;
        $delay = $self->reconnect_delay * 2 ** $exponent;
        $delay = $self->max_reconnect_delay if $delay > $self->max_reconnect_delay;
        # Shortened, never lengthened, so both delays stay upper bounds.
        if (my $jitter = $self->reconnect_jitter) {
            $delay -= $delay * $jitter * $self->_random_fraction;
            $delay = int($delay * 1000 + 0.5) / 1000;
        }

        # Scheduled before the report, so an on_error that stops the watcher
        # cancels it.
        weaken(my $weak_self = $self);
        $self->{_retry_future} = $self->loop->delay_future(after => $delay)->on_done(sub {
            return unless $weak_self;
            delete $weak_self->{_retry_future};
            $weak_self->_start_watch;
        });
        $next = 'retrying in ' . $delay . 's';
    }

    my $status = {
        kind       => 'Status',
        apiVersion => 'v1',
        status     => 'Failure',
        reason     => 'WatchFailed',
        code       => $code // 0,
        message    => 'watch ' . $self->resource . ' failed, ' . $next . ': ' . $cause,
        details    => {
            kind => $self->resource,
            (defined $delay ? (retryAfterSeconds => $delay) : ()),
        },
    };

    if (my $cb = $self->on_error) {
        $cb->($status);
    } else {
        warn $status->{message} . "\n";
    }
}

sub _dispatch_event {
    my ($self, $event) = @_;
    my $type = $event->type;

    # Client-side event type filter
    # Explicit event_types wins; otherwise auto-derive from callbacks
    # (on_event is catch-all, so if set, all types pass)
    if (my $types = $self->event_types) {
        my %allowed = map { uc($_) => 1 } @$types;
        return unless $allowed{$type};
    } elsif (!$self->on_event) {
        my %has;
        $has{ADDED}    = 1 if $self->on_added;
        $has{MODIFIED} = 1 if $self->on_modified;
        $has{DELETED}  = 1 if $self->on_deleted;
        $has{ERROR}    = 1 if $self->on_error;
        return unless !%has || $has{$type};
    }

    # Client-side name filter (skip for ERROR events which have no metadata)
    if ($type ne 'ERROR' && (my $names = $self->names)) {
        my $obj_name = eval { $event->object->metadata->name } // '';
        my @patterns = ref $names eq 'ARRAY' ? @$names : ($names);
        my $matched = 0;
        for my $pat (@patterns) {
            if (ref $pat eq 'Regexp') {
                $matched = 1, last if $obj_name =~ $pat;
            } else {
                $matched = 1, last if $obj_name eq $pat;
            }
        }
        return unless $matched;
    }

    if (my $cb = $self->on_event) {
        $cb->($event);
    }

    if ($type eq 'ADDED' && $self->on_added) {
        $self->on_added->($event->object);
    } elsif ($type eq 'MODIFIED' && $self->on_modified) {
        $self->on_modified->($event->object);
    } elsif ($type eq 'DELETED' && $self->on_deleted) {
        $self->on_deleted->($event->object);
    } elsif ($type eq 'ERROR' && $self->on_error) {
        $self->on_error->($event->object);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Kubernetes::Watcher - Auto-reconnecting Kubernetes watch as IO::Async::Notifier

=head1 VERSION

version 0.009

=head1 SYNOPSIS

    my $watcher = $kube->watcher('Pod',
        namespace      => 'default',
        label_selector => 'app=web',
        on_added       => sub { my ($pod) = @_; say "Added: " . $pod->metadata->name },
        on_modified    => sub { my ($pod) = @_; say "Modified: " . $pod->metadata->name },
        on_deleted     => sub { my ($pod) = @_; say "Deleted: " . $pod->metadata->name },
        on_error       => sub { my ($status) = @_; warn "Error: $status->{message}" },
    );

    # Client-side filtering by name and event type
    $kube->watcher('Pod',
        namespace   => 'default',
        names       => [qr/^nginx/, qr/^redis/],  # only matching names
        event_types => ['ADDED', 'DELETED'],        # skip MODIFIED
        on_added    => sub { ... },
        on_deleted  => sub { ... },
    );

    # Watch multiple resources concurrently
    $kube->watcher('Deployment', namespace => 'production', on_modified => sub { ... });
    $kube->watcher('Service', namespace => 'production', on_added => sub { ... });

    # Stop watching
    $watcher->stop;

    # Restart
    $watcher->start;

=head1 DESCRIPTION

An L<IO::Async::Notifier> that watches a Kubernetes resource for changes.
Created via L<Net::Async::Kubernetes/watcher>.

The watcher automatically:

=over 4

=item * Reconnects when the server-side timeout expires

=item * Resumes from the last C<resourceVersion> to avoid missing events

=item * Handles 410 Gone by clearing the C<resourceVersion> and restarting

=item * Retries a failed watch attempt -- a transport error, a rejection
such as C<401> or C<403>, or a stream that closes at once without an event
or right after an C<ERROR> event -- with an exponential backoff (1s, 2s, 4s,
... up to 30s by default, see L</reconnect_delay>, each shortened at random
by up to a fifth, see L</reconnect_jitter>), reports every such
failure to L</on_error> or as a warning, and gives up after L</max_retries>
consecutive failures when a limit is set

=item * Filters events client-side by name patterns (C<names>) and event types (C<event_types>)

=back

=head2 configure

Internal L<IO::Async::Notifier> configuration method. Handles initialization
of C<kube>, C<resource>, C<namespace>, C<timeout>, C<label_selector>,
C<field_selector>, C<names>, C<event_types>, C<reconnect_delay>,
C<max_reconnect_delay>, C<reconnect_jitter>, C<max_retries>,
C<min_watch_duration>, and all event callbacks (C<on_added>, C<on_modified>,
C<on_deleted>, C<on_error>, C<on_event>). Croaks on a C<reconnect_delay>,
C<max_reconnect_delay> or C<min_watch_duration> that is not a non-negative
number, on a C<reconnect_jitter> that is not a number from 0 to 1, and on a
C<max_retries> that is neither a non-negative integer nor C<undef>.

=head2 kube

Returns the parent L<Net::Async::Kubernetes> instance.

=head2 resource

Required. The Kubernetes resource kind to watch (e.g., C<'Pod'>,
C<'Deployment'>), or a qualified C<'group/version/Kind'> name to watch a
specific API version -- see L<Net::Async::Kubernetes/expand_class>.

=head2 namespace

Optional. Namespace to watch. Omit for cluster-scoped resources or to
watch all namespaces.

=head2 timeout

Server-side timeout per watch cycle in seconds. Default: 300.

=head2 reconnect_delay

Seconds to wait before reconnecting after a failed watch attempt (see
L</on_error> for what counts as one). Default: 1. Each further consecutive
failure doubles the delay, up to L</max_reconnect_delay>, and every delay is
shortened at random by up to L</reconnect_jitter>. A reconnect that
gets through -- an event arrives on the stream (an C<ERROR> event does not
count), or the watch cycle ends cleanly -- starts the next failure at
C<reconnect_delay> again. A watch cycle that ends cleanly (the server-side
L</timeout>) is not a failure and reconnects at once; one that closes within
L</min_watch_duration> without an event, or right after an C<ERROR> event,
did not end cleanly.

=head2 max_reconnect_delay

Upper bound in seconds for the reconnect delay. Default: 30, the same cap
client-go's reflector puts on its watch backoff: a cluster that comes back is
noticed within half a minute, and one that stays away costs one request and
one report per half minute.

=head2 reconnect_jitter

The share, from 0 to 1, by which each reconnect delay is shortened at random.
Default: 0.2 -- a delay of 4 seconds becomes one between 3.2 and 4 seconds,
rounded to the millisecond. Without it, watchers that fail together (every
watch of a process, or of a fleet, on an API server that restarts) would
send their reconnects together again on every step of the backoff.

The delay is only ever shortened: L</reconnect_delay> and
L</max_reconnect_delay> stay upper bounds, and C<retryAfterSeconds> in the
report (see L</on_error>) is the delay the watcher actually waits. With the
default each step of the backoff still lies above the one before it
(0.8 times double the delay is more than the delay). C<0> turns jitter off,
for delays that are exactly the documented ones.

=head2 max_retries

How many consecutive failed watch requests are retried before the watcher
gives up. Default: C<undef>, retry for as long as the watcher runs. When the
limit is exceeded the watcher stops and reports that it gave up (see
L</on_error>); C<start()> begins again with the full count. C<0> gives up on
the first failure.

=head2 min_watch_duration

Seconds a watch stream has to stay open before it may end without an event.
Default: 1. A stream that closes sooner without delivering a single event is
no watch cycle that ran its course but a failed attempt (see L</on_error>):
reconnecting at once would send the API server one watch request after
another in a tight loop -- a proxy or API server that accepts the watch and
closes it straight away. The default is the threshold client-go's reflector
uses for the same case (a "very short watch"): a real watch cycle runs until
the server-side L</timeout>, minutes, so one second tells the two apart with
room for a slow connection. C<0> turns the check off.

=head2 label_selector

Optional label selector (e.g., C<'app=web,env=prod'>).

=head2 field_selector

Optional field selector (e.g., C<'status.phase=Running'>).

=head2 names

Optional client-side filter for resource names. Accepts a single regex,
a string (exact match), or an arrayref of regexes/strings. Events whose
resource name does not match any of the patterns are silently dropped
before callbacks fire.

    # Single regex
    names => qr/^nginx/

    # Multiple patterns (any match passes)
    names => [qr/^nginx/, qr/^redis/]

    # Exact string match
    names => 'my-pod'

=head2 event_types

Optional client-side filter for event types. Accepts an arrayref of
type strings (C<ADDED>, C<MODIFIED>, C<DELETED>, C<ERROR>). Events
whose type is not in the list are silently dropped.

    # Only ADDED and DELETED events
    event_types => ['ADDED', 'DELETED']

When not set, event types are automatically derived from which callbacks
are registered. If only C<on_added> is set, only C<ADDED> events are
dispatched. If C<on_event> is set (catch-all), all types pass through.

=head2 on_added

Callback for ADDED events. Receives the inflated IO::K8s object.

=head2 on_modified

Callback for MODIFIED events. Receives the inflated IO::K8s object.

=head2 on_deleted

Callback for DELETED events. Receives the inflated IO::K8s object.

=head2 on_error

Callback for errors of the watch. Receives a hashref shaped like a Kubernetes
C<Status>, in two cases:

=over 4

=item * An C<ERROR> event on the stream, for example a C<403> arriving
mid-stream: the raw C<Status> hashref the API server sent. C<410 Gone> is
handled internally and never reaches it.

=item * A failed watch attempt: the request fails outright (TLS support
missing, a TLS or connection error, an unreachable API server), the API
server rejects it with an HTTP error status (C<401>, C<403>, C<5xx>), or the
stream it opens ends badly -- within L</min_watch_duration> without a single
event, or right after an C<ERROR> event other than C<410 Gone> (that event
is reported first, as above). The watcher builds this C<Status> itself.
C<reason> is C<WatchFailed>, C<code> the HTTP status of a rejected request,
the C<code> of the C<ERROR> event the stream ended on, or C<0> when neither
is there (no response arrived, or the stream closed without an event),
C<message> names the resource, what the watcher does next and the cause (for
a rejected request its HTTP status, reason and message, as in C<HTTP 403
Forbidden: pods is forbidden: ...>), and C<details> carries C<kind> (the watched resource) and, while the watcher
retries, C<retryAfterSeconds>:

    {
        kind       => 'Status',
        apiVersion => 'v1',
        status     => 'Failure',
        reason     => 'WatchFailed',
        code       => 0,
        message    => 'watch Pod failed, retrying in 4s: Connection refused',
        details    => { kind => 'Pod', retryAfterSeconds => 4 },
    }

Once L</max_retries> is exceeded, the message says C<giving up after N
retries> instead and C<retryAfterSeconds> is absent; the watcher has
stopped by then.

=back

A failed watch attempt is reported whatever L</event_types> says. Without an
C<on_error> it is passed to C<warn> instead, so a watch that cannot reach its
cluster never fails silently. C<ERROR> events without an C<on_error> are
dropped, as before. The callback may call C<stop()>, which also cancels the
reconnect just announced.

=head2 on_event

Catch-all callback. Receives the L<Kubernetes::REST::WatchEvent> object.
Called in addition to the type-specific callbacks.

=head2 start

Start (or restart) the watch stream. Called automatically when the watcher
is added to the event loop. Safe to call multiple times (idempotent): a
watcher waiting to reconnect after a failed request is already running. After
C<stop()>, or after giving up on L</max_retries>, it starts over with the full
retry count.

=head2 stop

Stop the watch stream and cancel the current HTTP request, or a reconnect
that is waiting out its delay. The watcher will not automatically reconnect
until C<start()> is called again.

=head1 SEE ALSO

L<Net::Async::Kubernetes>, L<Kubernetes::REST::WatchEvent>,
L<IO::Async::Notifier>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-kubernetes/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
