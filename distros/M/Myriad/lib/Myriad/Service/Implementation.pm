package Myriad::Service::Implementation;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use utf8;

=encoding utf8

=head1 NAME

Myriad::Service - microservice coördination

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Object::Pad;
use Future;
use Future::AsyncAwait;
use Syntax::Keyword::Try;

use Myriad::Storage::Implementation::Redis;
use Myriad::Subscription;

use Myriad::Exception;

class Myriad::Service::Implementation extends IO::Async::Notifier;

use Log::Any qw($log);
use Metrics::Any qw($metrics);
use List::Util qw(min);
use Scalar::Util qw(blessed);
use Myriad::Service::Attributes;

# Only defer up to this many seconds between batch iterations
use constant MAX_EXPONENTIAL_BACKOFF => 2;

sub MODIFY_CODE_ATTRIBUTES {
    my ($class, $code, @attrs) = @_;
    Myriad::Service::Attributes->apply_attributes(
        class      => $class,
        code       => $code,
        attributes => \@attrs
    );
}

has $ryu;
has $storage;
has $myriad;
has $service_name;
has %active_batch;

=head1 ATTRIBUTES

These methods return instance variables.

=head2 ryu

Provides a common L<Ryu::Async> instance.

=cut

method ryu () { $ryu }

=head2 myriad

The L<Myriad> instance which owns this service. Stored internally as a weak reference.

=cut

method myriad () { $myriad }

=head2 rpc

=cut

method rpc () { $myriad->rpc }

=head2 subscription

=cut

method subscription () { $myriad->subscription }

=head2 service_name

The name of the service, defaults to the package name.

=cut

method service_name () { $service_name }


=head1 METRICS

General metrics that any service is assumed to have

=head2 myriad.service.rpc

Timing information about RPC calls tagged by service, status and method name

=cut


$metrics->make_timer( rpc_timing =>
   name => [ qw(myriad service rpc) ],
   description => "Time taken to process the RPC request",
   labels => [qw(method status service)]
);

=head2 myriad.service.batch

Timing information about the batch subscriptions tagged by service, status and method name

=cut

$metrics->make_timer( batch_timing =>
   name => [ qw(myriad service batch) ],
   description => "Time taken to process the RPC request",
   labels => [qw(method status service)]
);

=head2 myriad.service.receiver

Timing information about events receivers tagged by service, status and method name

=cut

$metrics->make_timer( receiver_timing =>
   name => [ qw(myriad service receiver) ],
   description => "Time taken to process the received events",
   labels => [qw(method status service)]
);

=head2 myriad.service.emitter

A counter for the events emitted by emitters tagged by service and method name

=cut

$metrics->make_counter( emitters_count =>
    name => [qw(myriad service emitter)],
    description => "Counter for the events emitted by the emitters",
    labels => [qw(method service)],
);

=head1 METHODS

=head2 configure

Populate internal configuration.

=cut

method configure (%args) {
    $service_name //= (delete $args{name} || die 'need a service name');
    Scalar::Util::weaken($myriad = delete $args{myriad}) if exists $args{myriad};
    $self->next::method(%args);
}

=head2 _add_to_loop

Apply this service to the current event loop.

This will trigger a number of actions:

=over 4

=item * initial startup

=item * first diagnostics check

=item * if successful, batch and subscription registration will occur

=back

=cut

method _add_to_loop($loop) {
    $log->tracef('Adding %s to loop', ref $self);
    $self->add_child(
        $ryu = Ryu::Async->new
    );

    $self->next::method($loop);
}

=head1 ASYNC METHODS

=cut

async method process_batch($k, $code, $src) {
    my $backoff;
    $log->tracef('Start batch processing for %s', $k);
    while (1) {
        await $src->unblocked;
        my $data = [];
        try {
            $data = await $self->$code->on_ready(sub {
                my $f = shift;
                $metrics->report_timer(
                    batch_timing => $f->elapsed // 0, {
                        method => $k,
                        status => $f->state,
                        service => $service_name
                    }
                );
            });
        } catch ($e) {
            $log->warnf("Batch iteration for %s failed - %s", $k, $e);
        }

        if ($data->@*) {
            $backoff = 0;
            $src->emit($_) for $data->@*;
            # Defer next processing, give other events a chance
            await $self->loop->delay_future(after => 0);
        } else {
            $backoff = min(MAX_EXPONENTIAL_BACKOFF, ($backoff || 0.02) * 2);
            $log->tracef('Batch for %s returned no results, delaying for %dms before retry', $k, $backoff * 1000.0);
            await $self->loop->delay_future(
                after => $backoff
            );
        }
    }
}

=head2 load

To wire the service with Myriad's component
before it actually starts work

=cut

