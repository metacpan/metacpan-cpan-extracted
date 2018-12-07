package C3;

use Moo;
extends 'B3';

has c3_1 => (
    is      => 'ro',
    T1_1    => 'should not stick',
    T2_1    => 'should not stick',
    default => 'c3_1.v',
);

1;

