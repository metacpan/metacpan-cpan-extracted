package My::Role::R1;

use Test::Lib;
use Moo::Role;

with 'My::Role::T1';

use namespace::clean -except => [ 'has', '_tags' ];

has r1_1 => (
    is      => 'rw',
    T1_1    => 'r1_1.t1_1',
    T1_2    => 'r1_1.t1_2',
    default => 'r1_1.v'
);

has r1_2 => (
    is      => 'rw',
    T1_1    => 'r1_2.t1_1',
    default => 'r1_2.v'
);

1;
