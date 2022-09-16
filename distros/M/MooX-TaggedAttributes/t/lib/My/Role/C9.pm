package My::Role::C9;
use Moo;

with 'My::Role::R3';

use namespace::clean -except => 'has';

has c9_1 => (
    is      => 'rw',
    T1_1    => 'c9_1.t1_1',
    default => 'c9_1.v',
);
1;
