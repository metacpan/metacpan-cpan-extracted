package My::Role::B2;

use Moo;

with 'My::Role::T2';

use namespace::clean -except => 'has';

has b2_1 => (
    is      => 'rw',
    default => 'b2_1.v',
    T2_1    => 'b2_1.t2_1',
);

1;

