package My::Role::Cache::C;
use Moo;
with 'My::Role::R1';

has c1 => (
    is   => 'rw',
    T1_1 => 't1_1_common',
);

has c2 => (
    is   => 'rw',
    T1_1 => 't1_1_common',
);

1;
