use lib 't', 'lib';
use strict;
use warnings;

package AAA;
use Spiffy -Base, ':XXX';

package BBB;
use Spiffy -Base, ':XXX', 'field';

package main;
use Test::More tests => 4;
ok(not defined &AAA::field);
ok(defined &BBB::field);
ok(defined &AAA::XXX);
ok(defined &BBB::XXX);
