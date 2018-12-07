package C7;

use Moo;
extends 'B2';

with 'R1';
with 'R2';

has c7_1 => (
    is      => 'ro',
    default => 'c7_1.v',
    T1_1    => 'should not stick',
    T2_1    => 'should not stick',
);

1;
