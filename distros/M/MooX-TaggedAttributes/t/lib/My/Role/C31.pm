package My::Role::C31;

use Moo;
extends 'My::Role::B4';

use namespace::clean;

has c31_1 => (
    is      => 'ro',
    T1_1    => 'should not stick',
    T2_1    => 'should not stick',
    default => 'c31_1.v',
);

1;

