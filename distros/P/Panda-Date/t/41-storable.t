use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use PDTest;
use Storable qw/freeze nfreeze dclone thaw/;

my ($date_cloned, $rdate_cloned, $idate_cloned);
my @a;

tzset("Europe/Moscow");

# date
my $date = date("2012-01-01 15:16:17");
my $dts = $date->epoch;
$date_cloned = thaw(freeze $date);
is($date_cloned->to_string, "2012-01-01 15:16:17");
ok($date_cloned->tz->{is_local});

$date_cloned = thaw(nfreeze date($date, "Europe/Kiev"));
is($date_cloned->to_string, "2012-01-01 15:16:17");
is($date_cloned->tzname, 'Europe/Kiev');
is($date_cloned->tzabbr, 'EET');
is($date_cloned->timezone->{name}, 'Europe/Kiev');
ok(!$date_cloned->tzlocal);

$date_cloned = dclone date($date, "Europe/Moscow");
is($date_cloned->to_string, "2012-01-01 15:16:17");
is($date_cloned->zone->{name}, 'Europe/Moscow');
ok($date_cloned->tz->{is_local});

my $frozen = freeze $date;
tzset('Europe/Kiev');
$date_cloned = thaw($frozen);
is($date_cloned->epoch, $dts);
isnt($date_cloned.'', $date.'');
ok($date_cloned->tzlocal);
is($date_cloned->tzname, 'Europe/Kiev');

# rdate
$rdate_cloned = thaw(freeze rdate("1Y 1M"));
is($rdate_cloned->to_string, "1Y 1M");
$rdate_cloned = thaw(nfreeze rdate("1Y 1M"));
is($rdate_cloned->to_string, "1Y 1M");
$rdate_cloned = dclone rdate("1Y 1M");
is($rdate_cloned->to_string, "1Y 1M");

# idate
my $idate = idate("2012-01-01 15:16:17", "2013-01-01 15:16:17");
$idate_cloned = thaw(freeze $idate);
is($idate_cloned->to_string, "2012-01-01 15:16:17 ~ 2013-01-01 15:16:17");
ok($idate_cloned->from->tzlocal);
ok($idate_cloned->till->tzlocal);
is($idate_cloned->from->tzname, tzget()->{name});
is($idate_cloned->till->tzname, tzget()->{name});

$idate->from(date("2012-01-01 15:16:17", 'Europe/Kiev'));
$idate_cloned = thaw(nfreeze $idate);
is($idate_cloned->to_string, "2012-01-01 15:16:17 ~ 2013-01-01 15:16:17");
ok($idate_cloned->from->tzlocal);
ok($idate_cloned->till->tzlocal);
is($idate_cloned->from->tzname, 'Europe/Kiev');
is($idate_cloned->till->tzname, tzget()->{name});

$idate->till(date("2013-01-01 15:16:17", 'Europe/Kiev'));
$idate_cloned = dclone $idate;
is($idate_cloned->to_string, "2012-01-01 15:16:17 ~ 2013-01-01 15:16:17");
ok($idate_cloned->from->tzlocal);
ok($idate_cloned->till->tzlocal);
is($idate_cloned->from->tzname, 'Europe/Kiev');
is($idate_cloned->till->tzname, 'Europe/Kiev');

#bug with dclone+newfrom
my $time = time();
$date = date($time);
$date_cloned = dclone($date);
is(date($date_cloned)->epoch, $time);

done_testing();
