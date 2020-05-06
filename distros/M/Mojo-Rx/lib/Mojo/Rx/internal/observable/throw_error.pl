use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';

*Mojo::Rx::rx_throw_error = sub {
    my ($error) = @_;

    return rx_observable->new(sub {
        my ($subscriber) = @_;

        $subscriber->{error}->($error) if defined $subscriber->{error};

        return;
    });
};

1;
