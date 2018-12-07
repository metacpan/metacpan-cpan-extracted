package C4;

use Moo;
extends 'B1';

with 'R1';

has c4_1 => (
    is      => 'ro',
    T1_1    => 'should not stick',
    default => 'c4_1.v',
);

1;
