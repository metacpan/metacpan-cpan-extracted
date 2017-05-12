use lib 't', 'lib';
use strict;
use warnings;

package AAA;
use Spiffy -base;
BEGIN {@AAA::EXPORT_OK = qw(dude)}
const dude => 10;

package BBB;
use base 'AAA';
BEGIN {
    @BBB::EXPORT_OK = qw(dude);
    const dude => 20;
}

package CCC;
BEGIN {BBB->import('dude')}

package main;
no warnings;
use Test::More tests => 2;
ok(defined $CCC::{dude});
is(CCC::dude(), 20);
