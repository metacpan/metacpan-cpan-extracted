package My::Class::Handler::T12;

use Moo::Role;
use My::Class::Handler::T1;
use My::Class::Handler::T2;

has t1t2 => ( is => 'ro', T1 => [], T2 => [] );
1;
