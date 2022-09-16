package My::Role::C8;

use Moo;
extends 'My::Role::B3';

with 'My::Role::R1';
with 'My::Role::R2';

use namespace::clean -except => 'has';

has c8_1 => (
    is      => 'ro',
    default => 'c8_1.v',
    T1_1    => 'c8_1.t1_1',
    T2_1    => 'c8_1.t2_1',
);

1;
