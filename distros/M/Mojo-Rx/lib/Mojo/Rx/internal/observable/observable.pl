use strict;
use warnings FATAL => 'all';

require Mojo::Rx::Observable;

*Mojo::Rx::rx_observable = sub { "Mojo::Rx::Observable" };

1;
