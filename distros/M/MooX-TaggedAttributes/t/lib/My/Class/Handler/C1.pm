package My::Class::Handler::C1;

use Test::Lib;
use Moo;
use My::Class::Handler::T1;

has c1 => ( is => 'ro', T1 => [] );

1;
