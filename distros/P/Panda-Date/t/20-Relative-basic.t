use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use PDTest;

my $rel;

$rel = new Panda::Date::Rel;
is($rel->sec, 0);
is($rel->min, 0);
is($rel->hour, 0);
is($rel->day, 0);
is($rel->month, 0);
is($rel->year, 0);
is($rel, "");

$rel = new Panda::Date::Rel(1000);
is($rel->sec, 1000);
is($rel->min, 0);
is($rel->hour, 0);
is($rel->day, 0);
is($rel->month, 0);
is($rel->year, 0);
is($rel, "1000s");
is($rel, $rel->string);
is($rel, $rel->to_string);
is($rel, $rel->as_string);
ok($rel->sec == $rel->secs and $rel->sec == $rel->second and $rel->sec == $rel->seconds);

$rel = new Panda::Date::Rel("1000");
is($rel->sec, 1000);
is($rel->min, 0);
is($rel->hour, 0);
is($rel->day, 0);
is($rel->month, 0);
is($rel->year, 0);
is($rel, "1000s");

$rel = new Panda::Date::Rel [1,2,3,4,5,6];
is($rel->sec, 6);
is($rel->min, 5);
is($rel->hour, 4);
is($rel->day, 3);
is($rel->month, 2);
is($rel->year, 1);
is($rel->to_sec, 37090322);
ok($rel->to_sec == $rel->to_number and int($rel) == $rel->to_sec);
cmp_ok(abs($rel->to_min   - 618172.033333), '<', 0.000001);
cmp_ok(abs($rel->to_hour  - 10302.867222), '<', 0.000001);
cmp_ok(abs($rel->to_day   - 429.286134), '<', 0.000001);
cmp_ok(abs($rel->to_month - 14.104156), '<', 0.000001);
cmp_ok(abs($rel->to_year  - 1.175346), '<', 0.000001);
ok($rel->to_secs == $rel->to_sec and $rel->to_sec == $rel->to_seconds and $rel->to_sec == $rel->to_second);
ok($rel->to_mins == $rel->to_min and $rel->to_min == $rel->to_minutes and $rel->to_min == $rel->to_minute);
ok($rel->to_hours == $rel->to_hour);
ok($rel->to_days == $rel->to_day);
ok($rel->to_months == $rel->to_month and $rel->to_month == $rel->to_mon and $rel->to_month == $rel->to_mons);
is($rel, "1Y 2M 3D 4h 5m 6s");

$rel = new Panda::Date::Rel($rel);
is($rel, "1Y 2M 3D 4h 5m 6s");

$rel = new Panda::Date::Rel {year => 6, month => 5, day => 4, hour => 3, min => 2, sec => 1};
is($rel->sec, 1);
is($rel->min, 2);
is($rel->hour, 3);
is($rel->day, 4);
is($rel->month, 5);
is($rel->year, 6);
is($rel, "6Y 5M 4D 3h 2m 1s");

$rel = new Panda::Date::Rel "6s";
is($rel, "6s");
is($rel->sec, 6);
is($rel->to_sec, 6);
cmp_ok(abs($rel->to_min - 0.1), '<', 0.000001);

$rel = new Panda::Date::Rel "5m";
is($rel, "5m");
is($rel->min, 5);
is($rel->to_sec, 300);

$rel = new Panda::Date::Rel "2h";
is($rel, "2h");
is($rel->hour, 2);
is($rel->to_sec, 7200);

$rel = new Panda::Date::Rel "1s 1m 1h";
is($rel, "1h 1m 1s");
is($rel->sec, 1);
is($rel->min, 1);
is($rel->hour, 1);
is($rel->to_sec, 3661);

$rel = new Panda::Date::Rel "-9999M";
is($rel, "-9999M");
is($rel->month, -9999);

$rel = new Panda::Date::Rel "12Y";
is($rel, "12Y");
is($rel->year, 12);

