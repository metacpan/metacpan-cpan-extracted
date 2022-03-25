package My::Handler::C2;

use Test::Lib;
use Moo;
use My::Handler::T2;

has c2 => ( is => 'ro', T2 => [] );

1;
