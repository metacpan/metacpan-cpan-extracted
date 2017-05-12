use lib 't';
use strict;
use warnings;

package AAA;
use Spiffy -base;
BEGIN {@AAA::EXPORT_OK = qw($A1 $A2)}
$AAA::A1 = 5;
$AAA::A2 = 10;

package BBB;
use base 'AAA';
BEGIN {@BBB::EXPORT_OK = qw($A2 $A3)}
$BBB::A2 = 15;
$BBB::A3 = 20;

package main;
no warnings;
use Test::More tests => 7;
BEGIN {BBB->import(qw($A1 $A2 $A3 $A4))}
ok(defined $main::A1);
ok(defined $main::A2);
ok(defined $main::A3);
ok(not defined $main::A4);
is($A1, 5);
is($A2, 10);
is($A3, 20);
