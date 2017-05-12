use strict;
use warnings;

use Test::More tests => 3;

use POE;
use POE::Declarative;

my @states = qw/ whisper say yell /;

on _start => run {
    yield $_ for @states;
};

on [ qw/ say yell whisper / ] => run {
    is(get STATE, shift(@states), 'state called in FIFO order');
};

POE::Declarative->setup;
POE::Kernel->run;
