package My::Class::C10;
use Moo;

extends 'My::Class::B1', 'My::Class::B2';

use namespace::clean;

use My::Class::R1;
use My::Class::R2;

has c10_1 => (
    is      => 'rw',
    T1_1    => 'c10_1.t1_1',
    T2_1    => 'c10_1.t2_1',
    default => 'c10_1.v',
);
1;
