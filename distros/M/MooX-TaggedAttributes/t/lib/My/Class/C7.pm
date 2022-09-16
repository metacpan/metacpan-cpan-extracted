package My::Class::C7;

use Moo;
extends 'My::Class::B2';

with 'My::Class::R1';
with 'My::Class::R2';

use namespace::clean;

has c7_1 => (
    is      => 'ro',
    default => 'c7_1.v',
    T1_1    => 'should not stick',
    T2_1    => 'should not stick',
);

1;
