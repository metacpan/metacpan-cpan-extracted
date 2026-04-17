package Net::Async::Kubernetes::Controller;
# ABSTRACT: Minimal controller runtime for Net::Async::Kubernetes
our $VERSION = '0.007';
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Carp qw(croak);
use Future;
use Scalar::Util qw(blessed);

sub configure {
    my ($self, %params) = @_;

    if (exists $params{kube}) {
        $self->{kube} = delete $params{kube};
    } elsif (!$self->{kube}) {
        require Net::Async::Kubernetes;
        my %kube_args;
        for my $key (qw(
            kubeconfig context server credentials resource_map
            resource_map_from_cluster
        )) {
            $kube_args{$key} = delete $params{$key} if exists $params{$key};
        }
        $self->{kube} = Net::Async::Kubernetes->new(%kube_args) if %kube_args;
    }

    if (exists $params{on_reconcile}) {
        $self->{on_reconcile} = delete $params{on_reconcile};
    }
    if (exists $params{retry_delay}) {
        $self->{retry_delay} = delete $params{retry_delay};
    }

    $self->{watch_specs} ||= [];
    $self->{queue} ||= [];
    $self->{entries} ||= {};

    $self->SUPER::configure(%params);
}

sub kube { $_[0]->{kube} }
sub on_reconcile { $_[0]->{on_reconcile} }
sub retry_delay { exists $_[0]->{retry_delay} ? $_[0]->{retry_delay} : 1 }

sub _add_to_loop {
    my ($self, $loop) = @_;

    croak "kube is required" unless $self->kube;
    croak "on_reconcile is required" unless $self->on_reconcile;

    if (!$self->kube->loop) {
        $loop->add($self->kube);
    } elsif ($self->kube->loop != $loop) {
        croak "controller and kube must use the same IO::Async loop";
    }

    $self->start;
}

sub _remove_from_loop {
    my ($self, $loop) = @_;
    $self->stop;
}

sub start {
    my ($self) = @_;
    return if $self->{started};
    $self->{started} = 1;
    $self->{stopped} = 0;

    for my $spec (@{ $self->{watch_specs} }) {
        $self->_start_watch_spec($spec);
    }
}

sub stop {
    my ($self) = @_;

    $self->{stopped} = 1;
    $self->{started} = 0;

    for my $spec (@{ $self->{watch_specs} || [] }) {
        next unless my $watcher = delete $spec->{watcher};
        $watcher->stop;
    }

    for my $key (keys %{ $self->{entries} || {} }) {
        delete $self->{entries}{$key}{retry_future};
    }
}

sub watch_resource {
    my ($self, $resource, %args) = @_;

    my $spec = {
        resource => $resource,
        %args,
    };

    push @{ $self->{watch_specs} }, $spec;
    $self->_start_watch_spec($spec) if $self->{started} && !$self->{stopped};
    return $spec->{watcher};
}

sub _start_watch_spec {
    my ($self, $spec) = @_;
    return if $spec->{watcher};

    my %watch_args = %$spec;
    my $resource = delete $watch_args{resource};
    delete @watch_args{qw(key_for)};

    $spec->{watcher} = $self->kube->watcher($resource,
        %watch_args,
        on_added    => sub { $self->_enqueue_event($spec, 'ADDED',    $_[0]) },
        on_modified => sub { $self->_enqueue_event($spec, 'MODIFIED', $_[0]) },
        on_deleted  => sub { $self->_enqueue_event($spec, 'DELETED',  $_[0]) },
    );
}

