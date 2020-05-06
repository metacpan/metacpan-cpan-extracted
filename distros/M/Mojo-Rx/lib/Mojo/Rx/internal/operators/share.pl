use strict;
use warnings FATAL => 'all';

use Mojo::Rx 'rx_subject', 'op_multicast', 'op_ref_count';

*Mojo::Rx::op_share = sub {
    return (
        op_multicast(sub { rx_subject->new }),
        op_ref_count(),
    );
};

1;
