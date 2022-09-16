package My::Role::C3;

use Moo;
extends 'My::Role::B3';

use namespace::clean;

has c3_1 => (
    is      => 'ro',
    T1_1    => 'should not stick',
    T2_1    => 'should not stick',
    default => 'c3_1.v',
);

1;

