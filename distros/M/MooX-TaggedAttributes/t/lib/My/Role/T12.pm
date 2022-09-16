package My::Role::T12;

use Moo::Role;

with 'My::Role::T1';
with 'My::Role::T2';

use namespace::clean -except => 'has';

has t12_1 => ( is => 'ro', default => 't12_1.v' );

1;
