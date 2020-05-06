use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';
use Mojo::Rx::Utils 'get_subscription_from_subscriber';

use Carp 'croak';

# NOTE: this observable keeps a hard reference to the EventEmitter $object.
# Should this change? TODO: think about that.

*Mojo::Rx::rx_from_event = sub {
    my ($object, $event_type) = @_;

    croak 'invalid object type, at rx_from_event' if not $object->isa('Mojo::EventEmitter');

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my $cb = sub {
            my ($e, @args) = @_;

            $subscriber->{next}->(splice @args, 0, 1) if defined $subscriber->{next};
        };

        get_subscription_from_subscriber($subscriber)->add_dependents(sub { $object->unsubscribe($cb) });

        $object->on($event_type, $cb);

        return;
    });
};

1;
