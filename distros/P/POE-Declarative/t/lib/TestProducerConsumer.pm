use strict;
use warnings;

package TestProducerConsumer;

use POE;
use POE::Declarative;

use TestProducer;
use TestConsumer;

on _start => run {
    for ( 1 .. 10 ) {
        yield produce => $_;
    }

    yield 'consume';
};

1;
