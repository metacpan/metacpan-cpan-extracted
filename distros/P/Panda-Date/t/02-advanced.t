use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use PDTest;

my $date;

$date = Panda::Date->new("2013-09-05 3:4:5");
is($date->mysql, "20130905030405");
is($date->hms, '03:04:05');
is($date->ymd, '2013/09/05');
is($date->mdy, '09/05/2013');
is($date->dmy, '05/09/2013');
is($date->ampm, 'AM');
is($date->meridiam, '03:04 AM');

$date = Panda::Date->new("2013-09-05 23:4:5");
is($date->ampm, 'PM');
is($date->meridiam, '11:04 PM');
is($date->gmtoff, 14400);

tzset('America/New_York');
$date = Panda::Date->new("2013-09-05 23:45:56");
is($date->gmtoff, -14400);
tzset('Europe/Moscow');

$date = Panda::Date->new("2013-09-05 3:4:5");
my @ret = $date->array;
cmp_deeply(\@ret, [2013,9,5,3,4,5]);
cmp_deeply($date->aref, \@ret);

$date = Panda::Date->new("2012-09-05 3:4:5");
cmp_deeply([$date->struct], [5,4,3,5,8,112,3,248,0]);
cmp_deeply($date->sref, [5,4,3,5,8,112,3,248,0]);

my %ret = $date->hash;
cmp_deeply(\%ret, {year => 2012, month => 9, day => 5, hour => 3, min => 4, sec => 5});
cmp_deeply($date->href, \%ret);

$date = Panda::Date->new("2013-09-05 3:4:5");
is($date->month_begin_new, "2013-09-01 03:04:05");
is($date->month_end_new, "2013-09-30 03:04:05");
is($date->days_in_month, 30);

$date = Panda::Date->new("2013-08-05 3:4:5");
is($date->month_begin_new, "2013-08-01 03:04:05");
is($date, "2013-08-05 03:04:05");
is($date->month_end_new, "2013-08-31 03:04:05");
is($date, "2013-08-05 03:04:05");
is($date->days_in_month, 31);
$date->month_begin;
is($date, "2013-08-01 03:04:05");
$date->month_end;
is($date, "2013-08-31 03:04:05");

$date = Panda::Date->new("2013-02-05 3:4:5");
is($date->month_begin_new, "2013-02-01 03:04:05");
is($date->month_end_new, "2013-02-28 03:04:05");
is($date->days_in_month, 28);

$date = Panda::Date->new("2012-02-05 3:4:5");
is($date->month_begin_new, "2012-02-01 03:04:05");
is($date->month_end_new, "2012-02-29 03:04:05");
is($date->days_in_month, 29);

# now
my $now = now();
ok(abs($now->epoch - time) <= 1);
# today
$date = today();
is($date->year, $now->year);
is($date->month, $now->month);
is($date->day, $now->day);
is($date->hour, 0);
is($date->min, 0);
is($date->sec, 0);
# today_epoch
ok(abs(today_epoch() - today()->epoch) <= 1);

# date
$date = date(0);
is($date, "1970-01-01 03:00:00");
$date = date 1000000000;
is($date, "2001-09-09 05:46:40");
$date = date [2012,02,20,15,16,17];
is($date, "2012-02-20 15:16:17");
$date = date {year => 2013, month => 06, day => 28, hour => 6, min => 6, sec => 6};
is($date, "2013-06-28 06:06:06");
$date = date "2013-01-26 6:47:29.345341";
is($date, "2013-01-26 06:47:29");

# truncate
$date = date "2013-01-26 6:47:29";
my $date2 = $date->truncate_new;
is($date, "2013-01-26 06:47:29");
is($date2, "2013-01-26 00:00:00");
$date->truncate;
is($date, "2013-01-26 00:00:00");

# to_number
is(int(date(123456789)), 123456789);

# set
$date->set(10);
is($date, "1970-01-01 03:00:10");
$date->set("2970-01-01 03:00:10");
is($date, "2970-01-01 03:00:10");
$date->set([2010,5,6,7,8,9]);
is($date, "2010-05-06 07:08:09");
$date->set({year => 2013, hour => 23});
is($date, "2013-01-01 23:00:00");

# big years
$date = date("85678-01-01");
is($date->year, 85678);
is($date, "85678-01-01");
is($date->string, "85678-01-01 00:00:00");

# dont core dump on bad values
$date = eval { date(bless([114,11,4,20,38,43,4,337,0,1417714723,'MSK'], 'Class::Date')); 1 };
is($date, undef);
$date = eval { date(bless({}, 'jopa')); 1 };
is($date, undef);
$date = eval { date(\1); 1 };
is($date, undef);
$date = eval { date(bless(\(my $a = 1), 'popa')); 1 };
is($date, undef);

done_testing();
