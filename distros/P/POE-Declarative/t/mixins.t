use strict;
use warnings;

use Test::More tests => 11;

use lib 't/lib';

use POE::Declarative;
use_ok('TestProducerConsumer');

POE::Declarative->setup('TestProducerConsumer');
POE::Kernel->run;
