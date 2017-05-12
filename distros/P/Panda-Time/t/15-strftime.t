use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use PDTest;

plan skip_all => 'rebuild Makefile with TEST_FULL=1 to enable real test coverage' unless Panda::Time->can('test_gmtime');

tzset('Europe/Moscow');

my $epoch = &timelocal(15, 30, 23, 31, 11, 2016);

is(strftime("%Y/%m/%d %H-%M-%S %Z", $epoch), "2016/12/31 23-30-15 MSK");

tzset('Europe/Kiev');

is(strftime("%Y/%m/%d %H-%M-%S %Z", $epoch), "2016/12/31 22-30-15 EET");

done_testing();

sub strftime { return Panda::Time::strftime(@_) }
