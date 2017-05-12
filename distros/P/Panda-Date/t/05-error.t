use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use PDTest;

# OK
my $date = new Panda::Date("2010-01-01");
my $ok;
$ok = 1 if $date;
ok($ok);
ok($date);
is($date->error, E_OK);

# UNPARSABLE
$date = new Panda::Date("pizdets");
$ok = 0;
$ok = 1 if $date;
ok(!$ok);
ok(!$date);
is($date->error, E_UNPARSABLE);
ok($date->errstr);
is(int($date), 0);

done_testing();
