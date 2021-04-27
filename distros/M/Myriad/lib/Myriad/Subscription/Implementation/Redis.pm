package Myriad::Subscription::Implementation::Redis;

our $VERSION = '0.003'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use Myriad::Class extends => qw(IO::Async::Notifier);

use JSON::MaybeUTF8 qw(:v1);
use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use Myriad::Util::UUID;

use Role::Tiny::With;

use constant MAX_ALLOWED_STREAM_LENGTH => 10_000;

with 'Myriad::Role::Subscription';

has $redis;

has $uuid;

# A list of all sources that emits events to Redis
# will need to keep track of them to block them when
# the stream size is more than what we think it should be
has @emitters;

# A list of all receivers that we should read items for
has @receivers;

has $should_shutdown;

BUILD {
    $uuid = Myriad::Util::UUID::uuid();
}

method configure (%args) {
    $redis = delete $args{redis} if exists $args{redis};
    $self->next::method(%args);
}

async method create_from_source (%args) {
    my $src = delete $args{source} or die 'need a source';
    my $service = delete $args{service} or die 'need a service';

    my $stream = "service.subscriptions.$service/$args{channel}";

    $src->unblocked->then($self->$curry::weak(async method {
        # The streams will be checked later by "check_for_overflow" to avoid unblocking the source by mistake
        # we will make "check_for_overflow" aware about this stream after the service has started
        push @emitters, {
            stream => $stream,
            source => $src,
            max_len => $args{max_len} // MAX_ALLOWED_STREAM_LENGTH
        };
        await $src->map($self->$curry::weak(method {
            $log->tracef('sub has an event! %s', $_);
            return $redis->xadd(
                encode_utf8($stream) => '*',
                data => encode_json_utf8($_),
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
    $log->tracef('created sub thing from sink');
    push @receivers, {
        key    => $stream,
        client => $args{client},
        sink   => $sink,
        group  => 0,
    };
}

async method start {
    $should_shutdown //= $self->loop->new_future(label => 'subscription::redis::shutdown');
    $log->tracef('Starting subscription handler');
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
        await $redis->create_group($receiver->{key}, $uuid);
        $receiver->{group} = 1;
    }
    return;
}

async method receive_items {
    $log->tracef('Start loop for receiving items');
    while (1) {
        if(@receivers) {
            my $item = shift @receivers;
            push @receivers, $item;

            $log->tracef('Will readgroup on %s', $item->{key});
            my $stream = $item->{key};
            my $sink = $item->{sink};
            my $client = $item->{client};

            try {
                await Future->wait_any(
                    $self->loop->timeout_future(after => 0.5),
                    $sink->unblocked,
                );
            } catch {
                $log->tracef("skipped stream %s because sink is blocked", $stream);
                next
            }

            await $self->create_group($item);

            my @events = await $redis->read_from_stream(
                stream => $stream,
                group => $uuid,
                client => $client
            );

            for my $event (@events) {
                try {
                    my $event_data = $event->{data}->[1];
                    $sink->source->emit({
                        data => decode_json_utf8($event_data)
                    });
                } catch($e) {
                    $log->tracef(
                        "An error happened while decoding event data for stream %s message: %s, error: %s",
                        $stream,
                        $event->{data},
                        $e
                    );
                }
                await $redis->ack(
                    $stream,
                    $client,
                    $event->{id}
                );
            }
        } else {
            $log->tracef('No receivers, waiting for a few seconds');
            await $self->loop->delay_future(after => 5);
        }
    }
}

async method check_for_overflow () {
    while (1) {
        if(@emitters) {
            my $emitter = shift @emitters;
            push @emitters, $emitter;
            try {
                my $len = await $redis->stream_length($emitter->{stream});
                if ($len >= $emitter->{max_len}) {
                    unless ($emitter->{source}->is_paused) {
                        $emitter->{source}->pause;
                        $log->tracef("Paused emitter on %s, length is %s, max allowed %s", $emitter->{stream}, $len, $emitter->{max_len});
                    }
                    await $redis->cleanup(
                        stream => $emitter->{stream},
                        limit => $emitter->{max_len}
                    );
                } else {
                    if($emitter->{source}->is_paused) {
                        $emitter->{source}->resume;
                        $log->infof("Resumed emitter on %s, length is %s", $emitter->{stream}, $len);
                    }
                }
            } catch ($e) {
                $log->warnf("An error ocurred while trying to check on stream %s status - %s", $emitter->{stream}, $e);
            }
        }

        # No need to run vigorously
        await $self->loop->delay_future(after => 5)
    }
}

1;

__END__

1;

