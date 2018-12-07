package C6;

use Moo;
extends 'B1';

with 'R1';
with 'R2';

has c6_1 => (
    is      => 'ro',
    default => 'c6_1.v',
    T1_1    => 'should not stick',
    T2_1    => 'should not stick',
);

1;
