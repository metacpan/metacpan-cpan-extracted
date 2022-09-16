package My::Role::B1;

use Moo;

with 'My::Role::T1';

use namespace::clean -except => 'has';

has b1_1 => (
    is      => 'rw',
    default => 'b1_1.v',
    T1_1    => 'b1_1.t1_1',
);

1;
