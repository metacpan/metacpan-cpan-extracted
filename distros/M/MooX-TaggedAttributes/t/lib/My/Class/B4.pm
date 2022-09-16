package My::Class::B4;

use Moo;

use namespace::clean;

use My::Class::T12;

has b4_1 => (
    is      => 'rw',
    default => 'b4_1.v',
    T1_1    => 'b4_1.t1_1',
    T2_1    => 'b4_1.t2_1',
);

1;

