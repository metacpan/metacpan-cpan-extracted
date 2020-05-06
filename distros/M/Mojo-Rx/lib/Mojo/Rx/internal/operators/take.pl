use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';

use Carp 'croak';

*Mojo::Rx::op_take = sub {
    my ($count) = @_;

    croak 'negative argument passed to op_take' unless $count >= 0;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $remaining = int $count;

            if ($remaining == 0) {
                $subscriber->{complete}->() if defined $subscriber->{complete};
                return;
            }

            my $own_subscriber = {
                %$subscriber,
                next => sub {
                    $subscriber->{next}->(@_) if defined $subscriber->{next};
                    $subscriber->{complete}->() if --$remaining == 0 and defined $subscriber->{complete};
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
};

1;
