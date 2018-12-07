package C10;
use Moo;

extends 'B1', 'B2';

use R1;
use R2;

has c10_1 => (
    is      => 'rw',
    T1_1    => 'c10_1.t1_1',
    T2_1    => 'c10_1.t2_1',
    default => 'c10_1.v',
);
1;
