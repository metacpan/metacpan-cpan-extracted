use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use PDTest;

my $rel;
my $i;

$i = new Panda::Date::Int(0, 0);
is($i->from, "1970-01-01 03:00:00");
is($i->till, "1970-01-01 03:00:00");
is($i->duration, 0);
is($i->sec, 0);
is($i->min, 0);
is($i->hour, 0);
is($i->day, 0);
is($i->month, 0);
is($i->year, 0);

$i = idate(1000000000, 1100000000);
is($i->from, "2001-09-09 05:46:40");
is($i->till, "2004-11-09 14:33:20");
is($i->to_string, "2001-09-09 05:46:40 ~ 2004-11-09 14:33:20");
is($i.'', $i->to_string);
is($i->string, $i->to_string);
is($i->as_string, $i->to_string);
is($i.'', "$i");
is($i->duration, 100000000);
is($i->sec, 100000000);
ok($i->secs == $i->sec and $i->second == $i->sec and $i->seconds == $i->sec);
is($i->imin, 1666666);
ok($i->imins == $i->imin and $i->iminute == $i->imin and $i->iminutes == $i->imin);
cmp_ok(abs($i->min-1666666.666666), '<', 0.000001);
ok($i->min == $i->mins and $i->min == $i->minute and $i->min == $i->minutes);
is($i->ihour, 27777);
is($i->ihours, $i->ihour);
cmp_ok(abs($i->hour-27777.777777), '<', 0.000001);
is($i->hours, $i->hour);
is($i->iday, 1157);
is($i->idays, $i->iday);
cmp_ok(abs($i->day - 1157.36574), '<', 0.000001);
is($i->day, $i->days);
is($i->imonth, 38);
ok($i->imon == $i->imonth and $i->imons == $i->imon and $i->imonths == $i->imon);
cmp_ok(abs($i->month - 38.012191), '<', 0.000001);
ok($i->months == $i->month and $i->mon == $i->month and $i->mon == $i->mons);
is($i->iyear, 3);
is($i->iyears, $i->iyear);
cmp_ok(abs($i->year - 3.167682), '<', 0.000001);
is($i->years, $i->year);
is($i->relative, "3Y 2M 8h 46m 40s");

$i = idate(date(1000000000), date(1100000000));
is($i->relative, "3Y 2M 8h 46m 40s");

$i = idate("2001-09-09 22:59:59","2001-09-10 01:00:00");
is($i->iday, 0);
cmp_ok(abs($i->day - 0.083344), '<', 0.000001);

is(idate("2004-09-10","2004-11-10 00:00:00")->relative, "2M");
is(idate("2004-09-10","2004-11-09 00:00:00")->relative, "1M 30D");
is(idate("2004-09-10","2005-02-09 00:00:00")->relative, "4M 30D");
is(idate("2004-09-10","2005-01-09 00:00:00")->relative, "3M 30D");
is(idate("2004-09-10","2005-03-09 00:00:00")->relative, "5M 27D");
is(idate("2003-09-10","2004-03-09 00:00:00")->relative, "5M 28D");
is(idate("2004-03-09 00:00:00", "2003-09-10")->relative, "-5M -28D");
$i->set("1985-01-02 01:02:03", "1990-02-29 23:23:23");
is($i, [{year => 1985, month => 1, day => 2, hour => 1, min => 2, sec => 3}, "1990-02-29 23:23:23"]);

# includes
$i = idate("2004-09-10","2004-11-10");
is($i->includes(date("2004-09-01")), 1);
is($i->includes("2004-10-01"), 0);
is($i->includes(1101848400), -1);

done_testing();
