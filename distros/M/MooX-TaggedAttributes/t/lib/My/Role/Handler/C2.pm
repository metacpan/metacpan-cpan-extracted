package My::Role::Handler::C2;

use Test::Lib;
use Moo;
with 'My::Role::Handler::T2';

has c2 => ( is => 'ro', T2 => [] );

1;
