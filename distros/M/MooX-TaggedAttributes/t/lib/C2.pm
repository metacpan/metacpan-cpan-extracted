package C2;

use Moo;
extends 'B2';

has c2_1 => (
    is      => 'ro',
    T2_1    => 'should not stick',
    default => 'c2_1.v',
);

1;

