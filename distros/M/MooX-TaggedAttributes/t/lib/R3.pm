package R3;
use Moo::Role;
with 'R1';

# this tag shouldn't stick as this isn't a tag role.
has r3_1 => (
    is   => 'ro',
    T1_1 => 'r3_1.t1_1',
);

1;


