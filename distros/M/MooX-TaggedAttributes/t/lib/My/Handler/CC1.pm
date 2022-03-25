package My::Handler::CC1;

use Test::Lib;
use Moo;

use My::Handler::T12;

extends 'My::Handler::C1';

has cc1 => ( is => 'ro', T1 => [], T2 => [] );

1;
