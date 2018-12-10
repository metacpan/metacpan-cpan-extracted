package C1;

use Moo;
extends 'B1';

use namespace::clean;

has c1_1 => (
    is      => 'ro',
    T1_1    => 'should not stick',
    default => 'c1_1.v',
);

1;
