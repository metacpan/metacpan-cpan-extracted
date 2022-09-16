package My::Role::LateApply::C1;

use Moo;
with 'My::Role::LateApply::T1';

has c1_1 => (
    is      => 'rw',
    tag1    => 'c1_1.t1',
    tag2    => 'c1_1.t2',
    default => 'c1_1.v',
);

has c1_2 => (
    is      => 'rw',
    tag2    => 'c1_2.t2',
    default => 'c1_2.v',
);

1;
