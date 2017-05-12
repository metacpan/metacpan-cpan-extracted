use strict;
use warnings;

use Test::More tests => 10;

package Common;

our @store;

package Consumer;

use POE;
use POE::Declarative;

use Test::More;

our $acc = 1;
our $active = 1;

on _start => run {
    get(KERNEL)->alias_set('consumer');
    yield 'consume';
};

on consume => run {
    if (@Common::store) {
        is(shift(@Common::store), $acc++);
    }

    yield 'consume' if $active || scalar(@Common::store);
};

on 'shutdown' => run {
    $active = 0;
};

package Producer;

use POE;
use POE::Declarative;

on _start => run {
    for (1 .. 10) {
        yield produce => $_;
    }
};

on produce => run {
    push @Common::store, get ARG0;
}; 

on _stop => run {
    call consumer => 'shutdown';
};

package main;

POE::Declarative->setup('Consumer');
POE::Declarative->setup('Producer');
POE::Kernel->run;
