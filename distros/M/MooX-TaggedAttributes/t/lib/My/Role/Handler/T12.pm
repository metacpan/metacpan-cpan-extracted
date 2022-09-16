package My::Role::Handler::T12;

use Moo::Role;
with 'My::Role::Handler::T1';
with 'My::Role::Handler::T2';

has t1t2 => ( is => 'ro', T1 => [], T2 => [] );
1;