sub _enqueue_event {
    my ($self, $spec, $event_type, $object) = @_;
    return if $self->{stopped};

    my $key = $self->_key_for($spec, $object);
    my $entry = $self->{entries}{$key} ||= { key => $key };

    $entry->{ctx} = {
        controller => $self,
        kube       => $self->kube,
        resource   => $spec->{resource},
        event_type => $event_type,
        object     => $object,
        key        => $key,
        attempt    => ($entry->{failures} // 0) + 1,
    };

    if ($entry->{active}) {
        $entry->{dirty} = 1;
        return;
    }

    return if $entry->{queued};
    $entry->{queued} = 1;
    push @{ $self->{queue} }, $key;
    $self->_schedule_drain;
}

sub _schedule_drain {
    my ($self) = @_;
    return if $self->{drain_scheduled} || $self->{stopped};
    $self->{drain_scheduled} = 1;
    $self->loop->later(sub {
        delete $self->{drain_scheduled};
        $self->_drain_queue;
    });
}

sub _drain_queue {
    my ($self) = @_;
    return if $self->{stopped} || $self->{active_key};

    my $key = shift @{ $self->{queue} || [] } or return;
    my $entry = $self->{entries}{$key} or return;
    my $ctx = $entry->{ctx} or return;

    $entry->{queued} = 0;
    $entry->{active} = 1;
    $self->{active_key} = $key;

    my $ret = eval { $self->on_reconcile->($ctx) };
    if ($@) {
        $ret = Future->fail($@);
    } elsif (!blessed($ret) || !$ret->isa('Future')) {
        $ret = Future->done($ret);
    }

    $ret->on_ready(sub {
        my ($f) = @_;
        delete $self->{active_key};
        $entry->{active} = 0;

        if ($f->is_done) {
            delete $entry->{failures};
            if ($entry->{dirty}) {
                $entry->{dirty} = 0;
                $entry->{queued} = 1;
                push @{ $self->{queue} }, $key;
            }
        } else {
            $entry->{dirty} = 0;
            $entry->{failures} = ($entry->{failures} // 0) + 1;
            my ($error) = $f->failure;
            $self->_schedule_retry($key, $entry->{ctx}, $entry->{failures}, $error);
        }

        $self->_schedule_drain;
    });
}

sub _schedule_retry {
    my ($self, $key, $ctx, $attempt, $error) = @_;
    return if $self->{stopped};

    my $entry = $self->{entries}{$key} or return;
    my $delay = $self->_retry_after($attempt, $ctx, $error);

    my $enqueue = sub {
        return if $self->{stopped};
        delete $entry->{retry_future};
        return if $entry->{active} || $entry->{queued};
        $entry->{queued} = 1;
        push @{ $self->{queue} }, $key;
        $self->_schedule_drain;
    };

    if (!$delay) {
        $self->loop->later($enqueue);
        return;
    }

    $entry->{retry_future} = $self->loop->delay_future(after => $delay)->on_ready($enqueue);
}

sub _retry_after {
    my ($self, $attempt, $ctx, $error) = @_;
    my $delay = $self->retry_delay;

    return $delay->($attempt, $ctx, $error) if ref($delay) eq 'CODE';
    if (ref($delay) eq 'ARRAY') {
        return $delay->[$attempt - 1] // $delay->[-1] // 0;
    }
    return $delay // 0;
}

sub _key_for {
    my ($self, $spec, $object) = @_;

    if (my $cb = $spec->{key_for}) {
        return $cb->($object, $spec);
    }

    my $meta = $object->metadata;
    my $name = $meta ? $meta->name : undef;
    my $namespace = $meta ? $meta->namespace : undef;

    return defined($namespace) && length($namespace)
        ? "$namespace/$name"
        : $name;
}

sub get_object {
    my ($self, @args) = @_;
    return $self->kube->get(@args);
}

sub list_objects {
    my ($self, @args) = @_;
    return $self->kube->list(@args);
}

sub patch_status {
    my ($self, $class_or_object, @rest_args) = @_;

    my $rest = $self->kube->_rest;
    my ($class, $name, $namespace, $status, $patch_type);

    if (ref($class_or_object) && blessed($class_or_object)) {
        my $object = $class_or_object;
        $class = ref($object);
        my $metadata = $object->metadata or return Future->fail("object must have metadata");
        $name = $metadata->name or return Future->fail("object must have metadata.name");
        $namespace = $metadata->namespace;
        my %args = @rest_args;
        $status = $args{status} // $object->status // return Future->fail("status required for patch_status");
        $patch_type = $args{type} // 'merge';
    } else {
        my %args;
        if (@rest_args >= 1 && !ref($rest_args[0]) && $rest_args[0] !~ /^(name|namespace|status|type)$/) {
            $args{name} = shift @rest_args;
            %args = (%args, @rest_args);
        } elsif (@rest_args % 2 == 0) {
            %args = @rest_args;
        } else {
            return Future->fail("Invalid arguments to patch_status()");
        }

        $class = $rest->expand_class($class_or_object);
        $name = $args{name} or return Future->fail("name required for patch_status");
        $namespace = $args{namespace};
        $status = $args{status} // return Future->fail("status required for patch_status");
        $patch_type = $args{type} // 'merge';
    }

    my %patch_types = (
        strategic => 'application/strategic-merge-patch+json',
        merge     => 'application/merge-patch+json',
        json      => 'application/json-patch+json',
    );
    my $content_type = $patch_types{$patch_type}
        // return Future->fail("Unknown patch type '$patch_type'");

    my $path = $rest->build_path($class, name => $name, namespace => $namespace) . '/status';
    my $req = $rest->prepare_request('PATCH', $path,
        body => { status => $status },
        content_type => $content_type,
    );

    return $self->kube->_do_request($req)->then(sub {
        my ($response) = @_;
        $rest->check_response($response, "patch status $class");
        return Future->done($rest->inflate_object($class, $response));
    });
}

sub update_status {
    my ($self, $object) = @_;
    my $rest = $self->kube->_rest;
    my $class = ref($object);
    my $metadata = $object->metadata or return Future->fail("object must have metadata");
    my $name = $metadata->name or return Future->fail("object must have metadata.name");
    my $namespace = $metadata->namespace;

    my $path = $rest->build_path($class, name => $name, namespace => $namespace) . '/status';
    my $req = $rest->prepare_request('PUT', $path, body => $object->TO_JSON);

    return $self->kube->_do_request($req)->then(sub {
        my ($response) = @_;
        $rest->check_response($response, "update status $class");
        return Future->done($rest->inflate_object($class, $response));
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Kubernetes::Controller - Minimal controller runtime for Net::Async::Kubernetes

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::Kubernetes;

    my $loop = IO::Async::Loop->new;
    my $kube = Net::Async::Kubernetes->new(
        kubeconfig => "$ENV{HOME}/.kube/config",
    );
    $loop->add($kube);

    my $controller = $kube->controller(
        on_reconcile => sub {
            my ($ctx) = @_;

            return $ctx->{controller}->patch_status('Pod', $ctx->{object},
                status => { phase => 'Running' },
            );
        },
    );

    $controller->watch_resource('Pod', namespace => 'default');
    $loop->run;

=head1 DESCRIPTION

L<Net::Async::Kubernetes::Controller> is a minimal controller runtime built on
top of L<Net::Async::Kubernetes> and its watcher support.

It is intentionally small. The module focuses on the operational pieces most
controllers need:

=over 4

=item *

watch registration

=item *

keyed queueing with deduplication

=item *

serialized reconcile dispatch

=item *

retry hooks with configurable delay policy

=item *

status subresource helpers

=back

It does not attempt to provide higher-level controller DSL sugar.

=head2 configure

Internal L<IO::Async::Notifier> configuration method.

Accepted parameters:

=over 4

=item C<kube>

Existing L<Net::Async::Kubernetes> instance to bind to.

=item C<kubeconfig>, C<context>, C<server>, C<credentials>, C<resource_map>,
C<resource_map_from_cluster>

Client construction parameters used when C<kube> is not supplied.

=item C<on_reconcile>

Required reconcile callback. Receives a hashref with C<controller>, C<kube>,
C<resource>, C<event_type>, C<object>, C<key>, and C<attempt>.

=item C<retry_delay>

Optional retry policy. Accepts a fixed scalar delay, an arrayref of delays, or
a coderef receiving C<($attempt, $ctx, $error)>.

=back

=head2 kube

Returns the bound L<Net::Async::Kubernetes> client.

=head2 on_reconcile

Returns the reconcile callback.

=head2 retry_delay

Returns the configured retry delay policy. Defaults to C<1>.

=head2 start

Starts all registered resource watches. Called automatically when the
controller is added to an event loop.

=head2 stop

Stops registered watches and prevents further queue processing.

=head2 watch_resource

    $controller->watch_resource('Pod',
        namespace => 'default',
        key_for   => sub {
            my ($object, $spec) = @_;
            return $object->metadata->name;
        },
    );

Registers a watched resource and returns the watcher instance once started.
Repeated events for the same reconcile key are coalesced into a single queued
entry.

=head2 get_object

Thin wrapper around C<< $controller->kube->get(...) >>.

=head2 list_objects

Thin wrapper around C<< $controller->kube->list(...) >>.

=head2 patch_status

    $controller->patch_status('Pod', 'my-pod',
        namespace => 'default',
        status    => { phase => 'Running' },
    )->get;

Patch the C</status> subresource for an object. Accepts either a class/name
pair or an object instance plus a C<status> payload.

=head2 update_status

    $controller->update_status($object)->get;

Update the C</status> subresource for a full object instance.

=head1 SEE ALSO

=over 4

=item *

L<Net::Async::Kubernetes>

=item *

L<Net::Async::Kubernetes::Watcher>

=item *

L<IO::Async::Notifier>

=back

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
