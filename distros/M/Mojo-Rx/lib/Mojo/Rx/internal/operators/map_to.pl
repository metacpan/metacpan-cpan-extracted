use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';

*Mojo::Rx::op_map_to = sub {
    my ($mapping_value) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $own_subscriber = { %$subscriber };
            $own_subscriber->{next} &&= sub {
                $subscriber->{next}->($mapping_value) if defined $subscriber->{next};
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
};

1;
