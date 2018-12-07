package C8;

use Moo;
extends 'B3';

with 'R1';
with 'R2';

has c8_1 => (
    is      => 'ro',
    default => 'c8_1.v',
    T1_1    => 'should not stick',
    T2_1    => 'should not stick',
);

1;
