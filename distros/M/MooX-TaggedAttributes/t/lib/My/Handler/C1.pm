package My::Handler::C1;

use Test::Lib;
use Moo;
use My::Handler::T1;

has c1 => ( is => 'ro', T1 => [] );

1;
