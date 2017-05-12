package R1;

use Test::Lib;

use Moo::Role;
use T1;

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
