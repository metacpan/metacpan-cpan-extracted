use strict;
use warnings;

use POE;
use POE::Declarative;

use Test::More tests => 10;

on _start => run {
    for my $val (@{ get HEAP }) {
        yield 'say_ok';
    }
};

on say_ok => run {
    ok(1);
};

POE::Declarative->setup(undef, [ 1 .. 10 ]);
POE::Kernel->run;
