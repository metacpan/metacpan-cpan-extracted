use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use PDTest;

my $now = time();

tzset('Europe/Moscow');
is(tzname(), 'Europe/Moscow');
my $date1 = &localtime($now);
isnt($date1, undef);
isnt($date1, '');
my @date1 = lt2tl(&localtime($now));
tzset('America/New_York');
is(tzname(), 'America/New_York');
my $date2 = &localtime($now);
my @date2 = lt2tl(&localtime($now));
tzset('Australia/Melbourne');
is(tzname(), 'Australia/Melbourne');
my $date3 = &localtime($now);
my @date3 = lt2tl(&localtime($now));

ok(tzdir('t/testzones'));
my @zones = available_zones();
is(scalar(@zones), 2);

tzset('Moscow');
is(tzname(), 'Moscow');
is(scalar &localtime($now), $date1);
is(&timelocal(@date1), $now);

tzset('New_York');
is(tzname(), 'New_York');
is(scalar &localtime($now), $date2);
is(&timelocal(@date2), $now);

tzset('Australia/Melbourne'); # no such timezone in t/testzones, should be using UTC
isnt(tzname(), 'Australia/Melbourne');
isnt(scalar(&localtime($now)), $date3);
isnt(&timelocal(@date3), $now);
tzset('Melbourne');
isnt(tzname(), 'Melbourne');
isnt(scalar(&localtime($now)), $date3);
isnt(&timelocal(@date3), $now);

done_testing();
