package Myriad::Subscription::Implementation::Memory;

use Myriad::Class extends => 'IO::Async::Notifier', does => [ 'Myriad::Role::Subscription', 'Myriad::Util::Defer' ];

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

has $transport;

has $receivers;

has $should_shutdown = 0;
has $stopped;

# FIXME Need to update :Defer for Object::Pad
sub MODIFY_CODE_ATTRIBUTES { }

BUILD {
    $receivers = [];
}

method receivers () { $receivers }

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
    await $transport->create_stream($channel_name);

    $src->map(async sub {
        my $message = shift;
        await $transport->add_to_stream(
            $channel_name,
            $message->%*
        );
    })->resolve->completed->retain;
    return;
}

async method create_from_sink (%args) {
    my $sink = delete $args{sink} or die 'need a sink';
    my $remote_service = $args{from} || $args{service};
    my $service_name = $args{service};
    my $channel_name = $remote_service . '.' . $args{channel};

    push $receivers->@*, {
        channel    => $channel_name,
        sink       => $sink,
        group_name => $service_name,
        group      => 0
    };
    return;
}

async method create_group ($subscription) {
    return if $subscription->{group};
    await $transport->create_consumer_group($subscription->{channel}, $subscription->{group_name}, 0, 0);
    $subscription->{group} = 1;
}

async method start {
    while (1) {
        await &fmap_void($self->$curry::curry(async method ($subscription) {
            await $self->create_group($subscription);
            try {
                $log->tracef('Sink blocked state: %s', $subscription->{sink}->unblocked->state);
                await Future->wait_any(
                    $self->loop->timeout_future(after => 0.5),
                    $subscription->{sink}->unblocked,
                );
            } catch {
                $log->tracef("skipped stream %s because sink is blocked", $subscription->{channel});
                return;
            }

            my $messages = await $transport->read_from_stream_by_consumer(
                $subscription->{channel},
                $subscription->{group_name},
                'consumer'
            );
            for my $event_id (sort keys $messages->%*) {
                $subscription->{sink}->emit($messages->{$event_id});
                await $transport->ack_message($subscription->{channel}, $subscription->{group_name}, $event_id);
            }

            if($should_shutdown) {
                $stopped->done;
                last;
            }
        }), foreach => [ $receivers->@* ], concurrent => 8);
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

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

