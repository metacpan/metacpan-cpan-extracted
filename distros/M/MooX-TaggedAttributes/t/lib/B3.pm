package B3;

use Moo;

use namespace::clean;

use T2;
use T1;

has b3_1 => (
    is      => 'rw',
    default => 'b3_1.v',
    T1_1    => 'b3_1.t1_1',
    T2_1    => 'b3_1.t2_1',
);



1;
