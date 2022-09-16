package My::Class::C6;

use Moo;
extends 'My::Class::B1';

with 'My::Class::R1';
with 'My::Class::R2';

use namespace::clean;

has c6_1 => (
    is      => 'ro',
    default => 'c6_1.v',
    T1_1    => 'should not stick',
    T2_1    => 'should not stick',
);

1;
