use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';
use Mojo::IOLoop;

*Mojo::Rx::rx_timer = sub {
    my ($after, $period) = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my $counter = 0;
        my $id;
        $id = Mojo::IOLoop->timer($after, sub {
            undef $id;
            $subscriber->{next}->($counter++) if defined $subscriber->{next};
            if (defined $period) {
                $id = Mojo::IOLoop->recurring($period, sub {
                    $subscriber->{next}->($counter++) if defined $subscriber->{next};
                });
            } else {
                $subscriber->{complete}->() if defined $subscriber->{complete};
            }
        });

        return sub {
            Mojo::IOLoop->remove($id) if defined $id;
        };
    });
};

1;
