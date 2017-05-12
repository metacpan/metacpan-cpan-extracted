use strict;
use warnings;

use POE;
use POE::Declarative;

use Test::More tests => 10;

our $acc = 1;

on _start => run {
    yield 'say_ok_times_10';
};

on say_ok_times_10 => run {
    for ( 1 .. 10 ) {
        yield 'say_ok', $_;
    }
};

on say_ok => run {
    is(get ARG0, $acc++);
};

POE::Declarative->setup;
POE::Kernel->run;

