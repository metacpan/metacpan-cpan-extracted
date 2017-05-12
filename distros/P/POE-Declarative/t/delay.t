use strict;
use warnings;

use POE;
use POE::Declarative;

use Test::More 'no_plan';

my $canceled = 0;

on _start => run {
    delay say_ok => 0.1;
    delay stop_it => 1;
};

on say_ok => run {
    $canceled ? fail("not ok") : pass("ok");
    delay say_ok => 0.1 unless $canceled;
};

on stop_it => run {
    $canceled = 1;
    delay 'say_ok'; # cancel!
};

POE::Declarative->setup;
POE::Kernel->run;
