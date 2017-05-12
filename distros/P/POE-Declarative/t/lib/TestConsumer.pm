use strict;
use warnings;

package TestConsumer;
use base qw/ POE::Declarative::Mixin /;

use POE;
use POE::Declarative;

use Test::More;

my $acc = 0;

on consume => run {
    my $consumed = shift @{ get(HEAP)->{'store'} };
    is($consumed, ++$acc, "consumed $consumed == acc $acc");

    yield 'consume' if scalar @{ get(HEAP)->{'store'} };
};

1;
