package My::Role::Handler::C1;

use Test::Lib;
use Moo;
with 'My::Role::Handler::T1';

has c1 => ( is => 'ro', T1 => [] );

1;
