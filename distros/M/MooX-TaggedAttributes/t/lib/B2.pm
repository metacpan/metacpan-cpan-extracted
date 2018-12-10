package B2;

use Moo;

use namespace::clean;

use T2;

has b2_1 => (
    is      => 'rw',
    default => 'b2_1.v',
    T2_1    => 'b2_1.t2_1',
);

1;

