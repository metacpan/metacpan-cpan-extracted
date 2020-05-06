use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';
use Mojo::IOLoop;

*Mojo::Rx::rx_interval = sub {
    my ($after) = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my $counter = 0;
        my $id = Mojo::IOLoop->recurring($after, sub {
            $subscriber->{next}->($counter++) if defined $subscriber->{next};
        });

        return sub {
            Mojo::IOLoop->remove($id);
        };
    });
};

1;
