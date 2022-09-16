package My::Role::R3;
use Moo::Role;

with 'My::Role::R1';

use namespace::clean -except => 'has';

has r3_1 => (
    is   => 'ro',
    T1_1 => 'r3_1.t1_1',
);

1;


