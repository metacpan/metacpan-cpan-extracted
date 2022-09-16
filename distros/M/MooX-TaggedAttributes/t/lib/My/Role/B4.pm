package My::Role::B4;

use Moo;

with 'My::Role::T12';

use namespace::clean -except => 'has';

has b4_1 => (
    is      => 'rw',
    default => 'b4_1.v',
    T1_1    => 'b4_1.t1_1',
    T2_1    => 'b4_1.t2_1',
);

1;

