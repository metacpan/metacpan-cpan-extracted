package My::Role::C4;

use Moo;
extends 'My::Role::B1';

with 'My::Role::R1';

use namespace::clean -except => 'has';

has c4_1 => (
    is      => 'ro',
    T1_1    => 'c4_1.t1_1',
    default => 'c4_1.v',
);

1;
