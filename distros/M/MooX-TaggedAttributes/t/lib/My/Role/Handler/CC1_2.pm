package My::Role::Handler::CC1_2;

use Test::Lib;
use Moo;

with 'My::Role::Handler::T12';

extends 'My::Role::Handler::C1', 'My::Role::Handler::C2';

has cc1_2 => ( is => 'ro', T1 => [], T2 => [] );

1;
