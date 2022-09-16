package My::Class::Handler::CC1;

use Test::Lib;
use Moo;

use My::Class::Handler::T12;

extends 'My::Class::Handler::C1';

has cc1 => ( is => 'ro', T1 => [], T2 => [] );

1;
