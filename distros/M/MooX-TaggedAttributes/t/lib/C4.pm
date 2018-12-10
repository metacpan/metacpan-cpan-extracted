package C4;

use Moo;
extends 'B1';

with 'R1';

use namespace::clean;

has c4_1 => (
    is      => 'ro',
    T1_1    => 'should not stick',
    default => 'c4_1.v',
);

1;
