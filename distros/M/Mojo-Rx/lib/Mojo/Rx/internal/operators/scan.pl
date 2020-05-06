use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';

*Mojo::Rx::op_scan = sub {
    my ($accumulator_function, $seed) = @_;
    my $has_seed = @_ >= 2;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $has_seed = $has_seed;

            my $acc; $acc = $seed if $has_seed;
            my $index = -1;
            my $own_subscriber = {
                %$subscriber,
                (
                    next => sub {
                        my ($value) = @_;

                        if (! $has_seed) {
                            $acc = $value;
                            $has_seed = 1;
                        } else {
                            ++$index;
                            $acc = $accumulator_function->($acc, $value, $index);
                        }

                        $subscriber->{next}->($acc) if defined $subscriber->{next};
                    },
                ) x!! defined $subscriber->{next},
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
};

1;
