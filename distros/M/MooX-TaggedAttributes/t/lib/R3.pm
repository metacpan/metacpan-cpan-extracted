package R3;

use Moo;
T1->import;
T2->import;

has r3_1 => (
    is      => 'ro',
    T1_1    => 'r3_1.t1_1',
    T2_1    => 'r3_1.t2_1',
    default => 'r3_1.v',
);

1;

