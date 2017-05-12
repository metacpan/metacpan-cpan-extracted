use Test::More 'no_plan';
use Test::Deep;
use lib '../lib';
use NG;

my $t = new Time;
isa_ok $t, 'Time';

is $t->strftime("%Y", $t->now), $t->now->year;
