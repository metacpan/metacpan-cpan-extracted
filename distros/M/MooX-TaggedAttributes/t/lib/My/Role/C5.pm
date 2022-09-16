package My::Role::C5;

use Moo;
extends 'My::Role::C4';

with 'My::Role::R1';
with 'My::Role::R2';

use namespace::clean -except => 'has';

has c5_1 => (
    is      => 'ro',
    default => 'c5_1.v',
    T1_1    => 'c5_1.t1_1',
    T2_1    => 'c5_1.t2_1',
);

1;
