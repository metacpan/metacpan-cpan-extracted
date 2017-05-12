use strict;
use warnings;

use Test::More tests => 21;

use lib 't/lib';

use POE::Declarative;
use_ok('TestProducerConsumer');

# An extra consume handler in TestProducerConsumer
{
    package TestProducerConsumer;

    use POE::Declarative;
    use Test::More;

    on consume => run {
        pass('one more pass');
    };
}

POE::Declarative->setup('TestProducerConsumer');
POE::Kernel->run;
