use strict;
use warnings;
use Test::More 'no_plan';

use Number::Compare::Duration;

my $c = 'Number::Compare::Duration';

my $t = $c->new('>1h');

ok($t->('0.5d'), '0.5d > 1h');
ok($t->('1d'), "1d > 1h");
ok($t->('2h'), "2h > 1h");
ok($t->('61m'), "61m > 1h");
ok($t->("3601"), "3601 > 1h");
ok(!$t->("3600"), "! 3600 > 1h");
