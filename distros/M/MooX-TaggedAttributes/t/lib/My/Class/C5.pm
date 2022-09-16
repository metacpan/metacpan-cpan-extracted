package My::Class::C5;

use Moo;
extends 'My::Class::C4';

use namespace::clean;

use My::Class::R1;
use My::Class::R2;

has c5_1 => (
    is      => 'ro',
    default => 'c5_1.v',
    T1_1    => 'c5_1.t1_1',
    T2_1    => 'c5_1.t2_1',
);

1;
