use strict;
use warnings;

use POE;
use POE::Declarative;

use Test::More tests => 10;

on _start => run {
    yield 'say_ok_times_10';
};

on say_ok_times_10 => run {
    for ( 1 .. 10 ) {
        yield 'say_ok';
    }
};

on say_ok => run {
    ok(1);
};

POE::Declarative->setup;
POE::Kernel->run;

