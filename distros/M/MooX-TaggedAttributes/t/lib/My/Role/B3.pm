package My::Role::B3;

use Moo;

with 'My::Role::T2';
with 'My::Role::T1';

use namespace::clean -except => 'has';

has b3_1 => (
    is      => 'rw',
    default => 'b3_1.v',
    T1_1    => 'b3_1.t1_1',
    T2_1    => 'b3_1.t2_1',
);



1;
