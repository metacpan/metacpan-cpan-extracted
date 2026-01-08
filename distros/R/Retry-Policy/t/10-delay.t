use strict;
use warnings;

use Test2::V0;
use Retry::Policy;

my $p = Retry::Policy->new(
    base_delay_ms => 100,
    max_delay_ms  => 1000,
    jitter        => 'none',
);

is($p->delay_ms(1), 100,  'attempt 1');
is($p->delay_ms(2), 200,  'attempt 2');
is($p->delay_ms(3), 400,  'attempt 3');
is($p->delay_ms(4), 800,  'attempt 4');
is($p->delay_ms(5), 1000, 'capped');

done_testing;

