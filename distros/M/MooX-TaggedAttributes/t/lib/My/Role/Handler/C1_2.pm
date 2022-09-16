package My::Role::Handler::C1_2;

use Moo;
with 'My::Role::Handler::T1';
with 'My::Role::Handler::T2';


has c1_2 => ( is => 'ro', T1 => [], T2 => [] );

1;
