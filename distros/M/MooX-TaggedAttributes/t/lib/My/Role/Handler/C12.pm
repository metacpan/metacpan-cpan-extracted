package My::Role::Handler::C12;

use Test::Lib;
use Moo;
with 'My::Role::Handler::T12';

has c12 => ( is => 'ro', T1 => [], T2 => [] );

1;
