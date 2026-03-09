package Net::Async::Kubernetes::Watcher;
# ABSTRACT: Auto-reconnecting Kubernetes watch as IO::Async::Notifier
our $VERSION = '0.006';
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Carp qw(croak);
use Scalar::Util qw(weaken);
use Kubernetes::REST::HTTPResponse;

sub configure {
    my ($self, %params) = @_;

    if (exists $params{kube}) {
        $self->{kube} = delete $params{kube};
        weaken($self->{kube});
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
    return if $self->{_watching};
    $self->{_stopped} = 0;
    $self->_start_watch;
}


sub stop {
    my ($self) = @_;
    $self->{_stopped} = 1;
    $self->{_watching} = 0;
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
    my $class = $rest->expand_class($self->resource);
    my $path = $rest->build_path($class,
        ($self->namespace ? (namespace => $self->namespace) : ()),
    );

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

    weaken(my $weak_self = $self);

    my $f = $self->kube->_do_streaming_request($req, sub {
        my ($chunk) = @_;
        return unless $weak_self;

        my $buffer = $weak_self->{_buffer};
        for my $result ($rest->process_watch_chunk($class, \$buffer, $chunk)) {
            $weak_self->{_buffer} = $buffer;

            if ($result->{resourceVersion}) {
                $weak_self->{_resource_version} = $result->{resourceVersion};
            }

            my $event = $result->{event};

            if ($result->{error_code} == 410) {
                $weak_self->{_resource_version} = undef;
                return;
            }

            $weak_self->_dispatch_event($event);
        }
        $weak_self->{_buffer} = $buffer;
    });

    $f->on_done(sub {
        return unless $weak_self;
        return if $weak_self->{_stopped};
        $weak_self->{_watching} = 0;
        $weak_self->_start_watch;
    });

    $f->on_fail(sub {
        my ($error) = @_;
        return unless $weak_self;
        return if $weak_self->{_stopped};
        $weak_self->{_watching} = 0;
        $weak_self->loop->watch_time(
            after => 1,
            code  => sub { $weak_self->_start_watch if $weak_self && !$weak_self->{_stopped} },
        );
    });

    $self->{_watch_future} = $f;
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

version 0.006

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

=item * Retries on connection errors after a 1-second delay

=item * Filters events client-side by name patterns (C<names>) and event types (C<event_types>)

=back

=head2 configure

Internal L<IO::Async::Notifier> configuration method. Handles initialization
of C<kube>, C<resource>, C<namespace>, C<timeout>, C<label_selector>,
C<field_selector>, C<names>, C<event_types>, and all event callbacks
(C<on_added>, C<on_modified>, C<on_deleted>, C<on_error>, C<on_event>).

=head2 kube

Returns the parent L<Net::Async::Kubernetes> instance.

=head2 resource

Required. The Kubernetes resource kind to watch (e.g., C<'Pod'>,
C<'Deployment'>).

=head2 namespace

Optional. Namespace to watch. Omit for cluster-scoped resources or to
watch all namespaces.

=head2 timeout

Server-side timeout per watch cycle in seconds. Default: 300.

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

Callback for ERROR events. Receives the raw error hashref.

=head2 on_event

Catch-all callback. Receives the L<Kubernetes::REST::WatchEvent> object.
Called in addition to the type-specific callbacks.

=head2 start

Start (or restart) the watch stream. Called automatically when the watcher
is added to the event loop. Safe to call multiple times (idempotent).

=head2 stop

Stop the watch stream and cancel the current HTTP request. The watcher will
not automatically reconnect until C<start()> is called again.

=head1 NAME

Net::Async::Kubernetes::Watcher - Auto-reconnecting Kubernetes watch as IO::Async::Notifier

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
