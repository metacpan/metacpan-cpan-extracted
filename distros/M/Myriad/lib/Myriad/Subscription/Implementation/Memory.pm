package Myriad::Subscription::Implementation::Memory;

our $VERSION = '0.004'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use Myriad::Class extends => qw(IO::Async::Notifier);

use Role::Tiny::With;

with 'Myriad::Role::Subscription';

has $transport;

has $receivers;

has $should_shutdown = 0;
has $stopped;

BUILD {
    $receivers = [];
}

method receivers { $receivers }

method _add_to_loop ($loop) {
    $stopped = $loop->new_future(label => 'subscription::redis::stopped');
}

method configure (%args) {
    $transport = delete $args{transport} if $args{transport};
    $self->next::method(%args);
}

async method create_from_source (%args) {
    my $src          = delete $args{source} or die 'need a source';
    my $service      = delete $args{service} or die 'need a service';
    my $channel_name = $service . '.' . $args{channel};

    $src->map(async sub {
        my $message = shift;
        await $transport->add_to_stream($channel_name, $message->%*);
    })->resolve->completed->retain;
    return;
}

async method create_from_sink (%args) {
    my $sink = delete $args{sink} or die 'need a sink';
    my $remote_service = $args{from} || $args{service};
    my $channel_name = $remote_service . '.' . $args{channel};

    push $receivers->@*, { channel => $channel_name, sink => $sink };
    return;
}


async method start {
    while (1) {
        if ($receivers && $receivers->@*) {
            my $subscription = shift $receivers->@*;
            push  $receivers->@*, $subscription;

            try {
                await $transport->create_consumer_group($subscription->{channel}, 'subscriber', 0, 1);
            } catch ($e) {
                $log->tracef('Failed to create consumer group due: %s', $e);
            }

            try {
                await Future->wait_any(
                    $self->loop->timeout_future(after => 0.5),
                    $subscription->{sink}->unblocked,
                );
            } catch {
                $log->tracef("skipped stream %s because sink is blocked", $subscription->{channel});
                next
            }

            my %messages = await $transport->read_from_stream_by_consumer($subscription->{channel}, 'subscriber', 'consumer');
            for my $event_id (keys %messages) {
                $subscription->{sink}->emit($messages{$event_id});
                await $transport->ack_message($subscription->{channel}, 'subscriber', $event_id);
            }
            if($should_shutdown) {
                $stopped->done;
                last;
            }
        }
        await $self->loop->delay_future(after => 0.1);
    }
}

async method stop {
    $should_shutdown = 1;
    await $stopped;
}

1;

__END__

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

