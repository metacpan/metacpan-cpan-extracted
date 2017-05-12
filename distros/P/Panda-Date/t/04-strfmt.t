use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use PDTest;

my $date = Panda::Date->new("2013-03-05 2:4:6");
is($date, "2013-03-05 02:04:06");
is($date->to_string, $date);
is($date, $date->sql);
is($date->iso, $date->sql);
ok(!defined Panda::Date::string_format);
Panda::Date::string_format("%Y%m%d%H%M%S");
is(Panda::Date::string_format, "%Y%m%d%H%M%S");
is($date->to_string, "20130305020406");
Panda::Date::string_format("%Y/%m/%d");
is($date->to_string, "2013/03/05");
Panda::Date::string_format(undef);
is($date->to_string, "2013-03-05 02:04:06");

done_testing();
