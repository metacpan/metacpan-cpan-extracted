use strict;
use warnings;

use Test::More tests => 3;

package Some::MadeUp::Package;

use POE;
use POE::Declarative;

use Scalar::Util qw/ blessed /;
use Test::More;

on _start => run {
    isa_ok(get OBJECT, 'Some::MadeUp::Package');
    can_ok(get OBJECT, '_poe_declarative__start');
    is(blessed get OBJECT, 'Some::MadeUp::Package');
};

package main;

POE::Declarative->setup(bless {}, 'Some::MadeUp::Package');
POE::Kernel->run;
