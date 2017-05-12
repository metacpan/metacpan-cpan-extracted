use lib 't';
use strict;
use warnings;

package AAA;
# Exporter before 5.8.4 needs the tag as the first thing imported
use Spiffy -base, qw(:XXX const);

package BBB;
use base 'AAA';

package CCC;
use Spiffy -XXX, -base;

package DDD;
use Spiffy -base;

package EEE;
use Spiffy -base, 'XXX';

package FFF;
use Spiffy -base;
use Spiffy 'XXX';

package main;
use Test::More tests => 24;

ok(not defined &AAA::field);
ok(defined &AAA::const);
ok(defined &AAA::XXX);
ok(defined &AAA::YYY);

ok(defined &BBB::field);
ok(defined &BBB::const);
ok(not defined &BBB::XXX);
ok(not defined &BBB::YYY);

ok(defined &CCC::field);
ok(defined &CCC::const);
ok(defined &CCC::XXX);
ok(defined &CCC::YYY);

ok(defined &DDD::field);
ok(defined &DDD::const);
ok(not defined &DDD::XXX);
ok(not defined &DDD::YYY);

ok(not defined &EEE::field);
ok(not defined &EEE::const);
ok(defined &EEE::XXX);
ok(not defined &EEE::YYY);

ok(defined &FFF::field);
ok(defined &FFF::const);
ok(defined &FFF::XXX);
ok(not defined &FFF::YYY);
