use strict;
use warnings FATAL => 'all';

require Mojo::Rx::Subject;

*Mojo::Rx::rx_subject = sub { "Mojo::Rx::Subject" };

1;
