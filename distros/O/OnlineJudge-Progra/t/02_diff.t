use strict;
use warnings;
use 5.008;

use Test::More tests => 2;
use OnlineJudge::Progra;

my $j = OnlineJudge::Progra->new();
ok($j->compare('t/02_diff01.txt', 't/02_diff01.txt') == 1, 'equality');
ok($j->compare('t/02_diff01.txt', 't/02_diff02.txt') == 0, 'difference');



