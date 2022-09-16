package My::Role::C7;

use Moo;
extends 'My::Role::B2';

with 'My::Role::R1';
with 'My::Role::R2';

use namespace::clean -except => 'has';

has c7_1 => (
    is      => 'ro',
    default => 'c7_1.v',
    T1_1    => 'c7_1.t1_1',
    T2_1    => 'c7_1.t2_1',
);

1;
