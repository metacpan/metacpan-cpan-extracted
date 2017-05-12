use strict;
use warnings;

use Test::More tests => 12; 

use POE;
use POE::Declarative;

use lib 't/lib';
use CrazyMixin;

on count 5 => run {
    is(get OBJECT, 'main');
    pass("count 5");
};

POE::Declarative->setup;
POE::Kernel->run;
