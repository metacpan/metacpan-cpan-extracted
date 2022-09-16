package My::Class::Handler::C1_2;

use Test::Lib;
use Moo;
use My::Class::Handler::T1;
use My::Class::Handler::T2;


has c1_2 => ( is => 'ro', T1 => [], T2 => [] );

1;
