use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';

$Mojo::Rx::rx_EMPTY = rx_observable->new(sub {
    my ($subscriber) = @_;

    $subscriber->{complete}->() if defined $subscriber->{complete};

    return;
});

*Mojo::Rx::rx_EMPTY = sub { $Mojo::Rx::rx_EMPTY };

1;
