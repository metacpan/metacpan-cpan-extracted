use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use PDTest;

plan skip_all => 'Panda::Lib required for testing Panda::Lib::clone' unless eval { require Panda::Lib; 1 };

# panda-lib clone check
my $a = date(1);
my $b = Panda::Lib::clone($a);
$a->truncate();
is($a, '1970-01-01 00:00:00');
is($b, '1970-01-01 03:00:01');

# check Panda::Lib::clone()
my $rel = rdate("1Y 2M 3D 4h 5m 6s");
my $cl = Panda::Lib::clone($rel);
$rel->year(2); $rel->month(3); $rel->day(4); $rel->hour(5); $rel->minute(6); $rel->second(7);
is($rel, "2Y 3M 4D 5h 6m 7s");
is($cl, "1Y 2M 3D 4h 5m 6s");

# check Panda::Lib::clone()
my $idate = idate("2013-01-01 00:00:00", "2014-12-31 23:59:59");
$cl = Panda::Lib::clone($idate);
$idate->from("2013-02-01 01:01:01");
is($idate, "2013-02-01 01:01:01 ~ 2014-12-31 23:59:59");
is($cl, "2013-01-01 00:00:00 ~ 2014-12-31 23:59:59");

done_testing();
