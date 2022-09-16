package My::Role::LateApply::R1;
use Moo::Role;

with 'My::Role::LateApply::T1';

has r1_1 => (
    is      => 'ro',
    default => 'r1_1.v',
    tag1    => 'r1_1.t1',
    tag2    => 'r1_1.t2',
);

1;
