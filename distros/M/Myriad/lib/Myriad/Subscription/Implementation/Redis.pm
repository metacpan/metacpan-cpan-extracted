package Myriad::Subscription::Implementation::Redis;

use Myriad::Class extends => qw(IO::Async::Notifier), does => [
    'Myriad::Role::Subscription'
];

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use Myriad::Util::UUID;

use constant MAX_ALLOWED_STREAM_LENGTH => 10_000;

has $redis;

has $client_id;

# A list of all sources that emits events to Redis
# will need to keep track of them to block them when
# the stream size is more than what we think it should be
has @emitters;

# A list of all receivers that we should read items for
has @receivers;

has $should_shutdown;

BUILD {
    $client_id = Myriad::Util::UUID::uuid();
}

method configure (%args) {
    $redis = delete $args{redis} if exists $args{redis};
    $self->next::method(%args);
}

async method create_from_source (%args) {
    my $src = delete $args{source} or die 'need a source';
    my $service = delete $args{service} or die 'need a service';

    my $stream = "service.subscriptions.$service/$args{channel}";

    $log->tracef('Adding subscription source %s to handler', $stream);
    push @emitters, {
        stream => $stream,
        source => $src,
        max_len => $args{max_len} // MAX_ALLOWED_STREAM_LENGTH
    };
    $src->unblocked->then($self->$curry::weak(async method {
        # The streams will be checked later by "check_for_overflow" to avoid unblocking the source by mistake
        # we will make "check_for_overflow" aware about this stream after the service has started
        await $src->map($self->$curry::weak(method ($event) {
            $log->tracef('Subscription source %s adding an event: %s',$stream, $event);
            return $redis->xadd(
                encode_utf8($stream) => '*',
                data => encode_json_utf8($event),
            );
        }))->ordered_futures(
            low => 100,
            high => 5000,
        )->completed
         ->on_fail($self->$curry::weak(method {
            $log->warnf("Redis XADD command failed for stream %s", $stream);
            $should_shutdown->fail(
                "Failed to publish subscription data for $stream - " . shift
            ) unless $should_shutdown->is_ready;
        }));
        return;
    }))->retain;
    return;
}

async method create_from_sink (%args) {
    my $sink = delete $args{sink}
        or die 'need a sink';
    my $remote_service = $args{from} || $args{service};
    my $stream = "service.subscriptions.$remote_service/$args{channel}";
    $log->tracef('Adding subscription sink %s to handler', $stream);
    push @receivers, {
        key        => $stream,
        sink       => $sink,
        group_name => $args{service},
        group      => 0,
    };
}

async method start {
    $should_shutdown //= $self->loop->new_future(label => 'subscription::redis::shutdown');
    $log->tracef('Starting subscription handler client_id: %s', $client_id);
    await $self->create_streams;
    await Future->wait_any(
        $should_shutdown->without_cancel,
        $self->receive_items,
        $self->check_for_overflow
    );
}

async method stop {
    $should_shutdown->done unless $should_shutdown->is_ready;
    return;
}


async method create_group($receiver) {
    unless ($receiver->{group}) {
        await $redis->create_group($receiver->{key}, $receiver->{group_name});
        $receiver->{group} = 1;
    }
    return;
}

async method receive_items {
    $log->tracef('Start receiving from (%d) subscription sinks', scalar(@receivers));
    while (@receivers == 0) {
        $log->tracef('No receivers, waiting for a few seconds');
        await $self->loop->delay_future(after => 5);
    }

    await &fmap_void($self->$curry::curry(async method ($rcv) {
        my $stream     = $rcv->{key};
        my $sink       = $rcv->{sink};
        my $group_name = $rcv->{group_name};

        while (1) {
            try {
                await $self->create_group($rcv);
            } catch ($e) {
                $log->warnf('skipped subscription on stream %s because: %s will try again', $stream, $e);
                await $self->loop->delay_future(after => 5);
                next;
            }
            await $sink->unblocked;
            my @events = await $redis->read_from_stream(
                stream => $stream,
                group  => $group_name,
                client => $client_id
            );

            for my $event (@events) {
                try {
                    my $event_data = decode_json_utf8($event->{data}->[1]);
                    $log->tracef('Passing event: %s | from stream: %s to subscription sink: %s', $event_data, $stream, $sink->label);
                    $sink->source->emit({
                        data => $event_data
                    });
                } catch($e) {
                    $log->tracef(
                        'An error happened while decoding event data for stream %s message: %s, error: %s',
                        $stream,
                        $event->{data},
                        $e
                    );
                }

                await $redis->ack(
                    $stream,
                    $group_name,
                    $event->{id}
                );
            }
        }
    }), foreach => [@receivers], concurrent => scalar @receivers);
}

async method check_for_overflow () {
    $log->tracef('Start checking overflow for (%d) subscription sources', scalar(@emitters));
    while (1) {
        if(@emitters) {
            my $emitter = shift @emitters;
            push @emitters, $emitter;
            try {
                my $len = await $redis->stream_length($emitter->{stream});
                if ($len >= $emitter->{max_len}) {
                    unless ($emitter->{source}->is_paused) {
                        $emitter->{source}->pause;
                        $log->tracef('Paused subscription source on %s, length is %s, max allowed %s', $emitter->{stream}, $len, $emitter->{max_len});
                    }
                    await $redis->cleanup(
                        stream => $emitter->{stream},
                        limit => $emitter->{max_len}
                    );
                } else {
                    if($emitter->{source}->is_paused) {
                        $emitter->{source}->resume;
                        $log->infof('Resumed subscription source on %s, length is %s', $emitter->{stream}, $len);
                    }
                }
            } catch ($e) {
                $log->warnf('An error ocurred while trying to check on stream %s status - %s', $emitter->{stream}, $e);
            }
        }

        # No need to run vigorously
        await $self->loop->delay_future(after => 5)
    }
}

async method create_streams() {
    await Future->needs_all(map { $redis->create_stream($_->{stream}) } @emitters);
}

1;

__END__

1;

