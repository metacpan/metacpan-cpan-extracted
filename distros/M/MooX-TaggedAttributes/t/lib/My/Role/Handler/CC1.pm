package My::Role::Handler::CC1;

use Test::Lib;
use Moo;

with 'My::Role::Handler::T12';

extends 'My::Role::Handler::C1';

has cc1 => ( is => 'ro', T1 => [], T2 => [] );

1;
