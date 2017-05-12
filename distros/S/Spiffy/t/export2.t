use lib 't';
use strict;
use warnings;
package AAA;
use Spiffy -base;
BEGIN {@AAA::EXPORT = qw($A1 $A2)}
$AAA::A1 = 5;
$AAA::A2 = 10;

package BBB;
use base 'AAA';
BEGIN {@BBB::EXPORT = qw($A2 $A3)}
$BBB::A2 = 15;
$BBB::A3 = 20;

package main;
use strict;
use Test::More tests => 6;
BEGIN {BBB->import}
ok(defined $main::A1);
ok(defined $main::A2);
ok(defined $main::A3);
is($main::A1, 5);
is($main::A2, 15);
is($main::A3, 20);
