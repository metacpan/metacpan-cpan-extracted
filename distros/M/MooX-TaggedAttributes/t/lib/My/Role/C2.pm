package My::Role::C2;

use Moo;
extends 'My::Role::B2';

use namespace::clean;

has c2_1 => (
    is      => 'ro',
    T2_1    => 'should not stick',
    default => 'c2_1.v',
);

1;

