use strict;
use warnings;

use Test2::V0;
use Retry::Policy;

like(
    dies {
        Retry::Policy->new(
            base_delay_ms => 200,
            max_delay_ms  => 100,
            jitter        => 'none',
        );
    },
    qr/max_delay_ms must be >= base_delay_ms/,
    "dies when max_delay_ms < base_delay_ms",
);

like(
    dies {
        Retry::Policy->new(jitter => 'weird');
    },
    qr/jitter must be 'none' or 'full'/,
    "dies on invalid jitter value",
);

done_testing;

