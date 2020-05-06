use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';

*Mojo::Rx::op_take_until = sub {
    my ($notifier_observable) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $n_s = $notifier_observable->subscribe(
                sub {
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                },
                sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
            );

            $source->subscribe($subscriber);

            return $n_s;
        });
    };
};

1;
