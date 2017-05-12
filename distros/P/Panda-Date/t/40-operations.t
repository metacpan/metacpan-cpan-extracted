use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use PDTest;

my $date;

##################### COMPARE ###########################
$date = date(1000);
cmp_ok($date, '>', 0);
cmp_ok($date, '>', 999);
cmp_ok($date, '>=', 1000);
cmp_ok($date, '<', 1001);
cmp_ok($date, '>', "1970-01-01 03:16:00");
cmp_ok($date, '>', [1970,1,1,3,16]);
cmp_ok($date, '<', "1970-01-01 03:17:00");
cmp_ok($date, '<', {year => 1970, month => 1, day => 1, hour => 3, min => 17});
cmp_ok($date, '==', "1970-01-01 03:16:40");
is($date, "1970-01-01 03:16:40");
cmp_ok(date("2013-05-06 01:02:03"), '<', date("2013-05-06 01:02:04"));
cmp_ok("2013-05-06 01:02:03", '<', date("2013-05-06 01:02:04"));
cmp_ok(date("2013-05-06 01:02:03"), '<', "2013-05-06 01:02:04");
cmp_ok("2013-05-06 01:02:04", '==', date("2013-05-06 01:02:04"));
cmp_ok(date("2001-09-09 05:46:40"), '==', 1000000000);
cmp_ok(date("2001-09-09 05:46:40"), '<', 1000000001);
cmp_ok(date("2001-09-09 05:46:40"), '>', 999999999);
cmp_ok(1000000000, '==', date("2001-09-09 05:46:40"));
cmp_ok(1000000001, '>', date("2001-09-09 05:46:40"));
cmp_ok(999999999, '<', date("2001-09-09 05:46:40"));

# INVALID COMPARE
ok(!eval{my $a = $date > rdate(10); 1;});
ok(!eval{my $a = rdate(10) > $date; 1;});

#################### ADD RELATIVE DATE ####################
$date = date("2013-01-01");

my $reldate = rdate(0);
cmp_ok($date + $reldate, '==', $date);

$reldate = rdate(10);
cmp_ok($date + $reldate, '==', "2013-01-01 00:00:10");
cmp_ok($date + "15m 60s", '==', "2013-01-01 00:15:60");
cmp_ok($date + "23h 15m 60s", '==', "2013-01-01 23:15:60");
cmp_ok($date + "24h 15m 60s", '==', "2013-01-02 00:15:60");
cmp_ok($date + 10*DAY, '==', "2013-01-11");
cmp_ok($date + MONTH, '==', "2013-02-01");
cmp_ok($date + 2000*YEAR, '==', "4013-01-01");

$date += "1M";
cmp_ok($date, '==', "2013-02-01");
$date += 27*DAY;
cmp_ok($date, '==', "2013-02-28");
$date += DAY;
cmp_ok($date, '==', "2013-03-01");

##################################### check ops table #######################################
$date = date("2012-03-02 15:47:32");
# +
cmp_ok($date + "1D", '==', "2012-03-03 15:47:32"); # $date $scalar
cmp_ok("1Y 1m" + $date, '==', "2013-03-02 15:48:32"); # $scalar $date
cmp_ok($date + HOUR, '==', "2012-03-02 16:47:32"); # $date $rel
ok(!eval {my $a = $date + date(0); 1}); # $date $date
ok(!eval {my $a = $date + idate(0,0); 1}); # $date $idate

# +=
# $date $scalar
$date = date("2012-03-02 15:47:32");
$date += "1M";
is($date, "2012-04-02 15:47:32");
# $scalar $date
my $scalar = "23h";
$scalar += $date;
is($date, "2012-04-02 15:47:32");
is($scalar, "2012-04-03 14:47:32");
# $date $rel
$date += YEAR;
is($date, "2013-04-02 15:47:32");
is(YEAR, "1Y");
# $date $date
ok(!eval { $date += date(123); 1; });
# $date $idate
ok(!eval { $date += idate(123,123); 1; });

# -
$date = date("2012-03-02 15:47:32");
cmp_ok($date - "1D", '==', "2012-03-01 15:47:32"); # $date $scalar-rel
is($date - "2011-04-03 16:48:33", ["2011-04-03 16:48:33", "2012-03-02 15:47:32"]); # $date $scalar-date
is("2013-04-03 16:48:33" - $date, ["2012-03-02 15:47:32", "2013-04-03 16:48:33"]); # $scalar $date
cmp_ok($date - HOUR, '==', "2012-03-02 14:47:32"); # $date $rel
is(date("2013-04-03 16:48:33") - $date, ["2012-03-02 15:47:32", "2013-04-03 16:48:33"]); # $date $date
ok(!eval { my $a = $date - idate(111,111); 1; }); # $date $idate

# -=
# $date $scalar
$date = date("2012-03-02 15:47:32");
$date -= "1M";
is($date, "2012-02-02 15:47:32");
is($date+1, "2012-02-02 15:47:33");
is($date-1, "2012-02-02 15:47:31");
# $scalar $date
$scalar = "2013-04-03 16:48:33";
$scalar -= $date;
is($date, "2012-02-02 15:47:32");
is($scalar, ["2012-02-02 15:47:32", "2013-04-03 16:48:33"]);
# $date $rel
$date -= DAY;
is($date, "2012-02-01 15:47:32");
# $date $date
ok(!eval { $date -= date(123); 1; });
# $date $idate
ok(!eval { $date -= idate(123,123); 1; });

# <=>
$date = date("2012-03-02 15:47:32");
# $date $scalar
cmp_ok($date, '>', "2012-03-02 15:47:31");
cmp_ok($date, '<', "2012-03-02 15:47:33");
cmp_ok($date, '>', 1330688851);
cmp_ok($date, '<', 1330688853);
cmp_ok($date, '==', 1330688852);
is($date, 1330688852);
# $scalar $date
cmp_ok("2012-03-02 15:47:31", '<', $date);
cmp_ok("2012-03-02 15:47:33", '>', $date);
cmp_ok(1330688851, '<', $date);
cmp_ok(1330688853, '>', $date);
cmp_ok(1330688852, '==', $date);
is(1330688852, $date);
# $date $rel
ok(!eval { my $a = $date > MONTH; 1});
# $date $date
cmp_ok($date, '>', date(0));
cmp_ok($date, '<', date(2000000000)); 
cmp_ok(date(1330688851), '<', $date);
cmp_ok(date(1330688853), '>', $date);
cmp_ok(date(1330688852), '==', $date);
is(date(1330688852), $date);
ok(!eval {my $a = $date == idate(0,0); 1}); # $rel $idate

#check that rdates haven't been changed
is(SEC, '1s');
is(MIN, '1m');
is(HOUR, '1h');
is(DAY, '1D');
is(MONTH, '1M');
is(YEAR, '1Y');

done_testing();
