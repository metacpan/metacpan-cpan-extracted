package B1;

use Moo;
use T1;

has b1_1 => (
    is      => 'rw',
    default => 'b1_1.v',
    T1_1    => 'b1_1.t1_1',
);

1;
