use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use PDTest;

my ($date, $date2, $date3);

$date = date('2014-01-01 00:00:00');
ok($date->tz->{is_local});
ok($date->zone->{is_local});
ok($date->timezone->{is_local});
ok($date->tzlocal);
is($date->tzname, tzget()->{name});

$date2 = date('2014-01-01 00:00:00', 'America/New_York');
ok(!$date2->tzlocal);
is($date2->tzname, 'America/New_York');
is($date2->zone->{name}, $date2->tzname);
cmp_ok($date->epoch, '<', $date2->epoch);
cmp_ok($date, '<', $date2);
isnt($date, $date2);
is($date.'', $date2.'');

$date3 = $date2->clone({tz => undef});
ok($date3->tzlocal);
is($date3->tzname, tzget()->{name});
cmp_ok($date3, '==', $date);
cmp_ok($date3, '!=', $date2);
is($date3, $date);
is($date3.'', $date.'');
isnt($date3, $date2);
is($date3.'', $date2.'');

$date3 = $date2->clone;
$date3->to_timezone("");
ok($date3->tzlocal);
is($date3->tzname, tzget()->{name});
cmp_ok($date3, '!=', $date);
isnt($date3, $date);
isnt($date3.'', $date.'');
cmp_ok($date3, '==', $date2);
is($date3, $date2);
isnt($date3.'', $date2.'');

$date3 = $date2->clone;
$date3->to_timezone('Australia/Melbourne');
is($date3->epoch, $date2->epoch);
isnt($date3.'', $date2.'');

$date3 = $date2->clone;
$date3->tz('Australia/Melbourne');
isnt($date3->epoch, $date2->epoch);
is($date3.'', $date2.'');

done_testing();
