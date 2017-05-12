use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use PDTest;
use Panda::Lib 'clone';

my $idate;
##################################### check ops table #######################################

# +
$idate = idate("2012-02-01", "2013-02-01");
is($idate + "1D", ["2012-02-02", "2013-02-02"]); # $idate $scalar
cmp_ok("1Y" + $idate, '==', [[2013,2,1], [2014,2,1]]); # $scalar $idate
is($idate + 28*DAY, ["2012-02-29", "2013-03-01"]); # $idate $rel
ok(!eval {my $a = $idate + date(0); 1}); # $idate $date
ok(!eval {my $a = $idate + $idate; 1}); # $idate $idate

# +=
$idate = idate("2012-02-01", "2013-02-01");
# $idate $scalar
$idate += "1D";
is($idate, ["2012-02-02", "2013-02-02"]);
# $scalar $idate
my $scalar = "1Y";
$scalar += $idate;
is($idate, ["2012-02-02", "2013-02-02"]);
is($scalar, ["2013-02-02", "2014-02-02"]);
# $idate $rel
$idate += HOUR;
is($idate, ["2012-02-02 01:00:00", "2013-02-02 01:00:00"]);
is(HOUR, "1h");
# $idate $date
ok(!eval { $idate += date(123); 1; });
# $idate $idate
ok(!eval { $idate += idate(123,123); 1; });

# -
$idate = idate("2012-02-01", "2013-02-01");
is($idate - "1D", ["2012-01-31", "2013-01-31"]); # $idate $scalar
ok(!eval {my $a = "1Y" - $idate; 1}); # $scalar $idate
is($idate - DAY, ["2012-01-31", "2013-01-31"]); # $idate $rel
ok(!eval { my $a = $idate - date("2012-01-01"); 1; }); # $idate $date
ok(!eval { my $a = $idate - idate(111,111); 1; }); # $idate $idate

# -=
$idate = idate("2012-02-01", "2013-02-01");
# $idate $scalar
$idate -= "1M";
is($idate, ["2012-01-01", "2013-01-01"]);
# $scalar $idate
$scalar = "23h";
ok(!eval { $scalar -= $idate; 1});
# $idate $rel
$idate -= DAY;
is($idate, ["2011-12-31", "2012-12-31"]);
is(DAY, "1D");
# $idate $date
ok(!eval { $idate -= date(123); 1; });
# $idate $idate
ok(!eval { $idate -= idate(123,123); 1; });

# - unary
$idate = idate("2012-02-01", "2013-02-01");
is($idate->duration, 31622400);
is((-$idate)->duration, -31622400);
$idate->negative;
is($idate->duration, -31622400);

# <=>
$idate = idate("2012-02-01 00:00:00", "2012-02-01 00:00:01");
# $idate $scalar
cmp_ok($idate, '>', ["2013-02-01 00:00:00", "2013-02-01 00:00:00"]);
cmp_ok($idate, '<', ["2013-02-01 00:00:00", "2013-02-01 00:00:02"]);
cmp_ok($idate, '==', ["2013-02-01 00:00:00", "2013-02-01 00:00:01"]);
isnt($idate, ["2013-02-01 00:00:00", "2013-02-01 00:00:01"]);
is($idate, ["2012-02-01 00:00:00", "2012-02-01 00:00:01"]);
cmp_ok($idate, '>', 0);
cmp_ok($idate, '<', 2);
cmp_ok($idate, '==', 1);
# $scalar $idate
cmp_ok(["2013-02-01 00:00:00", "2013-02-01 00:00:00"], '<', $idate);
cmp_ok(["2013-02-01 00:00:00", "2013-02-01 00:00:02"], '>', $idate);
cmp_ok(["2013-02-01 00:00:00", "2013-02-01 00:00:01"], '==', $idate);
cmp_ok(["2013-02-01 00:00:00", "2013-02-01 00:00:01"], 'ne', $idate);
is(["2012-02-01 00:00:00", "2012-02-01 00:00:01"], $idate);
cmp_ok(0, '<', $idate);
cmp_ok(2, '>', $idate);
cmp_ok(1, '==', $idate);
# $idate $rel
ok(!eval {my $a = $idate > DAY; 1});
# $idate $date
ok(!eval {my $a = $idate < date(0); 1});
# $idate $idate
cmp_ok($idate, '>', idate("2013-02-01 00:00:00", "2013-02-01 00:00:00"));
cmp_ok($idate, '<', idate("2013-02-01 00:00:00", "2013-02-01 00:00:02"));
cmp_ok($idate, '==', idate("2013-02-01 00:00:00", "2013-02-01 00:00:01"));
cmp_ok($idate, 'ne', idate("2013-02-01 00:00:00", "2013-02-01 00:00:01"));
is($idate, idate("2012-02-01 00:00:00", "2012-02-01 00:00:01"));

#check that rdates haven't been changed
is(SEC, '1s');
is(MIN, '1m');
is(HOUR, '1h');
is(DAY, '1D');
is(MONTH, '1M');
is(YEAR, '1Y');

#check cloning
$idate = idate("2013-01-01 00:00:00", "2014-12-31 23:59:59");
my $cl = $idate->clone;
$idate->from("2013-02-01 01:01:01");
is($idate, "2013-02-01 01:01:01 ~ 2014-12-31 23:59:59");
is($cl, "2013-01-01 00:00:00 ~ 2014-12-31 23:59:59");

# check Panda::Lib::clone()
$idate = idate("2013-01-01 00:00:00", "2014-12-31 23:59:59");
$cl = clone($idate);
$idate->from("2013-02-01 01:01:01");
is($idate, "2013-02-01 01:01:01 ~ 2014-12-31 23:59:59");
is($cl, "2013-01-01 00:00:00 ~ 2014-12-31 23:59:59");

done_testing();
