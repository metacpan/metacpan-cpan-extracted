package My::Class::C2;

use Moo;
extends 'My::Class::B2';

use namespace::clean;

has c2_1 => (
    is      => 'ro',
    T2_1    => 'should not stick',
    default => 'c2_1.v',
);

1;

