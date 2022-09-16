package My::Role::C10;
use Moo;

extends 'My::Role::B1', 'My::Role::B2';

with 'My::Role::R1';
with 'My::Role::R2';

use namespace::clean -except => 'has';

has c10_1 => (
    is      => 'rw',
    T1_1    => 'c10_1.t1_1',
    T2_1    => 'c10_1.t2_1',
    default => 'c10_1.v',
);
1;