$rel = new Panda::Date::Rel "1Y 2M 3D 4h 5m 6s";
is($rel->sec, 6);
is($rel->min, 5);
is($rel->hour, 4);
is($rel->day, 3);
is($rel->month, 2);
is($rel->year, 1);
is($rel, "1Y 2M 3D 4h 5m 6s");

$rel = new Panda::Date::Rel "-1Y -2M -3D 4h 5m 6s";
is($rel, "-1Y -2M -3D 4h 5m 6s");
is($rel->sec, 6);
is($rel->min, 5);
is($rel->hour, 4);
is($rel->day, -3);
is($rel->month, -2);
is($rel->year, -1);

$rel = rdate "1Y 2M 3D 4h 5m 6s";
is($rel->sec, 6);
is($rel->min, 5);
is($rel->hour, 4);
is($rel->day, 3);
is($rel->month, 2);
is($rel->year, 1);
is($rel, "1Y 2M 3D 4h 5m 6s");

is(rdate("2012-03-02 15:47:32", "2013-04-03 16:48:33"), "1Y 1M 1D 1h 1m 1s");
is(rdate("2013-04-03 16:48:33", "2012-03-02 15:47:32"), "-1Y -1M -1D -1h -1m -1s");
is(rdate("2012-03-02 15:47:32", "2013-04-03 16:48:33"), Panda::Date::Rel->new("2012-03-02 15:47:32", "2013-04-03 16:48:33"));

$rel->set(1000);
is($rel, "1000s");
$rel->set(0);
$rel->set("1000");
is($rel, "1000s");
$rel->set(0);
$rel->set("1Y 2M 3D 4h 5m 6s");
is($rel, "1Y 2M 3D 4h 5m 6s");
$rel->set(0);
$rel->set([1,2,3,4,5,6]);
is($rel, "1Y 2M 3D 4h 5m 6s");
$rel->set(0);
$rel->set({year => 1, month => 2, day => 3, hour => 4, min => 5, sec => 6});
is($rel, "1Y 2M 3D 4h 5m 6s");
$rel->set(0);

is(SEC, "1s");
is(MIN, "1m");
is(HOUR, "1h");
is(DAY, '1D');
is(MONTH, '1M');
is(YEAR, '1Y');

my $rotest = rdate("1Y 1M 1D");
$rotest->is_const(1);
my $rotest2 = rdate_const("1M 1D 1h");
foreach my $const (SEC, MIN, HOUR, DAY, MONTH, YEAR, $rotest, $rotest2) {
    my $initial_str = $const->to_string;
    ok(!eval { $const *= 10; 1 }, 'RO-MULS');
    ok(!eval { $const /= 2; 1 }, 'RO-DIVS');
    ok(!eval { $const += '5D'; 1 }, 'RO-ADDS');
    ok(!eval { $const -= '1M'; 1 }, 'RO-MINS');
    ok(!eval { $const->negative; 1 }, 'RO-NEG');
    ok(!eval { $const->sec(0); 1 }, 'RO-SEC');
    ok(!eval { $const->min(0); 1 }, 'RO-MIN');
    ok(!eval { $const->hour(0); 1 }, 'RO-HOUR');
    ok(!eval { $const->day(0); 1 }, 'RO-DAY');
    ok(!eval { $const->month(0); 1 }, 'RO-MON');
    ok(!eval { $const->year(0); 1 }, 'RO-YEAR');
    ok(!eval { $const->set(1024); 1 }, 'RO-SETNUM');
    ok(!eval { $const->set("3h 4m 5s"); 1 }, 'RO-SETSTR');
    ok(!eval { $const->set([1,2,3,4,5,6]); 1 }, 'RO-SETARR');
    ok(!eval { $const->set({year => 1000}); 1 }, 'RO-SETHASH');
    is($const->to_string, $initial_str, 'RO-cmp');
}

done_testing();
