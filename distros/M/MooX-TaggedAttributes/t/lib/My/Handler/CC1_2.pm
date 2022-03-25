package My::Handler::CC1_2;

use Test::Lib;
use Moo;

use My::Handler::T12;

extends 'My::Handler::C1', 'My::Handler::C2';

has cc1_2 => ( is => 'ro', T1 => [], T2 => [] );

1;
