use Test::More;

plan tests => 4;

package BBB;
use Spiffy -Base, -XXX;

package AAA;
use Spiffy -Base;

package main;

ok(not defined &AAA::XXX);
ok(defined &AAA::field);

ok(defined &BBB::XXX);
ok(defined &BBB::field);
