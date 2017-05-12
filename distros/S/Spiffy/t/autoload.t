use lib 't', 'lib';
use strict;
use warnings;
use Spiffy ();

package AAA;
use Spiffy -Base;

sub AUTOLOAD {
    super;
    join '+', $AAA::AUTOLOAD, @_;
}

package BBB;
use base 'AAA';

sub AUTOLOAD {
    super;
}

package CCC;
use base 'BBB';

sub AUTOLOAD {
    super;
}

package main;
use Test::More tests => 1;

is(CCC->foo(42), 'CCC::foo+42');
