package My::Handler::T12;

use Moo::Role;
use My::Handler::T1;
use My::Handler::T2;

has t1t2 => ( is => 'ro', T1 => [], T2 => [] );
1;
