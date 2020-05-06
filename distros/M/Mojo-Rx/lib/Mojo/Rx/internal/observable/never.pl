use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_observable';

my $rx_never;

*Mojo::Rx::rx_never = sub {
    return $rx_never //= rx_observable->new(sub {
        return;
    });
};

1;
