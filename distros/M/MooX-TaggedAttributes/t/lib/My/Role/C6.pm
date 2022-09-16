package My::Role::C6;

use Moo;
extends 'My::Role::B1';

with 'My::Role::R1';
with 'My::Role::R2';

use namespace::clean -except => 'has';

has c6_1 => (
    is      => 'ro',
    default => 'c6_1.v',
    T1_1    => 'c6_1.t1_1',
    T2_1    => 'c6_1.t2_1',
);

1;
