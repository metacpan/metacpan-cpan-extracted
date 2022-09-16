package My::Class::Handler::CC1_2;

use Test::Lib;
use Moo;

use My::Class::Handler::T12;

extends 'My::Class::Handler::C1', 'My::Class::Handler::C2';

has cc1_2 => ( is => 'ro', T1 => [], T2 => [] );

1;