async method load () {
    my $registry = $Myriad::REGISTRY;

    if(my $emitters = $registry->emitters_for(ref($self))) {
        for my $method (sort keys $emitters->%*) {
            $log->tracef('Found emitter %s as %s', $method, $emitters->{$method});
            my $spec = $emitters->{$method};
            my $chan = $spec->{args}{channel} // die 'expected a channel, but there was none to be found';
            my $sink = $spec->{sink} = $ryu->sink(
                label => "emitter:$chan",
            );

            $spec->{src} = $sink->source->map(sub {
                $metrics->inc_counter(
                    'emitters_count', {
                        method => $method,
                        service => $service_name
                    }
                );
                return $_;
            });

            await $self->subscription->create_from_source(
                source  => $spec->{src}->pause,
                channel => $chan,
                service => $service_name,
            );
        }
    }

    if(my $receivers = $registry->receivers_for(ref($self))) {
        for my $method (sort keys $receivers->%*) {
            try {
                $log->tracef('Found receiver %s as %s', $method, $receivers->{$method});
                my $spec = $receivers->{$method};
                my $chan = $spec->{args}{channel} // die 'expected a channel, but there was none to be found';
                my $sink = $spec->{sink} = $ryu->sink(
                    label => "receiver:$chan",
                );
                $sink->pause;
                $log->tracef('Creating receiver from sink');
                await $self->subscription->create_from_sink(
                    sink    => $sink,
                    channel => $chan,
                    client  => $service_name . '/' . $method,
                    from    => $spec->{args}{service},
                    service => $service_name,
                );
            } catch ($e) {
                $log->errorf('Failed while setting up receiver: %s', $e);
            }
        }
    }

    if (my $batches = $registry->batches_for(ref($self))) {
        for my $method (sort keys $batches->%*) {
            $log->tracef('Starting batch process %s for %s', $method, ref($self));
            my $sink = $batches->{$method}{sink} = $ryu->sink(label => 'batch:' . $method);
            $sink->pause;
            await $self->subscription->create_from_source(
                source  => $sink->source,
                channel => $method,
                service => $service_name,
            );
        }
    }

    if (my $rpc_calls = $registry->rpc_for(ref($self))) {
        for my $method (sort keys $rpc_calls->%*) {
            my $spec = $rpc_calls->{$method};
            my $sink = $spec->{sink} = $ryu->sink(label => "rpc:$service_name:$method");
            $sink->pause;
            $self->rpc->create_from_sink(
                service => $service_name,
                method => $method,
                sink => $sink
            );

            my $code = $spec->{code};
            $spec->{current} = $sink->source->map($self->$curry::weak(async method ($message) {
                try {
                    my $response = await $self->$code(
                        $message->args->%*
                    )->on_ready(sub {
                        my $f = shift;
                        $metrics->report_timer(
                            rpc_timing => $f->elapsed // 0, {
                                method => $method,
                                status => $f->state,
                                service => $service_name
                            }
                        );
                    });
                    await $self->rpc->reply_success($service_name, $message, $response);
                } catch ($e) {
                    await $self->rpc->reply_error($service_name, $message, $e);
                }
            }))->resolve->completed;
        }
    }
}

=head2 start

Perform the diagnostics check and start the service

=cut

async method start {
    await $self->startup;

    my $diag = await Future->wait_any(
        $self->loop->timeout_future(after => 30),
        $self->diagnostics(1),
    );

    # Since everything is ready now we let the service commence work
    my $registry = $Myriad::REGISTRY;
    if(my $emitters = $registry->emitters_for(ref($self))) {
        for my $method (sort keys $emitters->%*) {
            $log->tracef('Starting emitter %s as %s', $method, $emitters->{$method}->{channel});
            my $spec = $emitters->{$method};
            my $code = delete $spec->{code};
            $spec->{current} = $self->$code(
                $spec->{sink},
            )->on_fail(sub {
                $log->fatalf('Emitter for %s failed - %s', $method, shift);
            })->retain;
            $spec->{src}->resume;
        }
    }

    if(my $receivers = $registry->receivers_for(ref($self))) {
        for my $method (sort keys $receivers->%*) {
            try {
                $log->tracef('Starting receiver %s as %s', $method, $receivers->{$method}->{channel});
                my $spec = $receivers->{$method};
                my $code = delete $spec->{code};
                my $current = await $self->$code(
                    $spec->{sink}->source
                );
                $log->tracef('Completed setup for receiver');

                die "Receivers method: $method should return a Ryu::Source"
                    unless blessed $current && $current->isa('Ryu::Source');

                Scalar::Util::weaken(my $sink_copy = $spec->{sink});
                $spec->{current} = $current->map(sub {
                    my $f = Future->wrap(shift);
                    $metrics->report_timer(
                        receiver_timing => ($f->elapsed // 0), {
                            method => $method,
                            status => $f->state,
                            service => $service_name
                        }
                    );
                    return $f;
                })->resolve->completed->on_fail(sub {
                    my $error = shift;
                    $log->errorf("Receiver %s failed while processing messages - %s", $method, $error);
                    my $sink = $sink_copy or return;
                    my $src = $sink->source;
                    $src->fail($error) unless $src->completed->is_ready;
                })->retain;
                $spec->{sink}->resume;
            } catch ($e) {
                $log->errorf('Failed while starting up receiver: %s', $e);
            }
        }
    }

    if (my $batches = $registry->batches_for(ref($self))) {
        for my $method (sort keys $batches->%*) {
            $log->tracef('Starting batch process %s for %s', $method, ref($self));
            my $code = delete $batches->{$method}{code};

            $active_batch{$method} = [
                $batches->{$method}{sink},
                $self->process_batch(
                    $method,
                    $code,
                    $batches->{$method}{sink}
                )
            ];

            $batches->{$method}{sink}->resume;
        }
    }

    if (my $rpc_calls = $registry->rpc_for(ref($self))) {
        $rpc_calls->{$_}->{sink}->resume for keys $rpc_calls->%*;
    }

    $log->infof('Done');

};

=head2 startup

Initialize the service internal status it will be called when the service is added to the L<IO::Async::Loop>.

The method here is just a placeholder it should be reimplemented by the service code.

=cut

async method startup {
    return;
}

=head2 diagnostics

Runs any internal diagnostics.

The method here is just a placeholder it should be reimplemented by the service code.

=cut

async method diagnostics($level) {
    return 'ok';
}

=head2 shutdown

Gracefully shut down the service. At the moment, this means we:

=over 4

=item * stop accepting more requests

=item * finish the pending requests

=back

=cut

async method shutdown {
    return;
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

