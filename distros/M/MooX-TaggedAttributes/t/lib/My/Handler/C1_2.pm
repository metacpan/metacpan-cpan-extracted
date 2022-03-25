package My::Handler::C1_2;

use Test::Lib;
use Moo;
use My::Handler::T1;
use My::Handler::T2;


has c1_2 => ( is => 'ro', T1 => [], T2 => [] );

1;
