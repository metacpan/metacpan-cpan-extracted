use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';

*Mojo::Rx::rx_defer = sub {
    my ($observable_factory) = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        my $observable = $observable_factory->();

        return $observable->subscribe($subscriber);
    });
};

1;
