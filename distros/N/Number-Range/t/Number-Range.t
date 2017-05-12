use Test::More tests => 40;
BEGIN { use_ok('Number::Range') };

ok($range = Number::Range->new("10..100"));
ok($range->inrange(10)   == 1);
ok($range->inrange(1000) == 0);
$range = Number::Range->new("10..50,60..100");
ok($range->inrange(10) == 1);
ok($range->inrange(55) == 0);
ok($range->inrange(75) == 1);
$range = Number::Range->new("10..100","150..200");
ok($range->inrange(10)  == 1);
ok($range->inrange(125) == 0);
ok($range->inrange(155) == 1);
$range = Number::Range->new("-10..10");
ok($range->inrange(10)  == 1);
ok($range->inrange(-10) == 1);
ok($range->inrange(0)   == 1);
$range->addrange("20..30");
ok($range->inrange(25) == 1);
ok($range->inrange(10) == 1);
ok($range->inrange(15) == 0);
$range->delrange("-10..0");
ok($range->inrange(-10) == 0);
ok($range->inrange(10)  == 1);
ok($range->inrange(25) == 1);
ok($range->inrange(10,25));
@test = $range->inrange(10,25,1000);
@rc   = qw/1 1 0/;
is_deeply(\@rc, \@test);
$range = Number::Range->new("1..100,150..200");
$rangeformat = $range->range;
cmp_ok("1..100,150..200", 'eq', $rangeformat);
ok($range->size == 151);
$range = Number::Range->new("1,3,4,5,6");
ok($range->range eq "1,3..6");
$range = Number::Range->new("1,2,3,4,5,6");
ok($range->range eq "1..6");
ok($range->inrange("01"));
# Tests for large range
$range = Number::Range->new("0..99999999");
ok($range->inrange("1"));
ok($range->inrange("99999999"));
ok($range->inrange("09"));
ok($range->size == 100000000);
# Tests for rangeList function
$range = Number::Range->new("1..10","150..200","300..300000","999999");
@rangeList = $range->rangeList();
ok($rangeList[0][0] == 1);
ok($rangeList[0][1] == 10);
ok($rangeList[1][0] == 150);
ok($rangeList[1][1] == 200);
ok($rangeList[2][0] == 999999);
# Single entries will not have a second indice
ok($rangeList[2][1] == undef);
# Large ranges always end up at the end of the list because they are processed seperatly
ok($rangeList[3][0] == 300);
ok($rangeList[3][1] == 300000);
# Test rangeList with only a single large range
$range = Number::Range->new("300..300000");
@rangeList = $range->rangeList();
ok($rangeList[0][0] == 300);
ok($rangeList[0][1] == 300000);
