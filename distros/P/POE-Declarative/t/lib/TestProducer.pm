use strict;
use warnings;

package TestProducer;
use base qw/ POE::Declarative::Mixin /;

use POE;
use POE::Declarative;

on produce => run {
    push @{ get(HEAP)->{'store'} }, get ARG0;
};

1;
