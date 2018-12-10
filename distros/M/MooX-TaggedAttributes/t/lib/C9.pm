package C9;
use Moo;
with 'R3';

use namespace::clean;

has c9_1 => (
    is      => 'rw',
    T1_1    => 'should not stick',
    default => 'c9_1.v',
);
1;
